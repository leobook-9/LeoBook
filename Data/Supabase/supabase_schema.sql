-- =============================================================================
-- GLOBAL SUPABASE SCHEMA (LeoBook) v4.0  (2026-03-17)
-- Single source of truth. Columns MUST match sync_schema.py SUPABASE_SCHEMA.
-- v4.0: fb_matches time→match_time, computed_standings VIEW, STEP 9 matching engine.
-- PostgreSQL naming: only [a-z0-9_] allowed in column names.
-- CSV "over_2.5" maps to Supabase "over_2_5" via sync_manager._COL_REMAP.
-- =============================================================================

CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- =============================================================================
-- 1. USER MANAGEMENT
-- =============================================================================

CREATE TABLE IF NOT EXISTS public.profiles (
    id UUID REFERENCES auth.users (id) ON DELETE CASCADE PRIMARY KEY,
    email TEXT,
    username TEXT UNIQUE,
    full_name TEXT,
    avatar_url TEXT,
    tier TEXT DEFAULT 'free',
    credits INTEGER DEFAULT 0,
    created_at TIMESTAMP
    WITH
        TIME ZONE DEFAULT NOW (),
        updated_at TIMESTAMP
    WITH
        TIME ZONE DEFAULT NOW (),
        last_updated TIMESTAMP
    WITH
        TIME ZONE DEFAULT NOW ()
);

ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can view own profile" ON public.profiles;

CREATE POLICY "Users can view own profile" ON public.profiles FOR
SELECT USING (auth.uid () = id);

DROP POLICY IF EXISTS "Users can update own profile" ON public.profiles;

CREATE POLICY "Users can update own profile" ON public.profiles FOR
UPDATE USING (auth.uid () = id);

-- =============================================================================
-- 2. CUSTOM RULE ENGINE
-- =============================================================================

-- =============================================================================
-- 2. CUSTOM RULE ENGINE
-- =============================================================================

CREATE TABLE IF NOT EXISTS public.custom_rules (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
    name TEXT NOT NULL,
    description TEXT,
    is_active BOOLEAN DEFAULT true,
    logic JSONB DEFAULT '{}'::jsonb NOT NULL,
    priority INTEGER DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    last_updated TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    is_default BOOLEAN DEFAULT false,
    scope JSONB DEFAULT '{}'::jsonb,
    accuracy JSONB DEFAULT '{}'::jsonb,
    backtest_csv_url TEXT
);

ALTER TABLE public.custom_rules ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can fully manage own rules" ON public.custom_rules;

CREATE POLICY "Users can fully manage own rules" ON public.custom_rules FOR ALL USING (auth.uid () = user_id);

CREATE TABLE IF NOT EXISTS public.rule_executions (
    id UUID DEFAULT uuid_generate_v4 () PRIMARY KEY,
    rule_id UUID REFERENCES public.custom_rules (id) ON DELETE CASCADE,
    fixture_id TEXT,
    user_id UUID REFERENCES public.profiles (id),
    result JSONB,
    executed_at TIMESTAMP
    WITH
        TIME ZONE DEFAULT NOW (),
        last_updated TIMESTAMP
    WITH
        TIME ZONE DEFAULT NOW ()
);

ALTER TABLE public.rule_executions ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can view own rule executions" ON public.rule_executions;

CREATE POLICY "Users can view own rule executions" ON public.rule_executions FOR
SELECT USING (auth.uid () = user_id);

-- =============================================================================
-- 3. CORE DATA TABLES (mirrors db_helpers.py files_and_headers exactly)
-- =============================================================================

-- predictions (37 columns) — CSV key: fixture_id
-- Note: CSV "over_2.5" → Supabase "over_2_5" (dots illegal in PostgreSQL identifiers)
CREATE TABLE IF NOT EXISTS public.predictions (
    fixture_id TEXT PRIMARY KEY,
    date TEXT,
    match_time TEXT,
    region_league TEXT,
    home_team TEXT,
    away_team TEXT,
    home_team_id TEXT,
    away_team_id TEXT,
    prediction TEXT,
    confidence TEXT,
    reason TEXT,
    xg_home TEXT,
    xg_away TEXT,
    btts TEXT,
    over_2_5 TEXT,
    best_score TEXT,
    top_scores TEXT,
    home_form_n TEXT,
    away_form_n TEXT,
    home_tags TEXT,
    away_tags TEXT,
    h2h_tags TEXT,
    standings_tags TEXT,
    h2h_count TEXT,
    actual_score TEXT,
    outcome_correct TEXT,
    status TEXT,
    match_link TEXT,
    odds TEXT,
    market_reliability_score TEXT,
    home_crest_url TEXT,
    away_crest_url TEXT,
    recommendation_score TEXT,
    h2h_fixture_ids TEXT,
    form_fixture_ids TEXT,
    standings_snapshot TEXT,
    league_stage TEXT,
    home_score TEXT,
    away_score TEXT,
    last_updated TIMESTAMP
    WITH
        TIME ZONE DEFAULT NOW ()
);

ALTER TABLE public.predictions ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Public Read Access Predictions" ON public.predictions;

CREATE POLICY "Public Read Access Predictions" ON public.predictions FOR
SELECT USING (true);

-- schedules (15 columns) — CSV key: fixture_id
CREATE TABLE IF NOT EXISTS public.schedules (
    fixture_id TEXT PRIMARY KEY,
    date TEXT,
    match_time TEXT,
    region_league TEXT,
    league_id TEXT,
    home_team TEXT,
    away_team TEXT,
    home_team_id TEXT,
    away_team_id TEXT,
    home_score TEXT,
    away_score TEXT,
    match_status TEXT,
    match_link TEXT,
    league_stage TEXT,
    last_updated TIMESTAMP
    WITH
        TIME ZONE DEFAULT NOW ()
);
-- Migration: add league_id if missing
ALTER TABLE public.schedules ADD COLUMN IF NOT EXISTS league_id TEXT;

ALTER TABLE public.schedules ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Public Read Access Schedules" ON public.schedules;

CREATE POLICY "Public Read Access Schedules" ON public.schedules FOR
SELECT USING (true);

-- teams (6 CSV columns + search enrichment) — CSV key: team_id
CREATE TABLE IF NOT EXISTS public.teams (
    team_id TEXT PRIMARY KEY,
    team_name TEXT,
    league_ids TEXT,
    team_crest TEXT,
    team_url TEXT,
    last_updated TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    country TEXT,
    city TEXT,
    stadium TEXT,
    other_names JSONB DEFAULT '[]',
    abbreviations JSONB DEFAULT '[]',
    search_terms TEXT[] DEFAULT ARRAY[]::TEXT[]
);
-- Migration: rename rl_ids → league_ids if old column exists
DO $$ BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='teams' AND column_name='rl_ids') THEN
    ALTER TABLE public.teams RENAME COLUMN rl_ids TO league_ids;
  END IF;
END $$;

ALTER TABLE public.teams ADD COLUMN IF NOT EXISTS league_ids TEXT;

ALTER TABLE public.teams ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Public Read Access Teams" ON public.teams;

CREATE POLICY "Public Read Access Teams" ON public.teams FOR
SELECT USING (true);

-- region_league (9 CSV columns + search enrichment) — CSV key: league_id
CREATE TABLE IF NOT EXISTS public.region_league (
    league_id TEXT PRIMARY KEY,
    region TEXT,
    region_flag TEXT,
    region_url TEXT,
    league TEXT,
    league_crest TEXT,
    league_url TEXT,
    date_updated TEXT,
    last_updated TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    other_names JSONB DEFAULT '[]',
    abbreviations JSONB DEFAULT '[]',
    search_terms TEXT[] DEFAULT ARRAY[]::TEXT[]
);
-- Migration: rename rl_id → league_id if old column exists
DO $$ BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='region_league' AND column_name='rl_id') THEN
    ALTER TABLE public.region_league RENAME COLUMN rl_id TO league_id;
  END IF;
END $$;
-- Migration: drop deprecated columns
ALTER TABLE public.region_league DROP COLUMN IF EXISTS logo_url;

ALTER TABLE public.region_league DROP COLUMN IF EXISTS country;

ALTER TABLE public.region_league ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Public Read Access RegionLeague" ON public.region_league;

CREATE POLICY "Public Read Access RegionLeague" ON public.region_league FOR
SELECT USING (true);

-- standings (15 columns) — CSV key: standings_key
CREATE TABLE IF NOT EXISTS public.standings (
    standings_key TEXT PRIMARY KEY,
    league_id TEXT,
    team_id TEXT,
    team_name TEXT,
    position INTEGER,
    played INTEGER,
    wins INTEGER,
    draws INTEGER,
    losses INTEGER,
    goals_for INTEGER,
    goals_against INTEGER,
    goal_difference INTEGER,
    points INTEGER,
    last_updated TIMESTAMP
    WITH
        TIME ZONE DEFAULT NOW (),
        region_league TEXT
);

ALTER TABLE public.standings ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Public Read Access Standings" ON public.standings;

CREATE POLICY "Public Read Access Standings" ON public.standings FOR
SELECT USING (true);

-- fb_matches (17 columns) — key: site_match_id
-- v4.0: renamed 'time' → 'match_time' (time is a reserved word in PostgreSQL).
-- Upgrade path: ALTER TABLE public.fb_matches RENAME COLUMN time TO match_time;
CREATE TABLE IF NOT EXISTS public.fb_matches (
    site_match_id TEXT PRIMARY KEY,
    date TEXT,
    match_time TEXT,  -- v4.0: was 'time' (reserved keyword)
    home_team TEXT,
    away_team TEXT,
    league TEXT,
    url TEXT,
    last_extracted TEXT,
    fixture_id TEXT,
    matched TEXT,
    odds TEXT,
    booking_status TEXT,
    booking_details TEXT,
    booking_code TEXT,
    booking_url TEXT,
    status TEXT,
    last_updated TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
-- Idempotent upgrade: rename column if old name still exists
DO $$ BEGIN
    IF EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_schema = 'public' AND table_name = 'fb_matches' AND column_name = 'time'
    ) THEN
        ALTER TABLE public.fb_matches RENAME COLUMN time TO match_time;
    END IF;
END $$;

ALTER TABLE public.fb_matches ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Public Read Access FBMatches" ON public.fb_matches;

CREATE POLICY "Public Read Access FBMatches" ON public.fb_matches FOR
SELECT USING (true);

-- live_scores (11 columns) — CSV key: fixture_id
CREATE TABLE IF NOT EXISTS public.live_scores (
    fixture_id TEXT PRIMARY KEY,
    home_team TEXT,
    away_team TEXT,
    home_score TEXT,
    away_score TEXT,
    minute TEXT,
    status TEXT,
    region_league TEXT,
    match_link TEXT,
    timestamp TIMESTAMP
    WITH
        TIME ZONE,
        last_updated TIMESTAMP
    WITH
        TIME ZONE DEFAULT NOW ()
);

ALTER TABLE public.live_scores ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Public Read Access LiveScores" ON public.live_scores;

CREATE POLICY "Public Read Access LiveScores" ON public.live_scores FOR
SELECT USING (true);

-- match_odds (v8.0) — CSV key: fixture_id, market_id, exact_outcome, line
CREATE TABLE IF NOT EXISTS public.match_odds (
    fixture_id TEXT NOT NULL,
    site_match_id TEXT NOT NULL,
    market_id TEXT NOT NULL,
    base_market TEXT NOT NULL,
    category TEXT,
    exact_outcome TEXT NOT NULL,
    line TEXT,
    odds_value DECIMAL(10, 3),
    likelihood_pct INTEGER,
    rank_in_list INTEGER,
    extracted_at TEXT,
    last_updated TIMESTAMP
    WITH
        TIME ZONE DEFAULT NOW (),
        PRIMARY KEY (
            fixture_id,
            market_id,
            exact_outcome,
            line
        )
);

ALTER TABLE public.match_odds ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Public Read Access MatchOdds" ON public.match_odds;

CREATE POLICY "Public Read Access MatchOdds" ON public.match_odds FOR
SELECT USING (true);

-- =============================================================================
-- 4. REPORTING & AUDIT
-- =============================================================================

CREATE TABLE IF NOT EXISTS public.accuracy_reports (
    report_id TEXT PRIMARY KEY,
    timestamp TIMESTAMP
    WITH
        TIME ZONE DEFAULT NOW (),
        volume INTEGER DEFAULT 0,
        win_rate DECIMAL(5, 2) DEFAULT 0,
        return_pct DECIMAL(5, 2) DEFAULT 0,
        period TEXT DEFAULT 'last_24h',
        last_updated TIMESTAMP
    WITH
        TIME ZONE DEFAULT NOW ()
);

ALTER TABLE public.accuracy_reports ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Public Read Access AccuracyReports" ON public.accuracy_reports;

CREATE POLICY "Public Read Access AccuracyReports" ON public.accuracy_reports FOR
SELECT USING (true);

CREATE TABLE IF NOT EXISTS public.audit_log (
    id UUID DEFAULT uuid_generate_v4 () PRIMARY KEY,
    timestamp TIMESTAMP
    WITH
        TIME ZONE DEFAULT NOW (),
        event_type TEXT NOT NULL,
        description TEXT,
        balance_before DECIMAL(15, 2),
        balance_after DECIMAL(15, 2),
        stake DECIMAL(15, 2),
        status TEXT DEFAULT 'success',
        last_updated TIMESTAMP
    WITH
        TIME ZONE DEFAULT NOW ()
);

ALTER TABLE public.audit_log ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Public Read Access AuditLog" ON public.audit_log;

CREATE POLICY "Public Read Access AuditLog" ON public.audit_log FOR
SELECT USING (true);

-- =============================================================================
-- 5. ADAPTIVE LEARNING
-- =============================================================================

CREATE TABLE IF NOT EXISTS public.learning_weights (
    region_league TEXT PRIMARY KEY,
    weights JSONB NOT NULL DEFAULT '{}'::jsonb,
    confidence_calibration JSONB NOT NULL DEFAULT '{"Very High": 0.70, "High": 0.60, "Medium": 0.50, "Low": 0.40}'::jsonb,
    predictions_analyzed INTEGER DEFAULT 0,
    last_updated TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

ALTER TABLE public.learning_weights ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Public Read Access LearningWeights" ON public.learning_weights;

CREATE POLICY "Public Read Access LearningWeights" ON public.learning_weights FOR
SELECT USING (true);

-- =============================================================================
-- 6. AUTO-UPDATE TRIGGERS
-- =============================================================================

CREATE OR REPLACE FUNCTION update_last_updated_column()
RETURNS TRIGGER AS $$
BEGIN
   NEW.last_updated = NOW();
   RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS update_profiles_last_updated ON public.profiles;

CREATE TRIGGER update_profiles_last_updated BEFORE UPDATE ON public.profiles FOR EACH ROW EXECUTE PROCEDURE update_last_updated_column();

DROP TRIGGER IF EXISTS update_rules_last_updated ON public.custom_rules;

CREATE TRIGGER update_rules_last_updated BEFORE UPDATE ON public.custom_rules FOR EACH ROW EXECUTE PROCEDURE update_last_updated_column();

DROP TRIGGER IF EXISTS update_predictions_last_updated ON public.predictions;

CREATE TRIGGER update_predictions_last_updated BEFORE UPDATE ON public.predictions FOR EACH ROW EXECUTE PROCEDURE update_last_updated_column();

DROP TRIGGER IF EXISTS update_schedules_last_updated ON public.schedules;

CREATE TRIGGER update_schedules_last_updated BEFORE UPDATE ON public.schedules FOR EACH ROW EXECUTE PROCEDURE update_last_updated_column();

DROP TRIGGER IF EXISTS update_teams_last_updated ON public.teams;

CREATE TRIGGER update_teams_last_updated BEFORE UPDATE ON public.teams FOR EACH ROW EXECUTE PROCEDURE update_last_updated_column();

DROP TRIGGER IF EXISTS update_standings_last_updated ON public.standings;

CREATE TRIGGER update_standings_last_updated BEFORE UPDATE ON public.standings FOR EACH ROW EXECUTE PROCEDURE update_last_updated_column();

DROP TRIGGER IF EXISTS update_fbmatches_last_updated ON public.fb_matches;

CREATE TRIGGER update_fbmatches_last_updated BEFORE UPDATE ON public.fb_matches FOR EACH ROW EXECUTE PROCEDURE update_last_updated_column();

DROP TRIGGER IF EXISTS update_livescores_last_updated ON public.live_scores;

CREATE TRIGGER update_livescores_last_updated BEFORE UPDATE ON public.live_scores FOR EACH ROW EXECUTE PROCEDURE update_last_updated_column();

DROP TRIGGER IF EXISTS update_reports_last_updated ON public.accuracy_reports;

CREATE TRIGGER update_reports_last_updated BEFORE UPDATE ON public.accuracy_reports FOR EACH ROW EXECUTE PROCEDURE update_last_updated_column();

DROP TRIGGER IF EXISTS update_audit_last_updated ON public.audit_log;

CREATE TRIGGER update_audit_last_updated BEFORE UPDATE ON public.audit_log FOR EACH ROW EXECUTE PROCEDURE update_last_updated_column();

DROP TRIGGER IF EXISTS update_learning_weights_last_updated ON public.learning_weights;

CREATE TRIGGER update_learning_weights_last_updated BEFORE UPDATE ON public.learning_weights FOR EACH ROW EXECUTE PROCEDURE update_last_updated_column();

DROP TRIGGER IF EXISTS update_match_odds_last_updated ON public.match_odds;

CREATE TRIGGER update_match_odds_last_updated BEFORE UPDATE ON public.match_odds FOR EACH ROW EXECUTE PROCEDURE update_last_updated_column();

-- =============================================================================
-- 7. GRANTS
-- =============================================================================
GRANT SELECT ON public.predictions TO anon, authenticated;

GRANT SELECT ON public.schedules TO anon, authenticated;

GRANT SELECT ON public.teams TO anon, authenticated;

GRANT SELECT ON public.region_league TO anon, authenticated;

GRANT SELECT ON public.standings TO anon, authenticated;

GRANT SELECT ON public.fb_matches TO anon, authenticated;

GRANT SELECT ON public.live_scores TO anon, authenticated;

GRANT SELECT ON public.accuracy_reports TO anon, authenticated;

GRANT SELECT ON public.audit_log TO anon, authenticated;

GRANT SELECT ON public.learning_weights TO anon, authenticated;

GRANT SELECT ON public.match_odds TO anon, authenticated;

-- =============================================================================
-- 8. AUTH TRIGGERS (Moved to end to prevent blocking tables if permissions fail)
-- =============================================================================

DO $$
BEGIN
    -- Only try to create these if we can access the auth schema
    -- The service_role key sometimes lacks permission for triggers on auth.users
    BEGIN
        CREATE OR REPLACE FUNCTION public.handle_new_user()
        RETURNS TRIGGER AS $func$
        BEGIN
          INSERT INTO public.profiles (id, email, full_name, avatar_url)
          VALUES (new.id, new.email, new.raw_user_meta_data->>'full_name', new.raw_user_meta_data->>'avatar_url');
          RETURN new;
        END;
        $func$ LANGUAGE plpgsql SECURITY DEFINER;

        IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'auth' AND table_name = 'users') THEN
            DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
            CREATE TRIGGER on_auth_user_created AFTER INSERT ON auth.users FOR EACH ROW EXECUTE PROCEDURE public.handle_new_user();
        END IF;
    EXCEPTION WHEN OTHERS THEN
        -- Gracefully log but don't fail the whole script
        RAISE NOTICE 'Skipping auth.users trigger due to missing permissions: %', SQLERRM;
    END;
END $$;

-- =============================================================================
-- 9. COMPUTED STANDINGS VIEW  (v4.0 — always computed, never stored)
-- Standings are derived on-the-fly from schedules. Zero sync overhead.
-- Flutter app and Python backend query computed_standings directly.
-- =============================================================================

CREATE OR REPLACE VIEW public.computed_standings AS
WITH all_matches AS (
    SELECT
        league_id, NULL::TEXT AS season,
        home_team_id AS team_id, home_team AS team_name,
        home_score::INTEGER AS gf, away_score::INTEGER AS ga
    FROM public.schedules
    WHERE home_score IS NOT NULL AND away_score IS NOT NULL
      AND match_status = 'finished'
    UNION ALL
    SELECT
        league_id, NULL::TEXT AS season,
        away_team_id AS team_id, away_team AS team_name,
        away_score::INTEGER AS gf, home_score::INTEGER AS ga
    FROM public.schedules
    WHERE home_score IS NOT NULL AND away_score IS NOT NULL
      AND match_status = 'finished'
)
SELECT
    league_id, season, team_id, team_name,
    COUNT(*) AS played,
    SUM(CASE WHEN gf > ga THEN 1 ELSE 0 END) AS won,
    SUM(CASE WHEN gf = ga THEN 1 ELSE 0 END) AS drawn,
    SUM(CASE WHEN gf < ga THEN 1 ELSE 0 END) AS lost,
    SUM(gf) AS goals_for,
    SUM(ga) AS goals_against,
    SUM(gf) - SUM(ga) AS goal_difference,
    SUM(CASE WHEN gf > ga THEN 3 WHEN gf = ga THEN 1 ELSE 0 END) AS points
FROM all_matches
GROUP BY league_id, season, team_id, team_name;

GRANT SELECT ON public.computed_standings TO anon, authenticated, service_role;

-- =============================================================================
-- 10. TEAM MATCHING ENGINE v1.2  (2026-03-17)
-- Deterministic SQL-first fb_matches → schedules linkage.
-- Python: SQL (confidence ≥ 88) → search_dict → LLM fallback.
-- All objects use CREATE OR REPLACE / IF NOT EXISTS — safe to re-run.
-- =============================================================================

-- 10a: Name normalizer
CREATE OR REPLACE FUNCTION public.normalize_team_name(raw TEXT)
RETURNS TEXT LANGUAGE sql IMMUTABLE STRICT AS $$
  SELECT TRIM(
           REGEXP_REPLACE(
             REGEXP_REPLACE(
               LOWER(COALESCE(raw, '')),
               '\m(fc|cf|sc|ac|bk|sk|fk|if|afc|bfc|sfc|united|city|town|rovers|wanderers|athletic|albion|county)\M',
               '', 'gi'
             ),
             '[^a-z0-9]+', ' ', 'g'
           )
         )
$$;
GRANT EXECUTE ON FUNCTION public.normalize_team_name(TEXT) TO service_role, anon, authenticated;

-- 10b: Candidate view (fb_matches × schedules, ±1 day window, normalized score)
CREATE OR REPLACE VIEW public.fb_match_candidates AS
SELECT
    fb.site_match_id,
    fb.date AS fb_date, fb.match_time AS fb_time,
    fb.home_team AS fb_home, fb.away_team AS fb_away,
    fb.league AS fb_league, fb.url AS fb_url,
    s.fixture_id,
    s.date AS s_date, s.match_time AS s_time,
    s.home_team AS s_home, s.away_team AS s_away,
    s.home_team_id, s.away_team_id, s.league_id, s.region_league,
    CASE
        WHEN public.normalize_team_name(fb.home_team) = public.normalize_team_name(s.home_team)
         AND public.normalize_team_name(fb.away_team) = public.normalize_team_name(s.away_team)
        THEN 100
        WHEN (
            public.normalize_team_name(fb.home_team) LIKE '%' || public.normalize_team_name(s.home_team) || '%'
            OR public.normalize_team_name(s.home_team) LIKE '%' || public.normalize_team_name(fb.home_team) || '%'
        ) AND (
            public.normalize_team_name(fb.away_team) LIKE '%' || public.normalize_team_name(s.away_team) || '%'
            OR public.normalize_team_name(s.away_team) LIKE '%' || public.normalize_team_name(fb.away_team) || '%'
        ) THEN 88
        ELSE 0
    END AS confidence
FROM public.fb_matches fb
CROSS JOIN public.schedules s
WHERE fb.date IS NOT NULL AND s.date IS NOT NULL
  AND ABS(EXTRACT(EPOCH FROM (fb.date::DATE - s.date::DATE)) / 86400) <= 1
  AND (fb.fixture_id IS NULL OR fb.matched IS NULL OR fb.matched = 'false')
  AND (
    public.normalize_team_name(fb.home_team) LIKE '%' || public.normalize_team_name(s.home_team) || '%'
    OR public.normalize_team_name(s.home_team) LIKE '%' || public.normalize_team_name(fb.home_team) || '%'
  );
GRANT SELECT ON public.fb_match_candidates TO anon, authenticated, service_role;

-- 10c: Per-row resolver — Python calls via supabase.rpc('match_fb_to_schedule', ...)
CREATE OR REPLACE FUNCTION public.match_fb_to_schedule(p_site_match_id TEXT)
RETURNS TABLE(fixture_id TEXT, confidence INTEGER, home_team_id TEXT, away_team_id TEXT,
              s_home TEXT, s_away TEXT, s_date TEXT, s_time TEXT)
LANGUAGE sql STABLE AS $$
    SELECT c.fixture_id, c.confidence, c.home_team_id, c.away_team_id,
           c.s_home, c.s_away, c.s_date, c.s_time
    FROM public.fb_match_candidates c
    WHERE c.site_match_id = p_site_match_id AND c.confidence > 0
    ORDER BY c.confidence DESC, c.s_date ASC LIMIT 1;
$$;
GRANT EXECUTE ON FUNCTION public.match_fb_to_schedule(TEXT) TO service_role, anon, authenticated;

-- 10d: Batch resolver — call after full harvest run
CREATE OR REPLACE FUNCTION public.auto_match_fb_matches()
RETURNS INTEGER LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE matched_count INTEGER := 0; rec RECORD;
BEGIN
    FOR rec IN
        SELECT DISTINCT ON (site_match_id) site_match_id,
               fixture_id AS resolved_fixture_id, confidence
        FROM public.fb_match_candidates WHERE confidence >= 88
        ORDER BY site_match_id, confidence DESC
    LOOP
        UPDATE public.fb_matches
        SET fixture_id = rec.resolved_fixture_id, matched = 'sql_v1.2', last_updated = NOW()
        WHERE site_match_id = rec.site_match_id AND (fixture_id IS NULL OR fixture_id = '');
        IF FOUND THEN matched_count := matched_count + 1; END IF;
    END LOOP;
    RETURN matched_count;
END;
$$;
GRANT EXECUTE ON FUNCTION public.auto_match_fb_matches() TO service_role;

-- 10e: Per-row trigger (fires on INSERT or UPDATE of matching columns)
CREATE OR REPLACE FUNCTION public.trg_fn_auto_match_fb()
RETURNS TRIGGER LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE best RECORD;
BEGIN
    IF NEW.fixture_id IS NOT NULL AND NEW.fixture_id <> '' THEN RETURN NEW; END IF;
    SELECT fixture_id, confidence INTO best
    FROM public.match_fb_to_schedule(NEW.site_match_id) LIMIT 1;
    IF FOUND AND best.confidence >= 88 THEN
        NEW.fixture_id := best.fixture_id;
        NEW.matched    := 'sql_v1.2';
        NEW.last_updated := NOW();
    END IF;
    RETURN NEW;
END;
$$;
DROP TRIGGER IF EXISTS trg_auto_match_fb_matches ON public.fb_matches;
CREATE TRIGGER trg_auto_match_fb_matches
    BEFORE INSERT OR UPDATE OF home_team, away_team, date ON public.fb_matches
    FOR EACH ROW EXECUTE FUNCTION public.trg_fn_auto_match_fb();

-- 10f: Performance indexes
CREATE INDEX IF NOT EXISTS idx_fb_matches_unresolved
    ON public.fb_matches (date) WHERE fixture_id IS NULL OR fixture_id = '';
CREATE INDEX IF NOT EXISTS idx_schedules_date_home_away
    ON public.schedules (date, home_team, away_team);
CREATE INDEX IF NOT EXISTS idx_schedules_date
    ON public.schedules (date);

GRANT SELECT ON public.fb_match_candidates TO anon, authenticated, service_role;
-- =============================================================================
-- Schema v4.0 complete.
-- Tables: 14 core + views: computed_standings, fb_match_candidates
-- Functions: normalize_team_name, match_fb_to_schedule, auto_match_fb_matches
-- Triggers: trg_auto_match_fb_matches (per-row), update_*_last_updated (all tables)
-- Run: SELECT public.auto_match_fb_matches(); to batch-link all fb_matches.
-- =============================================================================