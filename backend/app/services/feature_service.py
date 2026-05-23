from typing import AsyncGenerator, Optional
from uuid import UUID
from sqlalchemy.ext.asyncio import AsyncSession

from app.services.chat_history_service import ChatHistoryService
from app.services.llm_service import LmIoNoStream, LmIoStream
from app.policies.retry import LLMRetryPolicy
from app.dto.feature.chat.enums import FeatureType, ChatRoleType
from app.dto.feature.chat.base import ChatSessionDTO, FeatureHistoryListDTO
from app.dto.feature.llm.base import LLMRequestDTO, LLMChunkDTO, LLMHistoryMessageDTO
from app.dto.feature.HistoryMan.base import FeatureResponseDTO


async def _resolve_session(
    session_id: Optional[UUID], user_id: UUID, feature: FeatureType, db: AsyncSession
) -> ChatSessionDTO:
    return (
        await ChatHistoryService.get_session(session_id, db)
        if session_id
        else await ChatHistoryService.create_session(user_id, feature, db)
    )


def _to_llm_history(session: ChatSessionDTO) -> list[LLMHistoryMessageDTO]:
    return [LLMHistoryMessageDTO(role=m.role.value, content=m.content) for m in session.history]


class FeatureService:
    @staticmethod
    async def process(
        feature: FeatureType,
        system_prompt: str,
        text: str,
        user_id: UUID,
        db: AsyncSession,
        session_id: Optional[UUID] = None,
    ) -> FeatureResponseDTO:
        session = await _resolve_session(session_id, user_id, feature, db)
        history = _to_llm_history(session)
        await ChatHistoryService.append_message(session.session_id, ChatRoleType.USER, text, db)

        llm_req = LLMRequestDTO(prompt=text, system_prompt=system_prompt, history=history)
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
        return FeatureResponseDTO(
            result=llm_res.content,
            feature=feature.value,
            session_id=session.session_id,
            history_id=item.id,
        )

    @staticmethod
    async def process_stream(
        feature: FeatureType,
        system_prompt: str,
        text: str,
        user_id: UUID,
        db: AsyncSession,
        session_id: Optional[UUID] = None,
    ) -> AsyncGenerator[LLMChunkDTO, None]:
        session = await _resolve_session(session_id, user_id, feature, db)
        history = _to_llm_history(session)
        await ChatHistoryService.append_message(session.session_id, ChatRoleType.USER, text, db)

        llm_req = LLMRequestDTO(prompt=text, system_prompt=system_prompt, history=history)
        collected = []
        async for chunk in LmIoStream.stream(llm_req):
            collected.append(chunk.content)
            yield chunk

        full_content = "".join(collected)
        await ChatHistoryService.append_message(session.session_id, ChatRoleType.ASSISTANT, full_content, db)
        await ChatHistoryService.save_feature_history(
            session_id=session.session_id,
            user_id=user_id,
            feature=feature,
            input_text=text,
            output_text=full_content,
            db=db,
        )

    @staticmethod
    async def get_history(
        feature: FeatureType,
        user_id: UUID,
        db: AsyncSession,
    ) -> FeatureHistoryListDTO:
        return await ChatHistoryService.get_feature_history(user_id, feature, db)
