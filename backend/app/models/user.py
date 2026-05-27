from datetime import datetime, timezone
from uuid import UUID, uuid4
from typing import Optional

import petname
from sqlalchemy.orm import Mapped, mapped_column
from sqlalchemy import String, Boolean, DateTime, UUID as SQLAlchemyUUID, func

from app.config.database import Base
from app.utils.account_number_generator import AccountNumberGenerator


def utc_now() -> datetime:
    return datetime.now(timezone.utc)


class User(Base):
    __tablename__ = "users"

    user_id: Mapped[UUID] = mapped_column(
        SQLAlchemyUUID(as_uuid=True), primary_key=True, default=uuid4, nullable=False
    )
    account_number: Mapped[str] = mapped_column(
        String(16), unique=True, nullable=False, index=True
    )
    display_name: Mapped[str] = mapped_column(
        String(64), nullable=False, index=True
    )
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), nullable=False, server_default=func.now()
    )
    last_login: Mapped[Optional[datetime]] = mapped_column(
        DateTime(timezone=True), nullable=True, default=None
    )
    is_active: Mapped[bool] = mapped_column(Boolean, nullable=False, default=True)

    def __init__(
        self,
        account_number: Optional[str] = None,
        display_name: Optional[str] = None,
        **kwargs,
    ):
        super().__init__(**kwargs)
        self.account_number = account_number or AccountNumberGenerator.generate()
        self.display_name = display_name or petname.Generate(2, "-")

    def update_last_login(self) -> None:
        self.last_login = utc_now()

    def deactivate(self) -> None:
        self.is_active = False

    def activate(self) -> None:
        self.is_active = True

    def __repr__(self) -> str:
        return f"User(user_id={self.user_id}, display_name={self.display_name})"
