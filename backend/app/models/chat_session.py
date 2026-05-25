from datetime import datetime
from uuid import UUID, uuid4
from sqlalchemy import String, DateTime, ForeignKey, Index, Text, func
from sqlalchemy.orm import Mapped, mapped_column
from sqlalchemy import UUID as SQLAlchemyUUID
from sqlalchemy.dialects.postgresql import JSONB
from app.config.database import Base


class ChatSession(Base):
    __tablename__ = "chat_sessions"

    session_id: Mapped[UUID] = mapped_column(
        SQLAlchemyUUID(as_uuid=True), primary_key=True, default=uuid4
    )
    user_id: Mapped[UUID] = mapped_column(
        SQLAlchemyUUID(as_uuid=True), ForeignKey("users.user_id"), nullable=False, index=True
    )
    feature: Mapped[str] = mapped_column(String(50), nullable=False, index=True)
    history: Mapped[list] = mapped_column(JSONB, nullable=False, default=list)
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), nullable=False, server_default=func.now()
    )
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), nullable=False, server_default=func.now()
    )

    __table_args__ = (
        Index("ix_chat_sessions_history_gin", "history", postgresql_using="gin"),
    )


class FeatureHistory(Base):
    __tablename__ = "feature_history"

    id: Mapped[UUID] = mapped_column(
        SQLAlchemyUUID(as_uuid=True), primary_key=True, default=uuid4
    )
    session_id: Mapped[UUID] = mapped_column(
        SQLAlchemyUUID(as_uuid=True), ForeignKey("chat_sessions.session_id"), nullable=False, index=True
    )
    user_id: Mapped[UUID] = mapped_column(
        SQLAlchemyUUID(as_uuid=True), ForeignKey("users.user_id"), nullable=False
    )
    feature: Mapped[str] = mapped_column(String(50), nullable=False)
    input_text: Mapped[str] = mapped_column(Text, nullable=False)
    output_text: Mapped[str | None] = mapped_column(Text, nullable=True)
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), nullable=False, server_default=func.now()
    )

    __table_args__ = (
        Index("ix_feature_history_user_feature", "user_id", "feature"),
    )
