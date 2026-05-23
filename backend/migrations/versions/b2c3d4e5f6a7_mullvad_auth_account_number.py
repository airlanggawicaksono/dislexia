"""mullvad auth — replace email/username/access_code with account_number

Revision ID: b2c3d4e5f6a7
Revises: a1b2c3d4e5f6
Create Date: 2026-05-23

"""

from typing import Sequence, Union
from alembic import op
import sqlalchemy as sa

revision: str = "b2c3d4e5f6a7"
down_revision: Union[str, Sequence[str], None] = "a1b2c3d4e5f6"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.drop_index("ix_users_email", table_name="users")
    op.drop_index("ix_users_username", table_name="users")
    op.drop_index("ix_users_access_code", table_name="users")
    op.drop_column("users", "email")
    op.drop_column("users", "username")
    op.drop_column("users", "access_code")
    op.add_column("users", sa.Column("account_number", sa.String(16), nullable=False, server_default="0000000000000000"))
    op.create_index("ix_users_account_number", "users", ["account_number"], unique=True)
    op.alter_column("users", "account_number", server_default=None)


def downgrade() -> None:
    op.drop_index("ix_users_account_number", table_name="users")
    op.drop_column("users", "account_number")
    op.add_column("users", sa.Column("email", sa.String(255), nullable=False, server_default=""))
    op.add_column("users", sa.Column("username", sa.String(100), nullable=False, server_default=""))
    op.add_column("users", sa.Column("access_code", sa.String(7), nullable=False, server_default=""))
    op.create_index("ix_users_email", "users", ["email"], unique=True)
    op.create_index("ix_users_username", "users", ["username"], unique=True)
    op.create_index("ix_users_access_code", "users", ["access_code"], unique=True)
