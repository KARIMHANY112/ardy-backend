"""add listing size_unit

`size` was stored as a bare number while the UI hardcoded a "sqm" suffix, so a
plot entered as 5 feddan displayed as "5 sqm" — off by a factor of 4,200. This
records the unit alongside the number.

Existing rows default to sqm: every listing present when this ran had been
entered in square metres.

Revision ID: d1e4b7c2a9f5
Revises: c7a1b9e4f382
Create Date: 2026-08-05 00:00:00.000000

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = 'd1e4b7c2a9f5'
down_revision: Union[str, None] = 'c7a1b9e4f382'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


size_unit = sa.Enum('sqm', 'feddan', name='sizeunit')


def upgrade() -> None:
    size_unit.create(op.get_bind(), checkfirst=True)
    op.add_column(
        'listings',
        sa.Column('size_unit', size_unit, nullable=False, server_default='sqm'),
    )


def downgrade() -> None:
    op.drop_column('listings', 'size_unit')
    size_unit.drop(op.get_bind(), checkfirst=True)
