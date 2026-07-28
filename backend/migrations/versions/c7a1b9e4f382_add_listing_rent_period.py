"""add listing rent_period

Revision ID: c7a1b9e4f382
Revises: b4e8d1f6a207
Create Date: 2026-07-28 00:00:00.000000

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = 'c7a1b9e4f382'
down_revision: Union[str, None] = 'b4e8d1f6a207'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


rent_period = sa.Enum('monthly', 'yearly', name='rentperiod')


def upgrade() -> None:
    rent_period.create(op.get_bind(), checkfirst=True)
    # Nullable with no backfill: every existing row is offer_type 'sale', and a sale
    # price has no period.
    op.add_column('listings', sa.Column('rent_period', rent_period, nullable=True))


def downgrade() -> None:
    op.drop_column('listings', 'rent_period')
    rent_period.drop(op.get_bind(), checkfirst=True)
