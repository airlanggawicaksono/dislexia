from uuid import UUID
from sqlalchemy.ext.asyncio import AsyncSession

from app.services.chat_history_service import ChatHistoryService
from app.services.feature_service import FeatureService
from app.services.llm_service import LmIoNoStream
from app.policies.retry import LLMRetryPolicy
from app.services.screening.prompts import PERSONA, STYLE_TEMPLATE, QUESTIONS, build_system_prompt
from app.dto.feature.chat.enums import FeatureType, ChatRoleType
from app.dto.feature.chat.base import ChatSessionDTO
from app.dto.feature.llm import LLMRequestDTO, LLMHistoryMessageDTO
from app.dto.feature.screening import ScreeningResponseDTO


def _next_question_index(session: ChatSessionDTO) -> int:
    return sum(1 for m in session.history if m.role == ChatRoleType.ASSISTANT)


def _to_llm_history(session: ChatSessionDTO) -> list[LLMHistoryMessageDTO]:
    return [LLMHistoryMessageDTO(role=m.role.value, content=m.content) for m in session.history]


class ScreeningService:
    @staticmethod
    async def start(user_id: UUID, db: AsyncSession) -> ScreeningResponseDTO:
        session = await ChatHistoryService.create_session(user_id, FeatureType.SCREEN, db)

        system_prompt = (
            f"{PERSONA}"
            f"{STYLE_TEMPLATE}"
            f"\nWarmly greet the user, briefly explain this is a reading history chat, "
            f"then ask this first question in your own natural words:\n{QUESTIONS[0]}"
        )
        llm_req = LLMRequestDTO(prompt="[begin]", system_prompt=system_prompt, history=[])
        llm_res = await LLMRetryPolicy.execute(LmIoNoStream.invoke, llm_req)

        await ChatHistoryService.append_message(session.session_id, user_id, ChatRoleType.ASSISTANT, llm_res.content, db)
        item = await ChatHistoryService.save_feature_history(
            session_id=session.session_id,
            user_id=user_id,
            feature=FeatureType.SCREEN,
            input_text="[screening started]",
            output_text=llm_res.content,
            db=db,
        )
        return ScreeningResponseDTO(
            result=llm_res.content,
            session_id=session.session_id,
            history_id=item.id,
            is_complete=False,
        )

    @staticmethod
    async def reply(text: str, session_id: UUID, user_id: UUID, db: AsyncSession) -> ScreeningResponseDTO:
        session = await ChatHistoryService.get_session(session_id, user_id, db)
        idx = _next_question_index(session)
        is_complete = idx >= len(QUESTIONS)

        feature_res = await FeatureService.process(
            FeatureType.SCREEN, build_system_prompt(idx), text, user_id, db, session_id
        )
        return ScreeningResponseDTO(
            result=feature_res.result,
            session_id=feature_res.session_id,
            history_id=feature_res.history_id,
            is_complete=is_complete,
        )
