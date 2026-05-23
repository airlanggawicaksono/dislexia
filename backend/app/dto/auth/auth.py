from pydantic import BaseModel, Field, ConfigDict


class GenerateResponseDTO(BaseModel):
    model_config = ConfigDict(populate_by_name=True)

    account_number: str = Field(..., description="16-digit account number — save this, it's your only key")
    access_token: str
    token_type: str = "bearer"
    expires_in: int


class LoginRequestDTO(BaseModel):
    model_config = ConfigDict(populate_by_name=True)

    account_number: str = Field(..., min_length=16, max_length=16, description="16-digit account number")
