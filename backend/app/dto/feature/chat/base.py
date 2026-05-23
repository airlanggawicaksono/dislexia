from datetime import datetime
from typing import Optional
from uuid import UUID
from pydantic import BaseModel, ConfigDict

from app.dto.feature.chat.enums import FeatureType, ChatRoleType


class ChatMessageDTO(BaseModel):
    model_config = ConfigDict(populate_by_name=True)

    role: ChatRoleType
    content: str
    timestamp: datetime


class ChatSessionDTO(BaseModel):
    model_config = ConfigDict(populate_by_name=True)

    session_id: UUID
    user_id: UUID
    feature: FeatureType
    history: list[ChatMessageDTO]
    created_at: datetime
    updated_at: datetime


class ChatSessionMetadataDTO(BaseModel):
    model_config = ConfigDict(populate_by_name=True)

    session_id: UUID
    user_id: UUID
    feature: FeatureType
    message_count: int
    created_at: datetime
    updated_at: datetime


class FeatureHistoryItemDTO(BaseModel):
    model_config = ConfigDict(populate_by_name=True)

    id: UUID
    session_id: UUID
    user_id: UUID
    feature: FeatureType
    input_text: str
    output_text: Optional[str] = None
    created_at: datetime


class FeatureHistoryListDTO(BaseModel):
    model_config = ConfigDict(populate_by_name=True)

    items: list[FeatureHistoryItemDTO]
    total: int
    feature: FeatureType
