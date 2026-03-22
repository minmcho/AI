package handlers

import (
	"encoding/json"
	"io"
	"net/http"
	"net/url"
	"os"
	"strconv"
	"strings"
	"time"
)

type Video struct {
	ID          string   `json:"id"`
	URL         string   `json:"url"`
	Thumbnail   string   `json:"thumbnail"`
	Caption     string   `json:"caption"`
	Likes       int      `json:"likes"`
	Comments    int      `json:"comments"`
	Shares      int      `json:"shares"`
	Duration    float64  `json:"duration"`
	Tags        []string `json:"tags"`
	MixTrackURL *string  `json:"mix_track_url,omitempty"`
	CreatedAt   string   `json:"created_at"`
}

func Health(w http.ResponseWriter, r *http.Request) {
	writeJSON(w, http.StatusOK, map[string]string{"status": "ok", "ts": time.Now().UTC().Format(time.RFC3339)})
}

// ListVideos proxies paginated video feed from Supabase.
func ListVideos(w http.ResponseWriter, r *http.Request) {
	page, _ := strconv.Atoi(r.URL.Query().Get("page"))
	limit, _ := strconv.Atoi(r.URL.Query().Get("limit"))
	if limit == 0 {
		limit = 5
	}
	offset := page * limit

	supaURL := os.Getenv("SUPABASE_URL")
	anonKey := os.Getenv("SUPABASE_ANON_KEY")

	q := url.Values{}
	q.Set("select", "id,url,thumbnail,caption,likes,comments,shares,duration,tags,mix_track_url,created_at,profiles(id,username,avatar_url)")
	q.Set("order", "created_at.desc")
	q.Set("offset", strconv.Itoa(offset))
	q.Set("limit", strconv.Itoa(limit))

	req, _ := http.NewRequestWithContext(r.Context(), "GET", supaURL+"/rest/v1/videos?"+q.Encode(), nil)
	req.Header.Set("apikey", anonKey)
	req.Header.Set("Authorization", "Bearer "+anonKey)

	resp, err := http.DefaultClient.Do(req)
	if err != nil {
		writeJSON(w, http.StatusBadGateway, map[string]string{"error": err.Error()})
		return
	}
	defer resp.Body.Close()

	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(resp.StatusCode)
	io.Copy(w, resp.Body)
}

// GetVideo fetches a single video by ID.
func GetVideo(w http.ResponseWriter, r *http.Request) {
	id := r.PathValue("id")
	supaURL := os.Getenv("SUPABASE_URL")
	anonKey := os.Getenv("SUPABASE_ANON_KEY")

	req, _ := http.NewRequestWithContext(r.Context(), "GET",
		supaURL+"/rest/v1/videos?id=eq."+id+"&select=*,profiles(id,username,avatar_url)&limit=1", nil)
	req.Header.Set("apikey", anonKey)
	req.Header.Set("Authorization", "Bearer "+anonKey)

	resp, err := http.DefaultClient.Do(req)
	if err != nil {
		writeJSON(w, http.StatusBadGateway, map[string]string{"error": err.Error()})
		return
	}
	defer resp.Body.Close()

	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(resp.StatusCode)
	io.Copy(w, resp.Body)
}

// LikeVideo calls the Supabase RPC to atomically increment likes.
func LikeVideo(w http.ResponseWriter, r *http.Request) {
	id := r.PathValue("id")
	supaURL := os.Getenv("SUPABASE_URL")
	anonKey := os.Getenv("SUPABASE_ANON_KEY")

	body := strings.NewReader(`{"video_id":"` + id + `"}`)
	req, _ := http.NewRequestWithContext(r.Context(), "POST", supaURL+"/rest/v1/rpc/increment_likes", body)
	req.Header.Set("apikey", anonKey)
	req.Header.Set("Authorization", "Bearer "+anonKey)
	req.Header.Set("Content-Type", "application/json")

	resp, err := http.DefaultClient.Do(req)
	if err != nil {
		writeJSON(w, http.StatusBadGateway, map[string]string{"error": err.Error()})
		return
	}
	defer resp.Body.Close()
	writeJSON(w, http.StatusOK, map[string]bool{"ok": true})
}

// ShareVideo increments share count.
func ShareVideo(w http.ResponseWriter, r *http.Request) {
	id := r.PathValue("id")
	supaURL := os.Getenv("SUPABASE_URL")
	anonKey := os.Getenv("SUPABASE_ANON_KEY")

	body := strings.NewReader(`{"video_id":"` + id + `"}`)
	req, _ := http.NewRequestWithContext(r.Context(), "POST", supaURL+"/rest/v1/rpc/increment_shares", body)
	req.Header.Set("apikey", anonKey)
	req.Header.Set("Authorization", "Bearer "+anonKey)
	req.Header.Set("Content-Type", "application/json")

	resp, err := http.DefaultClient.Do(req)
	if err != nil {
		writeJSON(w, http.StatusBadGateway, map[string]string{"error": err.Error()})
		return
	}
	defer resp.Body.Close()
	writeJSON(w, http.StatusOK, map[string]bool{"ok": true})
}

// StreamVideo proxies video bytes from Supabase Storage with HTTP range support.
func StreamVideo(w http.ResponseWriter, r *http.Request) {
	id := r.PathValue("id")
	storageURL := os.Getenv("SUPABASE_URL") + "/storage/v1/object/public/videos/" + id
	anonKey := os.Getenv("SUPABASE_ANON_KEY")

	req, _ := http.NewRequestWithContext(r.Context(), "GET", storageURL, nil)
	req.Header.Set("apikey", anonKey)
	if rangeHeader := r.Header.Get("Range"); rangeHeader != "" {
		req.Header.Set("Range", rangeHeader)
	}

	resp, err := http.DefaultClient.Do(req)
	if err != nil {
		http.Error(w, err.Error(), http.StatusBadGateway)
		return
	}
	defer resp.Body.Close()

	// Forward relevant headers
	for _, h := range []string{"Content-Type", "Content-Length", "Content-Range", "Accept-Ranges"} {
		if v := resp.Header.Get(h); v != "" {
			w.Header().Set(h, v)
		}
	}
	w.WriteHeader(resp.StatusCode)
	io.Copy(w, resp.Body)
}

func writeJSON(w http.ResponseWriter, status int, v any) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(status)
	json.NewEncoder(w).Encode(v)
}
