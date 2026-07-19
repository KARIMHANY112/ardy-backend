import uuid
import enum

from sqlalchemy import Column, String, Float, ForeignKey, DateTime, Enum, func
from sqlalchemy.dialects.postgresql import ARRAY, JSONB, UUID
from sqlalchemy.orm import relationship
from pgvector.sqlalchemy import Vector

from app.core.database import Base


class UserRole(str, enum.Enum):
    buyer = "buyer"  # regular user — can browse/favorite listings and submit their own
    owner = "owner"  # the single app owner/admin


class UserStatus(str, enum.Enum):
    pending = "pending"    # signed up, awaiting owner review
    approved = "approved"  # can log in and use the app
    rejected = "rejected"  # signup denied


class ListingStatus(str, enum.Enum):
    pending = "pending"                 # seller submitted, awaiting owner review
    live = "live"                       # approved, visible to buyers
    papers_pending = "papers_pending"   # a buyer is confirmed but registration paperwork isn't done yet
    rejected = "rejected"
    sold = "sold"                       # papers finalized, deal fully closed


class BuyRequestStatus(str, enum.Enum):
    pending = "pending"    # buyer expressed interest, awaiting owner review
    approved = "approved"  # owner will follow up by phone to close the deal
    rejected = "rejected"


class User(Base):
    __tablename__ = "users"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    name = Column(String, nullable=False)
    phone = Column(String, nullable=False, unique=True)
    email = Column(String, nullable=False, unique=True)
    password_hash = Column(String, nullable=False)
    role = Column(Enum(UserRole), nullable=False, default=UserRole.buyer)
    fcm_token = Column(String, nullable=True)  # registered by the client for push notifications
    created_at = Column(DateTime(timezone=True), server_default=func.now())

    # Password reset — a short-lived hashed OTP the user re-enters in the app.
    # Hashed (like the password itself) so a DB read alone can't be used to reset the account.
    reset_code_hash = Column(String, nullable=True)
    reset_code_expires_at = Column(DateTime(timezone=True), nullable=True)

    # New signups start pending; existing rows are backfilled to approved by the migration
    # so current accounts aren't locked out.
    status = Column(Enum(UserStatus), nullable=False, default=UserStatus.pending, server_default=UserStatus.approved.value)
    reviewed_by = Column(UUID(as_uuid=True), ForeignKey("users.id"), nullable=True)
    reviewed_at = Column(DateTime(timezone=True), nullable=True)

    listings = relationship("Listing", back_populates="submitted_by_user", foreign_keys="Listing.submitted_by")
    favorites = relationship("Favorite", back_populates="user")


class Listing(Base):
    __tablename__ = "listings"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    ref_code = Column(String, unique=True, nullable=False)  # e.g. REF-0142

    submitted_by = Column(UUID(as_uuid=True), ForeignKey("users.id"), nullable=False)
    reviewed_by = Column(UUID(as_uuid=True), ForeignKey("users.id"), nullable=True)

    title = Column(String, nullable=False)
    type = Column(String, nullable=False)  # agricultural / residential / etc.
    price = Column(Float, nullable=False)
    size = Column(Float, nullable=False)   # in feddan or m^2
    location = Column(String, nullable=False)
    description = Column(String, nullable=True)

    # Precise map pin, set when the submitter drops one in the app. Nullable —
    # older listings and free-text-only submissions won't have one.
    latitude = Column(Float, nullable=True)
    longitude = Column(Float, nullable=True)

    status = Column(Enum(ListingStatus), nullable=False, default=ListingStatus.pending)

    # Set when the owner marks the listing sold — the deal itself is arranged by phone,
    # so these are just the record of what was agreed.
    sold_price = Column(Float, nullable=True)
    sold_to_name = Column(String, nullable=True)
    sold_to_phone = Column(String, nullable=True)
    sold_at = Column(DateTime(timezone=True), nullable=True)

    photo_urls = Column(ARRAY(String), nullable=False, default=list, server_default="{}")

    # One embedding vector per listing, used by the Land Advisor for similarity search.
    # 1536 dims matches OpenAI's text-embedding-3-small — adjust if you switch providers.
    embedding = Column(Vector(1536), nullable=True)

    created_at = Column(DateTime(timezone=True), server_default=func.now())
    reviewed_at = Column(DateTime(timezone=True), nullable=True)

    submitted_by_user = relationship("User", back_populates="listings", foreign_keys=[submitted_by])
    favorited_by = relationship("Favorite", back_populates="listing")

    @property
    def submitted_by_name(self) -> str:
        return self.submitted_by_user.name

    @property
    def submitted_by_phone(self) -> str:
        return self.submitted_by_user.phone


class MessageRole(str, enum.Enum):
    user = "user"
    assistant = "assistant"


class Conversation(Base):
    """A Land Advisor chat session. Anonymous buyers are identified by possession of
    the conversation id (an opaque UUID that acts as a lightweight session token);
    user_id is set only when a logged-in buyer is chatting."""
    __tablename__ = "conversations"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    user_id = Column(UUID(as_uuid=True), ForeignKey("users.id"), nullable=True)

    # Buyer preference profile accumulated across turns (budget, location, land type,
    # size range...). Used to bias/filter the pgvector similarity search on later turns.
    preferences = Column(JSONB, nullable=False, default=dict, server_default="{}")

    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), server_default=func.now(), onupdate=func.now())

    messages = relationship(
        "ChatMessage",
        back_populates="conversation",
        order_by="ChatMessage.created_at",
        cascade="all, delete-orphan",
    )


class ChatMessage(Base):
    __tablename__ = "chat_messages"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    conversation_id = Column(UUID(as_uuid=True), ForeignKey("conversations.id"), nullable=False)
    role = Column(Enum(MessageRole), nullable=False)
    content = Column(String, nullable=False)
    created_at = Column(DateTime(timezone=True), server_default=func.now())

    conversation = relationship("Conversation", back_populates="messages")


class Favorite(Base):
    __tablename__ = "favorites"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    user_id = Column(UUID(as_uuid=True), ForeignKey("users.id"), nullable=False)
    listing_id = Column(UUID(as_uuid=True), ForeignKey("listings.id"), nullable=False)
    saved_at = Column(DateTime(timezone=True), server_default=func.now())

    user = relationship("User", back_populates="favorites")
    listing = relationship("Listing", back_populates="favorited_by")


class BuyRequest(Base):
    """A buyer expressing interest in a listing — the owner follows up and
    closes the deal by phone/WhatsApp (see Listing.status == sold)."""
    __tablename__ = "buy_requests"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    user_id = Column(UUID(as_uuid=True), ForeignKey("users.id"), nullable=False)
    listing_id = Column(UUID(as_uuid=True), ForeignKey("listings.id"), nullable=False)
    created_at = Column(DateTime(timezone=True), server_default=func.now())

    status = Column(Enum(BuyRequestStatus), nullable=False, default=BuyRequestStatus.pending, server_default=BuyRequestStatus.pending.value)
    reviewed_by = Column(UUID(as_uuid=True), ForeignKey("users.id"), nullable=True)
    reviewed_at = Column(DateTime(timezone=True), nullable=True)

    user = relationship("User", foreign_keys=[user_id])
    listing = relationship("Listing")

    @property
    def buyer_name(self) -> str:
        return self.user.name

    @property
    def buyer_phone(self) -> str:
        return self.user.phone
