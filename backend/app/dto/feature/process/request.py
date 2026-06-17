from typing import Optional, Self
from uuid import UUID

from pydantic import BaseModel, Field, ConfigDict, model_validator

from app.policies import MIN_INPUT_CHARS, MAX_INPUT_CHARS
from app.dto.feature.process.enums import SummaryLevel


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


class SummarizeRequestDTO(FeatureRequestDTO):
    """Request for /summarize/process. Adds summary length level."""

    level: SummaryLevel = Field(
        SummaryLevel.MODERATE,
        description="Summary length: short (2-3 sentences), moderate (key points), detailed (comprehensive).",
    )


class ProfessionalizeRequestDTO(FeatureRequestDTO):
    """Request for /professionalize/process.

    Email mode: provide BOTH recipient_name and sender_name.
    Plain text mode: provide NEITHER.
    """

    recipient_name: Optional[str] = Field(
        None,
        min_length=1,
        max_length=128,
        description="Recipient's name. Required together with sender_name for email mode.",
    )
    sender_name: Optional[str] = Field(
        None,
        min_length=1,
        max_length=128,
        description="Sender's name. Required together with recipient_name for email mode.",
    )

    @model_validator(mode="after")
    def validate_email_fields(self) -> Self:
        has_recipient = self.recipient_name is not None
        has_sender = self.sender_name is not None
        if has_recipient != has_sender:
            raise ValueError(
                "Provide both recipient_name and sender_name for email mode, or neither for plain text mode."
            )
        return self

    @property
    def is_email_mode(self) -> bool:
        return self.recipient_name is not None
