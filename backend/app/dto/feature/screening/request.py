from pydantic import BaseModel, Field, ConfigDict
from uuid import UUID

from app.policies import MIN_INPUT_CHARS, MAX_INPUT_CHARS


class ScreeningReplyRequestDTO(BaseModel):
    model_config = ConfigDict(populate_by_name=True, str_strip_whitespace=True)

    text: str = Field(
        ...,
        min_length=MIN_INPUT_CHARS,
        max_length=MAX_INPUT_CHARS,
        description="User's reply to the current screening question",
    )
    session_id: UUID = Field(..., description="Active screening session ID from /start")
