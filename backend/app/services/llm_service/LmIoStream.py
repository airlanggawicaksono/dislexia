from typing import Any, AsyncGenerator
from langchain_core.messages import HumanMessage, SystemMessage

from app.services.llm_service.base import LmFactories
from app.dto.feature.llm.base import (
    LLMRequestDTO,
    LLMChunkDTO,
    LLMGenerationConfigDTO,
)


def _build_messages(request: LLMRequestDTO) -> list:
    system = [SystemMessage(content=request.system_prompt)] if request.system_prompt else []
    return [*system, HumanMessage(content=request.prompt)]


def _apply_config(llm: Any, config: LLMGenerationConfigDTO) -> Any:
    return llm.bind(temperature=config.temperature, max_tokens=config.max_tokens, top_p=config.top_p)


class LmIoStream:
    @staticmethod
    async def stream(request: LLMRequestDTO) -> AsyncGenerator[LLMChunkDTO, None]:
        factory = LmFactories(provider=request.provider, model=request.model)
        llm = _apply_config(factory.get_llm(), request.generation_config)
        async for chunk in llm.astream(_build_messages(request)):
            yield LLMChunkDTO(
                content=chunk.content,
                provider=request.provider,
                model=factory.model,
            )
