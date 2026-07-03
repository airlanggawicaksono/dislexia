"""Pure builders + status derivation for the ARHQ metadata dict persisted to
`feature_history.metadata` (JSONB). No IO — plain dict/enum work."""

from __future__ import annotations

from datetime import datetime
from typing import Optional

from app.policies import classify_severity
from app.dto.feature.screening.enums import PostProcessStatus


def build_success_metadata(
    scores: list[int],
    comments: list[str],
    *,
    started_at: datetime,
    finished_at: datetime,
) -> dict:
    total = sum(scores)
    return {
        "ahrq_status": PostProcessStatus.SUCCESS.value,
        "ahrq_started_at": started_at.isoformat(),
        "ahrq_finished_at": finished_at.isoformat(),
        "ahrq_scores": scores,
        "ahrq_comments": ",".join(comments),
        "ahrq_total": total,
        "ahrq_severity": classify_severity(total),
        "ahrq_error": None,
    }


def build_failure_metadata(
    reason: str,
    message: str = "",
    *,
    started_at: datetime,
    finished_at: datetime,
) -> dict:
    error: dict = {"reason": reason}
    if message:
        error["message"] = message
    return {
        "ahrq_status": PostProcessStatus.FAILED.value,
        "ahrq_started_at": started_at.isoformat(),
        "ahrq_finished_at": finished_at.isoformat(),
        "ahrq_scores": None,
        "ahrq_comments": None,
        "ahrq_total": None,
        "ahrq_severity": None,
        "ahrq_error": error,
    }


def resolve_status(metadata: Optional[dict]) -> PostProcessStatus:
    """Pure fn: JSONB metadata → status enum. No side-effects, no DB access."""
    if not metadata:
        return PostProcessStatus.NOT_STARTED
    raw = metadata.get("ahrq_status")
    if raw == PostProcessStatus.SUCCESS.value:
        return PostProcessStatus.SUCCESS
    if raw == PostProcessStatus.FAILED.value:
        return PostProcessStatus.FAILED
    return PostProcessStatus.NOT_STARTED
