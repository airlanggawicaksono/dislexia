"""
CLI commands for database management

Usage:
    python -m app.cli init-db    # Initialize database tables
    python -m app.cli drop-db    # Drop all database tables
"""

import asyncio
import typer
from app.config.database import engine, Base


app = typer.Typer(help="Database management commands")


@app.command()
def init_db():
    """Initialize database tables"""

    async def _init():
        typer.echo("Creating database tables...")
        async with engine.begin() as conn:
            await conn.run_sync(Base.metadata.create_all)
        typer.echo("Database tables created successfully!")

    asyncio.run(_init())


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
