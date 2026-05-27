from pydantic import BaseModel, ConfigDict
from datetime import datetime
from typing import Optional
from uuid import UUID


class UserResponseDTO(BaseModel):
    model_config = ConfigDict(populate_by_name=True)

    user_id: UUID
    account_number: str
    display_name: str
    created_at: datetime
    last_login: Optional[datetime] = None
    is_active: bool


class TokenResponseDTO(BaseModel):
    model_config = ConfigDict(populate_by_name=True)

    access_token: str
    token_type: str = "bearer"
    expires_in: int
    user: UserResponseDTO
