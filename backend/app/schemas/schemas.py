import uuid
from datetime import datetime
from typing import Optional

from pydantic import BaseModel, EmailStr

from app.models.models import UserRole, UserStatus, ListingStatus, BuyRequestStatus, LicenseStatus


# ---- Auth ----

class UserCreate(BaseModel):
    name: str
    phone: str
    email: EmailStr
    password: str
    # No role field — every signup is a buyer (who can also list). Owner accounts
    # are created manually, not via signup.


class UserOut(BaseModel):
    id: uuid.UUID
    name: str
    phone: str
    email: EmailStr
    role: UserRole
    status: UserStatus

    class Config:
        from_attributes = True


class Token(BaseModel):
    access_token: str
    token_type: str = "bearer"
    user: UserOut


class FcmTokenUpdate(BaseModel):
    fcm_token: str


class UserReviewAction(BaseModel):
    approve: bool  # true = approve, false = reject


class ForgotPasswordRequest(BaseModel):
    email: EmailStr


class ResetPasswordRequest(BaseModel):
    email: EmailStr
    code: str
    new_password: str


# ---- Listings ----

class ListingCreate(BaseModel):
    title: str
    type: str
    price: float
    size: float
    location: str
    description: Optional[str] = None
    latitude: Optional[float] = None
    longitude: Optional[float] = None
    license_status: LicenseStatus = LicenseStatus.pending


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
    license_status: LicenseStatus
    photo_urls: list[str]
    created_at: datetime
    latitude: Optional[float] = None
    longitude: Optional[float] = None
    sold_price: Optional[float] = None
    sold_to_name: Optional[str] = None
    sold_to_phone: Optional[str] = None
    sold_at: Optional[datetime] = None

    class Config:
        from_attributes = True


class ListingSaleAction(BaseModel):
    sold_price: float
    sold_to_name: str
    sold_to_phone: str


class ListingDashboardOut(ListingOut):
    """ListingOut plus the seller's contact info — owner-dashboard endpoints only.
    Never used for the public browse/get endpoints, which stay seller-anonymous."""
    submitted_by_name: str
    submitted_by_phone: str


# ---- Favorites ----

class FavoriteOut(BaseModel):
    id: uuid.UUID
    listing: ListingOut
    saved_at: datetime

    class Config:
        from_attributes = True


# ---- Buy requests ----

class BuyRequestOut(BaseModel):
    id: uuid.UUID
    listing: ListingOut
    status: BuyRequestStatus
    created_at: datetime

    class Config:
        from_attributes = True


class BuyRequestDashboardOut(BaseModel):
    """BuyRequestOut plus the buyer's contact info — owner-dashboard endpoint only."""
    id: uuid.UUID
    listing: ListingDashboardOut
    buyer_name: str
    buyer_phone: str
    status: BuyRequestStatus
    created_at: datetime

    class Config:
        from_attributes = True


class BuyRequestReviewAction(BaseModel):
    approve: bool  # true = approve, false = reject


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
