# VideoFeed — AI-Powered Short-Form Video App

A production-ready, TikTok-style iOS video feed with AI audio manipulation, social media search, and personalised recommendations powered by OpenClaw agents, Gemini, Supabase/pgvector, Go, and Python FastAPI.

---

## Architecture

```
┌─────────────────────────────────────────────────────────┐
│  iOS App (SwiftUI / iOS 17+)                            │
│  Feed · Search · Favorites · Preferences · DJ · Dub     │
└────────────────────┬────────────────────────────────────┘
                     │ HTTPS
          ┌──────────▼──────────┐
          │   Nginx (TLS proxy)  │
          └──────┬───────────────┘
                 │
     ┌───────────▼───────────┐
     │  Go API Gateway :8080  │  ← feed, stream, search proxy, webhooks
     └───────────┬────────────┘
                 │
     ┌───────────▼───────────┐
     │  Python FastAPI :8000  │  ← AI, search aggregation, prefs, recs
     └───────┬────────────────┘
             │
    ┌────────▼──────────┐    ┌─────────────────────────────┐
    │  Supabase/pgvector │    │  OpenClaw Agent              │
    │  HNSW · Realtime   │    │  kokoro-tts · ace-music      │
    │  RLS · RPC         │    │  eachlabs-video-edit         │
    └───────────────────┘    └─────────────────────────────┘
             │
    ┌────────▼────────────────────────────────────────────┐
    │  Social Platforms: YouTube · Spotify · SoundCloud   │
    └─────────────────────────────────────────────────────┘
```

---

## Features

### Video Feed
- Full-screen vertical snap scrolling — iOS 17 `.scrollTargetBehavior(.paging)` + `.scrollPosition(id:)`
- `AVPlayer` with seamless looping and active-video tracking via `@Observable`
- Infinite scroll with Supabase-backed pagination

### DJ Mode
- Real-time speed control (0.5×–2.0×) via `AVAudioEngine` + `AVAudioUnitTimePitch`
- Pitch preservation toggle (tempo-only vs. vinyl shift)
- AutoMix crossfader — blend original audio with OpenClaw `ace-music` generated track

### AI Voice Dubbing (DubPanel)
- **Transcription** — Gemini 2.0 Flash Vision extracts spoken audio
- **Translation** — Gemini translates to 10 target languages
- **TTS** — OpenClaw `kokoro-tts` skill with 6 voice personas
- **Video Edit** — OpenClaw `eachlabs-video-edit` applies lip-sync + subtitles

### Search & Discovery
- Cross-platform search: **YouTube**, **Spotify**, **SoundCloud**, **TikTok**, **Instagram**
- Filter by platform, content type (video / music), and **country**
- pgvector cosine-similarity for "Find Similar Videos"
- Search history + trending suggestions

### Favorites
- Save videos and music from any social platform
- Filter by type (video/music) or platform
- Persistent via Supabase with RLS per user

### Personalised Preferences
- Pick music genres, moods, video types, countries, and platforms
- Preference embedding (Gemini `text-embedding-004`) → pgvector HNSW index
- `personalised_feed()` Supabase RPC — cosine similarity between user and video embeddings

---

## Tech Stack

| Layer | Technology |
|---|---|
| iOS | SwiftUI · iOS 17 · AVFoundation · AVAudioEngine · `@Observable` |
| API Gateway | Go 1.22 · `net/http` ServeMux · `log/slog` · graceful shutdown |
| AI Service | Python 3.12 · FastAPI · asyncpg · Uvicorn |
| AI Models | Gemini 2.0 Flash (transcription, translation, embedding) |
| Voice/Music | OpenClaw (`kokoro-tts`, `ace-music`, `eachlabs-video-edit`) |
| Database | Supabase · PostgreSQL 16 · pgvector HNSW · Realtime · RLS |
| Infra | Docker Compose · Nginx TLS reverse proxy |
| CI/CD | GitHub Actions (iOS · Go · Python) |

---

## Quick Start

### Prerequisites
- Xcode 15.3+ (iOS 17 simulator)
- Go 1.22+
- Python 3.12+
- Docker & Docker Compose
- [Supabase](https://supabase.com) project
- [Gemini API key](https://ai.google.dev)
- OpenClaw (`npx openclaw` or self-hosted)

### 1. Clone & configure

```bash
git clone https://github.com/minmcho/AI.git
cd AI
cp .env.example .env
# Fill in SUPABASE_URL, SUPABASE_ANON_KEY, DATABASE_URL,
# GEMINI_API_KEY, OPENCLAW_*, YOUTUBE_API_KEY, SPOTIFY_*, SOUNDCLOUD_*
```

### 2. Run migrations & seed

```bash
make migrate    # applies supabase/migrations/* via Supabase CLI
make seed       # inserts sample videos and profiles
```

### 3. Start backend

```bash
make docker-up          # Go + Python + OpenClaw + Nginx
# or individually:
make dev-go             # Go API on :8080
make dev-py             # FastAPI on :8000
```

### 4. Open iOS app

```bash
open ios/VideoFeedApp.xcodeproj
# In Xcode → Scheme editor → Run → Arguments → Environment Variables:
# GO_API_URL  = http://localhost:8080
# PY_API_URL  = http://localhost:8000
# SUPABASE_URL / SUPABASE_ANON_KEY
```

---

## API Reference

### Go Gateway (`:8080`)

| Method | Path | Description |
|---|---|---|
| `GET` | `/api/v1/videos` | Paginated video feed |
| `GET` | `/api/v1/stream/:id` | Range-request video stream |
| `POST` | `/api/v1/videos/:id/like` | Increment likes |
| `GET` | `/api/v1/search` | Social media search (proxies FastAPI) |
| `GET` | `/api/v1/recommendations/:profileID` | Personalised feed |
| `GET` | `/api/v1/recommendations/:profileID/music` | Music recommendations |
| `GET/PUT` | `/api/v1/preferences/:profileID` | User preferences |
| `GET` | `/api/v1/preferences/options` | All available options |
| `GET/POST` | `/api/v1/favorites/:profileID` | Favorites |
| `DELETE` | `/api/v1/favorites/:profileID/:id` | Remove favorite |
| `POST` | `/webhooks/supabase` | Supabase DB webhook |
| `POST` | `/webhooks/openclaw` | OpenClaw job callback |

### Python FastAPI (`:8000`) — interactive docs at `/docs` (dev only)

| Method | Path | Description |
|---|---|---|
| `POST` | `/ai/transcribe` | Gemini transcription + pgvector embedding |
| `POST` | `/ai/dub` | Transcribe → translate → TTS pipeline |
| `POST` | `/ai/music` | OpenClaw `ace-music` generation |
| `GET` | `/ai/jobs/:id` | Agent job polling |
| `GET` | `/ai/search` | Aggregated social platform search |
| `GET/PUT` | `/ai/preferences/:profileID` | Preferences CRUD + re-embed |
| `GET/POST/DELETE` | `/ai/favorites/:profileID` | Favorites CRUD |
| `GET` | `/ai/recommendations/:profileID` | pgvector personalised feed |

---

## Environment Variables

See `.env.example` for the complete list. Key variables:

```env
SUPABASE_URL=https://<project>.supabase.co
SUPABASE_ANON_KEY=<anon-key>
DATABASE_URL=postgresql://postgres:<pw>@db.<project>.supabase.co:5432/postgres
GEMINI_API_KEY=<key>
OPENCLAW_API_URL=http://localhost:3000
YOUTUBE_API_KEY=<key>
SPOTIFY_CLIENT_ID=<id>
SPOTIFY_CLIENT_SECRET=<secret>
SOUNDCLOUD_CLIENT_ID=<id>
```

---

## Running Tests

```bash
make test-go    # Go: race detector + coverage report
make test-py    # Python: pytest + coverage
make test-ios   # Xcode unit tests (macOS only)
```

---

## OpenClaw Skills

Skills live in `openclaw/skills/` and are installed into your OpenClaw instance:

```bash
cp -r openclaw/skills/* ~/.openclaw/skills/
```

| Skill | File | Depends On |
|---|---|---|
| `videofeed-video-edit` | `video-agent/SKILL.md` | `eachlabs-video-edit` |
| `videofeed-music` | `music-agent/SKILL.md` | `ace-music` |

---

## License

MIT — see [LICENSE](LICENSE)
