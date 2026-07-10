import uuid
from datetime import datetime
from typing import Optional

from pydantic import BaseModel, EmailStr

from app.models.models import UserRole, ListingStatus


# ---- Auth ----

class UserCreate(BaseModel):
    name: str
    phone: str
    email: EmailStr
    password: str
    role: UserRole  # buyer or seller — owner accounts are created manually, not via signup


class UserLogin(BaseModel):
    email: EmailStr
    password: str


class UserOut(BaseModel):
    id: uuid.UUID
    name: str
    phone: str
    email: EmailStr
    role: UserRole

    class Config:
        from_attributes = True


class Token(BaseModel):
    access_token: str
    token_type: str = "bearer"
    user: UserOut


class FcmTokenUpdate(BaseModel):
    fcm_token: str


# ---- Listings ----

class ListingCreate(BaseModel):
    title: str
    type: str
    price: float
    size: float
    location: str
    description: Optional[str] = None


class ListingOut(BaseModel):
    id: uuid.UUID
    ref_code: str
    title: str
    type: str
    price: float
    size: float
    location: str
    description: Optional[str]
    status: ListingStatus
    photo_urls: list[str]
    created_at: datetime

    class Config:
        from_attributes = True


class ListingReviewAction(BaseModel):
    approve: bool  # true = approve, false = reject — simple toggle, no reason field


# ---- Favorites ----

class FavoriteOut(BaseModel):
    id: uuid.UUID
    listing: ListingOut
    saved_at: datetime

    class Config:
        from_attributes = True


# ---- Land Advisor ----

class AdvisorQuery(BaseModel):
    message: str
    # Omit on the first turn; the server mints a conversation and returns its id.
    # Pass it back on later turns to continue the same conversation.
    conversation_id: Optional[uuid.UUID] = None


class AdvisorResponse(BaseModel):
    reply: str
    matches: list[ListingOut]
    conversation_id: uuid.UUID
    # The buyer profile the advisor has accumulated so far (budget, location, etc.).
    preferences: dict
