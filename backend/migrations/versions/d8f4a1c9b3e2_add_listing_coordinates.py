"""add listing coordinates

Revision ID: d8f4a1c9b3e2
Revises: c1e5f8a2b4d6
Create Date: 2026-07-13 00:00:00.000000

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = 'd8f4a1c9b3e2'
down_revision: Union[str, None] = 'c1e5f8a2b4d6'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.add_column('listings', sa.Column('latitude', sa.Float(), nullable=True))
    op.add_column('listings', sa.Column('longitude', sa.Float(), nullable=True))


def downgrade() -> None:
    op.drop_column('listings', 'longitude')
    op.drop_column('listings', 'latitude')
