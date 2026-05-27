"""chat_sessions and feature_history tables

Revision ID: a1b2c3d4e5f6
Revises: d744aed83001
Create Date: 2026-05-23

"""

from typing import Sequence, Union
import uuid
from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects.postgresql import JSONB

revision: str = "a1b2c3d4e5f6"
down_revision: Union[str, Sequence[str], None] = "d744aed83001"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.create_table(
        "chat_sessions",
        sa.Column("session_id", sa.UUID(), primary_key=True, nullable=False, default=uuid.uuid4),
        sa.Column("user_id", sa.UUID(), sa.ForeignKey("users.user_id"), nullable=False),
        sa.Column("feature", sa.String(50), nullable=False),
        sa.Column("history", JSONB, nullable=False, server_default="[]"),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False, server_default=sa.func.now()),
        sa.Column("updated_at", sa.DateTime(timezone=True), nullable=False, server_default=sa.func.now()),
    )
    op.create_index("ix_chat_sessions_user_id", "chat_sessions", ["user_id"])
    op.create_index("ix_chat_sessions_feature", "chat_sessions", ["feature"])
    op.create_index("ix_chat_sessions_history_gin", "chat_sessions", ["history"], postgresql_using="gin")

    op.create_table(
        "feature_history",
        sa.Column("id", sa.UUID(), primary_key=True, nullable=False, default=uuid.uuid4),
        sa.Column("session_id", sa.UUID(), sa.ForeignKey("chat_sessions.session_id"), nullable=False),
        sa.Column("user_id", sa.UUID(), sa.ForeignKey("users.user_id"), nullable=False),
        sa.Column("feature", sa.String(50), nullable=False),
        sa.Column("input_text", sa.Text, nullable=False),
        sa.Column("output_text", sa.Text, nullable=True),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False, server_default=sa.func.now()),
    )
    op.create_index("ix_feature_history_session_id", "feature_history", ["session_id"])
    op.create_index("ix_feature_history_user_feature", "feature_history", ["user_id", "feature"])


def downgrade() -> None:
    op.drop_table("feature_history")
    op.drop_table("chat_sessions")
