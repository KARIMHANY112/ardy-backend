"""add advisor conversations and chat messages

Revision ID: d4f1a2b3c5e6
Revises: ca80c49577df
Create Date: 2026-07-11 00:00:00.000000

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects import postgresql


# revision identifiers, used by Alembic.
revision: str = 'd4f1a2b3c5e6'
down_revision: Union[str, None] = 'ca80c49577df'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.create_table(
        'conversations',
        sa.Column('id', sa.UUID(), nullable=False),
        sa.Column('user_id', sa.UUID(), nullable=True),
        sa.Column('preferences', postgresql.JSONB(astext_type=sa.Text()),
                  server_default=sa.text("'{}'::jsonb"), nullable=False),
        sa.Column('created_at', sa.DateTime(timezone=True), server_default=sa.text('now()'), nullable=True),
        sa.Column('updated_at', sa.DateTime(timezone=True), server_default=sa.text('now()'), nullable=True),
        sa.ForeignKeyConstraint(['user_id'], ['users.id'], ),
        sa.PrimaryKeyConstraint('id'),
    )
    op.create_table(
        'chat_messages',
        sa.Column('id', sa.UUID(), nullable=False),
        sa.Column('conversation_id', sa.UUID(), nullable=False),
        sa.Column('role', sa.Enum('user', 'assistant', name='messagerole'), nullable=False),
        sa.Column('content', sa.String(), nullable=False),
        sa.Column('created_at', sa.DateTime(timezone=True), server_default=sa.text('now()'), nullable=True),
        sa.ForeignKeyConstraint(['conversation_id'], ['conversations.id'], ),
        sa.PrimaryKeyConstraint('id'),
    )
    op.create_index('ix_chat_messages_conversation_id', 'chat_messages', ['conversation_id'])


def downgrade() -> None:
    op.drop_index('ix_chat_messages_conversation_id', table_name='chat_messages')
    op.drop_table('chat_messages')
    op.drop_table('conversations')
    sa.Enum(name='messagerole').drop(op.get_bind(), checkfirst=True)
