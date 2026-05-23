from uuid import UUID
from sqlalchemy.ext.asyncio import AsyncSession

from app.services.chat_history_service import ChatHistoryService
from app.services.llm_service import LmIoNoStream
from app.policies.retry import LLMRetryPolicy
from app.dto.feature.chat.enums import FeatureType, ChatRoleType
from app.dto.feature.chat.base import FeatureHistoryListDTO
from app.dto.feature.llm.base import LLMRequestDTO
from app.dto.feature.HistoryMan.base import FeatureResponseDTO


class FeatureService:
    @staticmethod
    async def process(
        feature: FeatureType,
        system_prompt: str,
        text: str,
        user_id: UUID,
        db: AsyncSession,
    ) -> FeatureResponseDTO:
        session = await ChatHistoryService.create_session(user_id, feature, db)
        await ChatHistoryService.append_message(session.session_id, ChatRoleType.USER, text, db)

        llm_req = LLMRequestDTO(prompt=text, system_prompt=system_prompt)
        llm_res = await LLMRetryPolicy.execute(LmIoNoStream.invoke, llm_req)

        await ChatHistoryService.append_message(session.session_id, ChatRoleType.ASSISTANT, llm_res.content, db)
        item = await ChatHistoryService.save_feature_history(
            session_id=session.session_id,
            user_id=user_id,
            feature=feature,
            input_text=text,
            output_text=llm_res.content,
            db=db,
        )
        return FeatureResponseDTO(result=llm_res.content, feature=feature.value, history_id=item.id)

    @staticmethod
    async def get_history(
        feature: FeatureType,
        user_id: UUID,
        db: AsyncSession,
    ) -> FeatureHistoryListDTO:
        return await ChatHistoryService.get_feature_history(user_id, feature, db)
