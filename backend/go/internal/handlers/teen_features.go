package handlers

import (
	"fmt"
	"net/http"
)

// Generic GET proxy that rewrites to a fixed Python path + original query string.
func ProxyToPyGET(pyPath string) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		r2, _ := http.NewRequestWithContext(r.Context(), http.MethodGet,
			pyURL(pyPath+"?"+r.URL.RawQuery), nil)
		copyHeaders(r2, r)
		doProxy(w, r2)
	}
}

// Generic POST proxy that forwards body to a fixed Python path.
func ProxyToPyPOST(pyPath string) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		r2, _ := http.NewRequestWithContext(r.Context(), http.MethodPost,
			pyURL(pyPath), r.Body)
		copyHeaders(r2, r)
		doProxy(w, r2)
	}
}

// Profile-path GET: /ai/<prefix><profileID>[<suffix>] + query string.
func ProxyToPyGETProfile(prefix string, suffix ...string) http.HandlerFunc {
	sfx := ""
	if len(suffix) > 0 {
		sfx = suffix[0]
	}
	return func(w http.ResponseWriter, r *http.Request) {
		profileID := r.PathValue("profileID")
		path := fmt.Sprintf("%s%s%s?%s", prefix, profileID, sfx, r.URL.RawQuery)
		r2, _ := http.NewRequestWithContext(r.Context(), http.MethodGet, pyURL(path), nil)
		copyHeaders(r2, r)
		doProxy(w, r2)
	}
}

// Specific helpers for URL path extraction
func ProxyChallenge(w http.ResponseWriter, r *http.Request) {
	id := r.PathValue("id")
	r2, _ := http.NewRequestWithContext(r.Context(), http.MethodGet,
		pyURL("/ai/challenges/"+id), nil)
	copyHeaders(r2, r)
	doProxy(w, r2)
}

func ProxyChallengeJoin(w http.ResponseWriter, r *http.Request) {
	id := r.PathValue("id")
	r2, _ := http.NewRequestWithContext(r.Context(), http.MethodPost,
		pyURL("/ai/challenges/"+id+"/join"), r.Body)
	copyHeaders(r2, r)
	doProxy(w, r2)
}

func ProxyChallengeLeaderboard(w http.ResponseWriter, r *http.Request) {
	id := r.PathValue("id")
	r2, _ := http.NewRequestWithContext(r.Context(), http.MethodGet,
		pyURL("/ai/challenges/"+id+"/leaderboard?"+r.URL.RawQuery), nil)
	copyHeaders(r2, r)
	doProxy(w, r2)
}

func ProxyVibeMatch(w http.ResponseWriter, r *http.Request) {
	profileID := r.PathValue("profileID")
	r2, _ := http.NewRequestWithContext(r.Context(), http.MethodGet,
		pyURL("/ai/vibe-match/"+profileID+"?"+r.URL.RawQuery), nil)
	copyHeaders(r2, r)
	doProxy(w, r2)
}

func ProxyVibeMatchShared(w http.ResponseWriter, r *http.Request) {
	profileID := r.PathValue("profileID")
	r2, _ := http.NewRequestWithContext(r.Context(), http.MethodGet,
		pyURL("/ai/vibe-match/"+profileID+"/shared-favorites?"+r.URL.RawQuery), nil)
	copyHeaders(r2, r)
	doProxy(w, r2)
}

func ProxyStudyStats(w http.ResponseWriter, r *http.Request) {
	profileID := r.PathValue("profileID")
	r2, _ := http.NewRequestWithContext(r.Context(), http.MethodGet,
		pyURL("/ai/study/stats/"+profileID), nil)
	copyHeaders(r2, r)
	doProxy(w, r2)
}

// ── shared internals ──────────────────────────────────────────────────────────

func pyURL(path string) string {
	base := pyBase()
	return base + path
}

func doProxy(w http.ResponseWriter, r *http.Request) {
	resp, err := http.DefaultClient.Do(r)
	if err != nil {
		writeJSON(w, http.StatusBadGateway, map[string]string{"error": err.Error()})
		return
	}
	defer resp.Body.Close()
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(resp.StatusCode)
	copyBody(w, resp)
}
