"""add user password reset code

Revision ID: e2a5c8b1d4f9
Revises: d8f4a1c9b3e2
Create Date: 2026-07-18 00:00:00.000000

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = 'e2a5c8b1d4f9'
down_revision: Union[str, None] = 'd8f4a1c9b3e2'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.add_column('users', sa.Column('reset_code_hash', sa.String(), nullable=True))
    op.add_column('users', sa.Column('reset_code_expires_at', sa.DateTime(timezone=True), nullable=True))


def downgrade() -> None:
    op.drop_column('users', 'reset_code_expires_at')
    op.drop_column('users', 'reset_code_hash')
