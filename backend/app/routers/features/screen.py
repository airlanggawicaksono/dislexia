from uuid import UUID

from fastapi import APIRouter, Depends, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.config.database import get_db
from app.dependencies import get_current_user
from app.dto.auth.userdata import UserResponseDTO
from app.dto.feature.chat.base import FeatureHistoryListDTO
from app.dto.feature.chat.enums import FeatureType
from app.dto.feature.screening import (
    ScreeningReplyRequestDTO,
    ScreeningResponseDTO,
    PostProcessRunDTO,
    PostProcessStatusDTO,
)
from app.services.screening import ScreeningService
from app.services.feature_service import FeatureService
from app.openapi import LLM_RESPONSES
from app.utils.lenient_json_route import LenientJSONRoute

TAG = {
    "name": "Screening",
    "description": (
        "Multi-turn dyslexia screening based on the Adult Reading History Questionnaire (ARHQ). "
        "Server controls the 23-question sequence; the LLM rephrases each one warmly."
    ),
}

router = APIRouter(prefix="/api/v1/me/screen", tags=[TAG["name"]], route_class=LenientJSONRoute)


@router.post(
    "/start",
    response_model=ScreeningResponseDTO,
    status_code=status.HTTP_201_CREATED,
    summary="Begin a screening session",
    responses=LLM_RESPONSES,
)
async def start(
    db: AsyncSession = Depends(get_db),
    user: UserResponseDTO = Depends(get_current_user),
):
    """
    Open a new ARHQ screening session.

    No body required. The server creates a session and the LLM responds with a
    warm greeting plus the first question. Use the returned `session_id` for all
    subsequent `/reply` calls.

    ```
    POST /start            (no body)
    → { "result": "<greeting + first question>", "session_id": "<id>",
        "is_complete": false }
    ```
    """
    return await ScreeningService.start(user.user_id, db)


@router.post(
    "/reply",
    response_model=ScreeningResponseDTO,
    status_code=status.HTTP_200_OK,
    summary="Reply to current question",
    responses=LLM_RESPONSES,
)
async def reply(
    request: ScreeningReplyRequestDTO,
    db: AsyncSession = Depends(get_db),
    user: UserResponseDTO = Depends(get_current_user),
):
    """
    Submit the user's answer to the current screening question.

    ### Usage by case

    All calls use the SAME request — only `session_id` reuse changes the case.

    Request (always):
    ```
    POST /reply
    { "text": "<the user's message>", "session_id": "<id from /start>" }
    ```

    - **Answer a question** → `result` = next question, `is_complete: false`.
    - **Vague reply** → `result` = a clarifying re-ask of the SAME question,
      still `is_complete: false` (server holds the topic).
    - **Continue an unfinished session later** → send the SAME saved
      `session_id`; the server resumes on the correct topic. No special flag.
    - **Final answer** → `is_complete: true`, `result` = warm summary, and
      `ahrq_result` is populated (see below).

    Minimal response shape:
    ```
    { "result": "...", "session_id": "...", "history_id": "...",
      "is_complete": false, "ahrq_result": null }
    ```
    On completion `is_complete` is `true` and `ahrq_result` carries the scores.

    ### Answer gate (advancement control)

    Each reply runs a single LLM call that BOTH judges whether the answer
    satisfies the current topic AND writes the next assistant message
    (returned in `result`):

    - **Answered** → advance to the next ARHQ topic; `result` acknowledges the
      answer and asks the next question.
    - **Not answered** (vague / off-topic / non-committal) → stay on the SAME
      topic; `result` is a gentle clarifying re-ask. The topic index does not
      move, so the number of turns can exceed the 23 topics.
    - **Loop guard**: after 3 clarifications on one topic the server accepts the
      answer and advances anyway, so a user can never get stuck.

    Topic progress (`answered_count`, `reask_count`) is persisted on each
    history row's `metadata`; the 23 ARHQ items remain the scoring backbone.
    When all 23 topics are answered the response sets `is_complete: true` and
    `result` is a warm summary.

    To **resume** an unfinished session, just call `/reply` again with its
    `session_id` — the server reads the last row's `answered_count` and
    continues on the correct topic.

    ### Post-processing on completion

    When `is_complete=true`, the server runs a SECOND LLM call (the
    "post-process callback") that discretizes the full conversation into a
    quantifiable ARHQ result. The result is persisted to
    `feature_history.metadata` on the final row AND returned as `ahrq_result`.

    | key | type | notes |
    |---|---|---|
    | `ahrq_status` | `"success"` \\| `"failed"` | Whether extraction succeeded |
    | `ahrq_started_at` | ISO-8601 str | When the extraction LLM call began |
    | `ahrq_finished_at` | ISO-8601 str | When persistence completed |
    | `ahrq_error` | `null` \\| `{reason, message}` | Populated only on failure |
    | `ahrq_scores` | `list[int]` \\| `null` | 23 ints, sequential order |
    | `ahrq_comments` | `str` \\| `null` | Comma-separated, index-aligned |
    | `ahrq_total` | `int` \\| `null` | `sum(ahrq_scores)` |
    | `ahrq_severity` | `str` \\| `null` | `"mild"` \\| `"moderate"` \\| `"severe"` |

    Errors never break `/reply`: transport/parse/schema issues become
    `ahrq_status="failed"` in metadata, but the endpoint still returns 200.
    """
    return await ScreeningService.reply(request.text, request.session_id, user.user_id, db)


@router.get(
    "/history",
    response_model=FeatureHistoryListDTO,
    status_code=status.HTTP_200_OK,
    summary="List screening history",
    responses=LLM_RESPONSES,
)
async def history(
    db: AsyncSession = Depends(get_db),
    user: UserResponseDTO = Depends(get_current_user),
):
    """Return all screening history items for the current user, newest first."""
    return await FeatureService.get_history(FeatureType.SCREEN, user.user_id, db)


@router.post(
    "/{session_id}/postprocess",
    response_model=PostProcessRunDTO,
    status_code=status.HTTP_200_OK,
    summary="Re-run ARHQ post-processing for a session",
    responses=LLM_RESPONSES,
)
async def postprocess(
    session_id: UUID,
    force: bool = False,
    db: AsyncSession = Depends(get_db),
    user: UserResponseDTO = Depends(get_current_user),
):
    """
    Re-trigger the ARHQ post-processing callback for an existing session.

    Same logic as the automatic run at the end of `/reply`. Idempotent —
    overwrites whatever metadata was on the latest history row. Returns the
    derived `status` plus the freshly persisted `metadata`.

    Use cases:
    - Retry after a prior `ahrq_status="failed"` result.
    - Re-score after tweaking the rubric or severity thresholds.
    - Admin / QA smoke-test (with `force=true`).

    Status codes:
    - `200` — post-processing completed (result may still carry
      `status=failed` — extractor errors don't 500 here).
    - `403` — session belongs to another user.
    - `404` — session or history row missing.
    - `409` — session is not complete AND `force=false`.
    """
    return await ScreeningService.postprocess(session_id, user.user_id, db, force=force)


@router.get(
    "/{session_id}/postprocess/status",
    response_model=PostProcessStatusDTO,
    status_code=status.HTTP_200_OK,
    summary="Get ARHQ post-process status for a session",
    responses=LLM_RESPONSES,
)
async def postprocess_status(
    session_id: UUID,
    db: AsyncSession = Depends(get_db),
    user: UserResponseDTO = Depends(get_current_user),
):
    """
    Cheap DB-only snapshot of ARHQ post-processing status for a session.

    Zero LLM cost. Reads the latest `feature_history` row's `metadata` JSONB
    and derives the status via a pure function.

    Response `status` values:
    - `not_started` — no history row yet, metadata is null, or the
      `ahrq_status` key is missing (e.g. a legacy row).
    - `success` — full result under `metadata`.
    - `failed` — failure reason + message under `metadata.ahrq_error`.

    Status codes:
    - `200` — snapshot returned.
    - `403` — session belongs to another user.
    - `404` — session or its history rows are missing.
    """
    return await ScreeningService.postprocess_status(session_id, user.user_id, db)
