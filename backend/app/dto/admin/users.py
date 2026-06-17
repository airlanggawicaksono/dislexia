from datetime import datetime
from typing import Optional
from uuid import UUID

from pydantic import BaseModel, ConfigDict, Field


class UserAdminItemDTO(BaseModel):
    """One user as the admin sees them. Raw account_number is intentionally
    redacted to MD5 — admins never see user credentials."""

    model_config = ConfigDict(populate_by_name=True)

    user_id: UUID
    display_name: str
    account_md5: str
    is_active: bool
    created_at: datetime
    last_login: Optional[datetime] = None


class UserAdminListDTO(BaseModel):
    model_config = ConfigDict(populate_by_name=True)

    items: list[UserAdminItemDTO]
    total: int


class AdminCreateUserResponseDTO(BaseModel):
    """Returned once when admin creates a user account.
    Share account_number with the user out-of-band — it is their only login credential."""

    model_config = ConfigDict(populate_by_name=True)

    user_id: UUID
    account_number: str = Field(..., description="6-digit code. Give this to the user — it's their only login key.")
    display_name: str
