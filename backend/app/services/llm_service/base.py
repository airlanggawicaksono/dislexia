from typing import Optional, Any

from app.config.settings import settings
from app.dto.feature.llm import LLMProvider


_FALLBACK_MODELS: dict[LLMProvider, str] = {
    LLMProvider.OPENAI: "gpt-4o-mini",
    LLMProvider.TOGETHER: "meta-llama/Llama-3.3-70B-Instruct-Turbo",
    LLMProvider.ANTHROPIC: "claude-haiku-4-5-20251001",
}


def _env_model_for(provider: LLMProvider) -> Optional[str]:
    return {
        LLMProvider.OPENAI: settings.OPENAI_MODEL,
        LLMProvider.TOGETHER: settings.TOGETHER_MODEL,
        LLMProvider.ANTHROPIC: settings.ANTHROPIC_MODEL,
    }[provider]


class LmFactories:
    _BUILDERS: dict[LLMProvider, str] = {
        LLMProvider.OPENAI: "_build_openai",
        LLMProvider.TOGETHER: "_build_together",
        LLMProvider.ANTHROPIC: "_build_anthropic",
    }

    def __init__(self, provider: Optional[LLMProvider] = None, model: Optional[str] = None):
        self._provider = provider or LLMProvider(settings.LLM_PROVIDER)
        self._model = model

    @property
    def provider(self) -> LLMProvider:
        return self._provider

    @provider.setter
    def provider(self, value: LLMProvider | str) -> None:
        self._provider = LLMProvider(value)

    @property
    def model(self) -> str:
        return self._model or _env_model_for(self._provider) or _FALLBACK_MODELS[self._provider]

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
