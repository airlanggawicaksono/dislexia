from pydantic import BaseModel, Field, ConfigDict
from typing import Optional
from uuid import UUID


class FeatureResponseDTO(BaseModel):
    """Shared response for /process endpoints (summarize, professionalize, define)."""

    model_config = ConfigDict(populate_by_name=True)

    result: str = Field(..., description="Processed text result")
    feature: str = Field(..., description="Feature name")
    session_id: UUID = Field(..., description="Session ID for continuing this conversation")
    history_id: Optional[UUID] = Field(None, description="History record ID")
