# Dislexia Backend

FastAPI backend for the Dislexia Reader monorepo with 7-digit access code authentication.

## Features

- **7-digit Access Code Authentication** (like Mullvad) — no passwords, just codes
- **JWT Token** sessions after login
- **Auto-generated usernames** (Adjective + Animal)
- **Feature stubs**: Summarize, Professionalize, Define
- **History routes**: `/{md5_hash}/{feature}/history`
- **Async PostgreSQL** with SQLAlchemy 2.0
- **Docker** ready with docker-compose

## Quick Start

```bash
cd backend

# 1. Create .env
cp .env.example .env

# 2. Run with Docker (recommended)
make dev

# 3. API docs at http://localhost:8000/docs
```

## Project Structure

```
backend/
├── app/
│   ├── config/       # Settings & database
│   ├── dto/          # Data Transfer Objects
│   │   ├── auth/     # Auth DTOs
│   │   └── feature/  # Feature DTOs (summarize, professionalize, define)
│   ├── models/       # SQLAlchemy models
│   ├── routers/      # API endpoints
│   │   ├── auth.py           # /api/v1/auth/*
│   │   ├── summarize.py      # /api/v1/{hash}/summarize/*
│   │   ├── professionalize.py # /api/v1/{hash}/professionalize/*
│   │   └── define.py         # /api/v1/{hash}/define/*
│   ├── services/     # Business logic
│   └── utils/        # Helpers (JWT, access code gen, username gen)
├── tests/
├── Dockerfile
├── docker-compose.yml
├── docker-compose.prod.yml
├── Makefile
└── requirements.txt
```

## API Routes

| Method | Route | Description |
|--------|-------|-------------|
| POST | `/api/v1/auth/signup` | Create account (returns 6-digit code) |
| POST | `/api/v1/auth/login` | Login with 6-digit code (returns JWT) |
| POST | `/api/v1/me/screen/{session_id}/postprocess` | Re-run ARHQ post-process for a session (`?force=true` to allow incomplete) |
| GET | `/api/v1/me/screen/{session_id}/postprocess/status` | DB-only snapshot: `not_started` \| `success` \| `failed` (no LLM cost) |
| POST | `/api/v1/me/summarize/process` | Summarize text (see Summarize Levels below) |
| POST | `/api/v1/me/summarize/process-stream` | Summarize (SSE stream) |
| GET | `/api/v1/me/summarize/history` | Summarize history |
| POST | `/api/v1/me/professionalize/process` | Professionalize text |
| GET | `/api/v1/me/professionalize/history` | Professionalize history |
| POST | `/api/v1/me/define/process` | Define/simplify text |
| GET | `/api/v1/me/define/history` | Define history |

## Summarize Levels

`POST /api/v1/me/summarize/process` accepts an optional `level` field controlling
how much of the source text is preserved. Content is always ordered by importance
so shorter tiers drop the least-critical layer first:

1. **CORE** — single most important idea (always the first sentence)
2. **DEPENDENCIES** — facts / context the core rests on
3. **DETAILS** — examples, numbers, nuance

| `level` value | Target size | Layers included |
|---------------|-------------|-----------------|
| `10pct` | ~10% of source chars | CORE only |
| `30pct` | ~30% | CORE + DEPENDENCIES |
| `50pct` (default) | ~50% | CORE + DEPENDENCIES + key DETAILS |
| `70pct` | ~70% | CORE + DEPENDENCIES + most DETAILS |
| `90pct` | ~90% | ALL layers, tightened prose |

Implementation details (`app/routers/features/summarize.py`):

- Source char count is computed after whitespace normalization
- Prompt injects both the target char budget and the original size as HARD RULES
- `max_tokens` = `target_chars / 4 * 1.5` (clamped ≤ 4096) — safety ceiling
- LLM instructed to end on a complete sentence

Each summarize invocation persists metadata to `feature_history.metadata` (JSONB):

```json
{ "level": "50pct", "pct": 0.5, "src_chars": 1240, "target_chars": 620, "max_tokens": 232 }
```

## Screening Post-Processing

`POST /api/v1/me/screen/reply` walks the user through 23 ARHQ questions. On the
final turn the server sets `is_complete=true` AND runs a second LLM call
("post-process callback", see `app/services/screening/postprocess.py`) that
discretizes the free-form chat into a quantifiable ARHQ result.

The extractor is asked to emit strict JSON:

```json
{ "scores": [int × 23], "comments": [str × 23] }
```

Response then includes `ahrq_result` (also persisted to
`feature_history.metadata` on the final row):

```json
{
  "ahrq_status": "success",
  "ahrq_error": null,
  "ahrq_scores": [2, 3, 1, ...],
  "ahrq_comments": "slow reader,work heavy,...",
  "ahrq_total": 45,
  "ahrq_severity": "mild"
}
```

Comments are joined comma-separated, index-aligned to `ahrq_scores`. Sum of
scores maps to a severity band (see `_SEVERITY_THRESHOLDS` in `postprocess.py`).

Failure handling: if the extractor LLM refuses, returns text that starts with a
known error signature (Together/OpenAI-style `error: …`, `I cannot …`, etc.),
returns malformed JSON, or the schema doesn't match (wrong array length, non-int
or out-of-range scores), `/reply` still returns 200 with the warm summary — but
`ahrq_status="failed"` is recorded and the numeric fields are `null`. Admin can
inspect / re-run post-processing off-line via history. (Commas inside a comment
are not a failure — they're sanitized to `;` so the comma-join stays aligned.)

### The post-process callback as an id-triggered reprocess

The post-process step is intentionally decoupled from the conversation. It runs
automatically at the end of `/reply`, but the exact same callback
(`PostProcessService.run`) is exposed as a standalone, id-addressable endpoint:

```
POST /api/v1/me/screen/{session_id}/postprocess
```

Because it is keyed only by `session_id` and reads the conversation back from
Postgres, it is a **safe, idempotent reprocess trigger**. Nothing about it
depends on being called inline with `/reply`. That gives you several recovery /
maintenance flows without new machinery:

- **Retry a failed run** — if the first pass recorded `ahrq_status="failed"`
  (LLM was down, returned malformed JSON, refused, etc.), just POST the endpoint
  again. It overwrites the metadata on the latest history row with a fresh
  result. Poll `GET …/postprocess/status` first (zero LLM cost) to decide
  whether a retry is even needed.
- **Re-score after a rubric change** — bump `SEVERITY_THRESHOLDS` or the score
  range in `app/policies/ahrq.py`, then replay the endpoint to recompute bands
  on old sessions.
- **Backfill** — sessions that completed before the callback existed show
  `not_started`; POST the endpoint to score them retroactively.
- **QA / smoke test** — pass `?force=true` to run against an in-progress session
  without waiting for all 23 questions.

Contract:

- Idempotent — overwrites whatever metadata was on the latest history row.
- Default: `409` if the session hasn't answered all 23 questions.
- `?force=true` — allow the run on incomplete sessions.
- Never `500`s on extractor/parse errors — those come back as
  `status=failed` in the body so a client can loop retry-on-failure safely.

### Status snapshot

`GET /api/v1/me/screen/{session_id}/postprocess/status` returns a cheap,
DB-only snapshot. Zero LLM cost — reads the latest feature_history row's
`metadata` JSONB and derives the status via `resolve_status`:

```
metadata is null / missing ahrq_status  →  "not_started"
metadata.ahrq_status == "success"        →  "success"
metadata.ahrq_status == "failed"         →  "failed"
```

The full `metadata` dict is returned alongside so the frontend can render
scores / severity / error reason without a second call.

### Code layout

Post-processing follows the same layering as the rest of the app — rubric
constants in `policies/`, status enum + response DTOs in `dto/`, HTTP errors
from `exceptions/`, and a stateless static-method service that talks to
`ChatHistoryService`:

```
app/policies/ahrq.py                      # SCORE_MIN/MAX, SEVERITY_THRESHOLDS, classify_severity
app/dto/feature/screening/enums.py        # PostProcessStatus enum
app/dto/feature/screening/response.py     # PostProcessRunDTO, PostProcessStatusDTO
app/services/screening/prompts.py         # build_extraction_prompt (+ conversation prompts)
app/services/screening/postprocess/
├── service.py   # PostProcessService.run / get_status (static, uses ChatHistoryService)
├── parser.py    # PostProcessError + parse_llm_response (defensive)
├── result.py    # build_success_metadata / build_failure_metadata / resolve_status (pure)
└── __init__.py  # re-exports
```

`PostProcessService` is stateless (static methods, no instance state — the
same pattern as the other services). It calls `ChatHistoryService` directly
for DB access, raises `ConflictError` from `app/exceptions` on incomplete
sessions, and reads scoring config from `app/policies/ahrq.py`. Extractor and
parse failures are converted to failure-shape metadata rather than raised, so
the endpoints always return 200 with a readable status.

## Feature History Metadata

The `feature_history.metadata` JSONB column (added in migration `f6a7b8c9d0e1`)
stores per-invocation context. Populated today by summarize (`level`, `pct`,
`src_chars`, `target_chars`, `max_tokens`). Reserved for future feature-specific
fields (e.g. professionalize email recipient/sender). Nullable — legacy rows
have `NULL` metadata.

## Make Commands

```bash
make dev          # Development with hot reload
make prod         # Production mode
make build        # Build Docker images
make down         # Stop containers
make logs         # View logs
make shell        # Shell into app container
make db-shell     # PostgreSQL shell
make test         # Run tests
make clean        # Clean cache
```

## Environment Variables

See `.env.example` for all options.

## Notes

- Access codes are **7 digits**, uppercase letters + numbers
- History routes use **MD5 hash** of the access code for URL privacy
- Feature implementations (LLM integration) are **stubs** — to be filled by team
