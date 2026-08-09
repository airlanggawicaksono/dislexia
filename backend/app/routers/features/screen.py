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
    ScreeningSessionListDTO,
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
        "Multi-turn dyslexia screening based on the Smythe & Everatt (2001) Adult "
        "Dyslexia Checklist. Server controls the 15-question sequence; the LLM "
        "rephrases each one warmly. Screening only — not a diagnostic assessment."
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
    Open a new dyslexia-checklist screening session.

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

    - **Answered** → advance to the next checklist topic; `result` acknowledges
      the answer and asks the next question.
    - **Not answered** (vague / off-topic / non-committal) → stay on the SAME
      topic; `result` is a gentle clarifying re-ask. The topic index does not
      move, so the number of turns can exceed the 15 topics.
    - **Loop guard**: after 3 clarifications on one topic the server accepts the
      answer and advances anyway, so a user can never get stuck.

    Topic progress (`answered_count`, `reask_count`) is persisted on each
    history row's `metadata`; the 15 checklist items remain the scoring backbone.
    When all 15 topics are answered the response sets `is_complete: true` and
    `result` is a warm summary.

    To **resume** an unfinished session, just call `/reply` again with its
    `session_id` — the server reads the last row's `answered_count` and
    continues on the correct topic.

    ### Post-processing on completion

    When `is_complete=true`, the server runs a SECOND LLM call (the
    "post-process callback") that maps each answer to a checklist column and
    computes the weighted result. It is persisted to `feature_history.metadata`
    on the final row AND returned as `ahrq_result`. (Metadata keys keep the
    `ahrq_` prefix for backward-compat; the instrument is now the Smythe &
    Everatt Adult Dyslexia Checklist.)

    | key | type | notes |
    |---|---|---|
    | `ahrq_status` | `"success"` \\| `"failed"` | Whether extraction succeeded |
    | `ahrq_started_at` | ISO-8601 str | When the extraction LLM call began |
    | `ahrq_finished_at` | ISO-8601 str | When persistence completed |
    | `ahrq_error` | `null` \\| `{reason, message}` | Populated only on failure |
    | `ahrq_scores` | `list[int]` \\| `null` | 15 ints, chosen answer column 0-4 (0 = unanswered) |
    | `ahrq_comments` | `str` \\| `null` | Comma-separated, index-aligned |
    | `ahrq_total` | `int` \\| `null` | WEIGHTED total, range 22-88 |
    | `ahrq_max_total` | `int` | 88 |
    | `ahrq_severity` | `str` \\| `null` | `"unlikely"` (<45) \\| `"mild"` (45-60) \\| `"moderate_severe"` (>60) |
    | `ahrq_disclaimer` | `str` | Not-a-diagnosis notice — always display |
    | `ahrq_attribution` | `str` | © notice — always display |

    Errors never break `/reply`: transport/parse/schema issues become
    `ahrq_status="failed"` in metadata, but the endpoint still returns 200.
    """
    return await ScreeningService.reply(request.text, request.session_id, user.user_id, db)


@router.get(
    "/sessions",
    response_model=ScreeningSessionListDTO,
    status_code=status.HTTP_200_OK,
    summary="List pre-screening conversations (as sets)",
    responses=LLM_RESPONSES,
)
async def sessions(
    db: AsyncSession = Depends(get_db),
    user: UserResponseDTO = Depends(get_current_user),
):
    """
    The user's pre-screening history as **conversation sets** — one item per
    session, newest first. Prefer this over `/history` (flat per-turn rows).

    Each item:
    ```
    { "session_id": "...", "is_complete": false,
      "answered_count": 7, "total_topics": 15,
      "status": "not_started" | "success" | "failed",
      "result": null | { "ahrq_severity": "...", "ahrq_total": ..., ... },
      "messages": [ {"role": "user"|"assistant", "content": "...", ...}, ... ] }
    ```

    Client usage:
    - `is_complete=false` → offer "continue where you left off": replay
      `messages`, then keep calling `/reply` with this `session_id`.
    - `is_complete=true, status=success` → show `result` as a past outcome.
    - `is_complete=true, status=failed|not_started` → scoring didn't land;
      re-trigger via `POST /{session_id}/postprocess?force=true`.
    """
    return await ScreeningService.list_sessions(user.user_id, db)


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
