.PHONY: help dev dev-go dev-py test test-go test-py test-ios lint lint-go lint-py \
        build build-go build-py docker-up docker-down migrate seed clean

# ── Default ───────────────────────────────────────────────────────────────────
help:
	@echo ""
	@echo "  VideoFeed – AI-powered short-form video app"
	@echo ""
	@echo "  dev          Start all backend services (Go + Python)"
	@echo "  dev-go       Start Go API gateway only"
	@echo "  dev-py       Start Python FastAPI service only"
	@echo "  docker-up    Start full stack via docker-compose"
	@echo "  docker-down  Stop docker-compose stack"
	@echo "  migrate      Run Supabase migrations"
	@echo "  seed         Seed Supabase with sample data"
	@echo "  test         Run all tests"
	@echo "  test-go      Run Go tests"
	@echo "  test-py      Run Python tests"
	@echo "  lint         Lint all code"
	@echo "  build        Build all binaries"
	@echo "  clean        Remove build artefacts"
	@echo ""

# ── Environment ───────────────────────────────────────────────────────────────
include .env
export

# ── Development ───────────────────────────────────────────────────────────────
dev:
	$(MAKE) -j2 dev-go dev-py

dev-go:
	cd backend/go && go run ./cmd/server

dev-py:
	cd backend/python && uvicorn main:app --reload --port 8000

# ── Docker ────────────────────────────────────────────────────────────────────
docker-up:
	docker compose up --build -d

docker-down:
	docker compose down --remove-orphans

docker-logs:
	docker compose logs -f

# ── Database ──────────────────────────────────────────────────────────────────
migrate:
	@echo "Applying migrations via Supabase CLI..."
	supabase db push

seed:
	@echo "Seeding sample data..."
	psql "$(DATABASE_URL)" -f supabase/seed.sql

# ── Tests ─────────────────────────────────────────────────────────────────────
test: test-go test-py

test-go:
	cd backend/go && go test ./... -race -coverprofile=coverage.out
	cd backend/go && go tool cover -html=coverage.out -o coverage.html

test-py:
	cd backend/python && python -m pytest tests/ -v --cov=. --cov-report=html

test-ios:
	xcodebuild test \
		-project ios/VideoFeedApp.xcodeproj \
		-scheme VideoFeedApp \
		-destination 'platform=iOS Simulator,name=iPhone 15 Pro' \
		| xcpretty

# ── Lint ──────────────────────────────────────────────────────────────────────
lint: lint-go lint-py

lint-go:
	cd backend/go && golangci-lint run ./...

lint-py:
	cd backend/python && ruff check . && mypy . --ignore-missing-imports

# ── Build ─────────────────────────────────────────────────────────────────────
build: build-go build-py

build-go:
	mkdir -p backend/go/bin
	cd backend/go && CGO_ENABLED=0 GOOS=linux go build -ldflags="-s -w" -o bin/server ./cmd/server

build-py:
	cd backend/python && pip install --quiet -r requirements.txt

# ── Clean ─────────────────────────────────────────────────────────────────────
clean:
	rm -rf backend/go/bin backend/go/coverage.out backend/go/coverage.html
	rm -rf backend/python/.pytest_cache backend/python/htmlcov backend/python/.coverage
	find . -name '__pycache__' -exec rm -rf {} + 2>/dev/null || true
