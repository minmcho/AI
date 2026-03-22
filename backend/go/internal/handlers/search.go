package handlers

import (
	"encoding/json"
	"fmt"
	"net/http"
	"net/url"
	"os"
	"strings"
)

// SearchProxy forwards search requests to the Python FastAPI service
// and adds caching headers. Keeps the Go layer as the single entry point for the iOS app.
func SearchVideos(w http.ResponseWriter, r *http.Request) {
	proxyToPython(w, r, "/ai/search")
}

func GetPreferences(w http.ResponseWriter, r *http.Request) {
	profileID := r.PathValue("profileID")
	proxyToPython(w, r, "/ai/preferences/"+profileID)
}

func UpsertPreferences(w http.ResponseWriter, r *http.Request) {
	profileID := r.PathValue("profileID")
	proxyToPythonWithBody(w, r, http.MethodPut, "/ai/preferences/"+profileID)
}

func GetPreferenceOptions(w http.ResponseWriter, r *http.Request) {
	proxyToPython(w, r, "/ai/preferences/options")
}

func ListFavorites(w http.ResponseWriter, r *http.Request) {
	profileID := r.PathValue("profileID")
	proxyToPython(w, r, "/ai/favorites/"+profileID)
}

func AddFavorite(w http.ResponseWriter, r *http.Request) {
	profileID := r.PathValue("profileID")
	proxyToPythonWithBody(w, r, http.MethodPost, "/ai/favorites/"+profileID)
}

func RemoveFavorite(w http.ResponseWriter, r *http.Request) {
	profileID  := r.PathValue("profileID")
	favoriteID := r.PathValue("favoriteID")
	proxyToPythonWithBody(w, r, http.MethodDelete, "/ai/favorites/"+profileID+"/"+favoriteID)
}

func GetRecommendations(w http.ResponseWriter, r *http.Request) {
	profileID := r.PathValue("profileID")
	proxyToPython(w, r, "/ai/recommendations/"+profileID)
}

func GetMusicRecommendations(w http.ResponseWriter, r *http.Request) {
	profileID := r.PathValue("profileID")
	proxyToPython(w, r, "/ai/recommendations/"+profileID+"/music")
}

// ── Proxy helpers ─────────────────────────────────────────────────────────────

func proxyToPython(w http.ResponseWriter, r *http.Request, path string) {
	pyBase := os.Getenv("PY_API_URL")
	if pyBase == "" {
		pyBase = "http://localhost:8000"
	}

	target, _ := url.Parse(pyBase + path)
	target.RawQuery = r.URL.RawQuery

	req, err := http.NewRequestWithContext(r.Context(), http.MethodGet, target.String(), nil)
	if err != nil {
		writeJSON(w, http.StatusInternalServerError, map[string]string{"error": err.Error()})
		return
	}
	copyHeaders(req, r)

	resp, err := http.DefaultClient.Do(req)
	if err != nil {
		writeJSON(w, http.StatusBadGateway, map[string]string{"error": err.Error()})
		return
	}
	defer resp.Body.Close()

	// Cache search results for 30s at the CDN layer
	if strings.Contains(path, "/search") {
		w.Header().Set("Cache-Control", "public, max-age=30, stale-while-revalidate=60")
	}

	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(resp.StatusCode)
	json.NewDecoder(resp.Body)
	copyBody(w, resp)
}

func proxyToPythonWithBody(w http.ResponseWriter, r *http.Request, method, path string) {
	pyBase := os.Getenv("PY_API_URL")
	if pyBase == "" {
		pyBase = "http://localhost:8000"
	}

	target := fmt.Sprintf("%s%s", pyBase, path)
	req, err := http.NewRequestWithContext(r.Context(), method, target, r.Body)
	if err != nil {
		writeJSON(w, http.StatusInternalServerError, map[string]string{"error": err.Error()})
		return
	}
	copyHeaders(req, r)

	resp, err := http.DefaultClient.Do(req)
	if err != nil {
		writeJSON(w, http.StatusBadGateway, map[string]string{"error": err.Error()})
		return
	}
	defer resp.Body.Close()

	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(resp.StatusCode)
	copyBody(w, resp)
}

func copyHeaders(dst *http.Request, src *http.Request) {
	for key, vals := range src.Header {
		for _, v := range vals {
			dst.Header.Add(key, v)
		}
	}
}

func copyBody(w http.ResponseWriter, resp *http.Response) {
	buf := make([]byte, 32*1024)
	for {
		n, err := resp.Body.Read(buf)
		if n > 0 {
			w.Write(buf[:n])
		}
		if err != nil {
			break
		}
	}
}

func pyBase() string {
	if v := os.Getenv("PY_API_URL"); v != "" {
		return v
	}
	return "http://localhost:8000"
}
