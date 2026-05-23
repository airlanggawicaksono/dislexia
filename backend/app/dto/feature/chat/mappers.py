from app.models.chat_session import ChatSession, FeatureHistory
from app.dto.feature.chat.enums import FeatureType
from app.dto.feature.chat.base import (
    ChatMessageDTO,
    ChatSessionDTO,
    ChatSessionMetadataDTO,
    FeatureHistoryItemDTO,
)


def to_session_dto(session: ChatSession) -> ChatSessionDTO:
    return ChatSessionDTO(
        session_id=session.session_id,
        user_id=session.user_id,
        feature=FeatureType(session.feature),
        history=[ChatMessageDTO(**msg) for msg in session.history],
        created_at=session.created_at,
        updated_at=session.updated_at,
    )


def to_metadata_dto(session: ChatSession) -> ChatSessionMetadataDTO:
    return ChatSessionMetadataDTO(
        session_id=session.session_id,
        user_id=session.user_id,
        feature=FeatureType(session.feature),
        message_count=len(session.history),
        created_at=session.created_at,
        updated_at=session.updated_at,
    )


def to_history_item_dto(item: FeatureHistory) -> FeatureHistoryItemDTO:
    return FeatureHistoryItemDTO(
        id=item.id,
        session_id=item.session_id,
        user_id=item.user_id,
        feature=FeatureType(item.feature),
        input_text=item.input_text,
        output_text=item.output_text,
        created_at=item.created_at,
    )
