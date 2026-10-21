"""make user phone optional

App Store review (guideline 5.1.1(v)) rejected signup for requiring a phone
number, so users.phone is now nullable. It stays UNIQUE; Postgres allows any
number of NULLs under a unique constraint.

Revision ID: e5b2c7d9f1a3
Revises: d1e4b7c2a9f5
Create Date: 2026-10-21 00:00:00.000000

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = 'e5b2c7d9f1a3'
down_revision: Union[str, None] = 'd1e4b7c2a9f5'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.alter_column('users', 'phone', existing_type=sa.String(), nullable=True)


def downgrade() -> None:
    op.alter_column('users', 'phone', existing_type=sa.String(), nullable=False)
