"""Top-level pytest config.

Intentionally empty — no app/DB imports here.
- DTO unit tests (tests/dto/) need zero app context.
- Router integration tests (tests/routers/) get their fixtures from
  tests/routers/conftest.py.
"""
