package handlers

import (
	"net/http"
	"net/http/httputil"
	"net/url"
	"time"
)

// PyAPIURL is injected from main.go at startup.
var PyAPIURL string

// pyClient is a shared HTTP client for proxying to FastAPI.
var pyClient = &http.Client{Timeout: 60 * time.Second}

// ProxyMLClustering proxies GET /api/v1/ml/cluster/{runType}/latest
// to FastAPI  GET /ml/cluster/{runType}/latest
func ProxyMLClustering(w http.ResponseWriter, r *http.Request) {
	runType := r.PathValue("runType")
	path := "/ml/cluster/" + runType + "/latest"
	r2, err := http.NewRequestWithContext(r.Context(), http.MethodGet,
		PyAPIURL+path+"?"+r.URL.RawQuery, nil)
	if err != nil {
		jsonError(w, "proxy build request", http.StatusInternalServerError)
		return
	}
	copyHeaders(r2, r)
	resp, err := pyClient.Do(r2)
	if err != nil {
		jsonError(w, "proxy call failed: "+err.Error(), http.StatusBadGateway)
		return
	}
	defer resp.Body.Close()
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(resp.StatusCode)
	copyBody(w, resp)
}

// ReverseProxyToPy creates a one-shot reverse proxy to the FastAPI service.
// Used for routes where we want full transparent proxying (headers, status, body).
func ReverseProxyToPy(targetPath string) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		base, err := url.Parse(PyAPIURL)
		if err != nil {
			jsonError(w, "invalid PY_API_URL", http.StatusInternalServerError)
			return
		}
		proxy := httputil.NewSingleHostReverseProxy(base)
		r.URL.Path = targetPath
		proxy.ServeHTTP(w, r)
	}
}
