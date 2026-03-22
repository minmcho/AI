package main

import (
	"log"
	"net/http"
	"os"

	"github.com/user/videofeed/internal/handlers"
	"github.com/user/videofeed/internal/middleware"
	"github.com/user/videofeed/internal/webhooks"
)

func main() {
	port := os.Getenv("PORT")
	if port == "" {
		port = "8080"
	}

	mux := http.NewServeMux()

	// Health
	mux.HandleFunc("GET /health", handlers.Health)

	// Video feed API
	mux.HandleFunc("GET /api/v1/videos", handlers.ListVideos)
	mux.HandleFunc("GET /api/v1/videos/{id}", handlers.GetVideo)
	mux.HandleFunc("POST /api/v1/videos/{id}/like", handlers.LikeVideo)
	mux.HandleFunc("POST /api/v1/videos/{id}/share", handlers.ShareVideo)

	// Video streaming (range-request aware)
	mux.HandleFunc("GET /api/v1/stream/{id}", handlers.StreamVideo)

	// Mood Feed
	mux.HandleFunc("GET /api/v1/moods",                                  handlers.ProxyToPyGET("/ai/moods"))
	mux.HandleFunc("GET /api/v1/feed/mood",                              handlers.ProxyToPyGET("/ai/feed/mood"))

	// Challenges
	mux.HandleFunc("GET /api/v1/challenges",                             handlers.ProxyToPyGET("/ai/challenges"))
	mux.HandleFunc("GET /api/v1/challenges/{id}",                        handlers.ProxyChallenge)
	mux.HandleFunc("POST /api/v1/challenges",                            handlers.ProxyToPyPOST("/ai/challenges"))
	mux.HandleFunc("POST /api/v1/challenges/{id}/join",                  handlers.ProxyChallengeJoin)
	mux.HandleFunc("GET /api/v1/challenges/{id}/leaderboard",            handlers.ProxyChallengeLeaderboard)

	// Streaks & XP
	mux.HandleFunc("GET /api/v1/streak/{profileID}",                     handlers.ProxyToPyGETProfile("/ai/streak/"))
	mux.HandleFunc("POST /api/v1/streak/award",                          handlers.ProxyToPyPOST("/ai/streak/award"))
	mux.HandleFunc("GET /api/v1/streak/{profileID}/leaderboard",         handlers.ProxyToPyGETProfile("/ai/streak/", "/leaderboard"))
	mux.HandleFunc("GET /api/v1/badges",                                 handlers.ProxyToPyGET("/ai/badges"))

	// Vibe Match
	mux.HandleFunc("GET /api/v1/vibe-match/{profileID}",                 handlers.ProxyVibeMatch)
	mux.HandleFunc("GET /api/v1/vibe-match/{profileID}/shared-favorites", handlers.ProxyVibeMatchShared)

	// Study Mode
	mux.HandleFunc("GET /api/v1/study/lofi-feed",                        handlers.ProxyToPyGET("/ai/study/lofi-feed"))
	mux.HandleFunc("POST /api/v1/study/session",                         handlers.ProxyToPyPOST("/ai/study/session"))
	mux.HandleFunc("GET /api/v1/study/stats/{profileID}",                handlers.ProxyStudyStats)

	// Search & Discovery
	mux.HandleFunc("GET /api/v1/search",                                 handlers.SearchVideos)
	mux.HandleFunc("GET /api/v1/recommendations/{profileID}",            handlers.GetRecommendations)
	mux.HandleFunc("GET /api/v1/recommendations/{profileID}/music",      handlers.GetMusicRecommendations)

	// Preferences
	mux.HandleFunc("GET /api/v1/preferences/options",                    handlers.GetPreferenceOptions)
	mux.HandleFunc("GET /api/v1/preferences/{profileID}",                handlers.GetPreferences)
	mux.HandleFunc("PUT /api/v1/preferences/{profileID}",                handlers.UpsertPreferences)

	// Favorites
	mux.HandleFunc("GET /api/v1/favorites/{profileID}",                  handlers.ListFavorites)
	mux.HandleFunc("POST /api/v1/favorites/{profileID}",                 handlers.AddFavorite)
	mux.HandleFunc("DELETE /api/v1/favorites/{profileID}/{favoriteID}",  handlers.RemoveFavorite)

	// Webhooks (inbound from Supabase + OpenClaw)
	mux.HandleFunc("POST /webhooks/supabase", webhooks.SupabaseHandler)
	mux.HandleFunc("POST /webhooks/openclaw", webhooks.OpenClawHandler)

	handler := middleware.Chain(
		mux,
		middleware.CORS,
		middleware.RequestID,
		middleware.Logger,
		middleware.RateLimit(100),
	)

	log.Printf("Go API gateway listening on :%s", port)
	if err := http.ListenAndServe(":"+port, handler); err != nil {
		log.Fatal(err)
	}
}
