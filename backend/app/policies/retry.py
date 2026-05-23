from tenacity import AsyncRetrying, stop_after_attempt, wait_exponential, RetryError
from app.policies.exceptions import LLMUnavailableError


class LLMRetryPolicy:
    @staticmethod
    async def execute(coro_func, *args, **kwargs):
        try:
            async for attempt in AsyncRetrying(
                stop=stop_after_attempt(3),
                wait=wait_exponential(multiplier=1, min=1, max=8),
                reraise=True,
            ):
                with attempt:
                    return await coro_func(*args, **kwargs)
        except RetryError:
            raise LLMUnavailableError("LLM provider unavailable after 3 attempts")
