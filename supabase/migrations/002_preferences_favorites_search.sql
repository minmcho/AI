-- ── User Preferences ─────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS user_preferences (
    id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    profile_id      UUID REFERENCES profiles(id) ON DELETE CASCADE UNIQUE,
    -- Music
    music_genres    TEXT[] DEFAULT '{}',  -- electronic, hiphop, lofi, pop, ambient, edm
    music_moods     TEXT[] DEFAULT '{}',  -- energetic, chill, dramatic, uplifting, dark
    -- Video
    video_types     TEXT[] DEFAULT '{}',  -- dance, comedy, travel, food, sports, tech, fashion, gaming
    -- Regions
    countries       TEXT[] DEFAULT '{}',  -- ISO 3166-1 alpha-2 codes: US, JP, KR, BR ...
    -- Social platforms to pull from
    platforms       TEXT[] DEFAULT '{"youtube","tiktok","instagram","spotify","soundcloud"}',
    -- Feed tuning
    prefer_dubbed   BOOLEAN DEFAULT false,
    prefer_subtitles BOOLEAN DEFAULT false,
    autoplay_muted  BOOLEAN DEFAULT false,
    updated_at      TIMESTAMPTZ DEFAULT NOW(),
    created_at      TIMESTAMPTZ DEFAULT NOW()
);

-- ── Favorites ─────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS favorites (
    id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    profile_id      UUID REFERENCES profiles(id) ON DELETE CASCADE,
    item_type       TEXT NOT NULL CHECK (item_type IN ('video', 'music', 'social_video', 'social_music')),
    -- Internal item (nullable — set if item_type = video/music)
    video_id        UUID REFERENCES videos(id) ON DELETE SET NULL,
    -- External social media item
    external_id     TEXT,           -- platform-native ID
    platform        TEXT,           -- youtube | tiktok | instagram | spotify | soundcloud
    title           TEXT,
    thumbnail_url   TEXT,
    media_url       TEXT,
    author_name     TEXT,
    duration        FLOAT,
    metadata        JSONB DEFAULT '{}',
    created_at      TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE (profile_id, item_type, external_id),
    UNIQUE (profile_id, item_type, video_id)
);

-- ── Search History ─────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS search_history (
    id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    profile_id  UUID REFERENCES profiles(id) ON DELETE CASCADE,
    query       TEXT NOT NULL,
    platforms   TEXT[] DEFAULT '{}',
    result_count INT DEFAULT 0,
    created_at  TIMESTAMPTZ DEFAULT NOW()
);

-- Index for fast user lookup
CREATE INDEX IF NOT EXISTS favorites_profile_idx      ON favorites(profile_id, item_type);
CREATE INDEX IF NOT EXISTS search_history_profile_idx ON search_history(profile_id, created_at DESC);

-- ── pgvector: preference embedding for personalised feed ─────────────────────
ALTER TABLE user_preferences
    ADD COLUMN IF NOT EXISTS preference_embedding vector(768);

CREATE INDEX IF NOT EXISTS user_pref_embedding_idx
    ON user_preferences USING hnsw (preference_embedding vector_cosine_ops)
    WITH (m = 16, ef_construction = 64);

-- ── RPC: personalised video feed (preference-aware cosine similarity) ─────────
CREATE OR REPLACE FUNCTION personalised_feed(
    p_profile_id UUID,
    p_limit      INT DEFAULT 20
)
RETURNS TABLE (
    id UUID, url TEXT, thumbnail TEXT, caption TEXT,
    likes INT, comments INT, shares INT, duration FLOAT, tags TEXT[],
    mix_track_url TEXT, created_at TIMESTAMPTZ, similarity FLOAT
) LANGUAGE sql STABLE AS $$
    SELECT
        v.id, v.url, v.thumbnail, v.caption,
        v.likes, v.comments, v.shares, v.duration, v.tags,
        v.mix_track_url, v.created_at,
        1 - (v.embedding <=> up.preference_embedding) AS similarity
    FROM videos v
    JOIN user_preferences up ON up.profile_id = p_profile_id
    WHERE v.embedding IS NOT NULL
      AND up.preference_embedding IS NOT NULL
    ORDER BY v.embedding <=> up.preference_embedding
    LIMIT p_limit;
$$;

-- ── RLS ───────────────────────────────────────────────────────────────────────
ALTER TABLE user_preferences ENABLE ROW LEVEL SECURITY;
ALTER TABLE favorites        ENABLE ROW LEVEL SECURITY;
ALTER TABLE search_history   ENABLE ROW LEVEL SECURITY;

CREATE POLICY "prefs_own"   ON user_preferences FOR ALL USING (auth.uid() = profile_id);
CREATE POLICY "favs_own"    ON favorites        FOR ALL USING (auth.uid() = profile_id);
CREATE POLICY "search_own"  ON search_history   FOR ALL USING (auth.uid() = profile_id);

-- Service role bypass for AI service writes
CREATE POLICY "prefs_service"  ON user_preferences FOR ALL USING (auth.role() = 'service_role');
CREATE POLICY "favs_service"   ON favorites        FOR ALL USING (auth.role() = 'service_role');
