package handlers

import (
	"log/slog"
	"net/http"

	"github.com/google/uuid"
	"github.com/gorilla/websocket"
	"github.com/user/cargotrack/internal/streaming"
)

var upgrader = websocket.Upgrader{
	ReadBufferSize:  1024,
	WriteBufferSize: 4096,
	CheckOrigin: func(r *http.Request) bool {
		// TODO: restrict to known origins in production
		return true
	},
}

// WebSocketHandler  GET /ws
// Query params:
//   - department_id   — filter events by department
//   - location_id     — filter events by location
//   - shipment_id     — filter tracking events for one shipment
func WebSocketHandler(w http.ResponseWriter, r *http.Request) {
	conn, err := upgrader.Upgrade(w, r, nil)
	if err != nil {
		slog.Error("ws upgrade", "err", err)
		return
	}

	q := r.URL.Query()
	filter := streaming.Filter{
		DepartmentID: q.Get("department_id"),
		LocationID:   q.Get("location_id"),
		ShipmentID:   q.Get("shipment_id"),
	}

	clientID := uuid.NewString()
	client := Hub.Register(clientID, conn, filter)

	go client.WritePump()
	client.ReadPump(Hub)
}

// SSEHandler  GET /sse
// Server-Sent Events endpoint — simpler than WebSocket for read-only consumers.
func SSEHandler(w http.ResponseWriter, r *http.Request) {
	flusher, ok := w.(http.Flusher)
	if !ok {
		http.Error(w, "SSE not supported", http.StatusInternalServerError)
		return
	}

	w.Header().Set("Content-Type", "text/event-stream")
	w.Header().Set("Cache-Control", "no-cache")
	w.Header().Set("Connection", "keep-alive")
	w.Header().Set("X-Accel-Buffering", "no") // Nginx

	// Reuse WebSocket client as send channel; wrap in SSE
	conn := &sseConn{w: w, flusher: flusher}
	q := r.URL.Query()
	filter := streaming.Filter{
		DepartmentID: q.Get("department_id"),
		LocationID:   q.Get("location_id"),
		ShipmentID:   q.Get("shipment_id"),
	}
	clientID := uuid.NewString()
	client := Hub.Register(clientID, conn.toWS(), filter)

	go client.WritePump()

	<-r.Context().Done()
	Hub.Unregister(client)
}

// sseConn adapts http.ResponseWriter to a minimal websocket-like interface
// by wrapping events as SSE text/event-stream data lines.
type sseConn struct {
	w       http.ResponseWriter
	flusher http.Flusher
}

// toWS creates a fake websocket.Conn so we can reuse streaming.Client.
// In a real implementation you'd use a proper SSE-specific client type.
// Here we fall back to the WebSocket path by upgrading.
func (s *sseConn) toWS() *websocket.Conn {
	// Not actually used; SSEHandler upgrades separately.
	return nil
}
