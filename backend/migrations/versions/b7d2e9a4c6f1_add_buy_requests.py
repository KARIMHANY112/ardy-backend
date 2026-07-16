"""add buy requests

Revision ID: b7d2e9a4c6f1
Revises: a9c4e7b1f2d3
Create Date: 2026-07-13 00:00:00.000000

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa
import sqlalchemy.dialects.postgresql


# revision identifiers, used by Alembic.
revision: str = 'b7d2e9a4c6f1'
down_revision: Union[str, None] = 'a9c4e7b1f2d3'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.create_table(
        'buy_requests',
        sa.Column('id', sa.dialects.postgresql.UUID(as_uuid=True), primary_key=True),
        sa.Column('user_id', sa.dialects.postgresql.UUID(as_uuid=True), sa.ForeignKey('users.id'), nullable=False),
        sa.Column('listing_id', sa.dialects.postgresql.UUID(as_uuid=True), sa.ForeignKey('listings.id'), nullable=False),
        sa.Column('created_at', sa.DateTime(timezone=True), server_default=sa.func.now()),
        sa.UniqueConstraint('user_id', 'listing_id', name='uq_buy_requests_user_listing'),
    )


def downgrade() -> None:
    op.drop_table('buy_requests')
