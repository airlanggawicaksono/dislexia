from datetime import datetime, timezone
from uuid import UUID, uuid4
from typing import Optional

from sqlalchemy import String, Boolean, DateTime, UUID as SQLAlchemyUUID, ForeignKey, func
from sqlalchemy.orm import Mapped, mapped_column

from app.config.database import Base


def utc_now() -> datetime:
    return datetime.now(timezone.utc)


class Admin(Base):
    __tablename__ = "admins"

    admin_id: Mapped[UUID] = mapped_column(
        SQLAlchemyUUID(as_uuid=True), primary_key=True, default=uuid4, nullable=False
    )
    username: Mapped[str] = mapped_column(String(64), unique=True, nullable=False, index=True)
    password_hash: Mapped[str] = mapped_column(String(255), nullable=False)
    must_change_password: Mapped[bool] = mapped_column(Boolean, nullable=False, default=True)
    is_active: Mapped[bool] = mapped_column(Boolean, nullable=False, default=True)
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), nullable=False, server_default=func.now()
    )
    last_login: Mapped[Optional[datetime]] = mapped_column(
        DateTime(timezone=True), nullable=True, default=None
    )
    created_by: Mapped[Optional[UUID]] = mapped_column(
        SQLAlchemyUUID(as_uuid=True), ForeignKey("admins.admin_id"), nullable=True
    )

    def update_last_login(self) -> None:
        self.last_login = utc_now()

    def __repr__(self) -> str:
        return f"Admin(admin_id={self.admin_id}, username={self.username})"
