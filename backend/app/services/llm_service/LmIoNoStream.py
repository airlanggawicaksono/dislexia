from typing import Any, Optional
from langchain_core.messages import HumanMessage, SystemMessage

from app.services.llm_service.base import LmFactories
from app.dto.feature.llm.base import (
    LLMRequestDTO,
    LLMResponseDTO,
    LLMGenerationConfigDTO,
    LLMUsageDTO,
)


def _build_messages(request: LLMRequestDTO) -> list:
    system = [SystemMessage(content=request.system_prompt)] if request.system_prompt else []
    return [*system, HumanMessage(content=request.prompt)]


def _apply_config(llm: Any, config: LLMGenerationConfigDTO) -> Any:
    return llm.bind(temperature=config.temperature, max_tokens=config.max_tokens, top_p=config.top_p)


def _extract_usage(response: Any) -> Optional[LLMUsageDTO]:
    meta = getattr(response, "usage_metadata", None)
    return None if not meta else LLMUsageDTO(
        prompt_tokens=meta.get("input_tokens", 0),
        completion_tokens=meta.get("output_tokens", 0),
        total_tokens=meta.get("total_tokens", 0),
    )


class LmIoNoStream:
    @staticmethod
    async def invoke(request: LLMRequestDTO) -> LLMResponseDTO:
        factory = LmFactories(provider=request.provider, model=request.model)
        llm = _apply_config(factory.get_llm(), request.generation_config)
        response = await llm.ainvoke(_build_messages(request))
        return LLMResponseDTO(
            content=response.content,
            provider=request.provider,
            model=factory.model,
            usage=_extract_usage(response),
        )
