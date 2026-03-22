-- Enable extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS vector;

-- ── Profiles ─────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS profiles (
    id         UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    username   TEXT UNIQUE NOT NULL,
    avatar_url TEXT,
    bio        TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ── Videos ───────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS videos (
    id            UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    profile_id    UUID REFERENCES profiles(id) ON DELETE CASCADE,
    url           TEXT NOT NULL,
    thumbnail     TEXT,
    caption       TEXT DEFAULT '',
    likes         INT DEFAULT 0,
    comments      INT DEFAULT 0,
    shares        INT DEFAULT 0,
    duration      FLOAT DEFAULT 0,
    tags          TEXT[] DEFAULT '{}',
    mix_track_url TEXT,
    -- pgvector: 768-dim embedding from text-embedding-004
    embedding     vector(768),
    created_at    TIMESTAMPTZ DEFAULT NOW()
);

-- HNSW index for fast approximate nearest-neighbour search
CREATE INDEX IF NOT EXISTS videos_embedding_idx
    ON videos USING hnsw (embedding vector_cosine_ops)
    WITH (m = 16, ef_construction = 64);

-- ── Agent Jobs ────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS agent_jobs (
    id         UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    video_id   UUID REFERENCES videos(id) ON DELETE SET NULL,
    job_type   TEXT NOT NULL,   -- transcription | translation | tts | music | video_edit
    status     TEXT NOT NULL DEFAULT 'pending', -- pending | running | completed | failed
    result     TEXT,
    error      TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ── RPC helpers ───────────────────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION increment_likes(video_id UUID)
RETURNS VOID LANGUAGE sql AS $$
    UPDATE videos SET likes = likes + 1 WHERE id = video_id;
$$;

CREATE OR REPLACE FUNCTION increment_shares(video_id UUID)
RETURNS VOID LANGUAGE sql AS $$
    UPDATE videos SET shares = shares + 1 WHERE id = video_id;
$$;

-- ── Row-Level Security ────────────────────────────────────────────────────────
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE videos   ENABLE ROW LEVEL SECURITY;
ALTER TABLE agent_jobs ENABLE ROW LEVEL SECURITY;

-- Public read for videos
CREATE POLICY "videos_select_public" ON videos FOR SELECT USING (true);

-- Authenticated users manage their own content
CREATE POLICY "profiles_manage_own" ON profiles
    FOR ALL USING (auth.uid() = id);

CREATE POLICY "videos_insert_own" ON videos
    FOR INSERT WITH CHECK (auth.uid() = profile_id);

CREATE POLICY "videos_update_own" ON videos
    FOR UPDATE USING (auth.uid() = profile_id);

-- Service role can read/write agent_jobs
CREATE POLICY "agent_jobs_service" ON agent_jobs
    FOR ALL USING (auth.role() = 'service_role');

-- ── Supabase Realtime ─────────────────────────────────────────────────────────
ALTER PUBLICATION supabase_realtime ADD TABLE agent_jobs;
