"""account number: 16-digit → 6-digit (truncate, keep existing users)

Revision ID: e5f6a7b8c9d0
Revises: d4e5f6a7b8c9
Create Date: 2026-06-17

"""

from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


revision: str = "e5f6a7b8c9d0"
down_revision: Union[str, Sequence[str], None] = "d4e5f6a7b8c9"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    conn = op.get_bind()

    # When two 16-digit numbers share the same last-6 they'd collide after truncation.
    # Keep the most-recently created row; delete the others + their child rows.
    conn.execute(sa.text("""
        WITH ranked AS (
            SELECT user_id,
                   ROW_NUMBER() OVER (
                       PARTITION BY RIGHT(account_number, 6)
                       ORDER BY created_at DESC
                   ) AS rn
            FROM users
        ),
        to_delete AS (
            SELECT user_id FROM ranked WHERE rn > 1
        )
        DELETE FROM feature_history
        WHERE user_id IN (SELECT user_id FROM to_delete)
    """))

    conn.execute(sa.text("""
        WITH ranked AS (
            SELECT user_id,
                   ROW_NUMBER() OVER (
                       PARTITION BY RIGHT(account_number, 6)
                       ORDER BY created_at DESC
                   ) AS rn
            FROM users
        ),
        to_delete AS (
            SELECT user_id FROM ranked WHERE rn > 1
        )
        DELETE FROM chat_sessions
        WHERE user_id IN (SELECT user_id FROM to_delete)
    """))

    conn.execute(sa.text("""
        WITH ranked AS (
            SELECT user_id,
                   ROW_NUMBER() OVER (
                       PARTITION BY RIGHT(account_number, 6)
                       ORDER BY created_at DESC
                   ) AS rn
            FROM users
        )
        DELETE FROM users
        WHERE user_id IN (SELECT user_id FROM ranked WHERE rn > 1)
    """))

    # Truncate every surviving account_number to its last 6 digits.
    conn.execute(sa.text("UPDATE users SET account_number = RIGHT(account_number, 6)"))

    op.alter_column(
        "users",
        "account_number",
        existing_type=sa.String(16),
        type_=sa.String(6),
        existing_nullable=False,
    )


def downgrade() -> None:
    op.alter_column(
        "users",
        "account_number",
        existing_type=sa.String(6),
        type_=sa.String(16),
        existing_nullable=False,
    )
