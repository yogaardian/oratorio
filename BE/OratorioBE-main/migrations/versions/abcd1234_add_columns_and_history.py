"""Add phone, dob, hometown to users and create history table

Revision ID: abcd1234
Revises: c10c36af1dda
Create Date: 2025-12-15 12:00:00.000000

"""
from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision = 'abcd1234'
down_revision = 'c10c36af1dda'
branch_labels = None
depends_on = None


def upgrade():
    # Add columns to users table
    op.add_column('Users', sa.Column('phone', sa.String(length=20), nullable=True))
    op.add_column('Users', sa.Column('dob', sa.Date(), nullable=True))
    op.add_column('Users', sa.Column('hometown', sa.String(length=100), nullable=True))
    op.add_column('Users', sa.Column('is_active', sa.Boolean(), nullable=False, default=True))

    # Create history table
    op.create_table('history',
        sa.Column('history_id', sa.Integer(), nullable=False),
        sa.Column('user_id', sa.Integer(), nullable=False),
        sa.Column('user_email', sa.String(length=120), nullable=False),
        sa.Column('destination_id', sa.Integer(), nullable=False),
        sa.Column('action', sa.String(length=50), nullable=False),
        sa.Column('model_type', sa.String(length=10), nullable=True),
        sa.Column('started_at', sa.DateTime(), nullable=False, default=sa.func.now()),
        sa.ForeignKeyConstraint(['user_id'], ['Users.id'], ),
        sa.PrimaryKeyConstraint('history_id')
    )


def downgrade():
    # Drop history table
    op.drop_table('history')

    # Drop columns from users
    op.drop_column('Users', 'hometown')
    op.drop_column('Users', 'dob')
    op.drop_column('Users', 'phone')
    op.drop_column('Users', 'is_active')