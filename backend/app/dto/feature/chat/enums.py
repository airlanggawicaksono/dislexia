from enum import Enum


class FeatureType(str, Enum):
    SUMMARIZE = "summarize"
    PROFESSIONALIZE = "professionalize"
    DEFINE = "define"
    SCREEN = "screen"


class ChatRoleType(str, Enum):
    USER = "user"
    ASSISTANT = "assistant"
    SYSTEM = "system"
