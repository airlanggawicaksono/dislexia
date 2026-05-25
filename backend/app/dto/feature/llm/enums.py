from enum import Enum


class LLMProvider(str, Enum):
    OPENAI = "openai"
    TOGETHER = "together"
    ANTHROPIC = "anthropic"
