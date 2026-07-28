import uuid
from datetime import datetime
from typing import Optional

from pydantic import BaseModel, EmailStr, model_validator

from app.models.models import (
    UserRole,
    UserStatus,
    ListingStatus,
    BuyRequestStatus,
    LicenseStatus,
    OfferType,
    RentPeriod,
)


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
    # Required, no default — every listing has to say whether it's for sale, for rent
    # or a resale.
    offer_type: OfferType
    price: float
    # What the price is charged per — mandatory on rentals, rejected on sales, so a
    # rent figure is never ambiguous between monthly and yearly.
    rent_period: Optional[RentPeriod] = None
    size: float
    location: str
    description: Optional[str] = None
    latitude: Optional[float] = None
    longitude: Optional[float] = None
    license_status: LicenseStatus = LicenseStatus.pending

    @model_validator(mode="after")
    def check_rent_period(self):
        if self.offer_type is OfferType.rent and self.rent_period is None:
            raise ValueError("rent_period is required when offer_type is rent")
        if self.offer_type is not OfferType.rent and self.rent_period is not None:
            raise ValueError("rent_period only applies when offer_type is rent")
        return self


class ListingOut(BaseModel):
    id: uuid.UUID
    ref_code: str
    title: str
    type: str
    offer_type: OfferType
    price: float
    rent_period: Optional[RentPeriod] = None
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


class ListingUpdate(BaseModel):
    """Partial edit — only the fields present in the request body change. The
    offer_type/rent_period invariant can't be checked here the way ListingCreate
    does it, since a partial payload can't see the listing's current values; the
    router validates the merged result instead (see listings.resolve_offer_fields)."""
    title: Optional[str] = None
    type: Optional[str] = None
    offer_type: Optional[OfferType] = None
    rent_period: Optional[RentPeriod] = None
    price: Optional[float] = None
    size: Optional[float] = None
    location: Optional[str] = None
    description: Optional[str] = None
    latitude: Optional[float] = None
    longitude: Optional[float] = None
    license_status: Optional[LicenseStatus] = None


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
