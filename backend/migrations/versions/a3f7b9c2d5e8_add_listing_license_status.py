"""add listing license_status

Revision ID: a3f7b9c2d5e8
Revises: f6c3a9d1e7b2
Create Date: 2026-07-19 00:00:00.000000

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = 'a3f7b9c2d5e8'
down_revision: Union[str, None] = 'f6c3a9d1e7b2'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


license_status = sa.Enum('licensed', 'pending', 'not_applicable', name='licensestatus')


def upgrade() -> None:
    license_status.create(op.get_bind(), checkfirst=True)
    op.add_column(
        'listings',
        sa.Column('license_status', license_status, nullable=False, server_default='pending'),
    )


def downgrade() -> None:
    op.drop_column('listings', 'license_status')
    license_status.drop(op.get_bind(), checkfirst=True)
