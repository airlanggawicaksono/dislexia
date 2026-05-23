from fastapi import APIRouter, Depends
from sqlalchemy.ext.asyncio import AsyncSession

from app.config.database import get_db
from app.dependencies import get_current_user
from app.services.feature_service import FeatureService
from app.dto.feature.chat.enums import FeatureType
from app.dto.feature.chat.base import FeatureHistoryListDTO
from app.dto.feature.HistoryMan.base import FeatureRequestDTO, FeatureResponseDTO
from app.dto.auth.userdata import UserResponseDTO

router = APIRouter(prefix="/api/v1/me/summarize", tags=["Summarize"])

_PROMPT = (
    "You are a reading assistant for people with dyslexia. "
    "Summarize the provided text into clear, concise bullet points using simple, accessible language."
)


@router.post("/process", response_model=FeatureResponseDTO)
async def process(
    request: FeatureRequestDTO,
    db: AsyncSession = Depends(get_db),
    user: UserResponseDTO = Depends(get_current_user),
):
    return await FeatureService.process(FeatureType.SUMMARIZE, _PROMPT, request.text, user.user_id, db)


@router.get("/history", response_model=FeatureHistoryListDTO)
async def history(
    db: AsyncSession = Depends(get_db),
    user: UserResponseDTO = Depends(get_current_user),
):
    return await FeatureService.get_history(FeatureType.SUMMARIZE, user.user_id, db)
