import asyncio

from tenacity import AsyncRetrying, stop_after_attempt, wait_exponential, RetryError
from app.exceptions import LLMUnavailableError

_MAX_ATTEMPTS = 3


class LLMRetryPolicy:
    @staticmethod
    async def execute(coro_func, *args, **kwargs):
        try:
            async for attempt in AsyncRetrying(
                stop=stop_after_attempt(_MAX_ATTEMPTS),
                wait=wait_exponential(multiplier=1, min=1, max=8),
                reraise=True,
            ):
                with attempt:
                    return await coro_func(*args, **kwargs)
        except RetryError:
            raise LLMUnavailableError("LLM provider unavailable after 3 attempts")

    @staticmethod
    async def stream(stream_func, *args, **kwargs):
        """Retry a streaming LLM call, but ONLY before the first chunk is
        yielded. Once a token has reached the client, a mid-stream failure
        can't be retried — restarting would duplicate already-sent content —
        so it propagates. This covers the common transient case (rate-limit /
        connection-reset / provider-overloaded errors that fire at connect
        time, before any output) and gives the streaming path the same
        resilience the non-stream path already gets from `execute`.

        `stream_func` must be re-callable: it is invoked fresh on each attempt.
        """
        for attempt in range(_MAX_ATTEMPTS):
            started = False
            try:
                async for chunk in stream_func(*args, **kwargs):
                    started = True
                    yield chunk
                return
            except Exception:
                # Already streaming to the client, or out of attempts → surface it.
                if started or attempt == _MAX_ATTEMPTS - 1:
                    raise
                await asyncio.sleep(2 ** attempt)  # 1s, 2s backoff
