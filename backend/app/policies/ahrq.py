"""Adult Dyslexia Checklist — scoring policy (Smythe & Everatt, 2001).

Replaces the earlier free 0-4-per-item ARHQ scoring. This is a WEIGHTED
fixed-option instrument: every question has exactly four answer columns, each
worth a set number of points. The conversational screener infers which column
a user's free-text answer falls into (option 1-4, or 0 = not answered); this
module owns the weight table, the weighted total, and the published bands.

Metadata keys stay `ahrq_*` for backward-compatibility with existing clients
and stored rows — only the scoring math and the band labels changed.

Source: Ian Smythe & John Everatt, 2001. This is NOT a diagnostic tool — a
score only points toward whether a full professional assessment is warranted.
"""

# Answer column chosen per question. 0 = not answered (contributes 0 points);
# 1..4 = the four printed columns, left→right (least → most indicative).
SCORE_MIN = 0
SCORE_MAX = 4

# Point values for columns 1..4, in QUESTIONS order (15 items). These are the
# instrument's own weights — do NOT rebalance without re-validating the bands.
# Q1-10 use a frequency scale (Rarely/Occasionally/Often/Most of the time);
# Q11-15 use a difficulty scale (Easy/Challenging/Difficult/Very difficult).
OPTION_WEIGHTS: list[tuple[int, int, int, int]] = [
    (3, 6, 9, 12),  # 1  confuse visually similar words (cat/cot)
    (2, 4, 6, 8),   # 2  lose place / miss lines when reading
    (1, 2, 3, 4),   # 3  confuse names of objects (table/chair)
    (1, 2, 3, 4),   # 4  trouble telling left from right
    (1, 2, 3, 4),   # 5  map reading / finding the way confusing
    (1, 2, 3, 4),   # 6  re-read paragraphs to understand them
    (1, 2, 3, 4),   # 7  confused by several instructions at once
    (1, 2, 3, 4),   # 8  mistakes when taking down phone messages
    (1, 2, 3, 4),   # 9  difficulty finding the right word to say
    (1, 2, 3, 4),   # 10 thinking of creative solutions (more often = higher)
    (3, 6, 9, 12),  # 11 sounding out words (e-le-phant)
    (2, 4, 6, 8),   # 12 organising thoughts on paper when writing
    (2, 4, 6, 8),   # 13 learning multiplication tables
    (1, 2, 3, 4),   # 14 reciting the alphabet
    (1, 2, 3, 4),   # 15 reading aloud
]

# Weighted total range: all-column-1 = 22 (min) .. all-column-4 = 88 (max).
MIN_TOTAL = sum(w[0] for w in OPTION_WEIGHTS)   # 22
MAX_TOTAL = sum(w[-1] for w in OPTION_WEIGHTS)  # 88

# Published bands (Smythe & Everatt, 2001). Each: (inclusive_upper_bound, label).
#   < 45  → probably non-dyslexic
#   45-60 → signs consistent with mild dyslexia
#   > 60  → signs consistent with moderate or severe dyslexia
SEVERITY_THRESHOLDS: list[tuple[int, str]] = [
    (44, "unlikely"),
    (60, "mild"),
    (MAX_TOTAL, "moderate_severe"),
]

DISCLAIMER = (
    "This checklist is not a diagnostic assessment. It highlights areas of "
    "possible difficulty and whether seeking a full professional assessment "
    "may be helpful."
)
ATTRIBUTION = "Adult Dyslexia Checklist © Ian Smythe & John Everatt, 2001."


def score_option(question_index: int, option: int) -> int:
    """Points contributed by `option` for one question.

    option: 0 = not answered (→ 0 points), 1..4 = the chosen answer column.
    """
    if option <= 0:
        return 0
    return OPTION_WEIGHTS[question_index][option - 1]


def score_total(options: list[int]) -> int:
    """Weighted total across all 15 answered options (0-columns add nothing)."""
    return sum(score_option(i, opt) for i, opt in enumerate(options))


def classify_severity(total: int) -> str:
    """Map a weighted total to a published band label."""
    for threshold, label in SEVERITY_THRESHOLDS:
        if total <= threshold:
            return label
    return SEVERITY_THRESHOLDS[-1][1]
