package webhooks

import (
	"crypto/hmac"
	"crypto/sha256"
	"encoding/hex"
	"encoding/json"
	"io"
	"log"
	"net/http"
	"os"
)

type WebhookEvent struct {
	Type    string          `json:"type"`
	Table   string          `json:"table,omitempty"`
	Record  json.RawMessage `json:"record,omitempty"`
	Payload json.RawMessage `json:"payload,omitempty"`
}

// SupabaseHandler receives Supabase Database Webhooks (pg_net or Supabase webhooks).
// Verifies HMAC-SHA256 signature from the X-Supabase-Signature header.
func SupabaseHandler(w http.ResponseWriter, r *http.Request) {
	body, err := io.ReadAll(io.LimitReader(r.Body, 1<<20))
	if err != nil {
		http.Error(w, "read error", http.StatusBadRequest)
		return
	}

	secret := os.Getenv("SUPABASE_WEBHOOK_SECRET")
	if secret != "" {
		sig := r.Header.Get("X-Supabase-Signature")
		if !verifyHMAC(body, sig, secret) {
			http.Error(w, "invalid signature", http.StatusUnauthorized)
			return
		}
	}

	var event WebhookEvent
	if err := json.Unmarshal(body, &event); err != nil {
		http.Error(w, "bad payload", http.StatusBadRequest)
		return
	}

	log.Printf("[supabase webhook] type=%s table=%s", event.Type, event.Table)

	switch event.Type {
	case "INSERT":
		handleInsert(event)
	case "UPDATE":
		handleUpdate(event)
	case "DELETE":
		handleDelete(event)
	}

	w.WriteHeader(http.StatusOK)
}

// OpenClawHandler receives job completion callbacks from the Python OpenClaw agent service.
func OpenClawHandler(w http.ResponseWriter, r *http.Request) {
	body, err := io.ReadAll(io.LimitReader(r.Body, 1<<20))
	if err != nil {
		http.Error(w, "read error", http.StatusBadRequest)
		return
	}

	secret := os.Getenv("OPENCLAW_WEBHOOK_SECRET")
	if secret != "" {
		sig := r.Header.Get("X-OpenClaw-Signature")
		if !verifyHMAC(body, sig, secret) {
			http.Error(w, "invalid signature", http.StatusUnauthorized)
			return
		}
	}

	var event WebhookEvent
	if err := json.Unmarshal(body, &event); err != nil {
		http.Error(w, "bad payload", http.StatusBadRequest)
		return
	}

	log.Printf("[openclaw webhook] type=%s payload=%s", event.Type, string(event.Payload))

	// Forward job completion to Supabase so Swift app's realtime subscription fires
	switch event.Type {
	case "job.completed", "job.failed":
		updateJobInSupabase(event)
	}

	w.WriteHeader(http.StatusOK)
}

// verifyHMAC checks HMAC-SHA256 signature.
func verifyHMAC(body []byte, sig, secret string) bool {
	mac := hmac.New(sha256.New, []byte(secret))
	mac.Write(body)
	expected := hex.EncodeToString(mac.Sum(nil))
	return hmac.Equal([]byte(sig), []byte(expected))
}

func handleInsert(e WebhookEvent) {
	log.Printf("[supabase] new row in %s", e.Table)
}

func handleUpdate(e WebhookEvent) {
	log.Printf("[supabase] updated row in %s", e.Table)
}

func handleDelete(e WebhookEvent) {
	log.Printf("[supabase] deleted row in %s", e.Table)
}

func updateJobInSupabase(e WebhookEvent) {
	log.Printf("[openclaw] updating job in supabase: %s", string(e.Payload))
	// TODO: PATCH /rest/v1/agent_jobs with job status from payload
}
