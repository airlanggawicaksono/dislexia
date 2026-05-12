"""initial

Revision ID: d744aed83001
Revises:
Create Date: 2026-05-16 21:21:00.459275

"""

from typing import Sequence, Union
import uuid
from alembic import op
import sqlalchemy as sa


revision: str = "d744aed83001"
down_revision: Union[str, Sequence[str], None] = None
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.create_table(
        "users",
        sa.Column(
            "user_id", sa.UUID(), nullable=False, primary_key=True, default=uuid.uuid4
        ),
        sa.Column("email", sa.String(255), nullable=False, unique=True, index=True),
        sa.Column("username", sa.String(100), nullable=False, unique=True, index=True),
        sa.Column("access_code", sa.String(7), nullable=False, unique=True, index=True),
        sa.Column(
            "created_at",
            sa.DateTime(timezone=True),
            nullable=False,
            server_default=sa.func.now(),
        ),
        sa.Column("last_login", sa.DateTime(timezone=True), nullable=True),
        sa.Column("is_active", sa.Boolean(), nullable=False, default=True),
    )


def downgrade() -> None:
    op.drop_table("users")
