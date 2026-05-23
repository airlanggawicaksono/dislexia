from fastapi import APIRouter, Depends
from fastapi.responses import StreamingResponse
from sqlalchemy.ext.asyncio import AsyncSession

from app.config.database import get_db
from app.dependencies import get_current_user
from app.services.feature_service import FeatureService
from app.dto.feature.chat.enums import FeatureType
from app.dto.feature.chat.base import FeatureHistoryListDTO
from app.dto.feature.HistoryMan.base import FeatureRequestDTO, FeatureResponseDTO
from app.dto.auth.userdata import UserResponseDTO

router = APIRouter(prefix="/api/v1/me/professionalize", tags=["Professionalize"])

_PROMPT = (
    "You are a professional writing assistant. "
    "Rewrite the provided text in a formal, professional tone while preserving the original meaning."
)


@router.post("/process", response_model=FeatureResponseDTO)
async def process(
    request: FeatureRequestDTO,
    db: AsyncSession = Depends(get_db),
    user: UserResponseDTO = Depends(get_current_user),
):
    return await FeatureService.process(FeatureType.PROFESSIONALIZE, _PROMPT, request.text, user.user_id, db, request.session_id)


@router.post("/process-stream")
async def process_stream(
    request: FeatureRequestDTO,
    db: AsyncSession = Depends(get_db),
    user: UserResponseDTO = Depends(get_current_user),
):
    async def sse():
        async for chunk in FeatureService.process_stream(FeatureType.PROFESSIONALIZE, _PROMPT, request.text, user.user_id, db, request.session_id):
            yield f"data: {chunk.model_dump_json()}\n\n"
    return StreamingResponse(sse(), media_type="text/event-stream")


@router.get("/history", response_model=FeatureHistoryListDTO)
async def history(
    db: AsyncSession = Depends(get_db),
    user: UserResponseDTO = Depends(get_current_user),
):
    return await FeatureService.get_history(FeatureType.PROFESSIONALIZE, user.user_id, db)
