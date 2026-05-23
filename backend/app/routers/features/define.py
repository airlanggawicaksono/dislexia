from fastapi import APIRouter, Depends
from sqlalchemy.ext.asyncio import AsyncSession

from app.config.database import get_db
from app.dependencies import get_current_user
from app.services.feature_service import FeatureService
from app.dto.feature.chat.enums import FeatureType
from app.dto.feature.chat.base import FeatureHistoryListDTO
from app.dto.feature.HistoryMan.base import FeatureRequestDTO, FeatureResponseDTO
from app.dto.auth.userdata import UserResponseDTO

router = APIRouter(prefix="/api/v1/me/define", tags=["Define"])

_PROMPT = (
    "You are a dictionary assistant for people with dyslexia. "
    "Provide a clear, simple definition of the given word or concept using short sentences and plain vocabulary."
)


@router.post("/process", response_model=FeatureResponseDTO)
async def process(
    request: FeatureRequestDTO,
    db: AsyncSession = Depends(get_db),
    user: UserResponseDTO = Depends(get_current_user),
):
    return await FeatureService.process(FeatureType.DEFINE, _PROMPT, request.text, user.user_id, db)


@router.get("/history", response_model=FeatureHistoryListDTO)
async def history(
    db: AsyncSession = Depends(get_db),
    user: UserResponseDTO = Depends(get_current_user),
):
    return await FeatureService.get_history(FeatureType.DEFINE, user.user_id, db)
