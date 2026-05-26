from typing import Any, AsyncGenerator
from langchain_core.messages import HumanMessage, SystemMessage, AIMessage

from app.exceptions import LLMEmptyResponseError
from app.services.llm_service.base import LmFactories
from app.dto.feature.llm import LLMRequestDTO, LLMChunkDTO, LLMGenerationConfigDTO

_ROLE_MAP = {"user": HumanMessage, "assistant": AIMessage, "system": SystemMessage}


def _build_messages(request: LLMRequestDTO) -> list:
    system = [SystemMessage(content=request.system_prompt)] if request.system_prompt else []
    history = [_ROLE_MAP[m.role](content=m.content) for m in request.history]
    return [*system, *history, HumanMessage(content=request.prompt)]


def _apply_config(llm: Any, config: LLMGenerationConfigDTO) -> Any:
    return llm.bind(temperature=config.temperature, max_tokens=config.max_tokens, top_p=config.top_p)


class LmIoStream:
    @staticmethod
    async def stream(request: LLMRequestDTO) -> AsyncGenerator[LLMChunkDTO, None]:
        factory = LmFactories(provider=request.provider, model=request.model)
        llm = _apply_config(factory.get_llm(), request.generation_config)
        total = 0
        async for chunk in llm.astream(_build_messages(request)):
            piece = chunk.content if isinstance(chunk.content, str) else ""
            total += len(piece)
            yield LLMChunkDTO(content=piece, provider=request.provider, model=factory.model)
        if total == 0:
            raise LLMEmptyResponseError(
                f"Provider '{request.provider.value}' streamed zero content. "
                f"Likely cause: invalid model id '{factory.model}', content filter, or quota."
            )
