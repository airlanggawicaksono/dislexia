from pydantic import BaseModel, Field, ConfigDict
from datetime import datetime
from typing import Optional, List
from uuid import UUID


class HistoryItemDTO(BaseModel):
    """Single history item for feature usage"""

    model_config = ConfigDict(populate_by_name=True)

    id: UUID = Field(..., description="History item ID")
    user_id: UUID = Field(..., description="User ID")
    feature: str = Field(
        ..., description="Feature name: summarize, professionalize, define"
    )
    input_text: str = Field(..., description="User input text")
    output_text: Optional[str] = Field(None, description="AI output text")
    created_at: datetime = Field(..., description="Creation timestamp")


class HistoryListResponseDTO(BaseModel):
    """List of history items"""

    model_config = ConfigDict(populate_by_name=True)

    items: List[HistoryItemDTO] = Field(
        default_factory=list, description="List of history items"
    )
    total: int = Field(..., description="Total number of items")
    feature: str = Field(..., description="Feature name")


class FeatureRequestDTO(BaseModel):
    """Base request for feature endpoints"""

    model_config = ConfigDict(populate_by_name=True)

    text: str = Field(..., description="Input text to process")


class FeatureResponseDTO(BaseModel):
    """Base response for feature endpoints"""

    model_config = ConfigDict(populate_by_name=True)

    result: str = Field(..., description="Processed text result")
    feature: str = Field(..., description="Feature name")
    history_id: Optional[UUID] = Field(None, description="History record ID")
