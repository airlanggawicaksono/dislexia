from typing import Optional, Self
from uuid import UUID

from pydantic import BaseModel, Field, ConfigDict, model_validator

from app.policies import MIN_INPUT_CHARS, MAX_INPUT_CHARS
from app.dto.feature.process.enums import SummaryLevel, DefineLevel


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
    """Request for /summarize/process.

    Adds `level` — the pct of source-text characters the summary should target.
    Content is always ordered by importance (CORE → DEPENDENCIES → DETAILS),
    so lower levels drop the least-important layers first.
    """

    model_config = ConfigDict(
        populate_by_name=True,
        str_strip_whitespace=True,
        json_schema_extra={
            "examples": [
                {
                    "text": "The quarterly earnings report indicates the company exceeded revenue targets.",
                    "level": "50pct",
                },
                {
                    "text": "Long article body...",
                    "level": "10pct",
                    "session_id": "3fa85f64-5717-4562-b3fc-2c963f66afa6",
                },
            ]
        },
    )

    level: SummaryLevel = Field(
        SummaryLevel.PCT_50,
        description=(
            "Summary length as pct of source (importance-ordered content): "
            "10pct (core only), 30pct (core+deps), 50pct (default), "
            "70pct, 90pct (near-verbatim)."
        ),
    )


class DefineRequestDTO(FeatureRequestDTO):
    """Request for /define/process.

    Adds `level` — how many explanation layers to include. Content is layered
    (core → example → usage → related words → nuance), so lower levels drop
    the deepest layers first. Not a length dial; a depth dial.
    """

    level: DefineLevel = Field(
        DefineLevel.PCT_50,
        description=(
            "Definition depth (cumulative explanation layers): "
            "10pct (core meaning only), 30pct (+example), 50pct (+usage, default), "
            "70pct (+related words), 90pct (+nuance/etymology)."
        ),
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
