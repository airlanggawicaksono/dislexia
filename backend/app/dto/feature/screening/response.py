from datetime import datetime
from pydantic import BaseModel, ConfigDict, Field
from typing import Optional
from uuid import UUID

from app.dto.feature.chat.base import ChatMessageDTO
from app.dto.feature.screening.enums import PostProcessStatus


class ScreeningResponseDTO(BaseModel):
    model_config = ConfigDict(populate_by_name=True)

    result: str
    session_id: UUID
    history_id: Optional[UUID] = None
    is_complete: bool = False
    answered: Optional[bool] = Field(
        None,
        description=(
            "Whether the user's reply satisfied the CURRENT topic. true → the "
            "server advanced to the next topic; false → same topic re-asked "
            "(result is a clarifying question). null on /start (no reply yet). "
            "Note: after the re-ask loop cap the server force-advances, in which "
            "case answered is reported true."
        ),
    )
    answered_count: int = Field(
        0, description="Number of ARHQ topics answered so far (progress numerator)."
    )
    total_topics: int = Field(
        0, description="Total ARHQ topics (progress denominator)."
    )
    ahrq_result: Optional[dict] = Field(
        None,
        description=(
            "ARHQ post-processing result. Present ONLY when is_complete=true. "
            "Keys: ahrq_status ('success'|'failed'), ahrq_error (null|{reason,message}), "
            "ahrq_scores (list[int]|null, one per question in ARHQ order), "
            "ahrq_comments (str|null, comma-separated, index-aligned to ahrq_scores), "
            "ahrq_total (int|null, sum of scores), "
            "ahrq_severity (str|null, 'mild'|'moderate'|'severe')."
        ),
    )


class ScreeningSessionDTO(BaseModel):
    """One pre-screening conversation as a SET: its messages, progress and
    outcome. This — not the flat per-turn feature-history rows — is the unit
    clients should treat as 'a history entry'."""

    model_config = ConfigDict(populate_by_name=True)

    session_id: UUID
    created_at: datetime
    updated_at: datetime
    is_complete: bool = Field(
        ..., description="All topics answered (scoring may still be running)."
    )
    answered_count: int = Field(0, description="Topics answered so far.")
    total_topics: int
    status: PostProcessStatus = Field(
        ..., description="ARHQ scoring status: not_started | success | failed."
    )
    result: Optional[dict] = Field(
        None, description="ARHQ metadata (ahrq_severity, ahrq_total, …) once scored."
    )
    messages: list[ChatMessageDTO] = Field(
        default_factory=list, description="Full conversation, chronological."
    )


class ScreeningSessionListDTO(BaseModel):
    model_config = ConfigDict(populate_by_name=True)

    items: list[ScreeningSessionDTO]
    total: int


class PostProcessRunDTO(BaseModel):
    """Response for an on-demand ARHQ post-process run (retrigger by session_id)."""

    model_config = ConfigDict(populate_by_name=True)

    session_id: UUID
    history_id: UUID = Field(..., description="Feature history row the metadata was written to")
    status: PostProcessStatus = Field(..., description="Status derived from the persisted metadata")
    metadata: dict = Field(
        ..., description="Full ARHQ metadata dict persisted to feature_history.metadata"
    )


class PostProcessStatusDTO(BaseModel):
    """Response for the cheap, DB-only post-process status snapshot."""

    model_config = ConfigDict(populate_by_name=True)

    session_id: UUID
    history_id: Optional[UUID] = Field(None, description="Latest history row for the session, if any")
    status: PostProcessStatus = Field(..., description="not_started | success | failed")
    metadata: Optional[dict] = Field(
        None, description="Persisted ARHQ metadata if a run has completed for this session"
    )
