from enum import Enum
from typing import Optional
from pydantic import BaseModel, Field, ConfigDict


class LLMProvider(str, Enum):
    OPENAI = "openai"
    TOGETHER = "together"
    ANTHROPIC = "anthropic"


class LLMGenerationConfigDTO(BaseModel):
    model_config = ConfigDict(populate_by_name=True)

    temperature: float = Field(0.7, ge=0.0, le=2.0)
    max_tokens: int = Field(1024, gt=0, le=32768)
    top_p: float = Field(1.0, ge=0.0, le=1.0)


class LLMUsageDTO(BaseModel):
    model_config = ConfigDict(populate_by_name=True)

    prompt_tokens: int
    completion_tokens: int
    total_tokens: int


class LLMRequestDTO(BaseModel):
    model_config = ConfigDict(populate_by_name=True)

    provider: LLMProvider = Field(LLMProvider.OPENAI)
    model: Optional[str] = Field(None, description="Override default model for provider")
    prompt: str = Field(..., description="User prompt")
    system_prompt: Optional[str] = Field(None)
    generation_config: LLMGenerationConfigDTO = Field(default_factory=LLMGenerationConfigDTO)


class LLMResponseDTO(BaseModel):
    model_config = ConfigDict(populate_by_name=True)

    content: str
    provider: LLMProvider
    model: str
    usage: Optional[LLMUsageDTO] = None


class LLMChunkDTO(BaseModel):
    model_config = ConfigDict(populate_by_name=True)

    content: str
    provider: LLMProvider
    model: str
    is_final: bool = False
