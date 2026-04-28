from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession
from app.config.database import get_db
from app.dto.feature.base import (
    FeatureRequestDTO,
    FeatureResponseDTO,
    HistoryListResponseDTO,
)

router = APIRouter(
    prefix="/api/v1/{access_hash}/professionalize", tags=["Professionalize"]
)


@router.post("/process", response_model=FeatureResponseDTO)
async def professionalize_text(
    request: FeatureRequestDTO, access_hash: str, db: AsyncSession = Depends(get_db)
):
    """
    Professionalize text input
    TODO: Nganu
    """
    return FeatureResponseDTO(
        result=f"[PROFESSIONALIZE STUB] Professionalized: {request.text[:50]}...",
        feature="professionalize",
        history_id=None,
    )


@router.get("/history", response_model=HistoryListResponseDTO)
async def get_professionalize_history(
    access_hash: str, db: AsyncSession = Depends(get_db)
):
    """
    Get professionalize history for user
    Route format: domain/{md5_hash}/professionalize/history
    """
    return HistoryListResponseDTO(items=[], total=0, feature="professionalize")
