"""add listing contact_phone

The number the seller types on the "List your property" form, so the admin can
call them to verify the property before approving. Admin-only: it's exposed by
the owner-dashboard schema and never by the public listing endpoints.

Nullable — listings created before this (and ones the owner posts directly)
don't have one.

Revision ID: a9c4e2f7b1d3
Revises: e5b2c7d9f1a3
Create Date: 2026-11-09 00:00:00.000000

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = 'a9c4e2f7b1d3'
down_revision: Union[str, None] = 'e5b2c7d9f1a3'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.add_column('listings', sa.Column('contact_phone', sa.String(), nullable=True))


def downgrade() -> None:
    op.drop_column('listings', 'contact_phone')
