from typing import Any, Optional
from langchain_core.messages import HumanMessage, SystemMessage, AIMessage

from app.exceptions import LLMEmptyResponseError
from app.services.llm_service.base import LmFactories
from app.dto.feature.llm import LLMRequestDTO, LLMResponseDTO, LLMGenerationConfigDTO, LLMUsageDTO

_ROLE_MAP = {"user": HumanMessage, "assistant": AIMessage, "system": SystemMessage}


def _build_messages(request: LLMRequestDTO) -> list:
    system = [SystemMessage(content=request.system_prompt)] if request.system_prompt else []
    history = [_ROLE_MAP[m.role](content=m.content) for m in request.history]
    return [*system, *history, HumanMessage(content=request.prompt)]


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
        content = response.content if isinstance(response.content, str) else ""
        if not content.strip():
            raise LLMEmptyResponseError(
                f"Provider '{request.provider.value}' returned empty content. "
                f"Likely cause: invalid model id '{factory.model}', content filter, or quota."
            )
        return LLMResponseDTO(
            content=content,
            provider=request.provider,
            model=factory.model,
            usage=_extract_usage(response),
        )
