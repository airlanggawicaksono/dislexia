"""ARHQ post-processing service.

Stateless (all static methods, like the other services in this package). On
completion of a screening session a SECOND LLM call discretizes the free-form
conversation into a quantifiable ARHQ result which is persisted to the
`feature_history.metadata` JSONB column and returned to the caller.

Extractor errors never raise to the router — they are converted into
failure-shape metadata so the endpoints still return 200 and the status is
readable later.

`run` is deliberately keyed only by `session_id` (it re-reads the conversation
from Postgres), so the same method backs both the automatic run inside `/reply`
AND the standalone `POST /screen/{session_id}/postprocess` endpoint. That makes
it a safe, idempotent **id-triggered reprocess**: retry a `failed` run, re-score
after a rubric change, or backfill sessions that predate the callback — all by
POSTing the endpoint again. See the README "id-triggered reprocess" section.
"""

from __future__ import annotations

from datetime import datetime, timezone
from uuid import UUID

from sqlalchemy.ext.asyncio import AsyncSession

from app.exceptions import ConflictError
from app.policies import LLMRetryPolicy
from app.services.chat_history_service import ChatHistoryService
from app.services.llm_service import LmIoNoStream
from app.dto.feature.chat.base import ChatSessionDTO
from app.dto.feature.chat.enums import ChatRoleType
from app.dto.feature.llm import LLMRequestDTO, LLMHistoryMessageDTO
from app.dto.feature.screening.response import PostProcessRunDTO, PostProcessStatusDTO
from app.services.screening.prompts import QUESTIONS, build_extraction_prompt
from app.services.screening.postprocess.parser import PostProcessError, parse_llm_response
from app.services.screening.postprocess.result import (
    build_failure_metadata,
    build_success_metadata,
    resolve_status,
)


def _utc_now() -> datetime:
    return datetime.now(timezone.utc)


def _answered_question_count(session: ChatSessionDTO) -> int:
    return sum(1 for m in session.history if m.role == ChatRoleType.ASSISTANT)


class PostProcessService:
    @staticmethod
    async def run(
        session_id: UUID, user_id: UUID, db: AsyncSession, *, force: bool = False,
    ) -> PostProcessRunDTO:
        """Run the ARHQ post-process callback, persist metadata, return outcome.

        - `force=False` and session incomplete → raises ConflictError (409).
        - Extractor / parse failures become failure-shape metadata; this method
          only raises for ownership (403) / not-found (404) / conflict (409).
        - Idempotent: overwrites the metadata on the latest feature_history row.
        """
        session = await ChatHistoryService.get_session(session_id, user_id, db)
        if not force and _answered_question_count(session) < len(QUESTIONS):
            raise ConflictError(
                "Screening session is not yet complete. Pass `force=true` to override."
            )

        last_item = await ChatHistoryService.get_last_feature_history_for_session(
            session_id, user_id, db
        )

        metadata = await PostProcessService._extract_and_score(session)
        await ChatHistoryService.set_feature_history_metadata(last_item.id, metadata, db)

        return PostProcessRunDTO(
            session_id=session_id,
            history_id=last_item.id,
            status=resolve_status(metadata),
            metadata=metadata,
        )

    @staticmethod
    async def get_status(
        session_id: UUID, user_id: UUID, db: AsyncSession,
    ) -> PostProcessStatusDTO:
        """Cheap DB-only status snapshot. No LLM call, no writes.

        Raises ForbiddenError (403) if the session belongs to another user,
        NotFoundError (404) if the session or its history rows are missing.
        """
        last_item = await ChatHistoryService.get_last_feature_history_for_session(
            session_id, user_id, db
        )
        return PostProcessStatusDTO(
            session_id=session_id,
            history_id=last_item.id,
            status=resolve_status(last_item.metadata),
            metadata=last_item.metadata,
        )

    @staticmethod
    async def _extract_and_score(session: ChatSessionDTO) -> dict:
        """Run the extraction LLM call + parse into success/failure metadata.

        Never raises — transport, parse, and schema errors all map to
        failure-shape metadata with a machine-readable reason.
        """
        started_at = _utc_now()
        try:
            raw = await PostProcessService._extract(session)
        except Exception as exc:  # noqa: BLE001 — transport failure ends the run
            return build_failure_metadata(
                "llm_call_failed", str(exc)[:200],
                started_at=started_at, finished_at=_utc_now(),
            )

        try:
            scores, comments = parse_llm_response(raw)
        except PostProcessError as exc:
            return build_failure_metadata(
                exc.reason, exc.message,
                started_at=started_at, finished_at=_utc_now(),
            )

        return build_success_metadata(
            scores, comments, started_at=started_at, finished_at=_utc_now(),
        )

    @staticmethod
    async def _extract(session: ChatSessionDTO) -> str:
        """Send the extraction prompt + full session history to the LLM.

        Returns the raw string response (parsing is the parser's job).
        """
        history = [
            LLMHistoryMessageDTO(role=m.role.value, content=m.content)
            for m in session.history
            if m.role in (ChatRoleType.USER, ChatRoleType.ASSISTANT)
        ]
        llm_req = LLMRequestDTO(
            prompt="Score the ARHQ from the conversation above. Emit STRICT JSON.",
            system_prompt=build_extraction_prompt(),
            history=history,
        )
        llm_res = await LLMRetryPolicy.execute(LmIoNoStream.invoke, llm_req)
        return llm_res.content
