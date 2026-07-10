import asyncio
import json
from uuid import UUID
from sqlalchemy.ext.asyncio import AsyncSession

from app.config.database import async_session_maker
from app.services.chat_history_service import ChatHistoryService
from app.services.feature_service import _to_llm_history
from app.services.llm_service import LmIoNoStream
from app.policies import LLMRetryPolicy
from app.services.screening.prompts import (
    PERSONA,
    STYLE_TEMPLATE,
    QUESTIONS,
    build_gate_prompt,
)
from app.services.screening.postprocess import PostProcessService
from app.dto.feature.chat.enums import FeatureType, ChatRoleType
from app.dto.feature.llm import LLMRequestDTO
from app.dto.feature.screening.response import (
    ScreeningResponseDTO,
    PostProcessRunDTO,
    PostProcessStatusDTO,
)

# After this many clarification attempts on one topic, accept the answer and
# move on — a confused user must never get stuck in an infinite re-ask loop.
_MAX_REASK = 3

# Strong refs to in-flight fire-and-forget post-process tasks so the event loop
# doesn't garbage-collect them mid-run.
_bg_tasks: set[asyncio.Task] = set()


def _schedule_postprocess(session_id: UUID, user_id: UUID) -> None:
    """Kick off ARHQ scoring in the background so /reply returns immediately.

    The client polls GET /me/screen/{session_id}/postprocess/status until it
    resolves to success/failed.
    """
    task = asyncio.create_task(_run_postprocess_bg(session_id, user_id))
    _bg_tasks.add(task)
    task.add_done_callback(_bg_tasks.discard)


async def _run_postprocess_bg(session_id: UUID, user_id: UUID) -> None:
    # ponytail: fire-and-forget with its own DB session (the request's session is
    # closed once /reply returns). No auto-retry if the worker crashes — recovery
    # is the idempotent POST /me/screen/{session_id}/postprocess, and the status
    # endpoint reports not_started/failed so the client can re-trigger it.
    async with async_session_maker() as bg_db:
        try:
            await PostProcessService.run(session_id, user_id, bg_db, force=True)
            await bg_db.commit()
        except Exception:
            await bg_db.rollback()


def _clean_json(raw: str) -> str:
    s = raw.strip()
    if s.startswith("```"):
        s = s.strip("`").lstrip()
        if s[:4].lower() == "json":
            s = s[4:]
    return s.strip()


def _parse_gate(raw: str) -> tuple[bool, str]:
    """Parse the gate's {"answered", "message"} JSON.

    On any parse failure we default to answered=true with the raw text as the
    message, so a malformed model response advances the flow instead of
    wedging the user on one topic forever.
    """
    try:
        data = json.loads(_clean_json(raw), strict=False)
        message = str(data.get("message", "")).strip()
        if not message:
            raise ValueError("empty message")
        return bool(data.get("answered", True)), message
    except Exception:
        return True, _clean_json(raw)


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
            answered=None,
            answered_count=0,
            total_topics=len(QUESTIONS),
        )

    @staticmethod
    async def reply(text: str, session_id: UUID, user_id: UUID, db: AsyncSession) -> ScreeningResponseDTO:
        session = await ChatHistoryService.get_session(session_id, user_id, db)

        # Topic progress is persisted on each row's metadata (the start row has
        # none → defaults to 0). We track ANSWERED topics, not message count, so
        # clarification re-asks don't advance the ARHQ sequence.
        answered_count, reask_count = 0, 0
        try:
            last = await ChatHistoryService.get_last_feature_history_for_session(
                session_id, user_id, db
            )
            meta = last.metadata or {}
            answered_count = int(meta.get("answered_count", 0))
            reask_count = int(meta.get("reask_count", 0))
        except Exception:
            pass

        current_q = QUESTIONS[answered_count] if answered_count < len(QUESTIONS) else None
        next_q = QUESTIONS[answered_count + 1] if answered_count + 1 < len(QUESTIONS) else None

        # The gate LLM judges whether the reply answers the CURRENT topic AND
        # writes the next assistant message (ack + next question, or a re-ask).
        llm_req = LLMRequestDTO(
            prompt=text,
            system_prompt=build_gate_prompt(current_q, next_q),
            history=_to_llm_history(session),
        )
        llm_res = await LLMRetryPolicy.execute(LmIoNoStream.invoke, llm_req)
        answered, message = _parse_gate(llm_res.content)

        # Loop guard: force-advance after too many clarifications on one topic.
        if not answered and reask_count + 1 >= _MAX_REASK:
            answered = True

        if answered:
            new_count, new_reask = answered_count + 1, 0
        else:
            new_count, new_reask = answered_count, reask_count + 1

        is_complete = new_count >= len(QUESTIONS)

        # Persist the exchange + progress.
        await ChatHistoryService.append_message(session_id, user_id, ChatRoleType.USER, text, db)
        await ChatHistoryService.append_message(session_id, user_id, ChatRoleType.ASSISTANT, message, db)
        item = await ChatHistoryService.save_feature_history(
            session_id=session_id,
            user_id=user_id,
            feature=FeatureType.SCREEN,
            input_text=text,
            output_text=message,
            db=db,
            metadata={"answered_count": new_count, "reask_count": new_reask},
        )

        # On completion the ARHQ scoring (a second LLM call) runs in the
        # background so this final reply returns without blocking on it. The
        # client polls the post-process status endpoint for the outcome, so we
        # return ahrq_result=None here rather than awaiting it.
        if is_complete:
            _schedule_postprocess(session_id, user_id)

        return ScreeningResponseDTO(
            result=message,
            session_id=session_id,
            history_id=item.id,
            is_complete=is_complete,
            answered=answered,
            answered_count=new_count,
            total_topics=len(QUESTIONS),
            ahrq_result=None,
        )

    @staticmethod
    async def postprocess(
        session_id: UUID, user_id: UUID, db: AsyncSession, force: bool = False,
    ) -> PostProcessRunDTO:
        return await PostProcessService.run(session_id, user_id, db, force=force)

    @staticmethod
    async def postprocess_status(
        session_id: UUID, user_id: UUID, db: AsyncSession,
    ) -> PostProcessStatusDTO:
        return await PostProcessService.get_status(session_id, user_id, db)
