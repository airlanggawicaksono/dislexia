"""Partial / invalid input fixtures for all request DTOs.

Each list is parametrize-ready: (payload_dict, human_readable_id).
Use with `@pytest.mark.parametrize("payload, case", LIST, ids=[c[1] for c in LIST])`.

Covers: MissingField / WrongType / OutOfRange / MalformedUUID / EdgeWhitespace /
NonDigit / Oversize / Empty / Null. DTOs reject ALL of these with 422.
"""

from uuid import uuid4
from app.policies import MAX_INPUT_CHARS, ACCOUNT_NUMBER_LENGTH

_DUMMY_UUID = str(uuid4())
_VALID_ACCOUNT = "1" * ACCOUNT_NUMBER_LENGTH
_OVERSIZE_TEXT = "a" * (MAX_INPUT_CHARS + 1)


# ─── auth.LoginRequestDTO ──────────────────────────────────────────────────────
LOGIN_INVALID = [
    ({}, "missing-account_number"),
    ({"account_number": ""}, "empty-string"),
    ({"account_number": None}, "null"),
    ({"account_number": "123"}, "too-short"),
    ({"account_number": "1" * 17}, "too-long-17"),
    ({"account_number": "abcdefghijklmnop"}, "non-digit-letters"),
    ({"account_number": "1234567890abcdef"}, "non-digit-mixed"),
    ({"account_number": "1234-5678-9012-3456"}, "with-dashes"),
    ({"account_number": "1234 5678 9012 3456"}, "with-spaces-inside"),
    ({"account_number": 1234567890123456}, "int-not-str"),
    ({"account_number": "   "}, "whitespace-only"),
    ({"wrong_field": _VALID_ACCOUNT}, "wrong-field-name"),
]

LOGIN_VALID = [
    ({"account_number": _VALID_ACCOUNT}, "valid-all-ones"),
    ({"account_number": "0000000000000000"}, "all-zeros"),
    ({"account_number": "9999999999999999"}, "all-nines"),
    ({"account_number": f"  {_VALID_ACCOUNT}  "}, "padded-whitespace-stripped"),
]


# ─── feature.FeatureRequestDTO (summarize/professionalize/define) ──────────────
FEATURE_PROCESS_INVALID = [
    ({}, "missing-text"),
    ({"text": ""}, "empty-text"),
    ({"text": None}, "null-text"),
    ({"text": "   "}, "whitespace-only"),
    ({"text": "\n\t\n"}, "newlines-tabs-only"),
    ({"text": 123}, "int-text"),
    ({"text": _OVERSIZE_TEXT}, "oversize-text"),
    ({"text": "hi", "session_id": "not-a-uuid"}, "invalid-uuid"),
    ({"text": "hi", "session_id": 12345}, "int-session_id"),
    ({"text": "hi", "session_id": ""}, "empty-session_id"),
]

FEATURE_PROCESS_VALID = [
    ({"text": "hello world"}, "minimal-no-session"),
    ({"text": "hello world", "session_id": _DUMMY_UUID}, "with-session"),
    ({"text": "x"}, "single-char"),
    ({"text": "a" * MAX_INPUT_CHARS}, "max-length"),
    ({"text": "  hello  "}, "padded-stripped"),
]


# ─── screening.ScreeningReplyRequestDTO ────────────────────────────────────────
SCREENING_REPLY_INVALID = [
    ({}, "missing-both"),
    ({"text": "hi"}, "missing-session_id"),
    ({"session_id": _DUMMY_UUID}, "missing-text"),
    ({"text": None, "session_id": _DUMMY_UUID}, "null-text"),
    ({"text": "", "session_id": _DUMMY_UUID}, "empty-text"),
    ({"text": "   ", "session_id": _DUMMY_UUID}, "whitespace-only-text"),
    ({"text": _OVERSIZE_TEXT, "session_id": _DUMMY_UUID}, "oversize-text"),
    ({"text": "hi", "session_id": None}, "null-session_id"),
    ({"text": "hi", "session_id": "not-uuid"}, "malformed-uuid"),
    ({"text": "hi", "session_id": ""}, "empty-session_id"),
    ({"text": 42, "session_id": _DUMMY_UUID}, "int-text"),
]

SCREENING_REPLY_VALID = [
    ({"text": "I read pretty slow", "session_id": _DUMMY_UUID}, "minimal"),
    ({"text": "yes", "session_id": _DUMMY_UUID}, "single-word"),
    ({"text": "  yes  ", "session_id": _DUMMY_UUID}, "padded-stripped"),
]


# ─── Header / auth-level partial cases ────────────────────────────────────────
AUTH_HEADER_INVALID = [
    ({}, "missing-authorization"),
    ({"Authorization": ""}, "empty-header"),
    ({"Authorization": "Bearer"}, "scheme-no-token"),
    ({"Authorization": "Bearer "}, "trailing-space-no-token"),
    ({"Authorization": "Basic abc123"}, "wrong-scheme"),
    ({"Authorization": "Bearer not.a.valid.jwt"}, "malformed-jwt"),
    ({"Authorization": "Bearer " + "x" * 500}, "garbage-token"),
]


# ─── Query param partial cases (admin/me history filters) ──────────────────────
HISTORY_QUERY_INVALID = [
    ({"feature": "not_a_feature"}, "invalid-feature-enum"),
    ({"feature": ""}, "empty-feature"),
    ({"feature": "SUMMARIZE"}, "wrong-case"),
    ({"feature": "summary"}, "typo"),
]

ADMIN_HISTORY_QUERY_INVALID = [
    ({"user": ""}, "empty-md5"),
    ({"feature": "garbage"}, "invalid-feature-enum"),
]


# ─── Path param partial cases (history_id, etc.) ──────────────────────────────
PATH_UUID_INVALID = [
    ("not-a-uuid", "not-uuid"),
    ("12345", "numeric-string"),
    ("00000000-0000-0000-0000", "truncated-uuid"),
    ("00000000-0000-0000-0000-zzzzzzzzzzzz", "bad-chars"),
]
