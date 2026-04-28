from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession
from app.config.database import get_db
from app.dto.feature.base import (
    FeatureRequestDTO,
    FeatureResponseDTO,
    HistoryListResponseDTO,
)

router = APIRouter(prefix="/api/v1/{access_hash}/summarize", tags=["Summarize"])


@router.post("/process", response_model=FeatureResponseDTO)
async def summarize_text(
    request: FeatureRequestDTO, access_hash: str, db: AsyncSession = Depends(get_db)
):
    """
    Summarize text input
    TODO: Nganu
    """
    return FeatureResponseDTO(
        result=f"[SUMMARIZE STUB] Summarized: {request.text[:50]}...",
        feature="summarize",
        history_id=None,
    )


@router.get("/history", response_model=HistoryListResponseDTO)
async def get_summarize_history(access_hash: str, db: AsyncSession = Depends(get_db)):
    """
    Get summarize history for user
    Route format: domain/{md5_hash}/summarize/history
    TODO: Nganu
    """
    return HistoryListResponseDTO(items=[], total=0, feature="summarize")
