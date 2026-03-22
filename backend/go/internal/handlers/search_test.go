package handlers_test

import (
	"net/http"
	"net/http/httptest"
	"os"
	"testing"

	"github.com/user/videofeed/internal/handlers"
	"github.com/user/videofeed/internal/middleware"
)

func setupTestPyServer(response string, status int) *httptest.Server {
	return httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		w.Header().Set("Content-Type", "application/json")
		w.WriteHeader(status)
		w.Write([]byte(response))
	}))
}

func TestSearchVideos(t *testing.T) {
	mock := setupTestPyServer(`{"results":[],"total":0,"query":"test","platforms":["youtube"]}`, 200)
	defer mock.Close()
	os.Setenv("PY_API_URL", mock.URL)

	req := httptest.NewRequest(http.MethodGet, "/api/v1/search?q=test", nil)
	rr := httptest.NewRecorder()
	handlers.SearchVideos(rr, req)

	if rr.Code != http.StatusOK {
		t.Errorf("expected 200, got %d", rr.Code)
	}
}

func TestGetPreferenceOptions(t *testing.T) {
	payload := `{"music_genres":["electronic"],"music_moods":["chill"],"video_types":["dance"],"platforms":["youtube"],"countries":[]}`
	mock := setupTestPyServer(payload, 200)
	defer mock.Close()
	os.Setenv("PY_API_URL", mock.URL)

	req := httptest.NewRequest(http.MethodGet, "/api/v1/preferences/options", nil)
	rr := httptest.NewRecorder()
	handlers.GetPreferenceOptions(rr, req)

	if rr.Code != http.StatusOK {
		t.Errorf("expected 200, got %d", rr.Code)
	}
}

func TestHealthHandler(t *testing.T) {
	req := httptest.NewRequest(http.MethodGet, "/health", nil)
	rr := httptest.NewRecorder()
	handlers.Health(rr, req)

	if rr.Code != http.StatusOK {
		t.Errorf("expected 200, got %d: body=%s", rr.Code, rr.Body.String())
	}
}
