from typing import Optional, Any
from app.config.settings import settings
from app.dto.feature.llm import LLMProvider

# sengaja sy buat stateless [wicak]


class LmFactories:
    _DEFAULT_MODELS: dict[LLMProvider, str] = {
        LLMProvider.OPENAI: "gpt-4.1-2025-04-14",
        LLMProvider.TOGETHER: "meta-llama/Llama-3-8b-chat-hf",
        LLMProvider.ANTHROPIC: "claude-haiku-4-5-20251001",
    }

    _BUILDERS: dict[LLMProvider, str] = {
        LLMProvider.OPENAI: "_build_openai",
        LLMProvider.TOGETHER: "_build_together",
        LLMProvider.ANTHROPIC: "_build_anthropic",
    }

    def __init__(self, provider: LLMProvider = LLMProvider.OPENAI, model: Optional[str] = None):
        self._provider = provider
        self._model = model

    @property
    def provider(self) -> LLMProvider:
        return self._provider

    @provider.setter
    def provider(self, value: LLMProvider | str) -> None:
        self._provider = LLMProvider(value)

    @property
    def model(self) -> str:
        return self._model or self._DEFAULT_MODELS[self._provider]

    @model.setter
    def model(self, value: str) -> None:
        self._model = value

    def _build_openai(self) -> Any:
        from langchain_openai import ChatOpenAI

        return ChatOpenAI(api_key=settings.OPENAI_API_KEY, model=self.model)

    def _build_together(self) -> Any:
        from langchain_together import ChatTogether

        return ChatTogether(api_key=settings.TOGETHER_API_KEY, model=self.model)

    def _build_anthropic(self) -> Any:
        from langchain_anthropic import ChatAnthropic

        return ChatAnthropic(api_key=settings.ANTHROPIC_API_KEY, model=self.model)

    def get_llm(self) -> Any:
        return getattr(self, self._BUILDERS[self._provider])()
