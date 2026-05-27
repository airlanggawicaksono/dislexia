from pydantic import BaseModel, Field, ConfigDict
from typing import Optional
from uuid import UUID

from app.policies import MIN_INPUT_CHARS, MAX_INPUT_CHARS


class FeatureRequestDTO(BaseModel):
    """Shared request for /process endpoints (summarize, professionalize, define)."""

    model_config = ConfigDict(populate_by_name=True, str_strip_whitespace=True)

    text: str = Field(
        ...,
        min_length=MIN_INPUT_CHARS,
        max_length=MAX_INPUT_CHARS,
        description="Input text to process",
    )
    session_id: Optional[UUID] = Field(None, description="Existing session to continue. Omit to start new session.")
