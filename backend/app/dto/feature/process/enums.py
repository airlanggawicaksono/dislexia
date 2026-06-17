from enum import Enum


class SummaryLevel(str, Enum):
    SHORT = "short"
    MODERATE = "moderate"
    DETAILED = "detailed"
