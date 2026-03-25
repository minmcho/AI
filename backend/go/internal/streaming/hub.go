// Package streaming provides a WebSocket / SSE pub-sub hub for real-time
// cargo-tracking events.
package streaming

import (
	"context"
	"encoding/json"
	"log/slog"
	"sync"
	"time"

	"github.com/gorilla/websocket"
)

// EventType enumerates every domain event the hub can broadcast.
type EventType string

const (
	EventShipmentUpdated  EventType = "shipment_updated"
	EventTrackingEvent    EventType = "tracking_event"
	EventNewAlert         EventType = "new_alert"
	EventDefectDetected   EventType = "defect_detected"
	EventInventoryChanged EventType = "inventory_changed"
)

// Event is the envelope sent over the wire to every subscribed client.
type Event struct {
	Type      EventType       `json:"type"`
	Payload   json.RawMessage `json:"payload"`
	Timestamp time.Time       `json:"timestamp"`
}

// Filter narrows which events a client receives.
type Filter struct {
	DepartmentID string
	LocationID   string
	ShipmentID   string
	Severity     string // "info","warning","error","critical" — for alerts
}

// Client represents a connected WebSocket consumer.
type Client struct {
	id     string
	conn   *websocket.Conn
	send   chan Event
	filter Filter
	mu     sync.Mutex
	closed bool
}

// Hub manages all active WebSocket clients.
type Hub struct {
	mu        sync.RWMutex
	clients   map[string]*Client
	broadcast chan Event
	register  chan *Client
	unregister chan *Client
}

// NewHub creates and returns an initialised Hub.
func NewHub() *Hub {
	return &Hub{
		clients:    make(map[string]*Client),
		broadcast:  make(chan Event, 512),
		register:   make(chan *Client, 64),
		unregister: make(chan *Client, 64),
	}
}

// Run starts the hub's event loop; call in a goroutine.
func (h *Hub) Run(ctx context.Context) {
	for {
		select {
		case <-ctx.Done():
			h.mu.Lock()
			for _, c := range h.clients {
				c.close()
			}
			h.mu.Unlock()
			return

		case c := <-h.register:
			h.mu.Lock()
			h.clients[c.id] = c
			h.mu.Unlock()
			slog.Info("ws client registered", "id", c.id, "total", len(h.clients))

		case c := <-h.unregister:
			h.mu.Lock()
			if _, ok := h.clients[c.id]; ok {
				delete(h.clients, c.id)
				c.close()
			}
			h.mu.Unlock()
			slog.Info("ws client unregistered", "id", c.id)

		case evt := <-h.broadcast:
			h.mu.RLock()
			for _, c := range h.clients {
				if matchesFilter(evt, c.filter) {
					select {
					case c.send <- evt:
					default:
						// slow consumer — drop & schedule disconnect
						go func(cl *Client) { h.unregister <- cl }(c)
					}
				}
			}
			h.mu.RUnlock()
		}
	}
}

// Publish pushes an event to every matching subscriber.
func (h *Hub) Publish(evtType EventType, payload any) {
	raw, err := json.Marshal(payload)
	if err != nil {
		slog.Error("hub marshal error", "err", err)
		return
	}
	h.broadcast <- Event{
		Type:      evtType,
		Payload:   raw,
		Timestamp: time.Now().UTC(),
	}
}

// Register adds a new WebSocket client.
func (h *Hub) Register(id string, conn *websocket.Conn, f Filter) *Client {
	c := &Client{
		id:     id,
		conn:   conn,
		send:   make(chan Event, 64),
		filter: f,
	}
	h.register <- c
	return c
}

// Unregister removes a client.
func (h *Hub) Unregister(c *Client) {
	h.unregister <- c
}

// WritePump pumps outbound events to the WebSocket connection.
// Run in a dedicated goroutine per client.
func (c *Client) WritePump() {
	ticker := time.NewTicker(30 * time.Second)
	defer func() {
		ticker.Stop()
		c.conn.Close()
	}()
	for {
		select {
		case evt, ok := <-c.send:
			c.conn.SetWriteDeadline(time.Now().Add(10 * time.Second))
			if !ok {
				c.conn.WriteMessage(websocket.CloseMessage, []byte{})
				return
			}
			if err := c.conn.WriteJSON(evt); err != nil {
				return
			}
		case <-ticker.C:
			c.conn.SetWriteDeadline(time.Now().Add(10 * time.Second))
			if err := c.conn.WriteMessage(websocket.PingMessage, nil); err != nil {
				return
			}
		}
	}
}

// ReadPump reads control frames (ping/close) from the client.
func (c *Client) ReadPump(hub *Hub) {
	defer hub.Unregister(c)
	c.conn.SetReadLimit(512)
	c.conn.SetReadDeadline(time.Now().Add(60 * time.Second))
	c.conn.SetPongHandler(func(string) error {
		c.conn.SetReadDeadline(time.Now().Add(60 * time.Second))
		return nil
	})
	for {
		if _, _, err := c.conn.ReadMessage(); err != nil {
			break
		}
	}
}

func (c *Client) close() {
	c.mu.Lock()
	defer c.mu.Unlock()
	if !c.closed {
		close(c.send)
		c.closed = true
	}
}

// matchesFilter returns true if the event should be delivered to the client.
func matchesFilter(evt Event, f Filter) bool {
	// No filter set → receive everything
	if f.DepartmentID == "" && f.LocationID == "" && f.ShipmentID == "" {
		return true
	}
	// Decode only the "id" fields we need without full model parse
	var envelope struct {
		DepartmentID string `json:"department_id"`
		LocationID   string `json:"location_id"`
		ShipmentID   string `json:"shipment_id"`
		Severity     string `json:"severity"`
	}
	_ = json.Unmarshal(evt.Payload, &envelope)

	if f.ShipmentID != "" && envelope.ShipmentID != f.ShipmentID {
		return false
	}
	if f.DepartmentID != "" && envelope.DepartmentID != f.DepartmentID {
		return false
	}
	if f.LocationID != "" && envelope.LocationID != f.LocationID {
		return false
	}
	return true
}
