"""Defensive parser for the ARHQ extraction LLM's raw text output.

LLM outputs are not standardized — we get markdown fences, leading prose,
trailing commas, single quotes, string-wrapped numbers, or refusal messages.
This module raises a distinct `PostProcessError.reason` for each pathology so
the caller can persist a machine-readable failure code alongside a truncated
sample of the raw response for debugging.
"""

from __future__ import annotations

import json
import re
from typing import Optional

from app.policies import SCORE_MIN, SCORE_MAX
from app.services.screening.prompts import QUESTIONS


# ---- Error signatures ------------------------------------------------------

# Matched with `startswith` on the trimmed, lowercased raw output. Order not
# significant. Keep short + specific — over-broad entries eat valid JSON.
_ERROR_SIGNATURES: tuple[str, ...] = (
    "error:",
    "error ",
    "{\"error\"",
    "{'error'",
    "i cannot",
    "i can't",
    "i'm unable",
    "i am unable",
    "sorry, i",
    "unable to",
    "api error",
    "rate limit",
    "invalid_request_error",
    "context_length_exceeded",
    "server error",
    "internal error",
    "the model",  # e.g. "The model refused to respond"
)


def _looks_like_error(raw: str) -> bool:
    trimmed = raw.strip().lower()
    return any(trimmed.startswith(sig) for sig in _ERROR_SIGNATURES)


# ---- Cleanup passes --------------------------------------------------------

_FENCE_OPEN = re.compile(r"^\s*```(?:json|JSON)?\s*", re.MULTILINE)
_FENCE_CLOSE = re.compile(r"\s*```\s*$", re.MULTILINE)
_TRAILING_COMMA = re.compile(r",(\s*[}\]])")
_BOM = "﻿"


def _strip_fences(raw: str) -> str:
    """Remove leading/trailing markdown code fences."""
    return _FENCE_CLOSE.sub("", _FENCE_OPEN.sub("", raw)).strip()


def _extract_json_object(raw: str) -> Optional[str]:
    """Grab first `{` to last `}`. Salvages when prose surrounds JSON."""
    start = raw.find("{")
    end = raw.rfind("}")
    if start == -1 or end == -1 or end <= start:
        return None
    return raw[start : end + 1]


def _strip_trailing_commas(text: str) -> str:
    return _TRAILING_COMMA.sub(r"\1", text)


def _swap_single_quotes(text: str) -> str:
    """Best-effort single→double quote swap for `{'a': 'b'}`-style output.

    Not safe if any value legitimately contains a single quote — that's why
    it's a LAST-RESORT try, only after strict json.loads has failed.
    """
    return text.replace("'", '"')


def _tidy(raw: str) -> str:
    """Cheap normalization applied before the first parse attempt."""
    return _strip_trailing_commas(_strip_fences(raw.lstrip(_BOM)))


# ---- Coercion --------------------------------------------------------------

def _coerce_int(v: object) -> Optional[int]:
    """Return int for `2` and `"2"`. None for anything else (incl. floats, bools)."""
    if isinstance(v, bool):
        return None
    if isinstance(v, int):
        return v
    if isinstance(v, str) and v.strip().lstrip("-").isdigit():
        try:
            return int(v.strip())
        except ValueError:
            return None
    return None


# ---- Error type ------------------------------------------------------------

class PostProcessError(Exception):
    """Raised when the extraction LLM output can't be turned into ARHQ result.

    - `reason`: short stable machine code (persisted to `ahrq_error.reason`).
    - `message`: human-readable detail (persisted, truncated) for debugging.
    """

    def __init__(self, reason: str, message: str = ""):
        self.reason = reason
        self.message = message
        super().__init__(f"{reason}: {message}" if message else reason)


# ---- Main parse ------------------------------------------------------------

def parse_llm_response(raw: str) -> tuple[list[int], list[str]]:
    """Turn raw LLM text into (scores, comments) or raise PostProcessError.

    Failure `reason` codes (each distinct, machine-readable):
      - empty_response, llm_refused_or_api_error, malformed_json,
        schema_mismatch, wrong_length, score_out_of_range.

    Note: commas inside a comment are sanitized (→ ';'), NOT treated as a
    failure — they'd only break the comma-join index alignment otherwise.
    """
    if not raw or not raw.strip():
        raise PostProcessError("empty_response")

    if _looks_like_error(raw):
        raise PostProcessError("llm_refused_or_api_error", raw.strip()[:200])

    tidied = _tidy(raw)
    candidate = _extract_json_object(tidied)
    if candidate is None:
        raise PostProcessError("malformed_json", "no JSON object found")

    payload: Optional[dict] = None
    try:
        payload = json.loads(candidate)
    except json.JSONDecodeError:
        # Last-resort: swap single quotes and retry ONCE.
        try:
            payload = json.loads(_swap_single_quotes(candidate))
        except json.JSONDecodeError as exc2:
            raise PostProcessError("malformed_json", str(exc2)) from exc2

    if not isinstance(payload, dict):
        raise PostProcessError("schema_mismatch", "top-level is not an object")

    scores_raw = payload.get("scores")
    comments_raw = payload.get("comments")
    if not isinstance(scores_raw, list) or not isinstance(comments_raw, list):
        raise PostProcessError("schema_mismatch", "scores/comments not arrays")

    expected = len(QUESTIONS)
    if len(scores_raw) != expected or len(comments_raw) != expected:
        raise PostProcessError(
            "wrong_length",
            f"got scores={len(scores_raw)}, comments={len(comments_raw)}, want {expected}",
        )

    scores: list[int] = []
    for i, s in enumerate(scores_raw):
        coerced = _coerce_int(s)
        if coerced is None:
            raise PostProcessError("schema_mismatch", f"scores[{i}] not int-like: {s!r}")
        if coerced < SCORE_MIN or coerced > SCORE_MAX:
            raise PostProcessError(
                "score_out_of_range",
                f"scores[{i}]={coerced} outside [{SCORE_MIN},{SCORE_MAX}]",
            )
        scores.append(coerced)

    comments: list[str] = []
    for i, c in enumerate(comments_raw):
        if not isinstance(c, str):
            raise PostProcessError("schema_mismatch", f"comments[{i}] not str: {c!r}")
        # Comments are joined comma-separated, so an internal comma would break
        # index alignment on read. Sanitize (comma → ';') rather than fail the
        # whole run — one stray comma shouldn't discard 23 valid scores.
        cleaned = re.sub(r"\s+", " ", c.replace(",", ";")).strip()
        comments.append(cleaned)

    return scores, comments
