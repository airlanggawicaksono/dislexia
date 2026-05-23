class LLMUnavailableError(Exception):
    """All retries exhausted — provider unreachable."""


class RetryExhaustedError(Exception):
    """Generic retry budget used up."""
