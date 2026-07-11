"""
CLI commands for database management

Usage:
    python -m app.cli init-db    # Initialize database tables (via alembic)
    python -m app.cli drop-db    # Drop all database tables
"""

import asyncio
import subprocess
import typer
from app.config.database import engine, Base


app = typer.Typer(help="Database management commands")


@app.command()
def init_db():
    """Initialize database tables via alembic migrations.

    create_all is deliberately not used here: it builds tables without the
    alembic_version stamp, which breaks every future `alembic upgrade head`.
    """
    typer.echo("Running alembic upgrade head...")
    subprocess.run(["alembic", "upgrade", "head"], check=True)
    typer.echo("Database tables created successfully!")


@app.command()
def drop_db():
    """Drop all database tables (DANGEROUS!)"""
    if typer.confirm("Are you sure you want to drop all database tables?"):

        async def _drop():
            typer.echo("Dropping database tables...")
            async with engine.begin() as conn:
                await conn.run_sync(Base.metadata.drop_all)
            typer.echo("Database tables dropped successfully!")

        asyncio.run(_drop())
    else:
        typer.echo("Aborted.")


if __name__ == "__main__":
    app()
