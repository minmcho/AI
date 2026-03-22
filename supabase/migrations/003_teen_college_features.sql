-- ═══════════════════════════════════════════════════════════════════════════
-- Migration 003: Teen & College Features
-- Mood Feed · Challenges · Streaks/XP · Vibe Match · Study Mode · Sound ID
-- ═══════════════════════════════════════════════════════════════════════════

-- ── Mood tags on videos ───────────────────────────────────────────────────────
ALTER TABLE videos ADD COLUMN IF NOT EXISTS mood_tags  TEXT[] DEFAULT '{}';
ALTER TABLE videos ADD COLUMN IF NOT EXISTS campus_tag TEXT;         -- e.g. "UCLA", "MIT"
ALTER TABLE videos ADD COLUMN IF NOT EXISTS challenge_id UUID;       -- FK added after table

-- Mood options: hype | chill | sad | funny | study | dance | romantic | gaming | asmr
CREATE INDEX IF NOT EXISTS videos_mood_idx ON videos USING gin(mood_tags);

-- ── Challenges ────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS challenges (
    id            UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    creator_id    UUID REFERENCES profiles(id) ON DELETE SET NULL,
    title         TEXT NOT NULL,
    description   TEXT,
    hashtag       TEXT NOT NULL UNIQUE,             -- e.g. #DormRoomDJ
    thumbnail_url TEXT,
    category      TEXT DEFAULT 'general',           -- dance|comedy|study|music|sports|fashion
    target_mood   TEXT,                             -- mood the challenge maps to
    is_featured   BOOLEAN DEFAULT false,
    ends_at       TIMESTAMPTZ,
    participant_count INT DEFAULT 0,
    view_count    INT DEFAULT 0,
    created_at    TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS challenge_entries (
    id           UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    challenge_id UUID REFERENCES challenges(id) ON DELETE CASCADE,
    profile_id   UUID REFERENCES profiles(id) ON DELETE CASCADE,
    video_id     UUID REFERENCES videos(id) ON DELETE SET NULL,
    likes        INT DEFAULT 0,
    rank         INT,                               -- recalculated periodically
    created_at   TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE (challenge_id, profile_id)
);

ALTER TABLE videos ADD CONSTRAINT fk_video_challenge
    FOREIGN KEY (challenge_id) REFERENCES challenges(id) ON DELETE SET NULL;

CREATE INDEX IF NOT EXISTS challenges_hashtag_idx ON challenges(hashtag);
CREATE INDEX IF NOT EXISTS challenges_featured_idx ON challenges(is_featured, ends_at DESC);

-- ── Streaks & XP ──────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS user_streaks (
    profile_id    UUID PRIMARY KEY REFERENCES profiles(id) ON DELETE CASCADE,
    streak_days   INT DEFAULT 0,           -- consecutive daily active days
    longest_streak INT DEFAULT 0,
    total_xp      INT DEFAULT 0,
    level         INT DEFAULT 1,           -- computed from total_xp
    badges        TEXT[] DEFAULT '{}',     -- earned badge IDs
    last_active   DATE DEFAULT CURRENT_DATE,
    updated_at    TIMESTAMPTZ DEFAULT NOW()
);

-- XP actions log
CREATE TABLE IF NOT EXISTS xp_events (
    id         UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    profile_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
    action     TEXT NOT NULL,   -- watch|like|share|save|challenge_join|challenge_win|daily_login|study_session
    xp_earned  INT NOT NULL,
    metadata   JSONB DEFAULT '{}',
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS xp_events_profile_idx ON xp_events(profile_id, created_at DESC);

-- XP thresholds for each level (level 1 = 0xp, level 2 = 500xp, ...)
CREATE OR REPLACE FUNCTION xp_to_level(xp INT) RETURNS INT LANGUAGE sql IMMUTABLE AS $$
    SELECT GREATEST(1, FLOOR(SQRT(xp::FLOAT / 50))::INT + 1);
$$;

-- Award XP and update streak
CREATE OR REPLACE FUNCTION award_xp(
    p_profile_id UUID,
    p_action     TEXT,
    p_xp         INT,
    p_metadata   JSONB DEFAULT '{}'
) RETURNS TABLE(new_xp INT, new_level INT, new_streak INT, badge_awarded TEXT)
LANGUAGE plpgsql AS $$
DECLARE
    v_today     DATE := CURRENT_DATE;
    v_last_active DATE;
    v_streak    INT;
    v_new_xp    INT;
    v_new_level INT;
    v_badge     TEXT := NULL;
BEGIN
    -- Upsert streak row
    INSERT INTO user_streaks (profile_id) VALUES (p_profile_id)
    ON CONFLICT DO NOTHING;

    SELECT last_active, streak_days INTO v_last_active, v_streak
    FROM user_streaks WHERE profile_id = p_profile_id;

    -- Update streak
    IF v_last_active = v_today - 1 THEN
        v_streak := v_streak + 1;
    ELSIF v_last_active < v_today - 1 THEN
        v_streak := 1;  -- broken — reset
    END IF;

    -- Log XP event
    INSERT INTO xp_events (profile_id, action, xp_earned, metadata)
    VALUES (p_profile_id, p_action, p_xp, p_metadata);

    -- Update totals
    UPDATE user_streaks SET
        streak_days    = v_streak,
        longest_streak = GREATEST(longest_streak, v_streak),
        total_xp       = total_xp + p_xp,
        level          = xp_to_level(total_xp + p_xp),
        last_active    = v_today,
        updated_at     = NOW()
    WHERE profile_id = p_profile_id
    RETURNING total_xp, level INTO v_new_xp, v_new_level;

    -- Badge milestones
    IF v_streak = 7 AND NOT EXISTS (
        SELECT 1 FROM user_streaks WHERE profile_id = p_profile_id AND badges @> '{week_warrior}'
    ) THEN
        UPDATE user_streaks SET badges = badges || '{week_warrior}' WHERE profile_id = p_profile_id;
        v_badge := 'week_warrior';
    ELSIF v_streak = 30 THEN
        UPDATE user_streaks SET badges = badges || '{monthly_legend}' WHERE profile_id = p_profile_id;
        v_badge := 'monthly_legend';
    END IF;

    RETURN QUERY SELECT v_new_xp, v_new_level, v_streak, v_badge;
END;
$$;

-- ── Study Sessions ────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS study_sessions (
    id            UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    profile_id    UUID REFERENCES profiles(id) ON DELETE CASCADE,
    duration_min  INT NOT NULL,            -- actual study minutes
    pomodoros     INT DEFAULT 0,           -- completed 25-min blocks
    lofi_video_id UUID REFERENCES videos(id) ON DELETE SET NULL,
    subject       TEXT,                   -- e.g. "Math", "CS", "History"
    created_at    TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS study_sessions_profile_idx ON study_sessions(profile_id, created_at DESC);

-- ── Vibe Match ────────────────────────────────────────────────────────────────
-- Find users whose preference_embedding is close to yours
CREATE OR REPLACE FUNCTION vibe_match(
    p_profile_id UUID,
    p_limit      INT DEFAULT 10
)
RETURNS TABLE (
    profile_id   UUID,
    username     TEXT,
    avatar_url   TEXT,
    similarity   FLOAT,
    shared_genres TEXT[],
    total_xp     INT,
    badges       TEXT[]
)
LANGUAGE sql STABLE AS $$
    SELECT
        p.id,
        p.username,
        p.avatar_url,
        1 - (up.preference_embedding <=> src.preference_embedding) AS similarity,
        (
            SELECT ARRAY_AGG(g)
            FROM unnest(up.music_genres) g
            WHERE g = ANY(src.music_genres)
        ) AS shared_genres,
        COALESCE(us.total_xp, 0),
        COALESCE(us.badges, '{}')
    FROM user_preferences up
    JOIN user_preferences src ON src.profile_id = p_profile_id
    JOIN profiles p ON p.id = up.profile_id
    LEFT JOIN user_streaks us ON us.profile_id = up.profile_id
    WHERE up.profile_id != p_profile_id
      AND up.preference_embedding IS NOT NULL
      AND src.preference_embedding IS NOT NULL
    ORDER BY up.preference_embedding <=> src.preference_embedding
    LIMIT p_limit;
$$;

-- ── Mood Feed RPC ─────────────────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION mood_feed(
    p_mood  TEXT,
    p_limit INT DEFAULT 20,
    p_campus TEXT DEFAULT NULL
)
RETURNS TABLE (
    id UUID, url TEXT, thumbnail TEXT, caption TEXT,
    likes INT, comments INT, shares INT, duration FLOAT,
    tags TEXT[], mood_tags TEXT[], campus_tag TEXT,
    challenge_id UUID, created_at TIMESTAMPTZ
) LANGUAGE sql STABLE AS $$
    SELECT id, url, thumbnail, caption, likes, comments, shares,
           duration, tags, mood_tags, campus_tag, challenge_id, created_at
    FROM videos
    WHERE p_mood = ANY(mood_tags)
      AND (p_campus IS NULL OR campus_tag ILIKE p_campus)
    ORDER BY likes DESC, created_at DESC
    LIMIT p_limit;
$$;

-- ── Leaderboard for a challenge ────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION challenge_leaderboard(
    p_challenge_id UUID,
    p_limit        INT DEFAULT 20
)
RETURNS TABLE (
    rank INT, username TEXT, avatar_url TEXT,
    video_id UUID, likes INT, created_at TIMESTAMPTZ
) LANGUAGE sql STABLE AS $$
    SELECT
        ROW_NUMBER() OVER (ORDER BY ce.likes DESC)::INT AS rank,
        p.username, p.avatar_url,
        ce.video_id, ce.likes, ce.created_at
    FROM challenge_entries ce
    JOIN profiles p ON p.id = ce.profile_id
    WHERE ce.challenge_id = p_challenge_id
    ORDER BY ce.likes DESC
    LIMIT p_limit;
$$;

-- ── RLS ───────────────────────────────────────────────────────────────────────
ALTER TABLE challenges       ENABLE ROW LEVEL SECURITY;
ALTER TABLE challenge_entries ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_streaks     ENABLE ROW LEVEL SECURITY;
ALTER TABLE xp_events        ENABLE ROW LEVEL SECURITY;
ALTER TABLE study_sessions   ENABLE ROW LEVEL SECURITY;

CREATE POLICY "challenges_public_read"  ON challenges        FOR SELECT USING (true);
CREATE POLICY "challenges_own_insert"   ON challenges        FOR INSERT WITH CHECK (auth.uid() = creator_id);
CREATE POLICY "entries_public_read"     ON challenge_entries FOR SELECT USING (true);
CREATE POLICY "entries_own"             ON challenge_entries FOR INSERT WITH CHECK (auth.uid() = profile_id);
CREATE POLICY "streaks_own"             ON user_streaks      FOR ALL   USING (auth.uid() = profile_id);
CREATE POLICY "xp_own"                  ON xp_events         FOR SELECT USING (auth.uid() = profile_id);
CREATE POLICY "study_own"               ON study_sessions    FOR ALL   USING (auth.uid() = profile_id);
CREATE POLICY "streaks_service"         ON user_streaks      FOR ALL   USING (auth.role() = 'service_role');
CREATE POLICY "xp_service"              ON xp_events         FOR ALL   USING (auth.role() = 'service_role');

-- ── Realtime ──────────────────────────────────────────────────────────────────
ALTER PUBLICATION supabase_realtime ADD TABLE challenges;
ALTER PUBLICATION supabase_realtime ADD TABLE challenge_entries;
ALTER PUBLICATION supabase_realtime ADD TABLE user_streaks;
