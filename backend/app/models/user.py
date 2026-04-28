from datetime import datetime, timezone
from uuid import UUID, uuid4
from typing import Optional
from sqlalchemy.orm import Mapped, mapped_column
from sqlalchemy import String, Boolean, DateTime, UUID as SQLAlchemyUUID, func
from app.config.database import Base
from app.utils.username_generator import UsernameGenerator
from app.utils.access_code_generator import AccessCodeGenerator


def utc_now() -> datetime:
    """Get current UTC time with timezone awareness"""
    return datetime.now(timezone.utc)


class User(Base):
    """
    User database model with 7-digit access code authentication
    """

    __tablename__ = "users"

    user_id: Mapped[UUID] = mapped_column(
        SQLAlchemyUUID(as_uuid=True), primary_key=True, default=uuid4, nullable=False
    )

    email: Mapped[str] = mapped_column(
        String(255), unique=True, nullable=False, index=True
    )

    username: Mapped[str] = mapped_column(
        String(100), unique=True, nullable=False, index=True
    )

    access_code: Mapped[str] = mapped_column(
        String(7), unique=True, nullable=False, index=True
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
        email: str,
        username: Optional[str] = None,
        access_code: Optional[str] = None,
        username_generator: Optional[UsernameGenerator] = None,
        access_code_generator: Optional[AccessCodeGenerator] = None,
        **kwargs,
    ):
        super().__init__(**kwargs)
        self.email = email
        self._username_generator = username_generator or UsernameGenerator()
        self._access_code_generator = access_code_generator or AccessCodeGenerator()
        self.username = username or self._generate_username()
        self.access_code = access_code or self._generate_access_code()

    def _generate_username(self) -> str:
        """Generate unique username with Adjective + Animal combination"""
        return self._username_generator.generate()

    def _generate_access_code(self) -> str:
        """Generate 7-digit alphanumeric access code"""
        return self._access_code_generator.generate()

    def update_last_login(self) -> None:
        """Update last login timestamp"""
        self.last_login = utc_now()

    def deactivate(self) -> None:
        """Deactivate user account"""
        self.is_active = False

    def activate(self) -> None:
        """Activate user account"""
        self.is_active = True

    def __repr__(self) -> str:
        return f"User(user_id={self.user_id}, username={self.username})"
