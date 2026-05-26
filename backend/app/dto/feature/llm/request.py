from typing import Optional
from pydantic import BaseModel, Field, ConfigDict

from app.config.settings import settings
from app.dto.feature.llm.enums import LLMProvider


class LLMGenerationConfigDTO(BaseModel):
    model_config = ConfigDict(populate_by_name=True)

    temperature: float = Field(0.7, ge=0.0, le=2.0)
    max_tokens: int = Field(1024, gt=0, le=32768)
    top_p: float = Field(1.0, ge=0.0, le=1.0)


class LLMHistoryMessageDTO(BaseModel):
    model_config = ConfigDict(populate_by_name=True)

    role: str
    content: str


class LLMRequestDTO(BaseModel):
    model_config = ConfigDict(populate_by_name=True)

    provider: LLMProvider = Field(default_factory=lambda: LLMProvider(settings.LLM_PROVIDER))
    model: Optional[str] = Field(None, description="Override default model for provider")
    prompt: str = Field(..., description="Current user message")
    system_prompt: Optional[str] = Field(None)
    history: list[LLMHistoryMessageDTO] = Field(default_factory=list, description="Prior conversation turns")
    generation_config: LLMGenerationConfigDTO = Field(default_factory=LLMGenerationConfigDTO)
