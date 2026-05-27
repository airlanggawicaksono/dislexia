"""Seed the master admin account.

Idempotent — skipped if an admin with the seed username already exists.
Credentials sourced from settings (SEED_ADMIN_USERNAME / SEED_ADMIN_PASSWORD env vars).

Auto-runs on every app startup via lifespan (see app/main.py).
First boot creates it; subsequent boots no-op. Can also be invoked manually:
    python -m app.scripts.seed_admin
    python -m app.scripts.seed_admin --username root --password supersecret123
    docker compose exec fastapi-app python -m app.scripts.seed_admin
"""

import asyncio

import typer
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.config.database import async_session_maker, init_db
from app.config.settings import settings
from app.models.admin import Admin
from app.utils.password_utils import hash_password


async def ensure_seed_admin(
    db: AsyncSession,
    username: str | None = None,
    password: str | None = None,
) -> bool:
    """Create the seed admin if missing. Returns True if created, False if already present."""
    username = username or settings.SEED_ADMIN_USERNAME
    password = password or settings.SEED_ADMIN_PASSWORD

    existing = await db.execute(select(Admin).where(Admin.username == username))
    if existing.scalar_one_or_none() is not None:
        return False

    db.add(Admin(
        username=username,
        password_hash=hash_password(password),
        must_change_password=True,
    ))
    await db.commit()
    return True


async def _run_cli(username: str, password: str) -> str:
    await init_db()
    async with async_session_maker() as db:
        created = await ensure_seed_admin(db, username, password)
    if not created:
        return f"Admin '{username}' already exists. Nothing to do."
    return (
        f"Seed admin created.\n"
        f"  username: {username}\n"
        f"  password: {password}\n"
        f"  must_change_password: True (rotate on first login)"
    )


app = typer.Typer(add_completion=False)


@app.command()
def main(
    username: str = typer.Option(None, help="Override SEED_ADMIN_USERNAME env."),
    password: str = typer.Option(None, help="Override SEED_ADMIN_PASSWORD env."),
):
    """Create the initial master admin if missing."""
    typer.echo(asyncio.run(_run_cli(
        username or settings.SEED_ADMIN_USERNAME,
        password or settings.SEED_ADMIN_PASSWORD,
    )))


if __name__ == "__main__":
    app()
