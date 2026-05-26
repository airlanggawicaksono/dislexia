from datetime import datetime
from typing import Optional
from uuid import UUID

from pydantic import BaseModel, Field, ConfigDict


class AdminLoginRequestDTO(BaseModel):
    model_config = ConfigDict(populate_by_name=True, str_strip_whitespace=True)

    username: str = Field(..., min_length=3, max_length=64)
    password: str = Field(..., min_length=8, max_length=128)


class AdminChangePasswordRequestDTO(BaseModel):
    model_config = ConfigDict(populate_by_name=True, str_strip_whitespace=True)

    current_password: str = Field(..., min_length=1, max_length=128)
    new_password: str = Field(..., min_length=8, max_length=128)


class AdminResponseDTO(BaseModel):
    model_config = ConfigDict(populate_by_name=True)

    admin_id: UUID
    username: str
    must_change_password: bool
    is_active: bool
    created_at: datetime
    last_login: Optional[datetime] = None


class AdminTokenResponseDTO(BaseModel):
    model_config = ConfigDict(populate_by_name=True)

    access_token: str
    token_type: str = "bearer"
    expires_in: int
    admin: AdminResponseDTO


class AdminCreateResponseDTO(BaseModel):
    """Returned once when a new admin is invited. Caller MUST save these — they cannot be recovered."""

    model_config = ConfigDict(populate_by_name=True)

    admin_id: UUID
    username: str
    temporary_password: str = Field(..., description="One-time password. Admin must change on first login.")
