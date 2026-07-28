"""add listing offer_type

Revision ID: b4e8d1f6a207
Revises: a3f7b9c2d5e8
Create Date: 2026-07-28 00:00:00.000000

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = 'b4e8d1f6a207'
down_revision: Union[str, None] = 'a3f7b9c2d5e8'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


offer_type = sa.Enum('sale', 'rent', 'resale', name='offertype')


def upgrade() -> None:
    offer_type.create(op.get_bind(), checkfirst=True)
    # Existing rows were all first-hand sales — that's the only thing the app offered
    # before this column existed.
    op.add_column(
        'listings',
        sa.Column('offer_type', offer_type, nullable=False, server_default='sale'),
    )


def downgrade() -> None:
    op.drop_column('listings', 'offer_type')
    offer_type.drop(op.get_bind(), checkfirst=True)
