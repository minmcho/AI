package handlers

import (
	"encoding/json"
	"log/slog"
	"net/http"
	"strconv"
	"time"

	"github.com/google/uuid"
	"github.com/user/cargotrack/internal/streaming"
)

// InventoryItem mirrors the DB row.
type InventoryItem struct {
	ID            string    `json:"id"`
	LocationID    string    `json:"location_id"`
	DepartmentID  *string   `json:"department_id,omitempty"`
	SKU           string    `json:"sku"`
	Description   *string   `json:"description,omitempty"`
	Quantity      int       `json:"quantity"`
	ReorderPoint  *int      `json:"reorder_point,omitempty"`
	MaxStock      *int      `json:"max_stock,omitempty"`
	BinLocation   *string   `json:"bin_location,omitempty"`
	Category      *string   `json:"category,omitempty"`
	SubCategory   *string   `json:"sub_category,omitempty"`
	ClusterID     *int      `json:"cluster_id,omitempty"`
	LastCountedAt *time.Time `json:"last_counted_at,omitempty"`
	UpdatedAt     time.Time `json:"updated_at"`
}

// ListInventory  GET /api/v1/inventory
func ListInventory(w http.ResponseWriter, r *http.Request) {
	q := r.URL.Query()
	locationID := q.Get("location_id")
	departmentID := q.Get("department_id")
	belowReorder := q.Get("below_reorder") == "true"
	limit := 100
	offset := 0
	if v := q.Get("limit"); v != "" {
		if n, err := strconv.Atoi(v); err == nil && n > 0 && n <= 500 {
			limit = n
		}
	}
	if v := q.Get("offset"); v != "" {
		if n, err := strconv.Atoi(v); err == nil {
			offset = n
		}
	}

	rows, err := DB.QueryContext(r.Context(), `
		SELECT id, location_id, department_id, sku, description,
		       quantity, reorder_point, max_stock, bin_location,
		       category, sub_category, cluster_id,
		       last_counted_at, updated_at
		FROM inventory
		WHERE ($1 = '' OR location_id::text = $1)
		  AND ($2 = '' OR department_id::text = $2)
		  AND (NOT $3   OR (reorder_point IS NOT NULL AND quantity <= reorder_point))
		ORDER BY updated_at DESC
		LIMIT $4 OFFSET $5`,
		locationID, departmentID, belowReorder, limit, offset)
	if err != nil {
		jsonError(w, "db query", http.StatusInternalServerError)
		slog.Error("ListInventory", "err", err)
		return
	}
	defer rows.Close()

	items := make([]InventoryItem, 0)
	for rows.Next() {
		var it InventoryItem
		if err := rows.Scan(
			&it.ID, &it.LocationID, &it.DepartmentID,
			&it.SKU, &it.Description, &it.Quantity,
			&it.ReorderPoint, &it.MaxStock, &it.BinLocation,
			&it.Category, &it.SubCategory, &it.ClusterID,
			&it.LastCountedAt, &it.UpdatedAt,
		); err == nil {
			items = append(items, it)
		}
	}
	jsonOK(w, map[string]any{"inventory": items, "count": len(items)})
}

// GetInventoryItem  GET /api/v1/inventory/{id}
func GetInventoryItem(w http.ResponseWriter, r *http.Request) {
	id := r.PathValue("id")
	var it InventoryItem
	err := DB.QueryRowContext(r.Context(), `
		SELECT id, location_id, department_id, sku, description,
		       quantity, reorder_point, max_stock, bin_location,
		       category, sub_category, cluster_id,
		       last_counted_at, updated_at
		FROM inventory WHERE id = $1`, id).Scan(
		&it.ID, &it.LocationID, &it.DepartmentID,
		&it.SKU, &it.Description, &it.Quantity,
		&it.ReorderPoint, &it.MaxStock, &it.BinLocation,
		&it.Category, &it.SubCategory, &it.ClusterID,
		&it.LastCountedAt, &it.UpdatedAt,
	)
	if err != nil {
		jsonError(w, "not found", http.StatusNotFound)
		return
	}
	jsonOK(w, it)
}

// AdjustInventory  POST /api/v1/inventory/adjust
func AdjustInventory(w http.ResponseWriter, r *http.Request) {
	var body struct {
		LocationID    string `json:"location_id"`
		SKU           string `json:"sku"`
		QuantityDelta int    `json:"quantity_delta"`
		MovementType  string `json:"movement_type"`
		Notes         *string `json:"notes"`
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

	// Upsert inventory row
	var invID string
	var newQty int
	err = tx.QueryRowContext(r.Context(), `
		INSERT INTO inventory (id, location_id, sku, quantity)
		VALUES (gen_random_uuid(), $1, $2, $3)
		ON CONFLICT (location_id, sku) DO UPDATE
		  SET quantity   = inventory.quantity + $3,
		      updated_at = NOW()
		RETURNING id, quantity`,
		body.LocationID, body.SKU, body.QuantityDelta,
	).Scan(&invID, &newQty)
	if err != nil {
		jsonError(w, "upsert inventory", http.StatusInternalServerError)
		slog.Error("AdjustInventory upsert", "err", err)
		return
	}

	// Record movement
	_, err = tx.ExecContext(r.Context(), `
		INSERT INTO inventory_movements
		  (id, inventory_id, movement_type, quantity_delta, quantity_after, notes)
		VALUES (gen_random_uuid(), $1, $2, $3, $4, $5)`,
		invID, body.MovementType, body.QuantityDelta, newQty, body.Notes,
	)
	if err != nil {
		jsonError(w, "insert movement", http.StatusInternalServerError)
		return
	}

	if err = tx.Commit(); err != nil {
		jsonError(w, "tx commit", http.StatusInternalServerError)
		return
	}

	it := InventoryItem{
		ID:         invID,
		LocationID: body.LocationID,
		SKU:        body.SKU,
		Quantity:   newQty,
		UpdatedAt:  time.Now(),
	}

	if Hub != nil {
		Hub.Publish(streaming.EventInventoryChanged, map[string]any{
			"inventory":   it,
			"location_id": body.LocationID,
		})
		// Low-stock alert
		if newQty <= 5 {
			alertID := uuid.NewString()
			_, _ = DB.ExecContext(r.Context(), `
				INSERT INTO alerts
				  (id, alert_type, severity, title, message, entity_type, entity_id, location_id)
				VALUES ($1,'low_stock','warning',$2,$3,'inventory',$4,$5)`,
				alertID,
				"Low Stock: "+body.SKU,
				"SKU "+body.SKU+" has only "+strconv.Itoa(newQty)+" units remaining.",
				invID, body.LocationID,
			)
			Hub.Publish(streaming.EventNewAlert, map[string]any{
				"alert_id":    alertID,
				"alert_type":  "low_stock",
				"severity":    "warning",
				"location_id": body.LocationID,
			})
		}
	}

	jsonOK(w, it)
}

// ListAlerts  GET /api/v1/alerts
func ListAlerts(w http.ResponseWriter, r *http.Request) {
	q := r.URL.Query()
	departmentID := q.Get("department_id")
	severity := q.Get("severity")
	unackedOnly := q.Get("unacknowledged_only") == "true"

	rows, err := DB.QueryContext(r.Context(), `
		SELECT id, alert_type, severity, title, message,
		       entity_type, entity_id, location_id, department_id,
		       acknowledged, created_at
		FROM alerts
		WHERE ($1 = '' OR department_id::text = $1)
		  AND ($2 = '' OR severity = $2)
		  AND (NOT $3   OR acknowledged = FALSE)
		ORDER BY created_at DESC LIMIT 200`,
		departmentID, severity, unackedOnly)
	if err != nil {
		jsonError(w, "db query", http.StatusInternalServerError)
		return
	}
	defer rows.Close()

	type Alert struct {
		ID           string    `json:"id"`
		AlertType    string    `json:"alert_type"`
		Severity     string    `json:"severity"`
		Title        string    `json:"title"`
		Message      string    `json:"message"`
		EntityType   *string   `json:"entity_type,omitempty"`
		EntityID     *string   `json:"entity_id,omitempty"`
		LocationID   *string   `json:"location_id,omitempty"`
		DepartmentID *string   `json:"department_id,omitempty"`
		Acknowledged bool      `json:"acknowledged"`
		CreatedAt    time.Time `json:"created_at"`
	}

	alerts := make([]Alert, 0)
	for rows.Next() {
		var a Alert
		if err := rows.Scan(&a.ID, &a.AlertType, &a.Severity, &a.Title, &a.Message,
			&a.EntityType, &a.EntityID, &a.LocationID, &a.DepartmentID,
			&a.Acknowledged, &a.CreatedAt); err == nil {
			alerts = append(alerts, a)
		}
	}
	jsonOK(w, map[string]any{"alerts": alerts, "count": len(alerts)})
}

// AcknowledgeAlert  POST /api/v1/alerts/{id}/acknowledge
func AcknowledgeAlert(w http.ResponseWriter, r *http.Request) {
	id := r.PathValue("id")
	_, err := DB.ExecContext(r.Context(), `
		UPDATE alerts SET acknowledged = TRUE, acknowledged_at = NOW() WHERE id = $1`, id)
	if err != nil {
		jsonError(w, "db update", http.StatusInternalServerError)
		return
	}
	jsonOK(w, map[string]bool{"acknowledged": true})
}
