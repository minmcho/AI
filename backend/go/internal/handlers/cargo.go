package handlers

import (
	"database/sql"
	"encoding/json"
	"fmt"
	"log/slog"
	"net/http"
	"strconv"
	"time"

	"github.com/google/uuid"
	"github.com/user/cargotrack/internal/streaming"
)

// ── Types ────────────────────────────────────────────────────

type Shipment struct {
	ID               string    `json:"id"`
	TrackingNumber   string    `json:"tracking_number"`
	Status           string    `json:"status"`
	Priority         string    `json:"priority"`
	OriginID         string    `json:"origin_id"`
	DestinationID    string    `json:"destination_id"`
	DepartmentID     *string   `json:"department_id,omitempty"`
	Carrier          *string   `json:"carrier,omitempty"`
	ServiceType      *string   `json:"service_type,omitempty"`
	EstimatedArrival *time.Time `json:"estimated_arrival,omitempty"`
	ActualArrival    *time.Time `json:"actual_arrival,omitempty"`
	TotalWeightKg    *float64  `json:"total_weight_kg,omitempty"`
	TotalVolumeM3    *float64  `json:"total_volume_m3,omitempty"`
	Notes            *string   `json:"notes,omitempty"`
	CreatedAt        time.Time `json:"created_at"`
	UpdatedAt        time.Time `json:"updated_at"`
}

type CargoItem struct {
	ID          string   `json:"id"`
	ShipmentID  string   `json:"shipment_id"`
	SKU         *string  `json:"sku,omitempty"`
	Description string   `json:"description"`
	Quantity    int      `json:"quantity"`
	WeightKg    *float64 `json:"weight_kg,omitempty"`
	VolumeM3    *float64 `json:"volume_m3,omitempty"`
	ValueUSD    *float64 `json:"value_usd,omitempty"`
	Category    *string  `json:"category,omitempty"`
	SubCategory *string  `json:"sub_category,omitempty"`
	ClusterID   *int     `json:"cluster_id,omitempty"`
	DefectScore *float64 `json:"defect_score,omitempty"`
	CreatedAt   time.Time `json:"created_at"`
}

type TrackingEvent struct {
	ID           string    `json:"id"`
	ShipmentID   string    `json:"shipment_id"`
	EventType    string    `json:"event_type"`
	LocationID   *string   `json:"location_id,omitempty"`
	LocationName *string   `json:"location_name,omitempty"`
	Latitude     *float64  `json:"latitude,omitempty"`
	Longitude    *float64  `json:"longitude,omitempty"`
	Description  *string   `json:"description,omitempty"`
	OccurredAt   time.Time `json:"occurred_at"`
}

// ── Dependencies injected via closure / package-level vars ───

var (
	DB  *sql.DB
	Hub *streaming.Hub
)

// ── Shipment handlers ─────────────────────────────────────────

// ListShipments  GET /api/v1/shipments
func ListShipments(w http.ResponseWriter, r *http.Request) {
	q := r.URL.Query()
	status := q.Get("status")
	departmentID := q.Get("department_id")
	limit := 50
	offset := 0
	if v := q.Get("limit"); v != "" {
		if n, err := strconv.Atoi(v); err == nil && n > 0 && n <= 200 {
			limit = n
		}
	}
	if v := q.Get("offset"); v != "" {
		if n, err := strconv.Atoi(v); err == nil && n >= 0 {
			offset = n
		}
	}

	query := `
		SELECT id, tracking_number, status, priority,
		       origin_id, destination_id, department_id,
		       carrier, service_type,
		       estimated_arrival, actual_arrival,
		       total_weight_kg, total_volume_m3,
		       notes, created_at, updated_at
		FROM shipments
		WHERE ($1 = '' OR status = $1)
		  AND ($2 = '' OR department_id::text = $2)
		ORDER BY created_at DESC
		LIMIT $3 OFFSET $4`

	rows, err := DB.QueryContext(r.Context(), query, status, departmentID, limit, offset)
	if err != nil {
		jsonError(w, "db query failed", http.StatusInternalServerError)
		slog.Error("ListShipments", "err", err)
		return
	}
	defer rows.Close()

	shipments := make([]Shipment, 0)
	for rows.Next() {
		var s Shipment
		err := rows.Scan(
			&s.ID, &s.TrackingNumber, &s.Status, &s.Priority,
			&s.OriginID, &s.DestinationID, &s.DepartmentID,
			&s.Carrier, &s.ServiceType,
			&s.EstimatedArrival, &s.ActualArrival,
			&s.TotalWeightKg, &s.TotalVolumeM3,
			&s.Notes, &s.CreatedAt, &s.UpdatedAt,
		)
		if err != nil {
			slog.Error("scan shipment", "err", err)
			continue
		}
		shipments = append(shipments, s)
	}
	jsonOK(w, map[string]any{"shipments": shipments, "count": len(shipments)})
}

// GetShipment  GET /api/v1/shipments/{id}
func GetShipment(w http.ResponseWriter, r *http.Request) {
	id := r.PathValue("id")
	if _, err := uuid.Parse(id); err != nil {
		jsonError(w, "invalid uuid", http.StatusBadRequest)
		return
	}

	var s Shipment
	err := DB.QueryRowContext(r.Context(), `
		SELECT id, tracking_number, status, priority,
		       origin_id, destination_id, department_id,
		       carrier, service_type,
		       estimated_arrival, actual_arrival,
		       total_weight_kg, total_volume_m3,
		       notes, created_at, updated_at
		FROM shipments WHERE id = $1`, id).Scan(
		&s.ID, &s.TrackingNumber, &s.Status, &s.Priority,
		&s.OriginID, &s.DestinationID, &s.DepartmentID,
		&s.Carrier, &s.ServiceType,
		&s.EstimatedArrival, &s.ActualArrival,
		&s.TotalWeightKg, &s.TotalVolumeM3,
		&s.Notes, &s.CreatedAt, &s.UpdatedAt,
	)
	if err == sql.ErrNoRows {
		jsonError(w, "not found", http.StatusNotFound)
		return
	}
	if err != nil {
		jsonError(w, "db error", http.StatusInternalServerError)
		return
	}
	jsonOK(w, s)
}

// GetShipmentByTracking  GET /api/v1/shipments/track/{trackingNumber}
func GetShipmentByTracking(w http.ResponseWriter, r *http.Request) {
	tn := r.PathValue("trackingNumber")
	if tn == "" {
		jsonError(w, "tracking number required", http.StatusBadRequest)
		return
	}
	var s Shipment
	err := DB.QueryRowContext(r.Context(), `
		SELECT id, tracking_number, status, priority,
		       origin_id, destination_id, department_id,
		       carrier, service_type,
		       estimated_arrival, actual_arrival,
		       total_weight_kg, total_volume_m3,
		       notes, created_at, updated_at
		FROM shipments WHERE tracking_number = $1`, tn).Scan(
		&s.ID, &s.TrackingNumber, &s.Status, &s.Priority,
		&s.OriginID, &s.DestinationID, &s.DepartmentID,
		&s.Carrier, &s.ServiceType,
		&s.EstimatedArrival, &s.ActualArrival,
		&s.TotalWeightKg, &s.TotalVolumeM3,
		&s.Notes, &s.CreatedAt, &s.UpdatedAt,
	)
	if err == sql.ErrNoRows {
		jsonError(w, "not found", http.StatusNotFound)
		return
	}
	if err != nil {
		jsonError(w, "db error", http.StatusInternalServerError)
		return
	}
	jsonOK(w, s)
}

// CreateShipment  POST /api/v1/shipments
func CreateShipment(w http.ResponseWriter, r *http.Request) {
	var body struct {
		OriginID         string  `json:"origin_id"`
		DestinationID    string  `json:"destination_id"`
		DepartmentID     *string `json:"department_id"`
		Carrier          *string `json:"carrier"`
		ServiceType      *string `json:"service_type"`
		Priority         string  `json:"priority"`
		EstimatedArrival *string `json:"estimated_arrival"`
		Notes            *string `json:"notes"`
	}
	if err := json.NewDecoder(r.Body).Decode(&body); err != nil {
		jsonError(w, "invalid body", http.StatusBadRequest)
		return
	}
	if body.Priority == "" {
		body.Priority = "standard"
	}

	id := uuid.NewString()
	tn := fmt.Sprintf("CT-%s", id[:8])

	var eta *time.Time
	if body.EstimatedArrival != nil {
		t, err := time.Parse(time.RFC3339, *body.EstimatedArrival)
		if err == nil {
			eta = &t
		}
	}

	_, err := DB.ExecContext(r.Context(), `
		INSERT INTO shipments
		  (id, tracking_number, status, priority,
		   origin_id, destination_id, department_id,
		   carrier, service_type, estimated_arrival, notes)
		VALUES ($1,$2,'pending',$3,$4,$5,$6,$7,$8,$9,$10)`,
		id, tn, body.Priority,
		body.OriginID, body.DestinationID, body.DepartmentID,
		body.Carrier, body.ServiceType, eta, body.Notes,
	)
	if err != nil {
		jsonError(w, "db insert failed", http.StatusInternalServerError)
		slog.Error("CreateShipment", "err", err)
		return
	}

	s := Shipment{
		ID: id, TrackingNumber: tn, Status: "pending",
		Priority: body.Priority, OriginID: body.OriginID,
		DestinationID: body.DestinationID, DepartmentID: body.DepartmentID,
		Carrier: body.Carrier, ServiceType: body.ServiceType,
		EstimatedArrival: eta, Notes: body.Notes,
		CreatedAt: time.Now(), UpdatedAt: time.Now(),
	}

	// Broadcast real-time update
	if Hub != nil {
		Hub.Publish(streaming.EventShipmentUpdated, map[string]any{
			"shipment":      s,
			"department_id": body.DepartmentID,
		})
	}

	w.WriteHeader(http.StatusCreated)
	jsonOK(w, s)
}

// UpdateShipmentStatus  PATCH /api/v1/shipments/{id}/status
func UpdateShipmentStatus(w http.ResponseWriter, r *http.Request) {
	id := r.PathValue("id")
	var body struct {
		Status      string  `json:"status"`
		LocationID  *string `json:"location_id"`
		Description *string `json:"description"`
	}
	if err := json.NewDecoder(r.Body).Decode(&body); err != nil {
		jsonError(w, "invalid body", http.StatusBadRequest)
		return
	}

	tx, err := DB.BeginTx(r.Context(), nil)
	if err != nil {
		jsonError(w, "tx begin", http.StatusInternalServerError)
		return
	}
	defer tx.Rollback()

	_, err = tx.ExecContext(r.Context(),
		`UPDATE shipments SET status=$2, updated_at=NOW() WHERE id=$1`, id, body.Status)
	if err != nil {
		jsonError(w, "db update", http.StatusInternalServerError)
		return
	}

	evtID := uuid.NewString()
	_, err = tx.ExecContext(r.Context(), `
		INSERT INTO tracking_events
		  (id, shipment_id, event_type, location_id, description)
		VALUES ($1,$2,'status_update',$3,$4)`,
		evtID, id, body.LocationID, body.Description,
	)
	if err != nil {
		jsonError(w, "db insert event", http.StatusInternalServerError)
		return
	}
	if err = tx.Commit(); err != nil {
		jsonError(w, "tx commit", http.StatusInternalServerError)
		return
	}

	evt := TrackingEvent{
		ID: evtID, ShipmentID: id, EventType: "status_update",
		LocationID: body.LocationID, Description: body.Description,
		OccurredAt: time.Now(),
	}

	if Hub != nil {
		Hub.Publish(streaming.EventTrackingEvent, map[string]any{
			"event":       evt,
			"shipment_id": id,
		})
		Hub.Publish(streaming.EventShipmentUpdated, map[string]any{
			"shipment_id": id,
			"status":      body.Status,
		})
	}
	jsonOK(w, evt)
}

// ListCargoItems  GET /api/v1/shipments/{id}/items
func ListCargoItems(w http.ResponseWriter, r *http.Request) {
	shipmentID := r.PathValue("id")
	rows, err := DB.QueryContext(r.Context(), `
		SELECT id, shipment_id, sku, description, quantity,
		       weight_kg, volume_m3, value_usd,
		       category, sub_category, cluster_id, defect_score, created_at
		FROM cargo_items WHERE shipment_id = $1 ORDER BY created_at`, shipmentID)
	if err != nil {
		jsonError(w, "db query", http.StatusInternalServerError)
		return
	}
	defer rows.Close()
	items := make([]CargoItem, 0)
	for rows.Next() {
		var c CargoItem
		if err := rows.Scan(&c.ID, &c.ShipmentID, &c.SKU, &c.Description,
			&c.Quantity, &c.WeightKg, &c.VolumeM3, &c.ValueUSD,
			&c.Category, &c.SubCategory, &c.ClusterID, &c.DefectScore,
			&c.CreatedAt); err == nil {
			items = append(items, c)
		}
	}
	jsonOK(w, map[string]any{"items": items})
}

// AddCargoItem  POST /api/v1/shipments/{id}/items
func AddCargoItem(w http.ResponseWriter, r *http.Request) {
	shipmentID := r.PathValue("id")
	var body CargoItem
	if err := json.NewDecoder(r.Body).Decode(&body); err != nil {
		jsonError(w, "invalid body", http.StatusBadRequest)
		return
	}
	id := uuid.NewString()
	_, err := DB.ExecContext(r.Context(), `
		INSERT INTO cargo_items
		  (id, shipment_id, sku, description, quantity,
		   weight_kg, volume_m3, value_usd)
		VALUES ($1,$2,$3,$4,$5,$6,$7,$8)`,
		id, shipmentID, body.SKU, body.Description, body.Quantity,
		body.WeightKg, body.VolumeM3, body.ValueUSD,
	)
	if err != nil {
		jsonError(w, "db insert", http.StatusInternalServerError)
		slog.Error("AddCargoItem", "err", err)
		return
	}
	body.ID = id
	body.ShipmentID = shipmentID
	body.CreatedAt = time.Now()
	w.WriteHeader(http.StatusCreated)
	jsonOK(w, body)
}

// ListTrackingEvents  GET /api/v1/shipments/{id}/events
func ListTrackingEvents(w http.ResponseWriter, r *http.Request) {
	shipmentID := r.PathValue("id")
	rows, err := DB.QueryContext(r.Context(), `
		SELECT id, shipment_id, event_type, location_id, location_name,
		       latitude, longitude, description, occurred_at
		FROM tracking_events WHERE shipment_id = $1
		ORDER BY occurred_at DESC LIMIT 100`, shipmentID)
	if err != nil {
		jsonError(w, "db query", http.StatusInternalServerError)
		return
	}
	defer rows.Close()
	events := make([]TrackingEvent, 0)
	for rows.Next() {
		var e TrackingEvent
		if err := rows.Scan(&e.ID, &e.ShipmentID, &e.EventType,
			&e.LocationID, &e.LocationName, &e.Latitude, &e.Longitude,
			&e.Description, &e.OccurredAt); err == nil {
			events = append(events, e)
		}
	}
	jsonOK(w, map[string]any{"events": events})
}

// DashboardStats  GET /api/v1/dashboard/stats
func DashboardStats(w http.ResponseWriter, r *http.Request) {
	departmentID := r.URL.Query().Get("department_id")

	var active, delivered, alerts, defects, lowStock int

	_ = DB.QueryRowContext(r.Context(), `
		SELECT COUNT(*) FROM shipments
		WHERE status IN ('pending','in_transit','at_customs','arrived')
		  AND ($1 = '' OR department_id::text = $1)`, departmentID).Scan(&active)

	_ = DB.QueryRowContext(r.Context(), `
		SELECT COUNT(*) FROM shipments
		WHERE status = 'delivered'
		  AND actual_arrival >= CURRENT_DATE
		  AND ($1 = '' OR department_id::text = $1)`, departmentID).Scan(&delivered)

	_ = DB.QueryRowContext(r.Context(), `
		SELECT COUNT(*) FROM alerts
		WHERE acknowledged = FALSE
		  AND ($1 = '' OR department_id::text = $1)`, departmentID).Scan(&alerts)

	_ = DB.QueryRowContext(r.Context(), `
		SELECT COUNT(*) FROM defect_detections
		WHERE resolved_at IS NULL
		  AND ($1 = '' OR location_id IN (
		        SELECT id FROM locations WHERE department_id::text = $1))`,
		departmentID).Scan(&defects)

	_ = DB.QueryRowContext(r.Context(), `
		SELECT COUNT(*) FROM inventory
		WHERE reorder_point IS NOT NULL
		  AND quantity <= reorder_point
		  AND ($1 = '' OR department_id::text = $1)`, departmentID).Scan(&lowStock)

	jsonOK(w, map[string]any{
		"active_shipments": active,
		"delivered_today":  delivered,
		"pending_alerts":   alerts,
		"defects_detected": defects,
		"low_stock_items":  lowStock,
	})
}

// ── helpers ──────────────────────────────────────────────────

func jsonOK(w http.ResponseWriter, v any) {
	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(v)
}

func jsonError(w http.ResponseWriter, msg string, code int) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(code)
	json.NewEncoder(w).Encode(map[string]string{"error": msg})
}
