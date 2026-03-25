package main

import (
	"context"
	"database/sql"
	"log"
	"log/slog"
	"net/http"
	"os"
	"os/signal"
	"syscall"
	"time"

	_ "github.com/lib/pq"
	"github.com/user/cargotrack/internal/handlers"
	"github.com/user/cargotrack/internal/middleware"
	"github.com/user/cargotrack/internal/streaming"
	"github.com/user/cargotrack/internal/webhooks"
)

func main() {
	port := env("PORT", "8080")
	dbURL := env("DATABASE_URL", "")
	pyURL := env("PY_API_URL", "http://api-py:8000")

	// ── Database ──────────────────────────────────────────────
	var db *sql.DB
	if dbURL != "" {
		var err error
		db, err = sql.Open("postgres", dbURL)
		if err != nil {
			log.Fatalf("db open: %v", err)
		}
		db.SetMaxOpenConns(20)
		db.SetMaxIdleConns(5)
		db.SetConnMaxLifetime(5 * time.Minute)
		if err = db.Ping(); err != nil {
			log.Fatalf("db ping: %v", err)
		}
		slog.Info("connected to PostgreSQL")
	} else {
		slog.Warn("DATABASE_URL not set — running without DB")
	}

	// ── Streaming hub ─────────────────────────────────────────
	hub := streaming.NewHub()
	ctx, cancel := context.WithCancel(context.Background())
	defer cancel()
	go hub.Run(ctx)

	// Inject into handlers
	handlers.DB = db
	handlers.Hub = hub
	handlers.PyAPIURL = pyURL

	// ── Router ────────────────────────────────────────────────
	mux := http.NewServeMux()

	// Health
	mux.HandleFunc("GET /health", handlers.Health)

	// ── Cargo / Shipments ─────────────────────────────────────
	mux.HandleFunc("GET /api/v1/shipments",                        handlers.ListShipments)
	mux.HandleFunc("GET /api/v1/shipments/{id}",                   handlers.GetShipment)
	mux.HandleFunc("POST /api/v1/shipments",                       handlers.CreateShipment)
	mux.HandleFunc("PATCH /api/v1/shipments/{id}/status",          handlers.UpdateShipmentStatus)
	mux.HandleFunc("GET /api/v1/shipments/track/{trackingNumber}", handlers.GetShipmentByTracking)
	mux.HandleFunc("GET /api/v1/shipments/{id}/items",             handlers.ListCargoItems)
	mux.HandleFunc("POST /api/v1/shipments/{id}/items",            handlers.AddCargoItem)
	mux.HandleFunc("GET /api/v1/shipments/{id}/events",            handlers.ListTrackingEvents)

	// ── Inventory ─────────────────────────────────────────────
	mux.HandleFunc("GET /api/v1/inventory",                        handlers.ListInventory)
	mux.HandleFunc("GET /api/v1/inventory/{id}",                   handlers.GetInventoryItem)
	mux.HandleFunc("POST /api/v1/inventory/adjust",                handlers.AdjustInventory)

	// ── Alerts ────────────────────────────────────────────────
	mux.HandleFunc("GET /api/v1/alerts",                           handlers.ListAlerts)
	mux.HandleFunc("POST /api/v1/alerts/{id}/acknowledge",         handlers.AcknowledgeAlert)

	// ── Dashboard ─────────────────────────────────────────────
	mux.HandleFunc("GET /api/v1/dashboard/stats",                  handlers.DashboardStats)

	// ── Org structure (proxied to FastAPI) ────────────────────
	mux.HandleFunc("GET /api/v1/departments",                      handlers.ProxyToPyGET("/cargo/departments"))
	mux.HandleFunc("GET /api/v1/regions",                          handlers.ProxyToPyGET("/cargo/regions"))
	mux.HandleFunc("GET /api/v1/locations",                        handlers.ProxyToPyGET("/cargo/locations"))
	mux.HandleFunc("GET /api/v1/units",                            handlers.ProxyToPyGET("/cargo/units"))

	// ── ML / AI (proxy to FastAPI) ────────────────────────────
	mux.HandleFunc("POST /api/v1/ml/defect-detect",                handlers.ProxyToPyPOST("/ml/defect-detect"))
	mux.HandleFunc("POST /api/v1/ml/classify",                     handlers.ProxyToPyPOST("/ml/classify"))
	mux.HandleFunc("POST /api/v1/ml/cluster",                      handlers.ProxyToPyPOST("/ml/cluster"))
	mux.HandleFunc("GET /api/v1/ml/cluster/{runType}/latest",      handlers.ProxyMLClustering)
	mux.HandleFunc("POST /api/v1/ml/similar-items",                handlers.ProxyToPyPOST("/ml/similar-items"))
	mux.HandleFunc("POST /api/v1/ml/reason",                       handlers.ProxyToPyPOST("/ml/reason"))

	// ── GraphQL ───────────────────────────────────────────────
	mux.HandleFunc("/graphql",                                      handlers.GraphQLHandler)

	// ── WebSocket real-time ───────────────────────────────────
	mux.HandleFunc("/ws",                                           handlers.WebSocketHandler)

	// ── Webhooks ──────────────────────────────────────────────
	mux.HandleFunc("POST /webhooks/supabase",                       webhooks.SupabaseHandler)
	mux.HandleFunc("POST /webhooks/openclaw",                       webhooks.OpenClawHandler)

	handler := middleware.Chain(
		mux,
		middleware.CORS,
		middleware.RequestID,
		middleware.Logger,
		middleware.RateLimit(200),
	)

	srv := &http.Server{
		Addr:         ":" + port,
		Handler:      handler,
		ReadTimeout:  15 * time.Second,
		WriteTimeout: 30 * time.Second,
		IdleTimeout:  60 * time.Second,
	}

	go func() {
		slog.Info("CargoTrack Go gateway listening", "port", port)
		if err := srv.ListenAndServe(); err != nil && err != http.ErrServerClosed {
			log.Fatalf("listen: %v", err)
		}
	}()

	quit := make(chan os.Signal, 1)
	signal.Notify(quit, syscall.SIGINT, syscall.SIGTERM)
	<-quit
	slog.Info("shutting down…")

	shutCtx, shutCancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer shutCancel()
	if err := srv.Shutdown(shutCtx); err != nil {
		log.Fatalf("shutdown: %v", err)
	}
}

func env(key, fallback string) string {
	if v := os.Getenv(key); v != "" {
		return v
	}
	return fallback
}
