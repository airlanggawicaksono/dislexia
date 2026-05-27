from typing import Optional
from pydantic import BaseModel, ConfigDict

from app.dto.feature.llm.enums import LLMProvider


class LLMUsageDTO(BaseModel):
    model_config = ConfigDict(populate_by_name=True)

    prompt_tokens: int
    completion_tokens: int
    total_tokens: int


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
