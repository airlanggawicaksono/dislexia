from pydantic import BaseModel, Field, ConfigDict


class SignupRequestDTO(BaseModel):
    """Request model for user signup"""

    model_config = ConfigDict(populate_by_name=True)

    email: str = Field(..., description="User email address")


class SignupResponseDTO(BaseModel):
    """Response model for user signup"""

    model_config = ConfigDict(populate_by_name=True)

    access_code: str = Field(
        ..., description="7-digit access code for login", min_length=7, max_length=7
    )
    email: str = Field(..., description="User email address")
    username: str = Field(..., description="Auto-generated username")
    message: str = Field(..., description="Success message")


class LoginRequestDTO(BaseModel):
    """Request model for user login"""

    model_config = ConfigDict(populate_by_name=True)

    access_code: str = Field(
        ..., description="7-digit access code", min_length=7, max_length=7
    )
