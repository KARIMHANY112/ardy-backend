"""add listing papers_pending status

Revision ID: f6c3a9d1e7b2
Revises: e2a5c8b1d4f9
Create Date: 2026-07-19 00:00:00.000000

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = 'f6c3a9d1e7b2'
down_revision: Union[str, None] = 'e2a5c8b1d4f9'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.execute("ALTER TYPE listingstatus ADD VALUE IF NOT EXISTS 'papers_pending'")


def downgrade() -> None:
    # Postgres can't drop a single value from an enum type, so 'papers_pending'
    # stays in listingstatus on downgrade — nothing to reverse.
    pass
