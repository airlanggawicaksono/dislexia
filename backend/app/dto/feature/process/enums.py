from enum import Enum


class SummaryLevel(str, Enum):
    """Summary length tiers driven by percentage of source text.

    Higher tier = more content preserved. Content ordered by importance:
    CORE (top idea) → DEPENDENCIES (supporting facts) → DETAILS (nuance).
    Truncation on the LLM side degrades gracefully because tail carries least value.
    """

    PCT_10 = "10pct"  # core only
    PCT_30 = "30pct"  # core + dependencies
    PCT_50 = "50pct"  # core + deps + key details (default)
    PCT_70 = "70pct"  # most detail
    PCT_90 = "90pct"  # full detail, tightened prose
