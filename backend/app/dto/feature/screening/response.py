from pydantic import BaseModel, ConfigDict, Field
from typing import Optional
from uuid import UUID

from app.dto.feature.screening.enums import PostProcessStatus


class ScreeningResponseDTO(BaseModel):
    model_config = ConfigDict(populate_by_name=True)

    result: str
    session_id: UUID
    history_id: Optional[UUID] = None
    is_complete: bool = False
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
