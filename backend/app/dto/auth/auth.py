from pydantic import BaseModel, Field, ConfigDict

from app.policies import ACCOUNT_NUMBER_LENGTH, ACCOUNT_NUMBER_PATTERN


class GenerateResponseDTO(BaseModel):
    model_config = ConfigDict(populate_by_name=True)

    account_number: str = Field(..., description="6-digit account number — save this, it's your only key")
    display_name: str = Field(..., description="Auto-generated adjective-animal nickname (e.g. 'amusing-bee')")
    access_token: str
    token_type: str = "bearer"
    expires_in: int


class LoginRequestDTO(BaseModel):
    model_config = ConfigDict(populate_by_name=True, str_strip_whitespace=True)

    account_number: str = Field(
        ...,
        min_length=ACCOUNT_NUMBER_LENGTH,
        max_length=ACCOUNT_NUMBER_LENGTH,
        pattern=ACCOUNT_NUMBER_PATTERN,
        description="6-digit account number (digits only)",
    )
