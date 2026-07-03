"""ARHQ scoring policy — score bounds + severity banding.

Shared config for the screening post-process. Lives here (not in the service)
so the extraction prompt, parser, and result builder all read the same source
of truth. Adjust thresholds here to re-band severity across the whole app.
"""

# 0 = no indication of dyslexia risk on an item, MAX = strong indication.
SCORE_MIN = 0
SCORE_MAX = 4

# Total = sum of per-item scores. For 23 items × 0..4 → 0..92 range.
# Each entry: (inclusive_upper_bound, label). Ordered ascending by bound.
SEVERITY_THRESHOLDS: list[tuple[int, str]] = [
    (30, "mild"),      # total <= 30 → mild
    (60, "moderate"),  # 31..60 → moderate
    (92, "severe"),    # 61..92 → severe
]


def classify_severity(total: int) -> str:
    """Map a total score to a severity band label."""
    for threshold, label in SEVERITY_THRESHOLDS:
        if total <= threshold:
            return label
    return SEVERITY_THRESHOLDS[-1][1]
