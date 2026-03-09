# ensemble.py: Neuro-Symbolic Ensemble Engine for LeoBook.
# Part of LeoBook Core — Intelligence
#
# Classes: EnsembleEngine

"""
Neuro-Symbolic Ensemble Engine
Merges Rule Engine (Symbolic) and RL (Neural) predictions using weighted averaging.
Supports per-league weighting and fallback logic for low-confidence neural outputs.
"""

import json
import os
import logging
from typing import Dict, Any, Optional

logger = logging.getLogger(__name__)

class EnsembleEngine:
    """
    Neuro-Symbolic Ensemble Engine
    Merges Rule Engine (Symbolic) and RL (Neural) predictions with weighted averaging.
    """
    
    _weights_path = os.path.join(os.path.dirname(__file__), '..', '..', 'Config', 'ensemble_weights.json')
    _weights = None

    @classmethod
    def _load_weights(cls):
        """Lazy loader for ensemble weights."""
        if cls._weights is not None:
            return cls._weights
        try:
            if os.path.exists(cls._weights_path):
                with open(cls._weights_path, 'r', encoding='utf-8') as f:
                    cls._weights = json.load(f)
            else:
                cls._weights = {"default": {"W_symbolic": 0.7, "W_neural": 0.3}, "leagues": {}}
        except Exception as e:
            logger.error(f"[Ensemble] Failed to load weights: {e}")
            cls._weights = {"default": {"W_symbolic": 0.7, "W_neural": 0.3}, "leagues": {}}
        return cls._weights

    @classmethod
    def merge(cls, rule_logits: Dict[str, float], rule_conf: float, 
              rl_logits: Optional[Dict[str, float]], rl_conf: Optional[float], 
              league_id: str) -> Dict[str, Any]:
        """
        Merge symbolic and neural outputs.
        
        Args:
            rule_logits: Dict with {'home': score, 'draw': score, 'away': score}
            rule_conf: Confidence (0.0 - 1.0) from Rule Engine
            rl_logits: Dict with {'home_win': prob, 'draw': prob, 'away_win': prob} or None
            rl_conf: Confidence (0.0 - 1.0) from RL Engine or None
            league_id: League ID for per-league weighting
            
        Returns:
            Dictionary containing merged results and path taken.
        """
        weights_data = cls._load_weights()
        league_weights = weights_data.get("leagues", {}).get(league_id, weights_data["default"])
        
        w_s = league_weights.get("W_symbolic", 0.7)
        w_n = league_weights.get("W_neural", 0.3)

        # Fallback to symbolic if RL confidence is too low or RL failed
        if rl_logits is None or rl_conf is None or rl_conf < 0.3:
            path = "symbolic_fallback"
            reason = "RL failed" if rl_logits is None else f"low confidence ({rl_conf:.2f} < 0.3)"
            
            logger.debug(f"[Ensemble] {league_id} | Path: {path} | Reason: {reason}")
            
            # Normalize rule_logits for consistency
            total = sum(rule_logits.values()) or 1.0
            norm_logits = {k: v / total for k, v in rule_logits.items()}
            
            return {
                "logits": norm_logits,
                "confidence": rule_conf,
                "path": path,
                "weights": {"W_symbolic": 1.0, "W_neural": 0.0}
            }

        # Ensemble path
        path = "ensemble"
        
        # Mapping RL action probs to consistent keys
        rl_1x2 = {
            "home": rl_logits.get("home_win", 0.33),
            "draw": rl_logits.get("draw", 0.34),
            "away": rl_logits.get("away_win", 0.33)
        }
        
        # Normalize Rule Logits
        s_total = sum(rule_logits.values()) or 1.0
        s_1x2 = {k: v / s_total for k, v in rule_logits.items()}

        # Weighted Merge
        final_1x2 = {
            "home": (s_1x2["home"] * w_s) + (rl_1x2["home"] * w_n),
            "draw": (s_1x2["draw"] * w_s) + (rl_1x2["draw"] * w_n),
            "away": (s_1x2["away"] * w_s) + (rl_1x2["away"] * w_n)
        }
        
        # Normalize final logits to ensure they sum to 1.0
        f_total = sum(final_1x2.values()) or 1.0
        final_1x2 = {k: v / f_total for k, v in final_1x2.items()}

        final_conf = (rule_conf * w_s) + (rl_conf * w_n)
        
        logger.info(f"[Ensemble] {league_id} | Path: {path} | RL Conf: {rl_conf:.2f} | s:{w_s} n:{w_n}")
        
        return {
            "logits": final_1x2,
            "confidence": final_conf,
            "path": path,
            "weights": {"W_symbolic": w_s, "W_neural": w_n}
        }


# ── 30-dim RL output → structured recommendation ─────────────

def rl_action_to_recommendation(
    action_idx: int,
    model_probs: list,
    live_odds: Optional[Dict[str, float]] = None,
) -> Optional[Dict]:
    """
    Convert 30-dim RL output to a structured recommendation.
    Applies stairway gate with live odds if available.
    Returns None if action is no_bet or fails gate.
    """
    from Core.Intelligence.rl.market_space import (
        ACTIONS, N_ACTIONS, stairway_gate, SYNTHETIC_ODDS
    )

    if action_idx >= N_ACTIONS:
        return None

    action = ACTIONS[action_idx]
    key    = action["key"]

    if key == "no_bet":
        return None

    model_prob = model_probs[action_idx] if action_idx < len(model_probs) else 0.0
    live_odds_val = (live_odds or {}).get(key)
    fair_odds_val = SYNTHETIC_ODDS.get(key)

    bettable, reason = stairway_gate(key, live_odds_val, model_prob)
    if not bettable:
        return None

    odds_to_use = live_odds_val or fair_odds_val or 0.0
    ev = (model_prob * odds_to_use) - 1.0 if odds_to_use > 0 else None

    return {
        "market_key":   key,
        "market_name":  action["market"],
        "outcome":      action["outcome"],
        "line":         action["line"],
        "market_id":    action["market_id"],
        "model_prob":   round(model_prob, 4),
        "live_odds":    live_odds_val,
        "fair_odds":    fair_odds_val,
        "is_value_bet": (ev is not None and ev > 0),
        "ev":           round(ev, 4) if ev is not None else None,
        "likelihood_pct": action["likelihood"],
    }
