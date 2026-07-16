"""add user status

Revision ID: f3a1c8d2e4b7
Revises: d4f1a2b3c5e6
Create Date: 2026-07-12 00:00:00.000000

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = 'f3a1c8d2e4b7'
down_revision: Union[str, None] = 'd4f1a2b3c5e6'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


user_status = sa.Enum('pending', 'approved', 'rejected', name='userstatus')


def upgrade() -> None:
    user_status.create(op.get_bind(), checkfirst=True)
    op.add_column(
        'users',
        sa.Column('status', user_status, nullable=False, server_default='approved'),
    )
    op.add_column('users', sa.Column('reviewed_by', sa.dialects.postgresql.UUID(as_uuid=True), nullable=True))
    op.add_column('users', sa.Column('reviewed_at', sa.DateTime(timezone=True), nullable=True))
    op.create_foreign_key('fk_users_reviewed_by_users', 'users', 'users', ['reviewed_by'], ['id'])


def downgrade() -> None:
    op.drop_constraint('fk_users_reviewed_by_users', 'users', type_='foreignkey')
    op.drop_column('users', 'reviewed_at')
    op.drop_column('users', 'reviewed_by')
    op.drop_column('users', 'status')
    user_status.drop(op.get_bind(), checkfirst=True)
