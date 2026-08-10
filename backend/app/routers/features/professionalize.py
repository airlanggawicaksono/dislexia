from fastapi import APIRouter, Depends, status
from fastapi.responses import StreamingResponse
from sqlalchemy.ext.asyncio import AsyncSession

from app.config.database import get_db
from app.dependencies import get_current_user
from app.services.feature_service import FeatureService
from app.services.prompts import DYSLEXIA_OUTPUT_RULES
from app.dto.feature.chat.enums import FeatureType
from app.dto.feature.chat.base import FeatureHistoryListDTO
from app.dto.feature.process import ProfessionalizeRequestDTO
from app.dto.auth.userdata import UserResponseDTO
from app.openapi import LLM_RESPONSES, SSE_RESPONSE
from app.utils.lenient_json_route import LenientJSONRoute

TAG = {
    "name": "Professionalize",
    "description": (
        "Rewrite casual text in a formal, professional tone. "
        "Supports two modes: plain text (default) and email "
        "(provide recipient_name + sender_name to activate)."
    ),
}

router = APIRouter(prefix="/api/v1/me/professionalize", tags=[TAG["name"]], route_class=LenientJSONRoute)

_PLAIN_PROMPT = (
    "You are a professional writing assistant. "
    "Rewrite the provided text in a formal, professional tone while preserving the original meaning. "
    "Do not use em-dashes anywhere in your output, in any language. "
    "Use periods, commas, or semicolons instead.\n\n"
    f"{DYSLEXIA_OUTPUT_RULES}"
)

_EMAIL_PROMPT_TEMPLATE = (
    "You are a professional email writing assistant. "
    "Rewrite the provided text as a formal, professional email from {sender_name} to {recipient_name}. "
    "Include an appropriate greeting (e.g. 'Dear {recipient_name},') and a professional closing "
    "(e.g. 'Best regards, {sender_name}'). "
    "Preserve the original meaning. "
    "Do not use em-dashes anywhere in your output, in any language. "
    "Use periods, commas, or semicolons instead.\n\n"
    f"{DYSLEXIA_OUTPUT_RULES}"
)


def _build_prompt(request: ProfessionalizeRequestDTO) -> str:
    if request.is_email_mode:
        return _EMAIL_PROMPT_TEMPLATE.format(
            sender_name=request.sender_name,
            recipient_name=request.recipient_name,
        )
    return _PLAIN_PROMPT


@router.post(
    "/process-stream",
    summary="Professionalize text (SSE stream)",
    responses={**SSE_RESPONSE, **LLM_RESPONSES},
)
async def process_stream(
    request: ProfessionalizeRequestDTO,
    db: AsyncSession = Depends(get_db),
    user: UserResponseDTO = Depends(get_current_user),
):
    """
    Streaming variant of `/process`. Returns Server-Sent Events of `LLMChunkDTO`.
    Full response is persisted to history after the stream completes.
    """
    prompt = _build_prompt(request)

    async def sse():
        async for chunk in FeatureService.process_stream(
            FeatureType.PROFESSIONALIZE, prompt, request.text, user.user_id, db, request.session_id
        ):
            yield f"data: {chunk.model_dump_json()}\n\n"

    return StreamingResponse(sse(), media_type="text/event-stream")


@router.get(
    "/history",
    response_model=FeatureHistoryListDTO,
    status_code=status.HTTP_200_OK,
    summary="List professionalize history",
    responses=LLM_RESPONSES,
)
async def history(
    db: AsyncSession = Depends(get_db),
    user: UserResponseDTO = Depends(get_current_user),
):
    """Return all professionalize history items for the current user, newest first."""
    return await FeatureService.get_history(FeatureType.PROFESSIONALIZE, user.user_id, db)
