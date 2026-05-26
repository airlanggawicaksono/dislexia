"""admins table

Revision ID: c3d4e5f6a8b9
Revises: a1b2c3d4e5f6
Create Date: 2026-05-26

"""

from typing import Sequence, Union
import uuid

from alembic import op
import sqlalchemy as sa


revision: str = "c3d4e5f6a8b9"
down_revision: Union[str, Sequence[str], None] = "b2c3d4e5f6a7"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.create_table(
        "admins",
        sa.Column("admin_id", sa.UUID(), primary_key=True, nullable=False, default=uuid.uuid4),
        sa.Column("username", sa.String(64), unique=True, nullable=False),
        sa.Column("password_hash", sa.String(255), nullable=False),
        sa.Column("must_change_password", sa.Boolean(), nullable=False, server_default=sa.true()),
        sa.Column("is_active", sa.Boolean(), nullable=False, server_default=sa.true()),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False, server_default=sa.func.now()),
        sa.Column("last_login", sa.DateTime(timezone=True), nullable=True),
        sa.Column("created_by", sa.UUID(), sa.ForeignKey("admins.admin_id"), nullable=True),
    )
    op.create_index("ix_admins_username", "admins", ["username"], unique=True)


def downgrade() -> None:
    op.drop_index("ix_admins_username", table_name="admins")
    op.drop_table("admins")
