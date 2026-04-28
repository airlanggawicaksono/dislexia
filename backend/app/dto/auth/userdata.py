from pydantic import BaseModel, Field, ConfigDict
from datetime import datetime
from typing import Optional
from uuid import UUID


class UserResponseDTO(BaseModel):
    """User data for API responses (read-only)"""

    model_config = ConfigDict(populate_by_name=True)

    user_id: UUID = Field(..., description="Unique user identifier")
    email: str = Field(..., description="User email address")
    username: str = Field(
        ..., description="Auto-generated username (Adjective + Animal)"
    )
    created_at: datetime = Field(..., description="Account creation timestamp")
    last_login: Optional[datetime] = Field(None, description="Last login timestamp")
    is_active: bool = Field(..., description="Whether the user account is active")


class TokenResponseDTO(BaseModel):
    """JWT token response"""

    model_config = ConfigDict(populate_by_name=True)

    access_token: str = Field(..., description="JWT access token")
    token_type: str = Field("bearer", description="Token type")
    expires_in: int = Field(..., description="Token expiration time in seconds")
    user: UserResponseDTO = Field(..., description="User information")
