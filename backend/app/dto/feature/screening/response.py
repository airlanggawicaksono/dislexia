from pydantic import BaseModel, ConfigDict
from typing import Optional
from uuid import UUID


class ScreeningResponseDTO(BaseModel):
    model_config = ConfigDict(populate_by_name=True)

    result: str
    session_id: UUID
    history_id: Optional[UUID] = None
    is_complete: bool = False
