"""user.display_name

Revision ID: d4e5f6a7b8c9
Revises: c3d4e5f6a8b9
Create Date: 2026-05-26

Adds a non-nullable display_name column (adjective-animal nickname) to users.
Backfills existing rows with petname-generated values before applying NOT NULL.
"""

from typing import Sequence, Union

import petname
from alembic import op
import sqlalchemy as sa


revision: str = "d4e5f6a7b8c9"
down_revision: Union[str, Sequence[str], None] = "c3d4e5f6a8b9"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.add_column("users", sa.Column("display_name", sa.String(64), nullable=True))

    conn = op.get_bind()
    rows = conn.execute(sa.text("SELECT user_id FROM users WHERE display_name IS NULL")).fetchall()
    for row in rows:
        conn.execute(
            sa.text("UPDATE users SET display_name = :name WHERE user_id = :uid"),
            {"name": petname.Generate(2, "-"), "uid": row.user_id},
        )

    op.alter_column("users", "display_name", nullable=False)
    op.create_index("ix_users_display_name", "users", ["display_name"])


def downgrade() -> None:
    op.drop_index("ix_users_display_name", table_name="users")
    op.drop_column("users", "display_name")
