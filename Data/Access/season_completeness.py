# season_completeness.py: tracks match coverage per league per season.
# Part of LeoBook Data — Access Layer (Quality Control)

import json
import logging
from datetime import datetime
from typing import List, Dict, Any, Optional
from Data.Access.league_db import get_connection, init_db

logger = logging.getLogger(__name__)

class SeasonCompletenessTracker:
    """
    Calculates and persists data coverage metrics per league/season.
    Ensures historical completeness and monitors live season progress.
    """

    @classmethod
    def _ensure_table(cls):
        """Create the season_completeness table if it doesn't exist."""
        conn = get_connection()
        conn.execute("""
            CREATE TABLE IF NOT EXISTS season_completeness (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                league_id TEXT NOT NULL,
                season TEXT NOT NULL,
                total_expected_matches INTEGER,
                total_scanned_matches INTEGER,
                finished_matches INTEGER,
                scheduled_matches INTEGER,
                live_matches INTEGER,
                postponed_matches INTEGER,
                canceled_matches INTEGER,
                season_status TEXT DEFAULT 'ACTIVE',
                completeness_pct REAL,
                progress_pct REAL,
                last_verified_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                UNIQUE(league_id, season)
            )
        """)
        conn.commit()

    @classmethod
    def compute_for_league(cls, league_id: str, season: str, conn=None):
        """Compute coverage metrics for a single league/season."""
        cls._ensure_table()
        local_conn = conn or get_connection()
        
        # 1. Aggregate match counts from schedules
        stats = local_conn.execute("""
            SELECT 
                COUNT(*) as total_scanned,
                SUM(CASE WHEN match_status IN ('FINISHED', 'finished', 'completed') THEN 1 ELSE 0 END) as finished,
                SUM(CASE WHEN match_status IN ('SCHEDULED', 'scheduled', '') OR match_status IS NULL THEN 1 ELSE 0 END) as scheduled,
                SUM(CASE WHEN match_status IN ('LIVE', 'IN_PROGRESS', 'live') THEN 1 ELSE 0 END) as live,
                SUM(CASE WHEN match_status IN ('POSTPONED', 'postponed') THEN 1 ELSE 0 END) as postponed,
                SUM(CASE WHEN match_status IN ('CANCELED', 'canceled') THEN 1 ELSE 0 END) as canceled
            FROM schedules
            WHERE league_id = ? AND season = ?
        """, (league_id, season)).fetchone()
        
        if not stats or stats["total_scanned"] == 0:
            return None

        # 2. Count registered teams (needed for CUP_FORMAT detection + expected calculation)
        team_count_row = local_conn.execute(
            "SELECT COUNT(*) as cnt FROM teams WHERE league_ids LIKE ?",
            (f'"%{league_id}%"',)
        ).fetchone()
        team_count = (
            (team_count_row["cnt"] if hasattr(team_count_row, "keys") else team_count_row[0])
            if team_count_row else 0
        )

        # 3. Determine expected matches
        total_expected = cls._get_expected_matches(
            league_id, season, stats["total_scanned"], team_count=team_count, conn=local_conn
        )

        total_scanned = stats["total_scanned"]
        finished = stats["finished"] or 0
        scheduled = stats["scheduled"] or 0
        live = stats["live"] or 0
        postponed = stats["postponed"] or 0
        canceled = stats["canceled"] or 0

        completeness_pct = round((total_scanned / total_expected) * 100, 2) if total_expected > 0 else 0
        progress_pct = round(((finished + postponed + canceled) / total_expected) * 100, 2) if total_expected > 0 else 0

        # 4. Determine status
        # Leagues with <4 registered teams are cup-format competitions (super cups,
        # one-off finals, playoff legs). They have no meaningful completeness concept
        # and must never be marked COMPLETED via the fallback heuristic.
        is_cup_format = total_expected <= total_scanned and team_count < 4

        status = "CUP_FORMAT" if is_cup_format else "ACTIVE"

        if not is_cup_format:
            if completeness_pct >= 99.0 and scheduled == 0 and live == 0:
                status = "COMPLETED"
            elif completeness_pct < 80.0:
                status = "INCOMPLETE"

        # 4. Upsert into season_completeness
        local_conn.execute("""
            INSERT INTO season_completeness (
                league_id, season, total_expected_matches, total_scanned_matches,
                finished_matches, scheduled_matches, live_matches, postponed_matches,
                canceled_matches, season_status, completeness_pct, progress_pct, last_verified_at
            ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
            ON CONFLICT(league_id, season) DO UPDATE SET
                total_expected_matches = excluded.total_expected_matches,
                total_scanned_matches = excluded.total_scanned_matches,
                finished_matches = excluded.finished_matches,
                scheduled_matches = excluded.scheduled_matches,
                live_matches = excluded.live_matches,
                postponed_matches = excluded.postponed_matches,
                canceled_matches = excluded.canceled_matches,
                season_status = excluded.season_status,
                completeness_pct = excluded.completeness_pct,
                progress_pct = excluded.progress_pct,
                last_verified_at = excluded.last_verified_at
        """, (
            league_id, season, total_expected, total_scanned, 
            finished, scheduled, live, postponed, canceled,
            status, completeness_pct, progress_pct, datetime.now().isoformat()
        ))
        
        if not conn:
            local_conn.commit()
        return status

    @classmethod
    def _get_expected_matches(
        cls,
        league_id: str,
        season: str,
        scanned_count: int,
        team_count: int = 0,    # pre-computed by compute_for_league — avoids extra query
        conn=None,
    ) -> int:
        """
        Heuristic for expected total matches in a season.

        Formula: teams * (teams - 1) for round-robin leagues.
        Falls back to scanned_count ONLY when team_count >= 4 and scanned
        exceeds the round-robin estimate (split seasons, playoffs, etc.).
        Returns scanned_count for cup-format (<4 teams) but CUP_FORMAT
        status is determined by the caller — this function just returns a
        number; status logic lives in compute_for_league.
        """
        local_conn = conn or get_connection()

        # 1. Manual override always wins
        row = local_conn.execute(
            "SELECT total_expected_matches FROM season_completeness "
            "WHERE league_id=? AND season=?",
            (league_id, season)
        ).fetchone()
        if row:
            val = row["total_expected_matches"] if hasattr(row, "keys") else row[0]
            if val:
                return val

        # 2. Round-robin formula (reliable for domestic leagues with >=4 teams)
        if team_count >= 4:
            expected = team_count * (team_count - 1)
            # If scanned exceeds round-robin estimate, the season has extra rounds
            # (playoffs, split format) — use scanned as the floor
            return max(expected, scanned_count)

        # 3. Cup-format (<4 teams) — return scanned so completeness_pct = 100%
        # but the CUP_FORMAT status in compute_for_league prevents COMPLETED
        # being assigned. This value is stored for audit but not used for gates.
        return scanned_count or 1

    @classmethod
    def bulk_compute_all(cls):
        """Iterate through all unique league+season pairs and update metrics."""
        cls._ensure_table()
        conn = get_connection()
        pairs = conn.execute("SELECT DISTINCT league_id, season FROM schedules WHERE league_id IS NOT NULL AND season IS NOT NULL").fetchall()
        
        count = 0
        for p in pairs:
            cls.compute_for_league(p["league_id"], p["season"], conn=conn)
            count += 1
            if count % 100 == 0:
                conn.commit()
                logger.debug(f"[Completeness] Progress: {count} seasons updated")
            
        conn.commit()
        logger.info(f"[Completeness] Bulk computed {count} league-season combinations.")
        return count
        
    @classmethod
    def get_season_progress(cls, league_id: str, season: str) -> Dict[str, Any]:
        """Fetch status dictionary for UI consumption."""
        conn = get_connection()
        row = conn.execute("SELECT * FROM season_completeness WHERE league_id=? AND season=?", (league_id, season)).fetchone()
        if row:
            return dict(row)
        return {"season_status": "UNKNOWN", "progress_pct": 0}

    @classmethod
    def get_data_richness_score(cls, league_id: str, current_season: str, conn=None) -> float:
        """Compute a data richness score in [0.0, 1.0] for a league.

        Measures how many PRIOR seasons (not the current one) exist with
        meaningful finished matches. Used by the ensemble to scale RL weight.

        Score mapping:
            0 prior seasons  -> 0.0   (pure Rule Engine — no training history)
            1 prior season   -> 0.33  (RL gets ~33% of its configured weight)
            2 prior seasons  -> 0.67  (RL gets ~67% of its configured weight)
            3+ prior seasons -> 1.0   (RL gets full configured weight)

        A "prior season" counts only if:
            - season != current_season
            - season_status IN ('COMPLETED', 'ACTIVE')
            - season_status != 'CUP_FORMAT'
            - finished_matches >= 20

        Args:
            league_id:      The league to evaluate.
            current_season: The active season string (from leagues.current_season).
            conn:           Optional open SQLite connection.

        Returns:
            Float in [0.0, 1.0]. Returns 0.0 if no data or on error.
        """
        try:
            local_conn = conn or get_connection()
            row = local_conn.execute("""
                SELECT COUNT(*) as prior_seasons
                FROM season_completeness
                WHERE league_id = ?
                  AND season != ?
                  AND season_status IN ('COMPLETED', 'ACTIVE')
                  AND season_status != 'CUP_FORMAT'
                  AND finished_matches >= 20
            """, (league_id, current_season or "")).fetchone()

            prior = (row["prior_seasons"] if hasattr(row, "keys") else row[0]) if row else 0

            # Cap at 3 for score calculation, then normalize to [0, 1]
            capped = min(prior, 3)
            return round(capped / 3.0, 4)

        except Exception as e:
            logger.warning("[Completeness] data_richness_score failed for %s: %s", league_id, e)
            return 0.0
