from datetime import datetime
from typing import Optional
from uuid import UUID

from pydantic import BaseModel, ConfigDict


class UserAdminItemDTO(BaseModel):
    """One user as the admin sees them. Raw account_number is intentionally
    redacted to MD5 — admins never see Mullvad credentials."""

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
