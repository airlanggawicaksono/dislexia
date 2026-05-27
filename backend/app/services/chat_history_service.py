from datetime import datetime, timezone
from typing import Optional
from uuid import UUID
from sqlalchemy import select, func
from sqlalchemy.ext.asyncio import AsyncSession

from app.exceptions import NotFoundError, ForbiddenError
from app.models.chat_session import ChatSession, FeatureHistory
from app.models.user import User
from app.dto.feature.chat.enums import FeatureType, ChatRoleType
from app.dto.feature.chat.base import (
    ChatSessionDTO,
    ChatSessionMetadataDTO,
    FeatureHistoryItemDTO,
    FeatureHistoryListDTO,
)
from app.dto.feature.chat.mappers import to_session_dto, to_metadata_dto, to_history_item_dto


def _now() -> datetime:
    return datetime.now(timezone.utc)


async def _load_owned_session(session_id: UUID, user_id: UUID, db: AsyncSession) -> ChatSession:
    result = await db.execute(select(ChatSession).where(ChatSession.session_id == session_id))
    session = result.scalar_one_or_none()
    if session is None:
        raise NotFoundError("Session not found")
    if session.user_id != user_id:
        raise ForbiddenError("Session belongs to another user")
    return session


class ChatHistoryService:
    @staticmethod
    async def create_session(user_id: UUID, feature: FeatureType, db: AsyncSession) -> ChatSessionDTO:
        session = ChatSession(user_id=user_id, feature=feature.value, history=[])
        db.add(session)
        await db.commit()
        await db.refresh(session)
        return to_session_dto(session)

    @staticmethod
    async def get_session(session_id: UUID, user_id: UUID, db: AsyncSession) -> ChatSessionDTO:
        session = await _load_owned_session(session_id, user_id, db)
        return to_session_dto(session)

    @staticmethod
    async def append_message(
        session_id: UUID, user_id: UUID, role: ChatRoleType, content: str, db: AsyncSession
    ) -> ChatSessionDTO:
        session = await _load_owned_session(session_id, user_id, db)
        message = {"role": role.value, "content": content, "timestamp": _now().isoformat()}
        session.history = [*session.history, message]
        session.updated_at = _now()
        await db.commit()
        await db.refresh(session)
        return to_session_dto(session)

    @staticmethod
    async def get_user_sessions(user_id: UUID, feature: FeatureType, db: AsyncSession) -> list[ChatSessionMetadataDTO]:
        result = await db.execute(
            select(ChatSession)
            .where(ChatSession.user_id == user_id, ChatSession.feature == feature.value)
            .order_by(ChatSession.updated_at.desc())
        )
        return [to_metadata_dto(s) for s in result.scalars().all()]

    @staticmethod
    async def save_feature_history(
        session_id: UUID, user_id: UUID, feature: FeatureType,
        input_text: str, output_text: str, db: AsyncSession,
    ) -> FeatureHistoryItemDTO:
        item = FeatureHistory(
            session_id=session_id,
            user_id=user_id,
            feature=feature.value,
            input_text=input_text,
            output_text=output_text,
        )
        db.add(item)
        await db.commit()
        await db.refresh(item)
        return to_history_item_dto(item)

    @staticmethod
    async def get_feature_history(user_id: UUID, feature: FeatureType, db: AsyncSession) -> FeatureHistoryListDTO:
        result = await db.execute(
            select(FeatureHistory)
            .where(FeatureHistory.user_id == user_id, FeatureHistory.feature == feature.value)
            .order_by(FeatureHistory.created_at.desc())
        )
        items = [to_history_item_dto(h) for h in result.scalars().all()]
        return FeatureHistoryListDTO(items=items, total=len(items), feature=feature)

    @staticmethod
    async def get_history_filtered(
        user_id: UUID, feature: Optional[FeatureType], db: AsyncSession
    ) -> FeatureHistoryListDTO:
        conditions = [FeatureHistory.user_id == user_id]
        if feature:
            conditions.append(FeatureHistory.feature == feature.value)
        result = await db.execute(
            select(FeatureHistory).where(*conditions).order_by(FeatureHistory.created_at.desc())
        )
        items = [to_history_item_dto(h) for h in result.scalars().all()]
        return FeatureHistoryListDTO(items=items, total=len(items), feature=feature)

    @staticmethod
    async def get_history_item_owned(history_id: UUID, user_id: UUID, db: AsyncSession) -> FeatureHistoryItemDTO:
        result = await db.execute(select(FeatureHistory).where(FeatureHistory.id == history_id))
        item = result.scalar_one_or_none()
        if item is None:
            raise NotFoundError("History item not found")
        if item.user_id != user_id:
            raise ForbiddenError("History item belongs to another user")
        return to_history_item_dto(item)

    @staticmethod
    async def get_history_admin(
        account_hash: Optional[str], feature: Optional[FeatureType], db: AsyncSession
    ) -> FeatureHistoryListDTO:
        query = select(FeatureHistory)
        if account_hash:
            query = (
                query.join(User, FeatureHistory.user_id == User.user_id)
                     .where(func.md5(User.account_number) == account_hash)
            )
        if feature:
            query = query.where(FeatureHistory.feature == feature.value)
        result = await db.execute(query.order_by(FeatureHistory.created_at.desc()))
        items = [to_history_item_dto(h) for h in result.scalars().all()]
        return FeatureHistoryListDTO(items=items, total=len(items), feature=feature)

    @staticmethod
    async def get_history_item_admin(history_id: UUID, db: AsyncSession) -> FeatureHistoryItemDTO:
        result = await db.execute(select(FeatureHistory).where(FeatureHistory.id == history_id))
        item = result.scalar_one_or_none()
        if item is None:
            raise NotFoundError("History item not found")
        return to_history_item_dto(item)

    @staticmethod
    async def clear_history(session_id: UUID, user_id: UUID, db: AsyncSession) -> ChatSessionDTO:
        session = await _load_owned_session(session_id, user_id, db)
        session.history = []
        session.updated_at = _now()
        await db.commit()
        await db.refresh(session)
        return to_session_dto(session)
