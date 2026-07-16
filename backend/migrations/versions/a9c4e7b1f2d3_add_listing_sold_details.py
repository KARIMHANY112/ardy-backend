"""add listing sold details

Revision ID: a9c4e7b1f2d3
Revises: f3a1c8d2e4b7
Create Date: 2026-07-12 00:00:00.000000

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = 'a9c4e7b1f2d3'
down_revision: Union[str, None] = 'f3a1c8d2e4b7'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.execute("ALTER TYPE listingstatus ADD VALUE IF NOT EXISTS 'sold'")
    op.add_column('listings', sa.Column('sold_price', sa.Float(), nullable=True))
    op.add_column('listings', sa.Column('sold_to_name', sa.String(), nullable=True))
    op.add_column('listings', sa.Column('sold_to_phone', sa.String(), nullable=True))
    op.add_column('listings', sa.Column('sold_at', sa.DateTime(timezone=True), nullable=True))


def downgrade() -> None:
    # Postgres can't drop a single value from an enum type, so 'sold' stays in
    # listingstatus on downgrade — only the listing columns are removed.
    op.drop_column('listings', 'sold_at')
    op.drop_column('listings', 'sold_to_phone')
    op.drop_column('listings', 'sold_to_name')
    op.drop_column('listings', 'sold_price')
