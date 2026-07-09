from fastapi import APIRouter, Depends, status
from fastapi.responses import StreamingResponse
from sqlalchemy.ext.asyncio import AsyncSession

from app.config.database import get_db
from app.dependencies import get_current_user
from app.services.feature_service import FeatureService
from app.services.prompts import DYSLEXIA_OUTPUT_RULES
from app.dto.feature.chat.enums import FeatureType
from app.dto.feature.chat.base import FeatureHistoryListDTO
from app.dto.feature.process import SummarizeRequestDTO, FeatureResponseDTO, SummaryLevel
from app.dto.feature.llm import LLMGenerationConfigDTO
from app.dto.auth.userdata import UserResponseDTO
from app.openapi import LLM_RESPONSES, SSE_RESPONSE
from app.utils.lenient_json_route import LenientJSONRoute

TAG = {
    "name": "Summarize",
    "description": "Summarize long text into clear, accessible prose for dyslexic readers.",
}

router = APIRouter(prefix="/api/v1/me/summarize", tags=[TAG["name"]], route_class=LenientJSONRoute)


# pct of source-text characters preserved in summary, per level.
_LEVEL_PCT: dict[SummaryLevel, float] = {
    SummaryLevel.PCT_10: 0.10,
    SummaryLevel.PCT_30: 0.30,
    SummaryLevel.PCT_50: 0.50,
    SummaryLevel.PCT_70: 0.70,
    SummaryLevel.PCT_90: 0.90,
}

# Which importance layers to include, per level.
_LEVEL_LAYERS: dict[SummaryLevel, str] = {
    SummaryLevel.PCT_10: "ONLY the CORE layer",
    SummaryLevel.PCT_30: "the CORE layer AND the DEPENDENCIES layer",
    SummaryLevel.PCT_50: "the CORE layer, the DEPENDENCIES layer, AND the most essential parts of the DETAILS layer",
    SummaryLevel.PCT_70: "the CORE layer, the DEPENDENCIES layer, AND most of the DETAILS layer",
    SummaryLevel.PCT_90: "ALL layers (CORE, DEPENDENCIES, DETAILS) in tightened prose",
}

# Floors/ceilings to keep tiny inputs usable and giant inputs sane.
_MIN_TARGET_CHARS = 240  # floor so short inputs still get a usable summary
_CHARS_PER_TOKEN = 4  # rough english heuristic
# Token budget is HEADROOM, not the length dial. It must be generous so the
# model finishes cleanly on a full sentence — length is steered by the prompt
# target, never by truncating the output mid-thought (that was the "too short"
# bug). ~3x the target's token estimate, with a comfortable floor.
_MAX_TOKENS_HEADROOM = 3.0
_MIN_MAX_TOKENS = 512
_MAX_TOKENS_HARD_CAP = 4096


def _normalize_chars(text: str) -> int:
    """Count chars after collapsing runs of whitespace into single spaces."""
    return len(" ".join(text.split()))


def _build_prompt_and_config(
    level: SummaryLevel, text: str
) -> tuple[str, LLMGenerationConfigDTO, dict]:
    src_chars = _normalize_chars(text)
    pct = _LEVEL_PCT[level]
    target_chars = max(_MIN_TARGET_CHARS, int(src_chars * pct))
    max_tokens = min(
        _MAX_TOKENS_HARD_CAP,
        max(_MIN_MAX_TOKENS, int(target_chars / _CHARS_PER_TOKEN * _MAX_TOKENS_HEADROOM)),
    )
    layers = _LEVEL_LAYERS[level]
    metadata = {
        "level": level.value,
        "pct": pct,
        "src_chars": src_chars,
        "target_chars": target_chars,
        "max_tokens": max_tokens,
    }

    prompt = (
        "You are a reading assistant for people with dyslexia. Summarize the provided "
        "text using strict importance ordering:\n"
        "1. CORE — the single most critical idea. Always the first sentence.\n"
        "2. DEPENDENCIES — the facts, claims, or context the CORE idea rests on.\n"
        "3. DETAILS — supporting examples, numbers, and nuance.\n\n"
        f"For THIS summary include {layers}.\n\n"
        f"Length (aim for the target — do not stop far short of it):\n"
        f"- Original text is {src_chars} characters (whitespace-normalized).\n"
        f"- Write approximately {target_chars} characters (roughly {max(1, target_chars // 90)} short sentences).\n"
        f"- Fill out the target by developing the included layers fully; do not pad with filler.\n"
        f"- Keep it shorter than the original ({src_chars} chars), but no shorter than needed to cover the layers above.\n"
        "- End on a complete sentence. Never trail off mid-word or mid-clause.\n\n"
        "Style:\n"
        "- Use simple, accessible language.\n"
        "- No bullet points, numbered lists, or headings — flowing sentences and short paragraphs only.\n\n"
        f"{DYSLEXIA_OUTPUT_RULES}"
    )
    return prompt, LLMGenerationConfigDTO(max_tokens=max_tokens), metadata


@router.post(
    "/process",
    response_model=FeatureResponseDTO,
    status_code=status.HTTP_200_OK,
    summary="Summarize text",
    responses=LLM_RESPONSES,
)
async def process(
    request: SummarizeRequestDTO,
    db: AsyncSession = Depends(get_db),
    user: UserResponseDTO = Depends(get_current_user),
):
    """
    Summarize the provided text into accessible prose.

    Use `level` to control how much of the source is preserved (by character percentage):
    - `10pct` — core idea only
    - `30pct` — core + supporting facts
    - `50pct` — core + facts + key details (default)
    - `70pct` — most detail retained
    - `90pct` — near-verbatim in tightened prose

    Content is always ordered by importance so shorter tiers remain coherent.

    Pass `session_id` to continue a prior conversation; omit to start fresh.
    """
    prompt, config, metadata = _build_prompt_and_config(request.level, request.text)
    return await FeatureService.process(
        FeatureType.SUMMARIZE, prompt, request.text, user.user_id, db, request.session_id, config, metadata
    )


@router.post(
    "/process-stream",
    summary="Summarize text (SSE stream)",
    responses={**SSE_RESPONSE, **LLM_RESPONSES},
)
async def process_stream(
    request: SummarizeRequestDTO,
    db: AsyncSession = Depends(get_db),
    user: UserResponseDTO = Depends(get_current_user),
):
    """
    Streaming variant of `/process`. Returns Server-Sent Events.

    Each event payload is a JSON-encoded `LLMChunkDTO`. The full response is
    persisted to history after the stream completes.
    """
    prompt, config, metadata = _build_prompt_and_config(request.level, request.text)

    async def sse():
        async for chunk in FeatureService.process_stream(
            FeatureType.SUMMARIZE, prompt, request.text, user.user_id, db, request.session_id, config, metadata
        ):
            yield f"data: {chunk.model_dump_json()}\n\n"

    return StreamingResponse(sse(), media_type="text/event-stream")


@router.get(
    "/history",
    response_model=FeatureHistoryListDTO,
    status_code=status.HTTP_200_OK,
    summary="List summarize history",
    responses=LLM_RESPONSES,
)
async def history(
    db: AsyncSession = Depends(get_db),
    user: UserResponseDTO = Depends(get_current_user),
):
    """Return all summarize history items for the current user, newest first."""
    return await FeatureService.get_history(FeatureType.SUMMARIZE, user.user_id, db)
