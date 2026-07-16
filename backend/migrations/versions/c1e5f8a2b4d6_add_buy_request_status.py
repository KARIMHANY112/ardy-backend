"""add buy request status

Revision ID: c1e5f8a2b4d6
Revises: b7d2e9a4c6f1
Create Date: 2026-07-13 00:00:00.000000

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa
import sqlalchemy.dialects.postgresql


# revision identifiers, used by Alembic.
revision: str = 'c1e5f8a2b4d6'
down_revision: Union[str, None] = 'b7d2e9a4c6f1'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


buy_request_status = sa.Enum('pending', 'approved', 'rejected', name='buyrequeststatus')


def upgrade() -> None:
    buy_request_status.create(op.get_bind(), checkfirst=True)
    op.add_column(
        'buy_requests',
        sa.Column('status', buy_request_status, nullable=False, server_default='pending'),
    )
    op.add_column(
        'buy_requests',
        sa.Column('reviewed_by', sa.dialects.postgresql.UUID(as_uuid=True), sa.ForeignKey('users.id'), nullable=True),
    )
    op.add_column('buy_requests', sa.Column('reviewed_at', sa.DateTime(timezone=True), nullable=True))


def downgrade() -> None:
    op.drop_column('buy_requests', 'reviewed_at')
    op.drop_column('buy_requests', 'reviewed_by')
    op.drop_column('buy_requests', 'status')
    buy_request_status.drop(op.get_bind(), checkfirst=True)
