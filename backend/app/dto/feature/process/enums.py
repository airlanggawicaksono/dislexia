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


class DefineLevel(str, Enum):
    """Definition elaboration tiers. Reuses summarize's pct labels for a
    familiar dial, but higher tier means MORE explanation LAYERS (not length):
    core meaning → example → usage → related words → nuance/etymology.
    Each tier is cumulative; lower tiers drop the deepest layers first.
    """

    PCT_10 = "10pct"  # core meaning only
    PCT_30 = "30pct"  # + example
    PCT_50 = "50pct"  # + usage/context (default)
    PCT_70 = "70pct"  # + related words / distinctions
    PCT_90 = "90pct"  # + nuance / etymology

class OutputLanguage(str, Enum):
    """Supported output languages for all feature responses."""

    EN = "English"
    ID = "Indonesian"