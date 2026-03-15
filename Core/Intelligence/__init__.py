"""
Intelligence Package: Advanced AI Engine for Football Prediction & Analysis
Refactored for Clean Architecture (v2.7)

This package contains the core intelligence components for LeoBook:
- Rule Engine: Comprehensive rule-based prediction logic
- Selector Manager: CSS selector storage and auto-healing
- Visual Analyzer: Screenshot analysis and Leo AI vision
"""

from .rule_engine import RuleEngine
from .selector_manager import SelectorManager
from .visual_analyzer import VisualAnalyzer

__version__ = "2.6.0"
__all__ = ["RuleEngine", "SelectorManager", "VisualAnalyzer"]
