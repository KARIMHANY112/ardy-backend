import random
from datetime import datetime, timezone

from cloudinary.exceptions import Error as CloudinaryError
from fastapi import APIRouter, BackgroundTasks, Depends, File, HTTPException, UploadFile
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.core.deps import get_current_user, require_owner, require_buyer
from app.core.notifications import send_push_notification
from app.core.storage import upload_listing_photo
from app.models.models import BuyRequest, BuyRequestStatus, Listing, ListingStatus, User
from app.routers.advisor import embed_and_store_listing
from app.schemas.schemas import (
    BuyRequestDashboardOut,
    BuyRequestOut,
    BuyRequestReviewAction,
    ListingCreate,
    ListingOut,
    ListingDashboardOut,
    ListingSaleAction,
)

router = APIRouter(prefix="/listings", tags=["listings"])


def generate_ref_code(db: Session) -> str:
    """Generates a deed-style reference like REF-0142. Retries on collision."""
    while True:
        code = f"REF-{random.randint(1000, 9999)}"
        if not db.query(Listing).filter(Listing.ref_code == code).first():
            return code


_BROWSABLE_STATUSES = [ListingStatus.live, ListingStatus.papers_pending]


@router.get("", response_model=list[ListingOut])
def browse_listings(db: Session = Depends(get_db)):
    """Public browse — live listings, plus papers-pending ones so a listing with a
    deal in progress stays visible (as reserved) instead of vanishing from the feed."""
    return db.query(Listing).filter(Listing.status.in_(_BROWSABLE_STATUSES)).all()


@router.get("/{listing_id}", response_model=ListingOut)
def get_listing(listing_id: str, db: Session = Depends(get_db)):
    listing = db.query(Listing).filter(Listing.id == listing_id, Listing.status.in_(_BROWSABLE_STATUSES)).first()
    if not listing:
        raise HTTPException(status_code=404, detail="Listing not found")
    return listing


@router.post("", response_model=ListingOut)
def submit_listing_request(
    payload: ListingCreate,
    background_tasks: BackgroundTasks,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_buyer),
):
    """User submits a listing — goes live immediately, same as an owner-posted listing."""
    listing = Listing(
        ref_code=generate_ref_code(db),
        submitted_by=current_user.id,
        status=ListingStatus.live,
        **payload.model_dump(),
    )
    db.add(listing)
    db.commit()
    db.refresh(listing)

    background_tasks.add_task(embed_and_store_listing, listing.id)

    return listing


@router.post("/{listing_id}/photos", response_model=ListingOut)
def upload_listing_photo_endpoint(
    listing_id: str,
    file: UploadFile = File(...),
    db: Session = Depends(get_db),
    current_user: User = Depends(require_buyer),
):
    """User adds a photo to their own listing (works regardless of pending/live/rejected status)."""
    listing = db.query(Listing).filter(Listing.id == listing_id, Listing.submitted_by == current_user.id).first()
    if not listing:
        raise HTTPException(status_code=404, detail="Listing not found")

    try:
        url = upload_listing_photo(file.file, listing_id)
    except CloudinaryError as exc:
        raise HTTPException(status_code=502, detail=f"Photo upload failed: {exc}") from exc

    listing.photo_urls = [*listing.photo_urls, url]
    db.commit()
    db.refresh(listing)
    return listing


@router.get("/mine/requests", response_model=list[ListingOut])
def my_requests(db: Session = Depends(get_db), current_user: User = Depends(require_buyer)):
    """A user checking on the status of their own submitted listing requests."""
    return db.query(Listing).filter(Listing.submitted_by == current_user.id).all()


@router.post("/{listing_id}/buy-request", response_model=BuyRequestOut)
def request_to_buy(listing_id: str, db: Session = Depends(get_db), current_user: User = Depends(get_current_user)):
    """Buyer expresses interest in a listing — the owner follows up and closes the deal by phone.
    Only an active pending request is idempotently returned. A rejected request (lost to another
    buyer) doesn't block trying again — and neither does a stray approved one: since this listing
    is live, any approved request found for it is necessarily stale (approval always moves a
    listing off live), e.g. left over from before revert-to-live also reset it."""
    listing = db.query(Listing).filter(Listing.id == listing_id, Listing.status == ListingStatus.live).first()
    if not listing:
        raise HTTPException(status_code=404, detail="Listing not found")

    existing = db.query(BuyRequest).filter(
        BuyRequest.user_id == current_user.id,
        BuyRequest.listing_id == listing_id,
        BuyRequest.status == BuyRequestStatus.pending,
    ).first()
    if existing:
        return existing

    buy_request = BuyRequest(user_id=current_user.id, listing_id=listing_id, status=BuyRequestStatus.pending)
    db.add(buy_request)
    db.commit()
    db.refresh(buy_request)
    return buy_request


@router.get("/mine/buy-requests", response_model=list[BuyRequestOut])
def my_buy_requests(db: Session = Depends(get_db), current_user: User = Depends(get_current_user)):
    """A buyer checking which listings they've requested to buy."""
    return db.query(BuyRequest).filter(BuyRequest.user_id == current_user.id).all()


# ---- Owner dashboard endpoints ----

@router.post("/dashboard", response_model=ListingDashboardOut)
def create_listing_as_owner(
    payload: ListingCreate,
    background_tasks: BackgroundTasks,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_owner),
):
    """Owner posts a listing directly — goes live immediately, same as a buyer submission."""
    listing = Listing(
        ref_code=generate_ref_code(db),
        submitted_by=current_user.id,
        status=ListingStatus.live,
        reviewed_by=current_user.id,
        reviewed_at=datetime.now(timezone.utc),
        **payload.model_dump(),
    )
    db.add(listing)
    db.commit()
    db.refresh(listing)

    background_tasks.add_task(embed_and_store_listing, listing.id)

    return listing


@router.post("/dashboard/{listing_id}/photos", response_model=ListingDashboardOut)
def upload_listing_photo_as_owner(
    listing_id: str,
    file: UploadFile = File(...),
    db: Session = Depends(get_db),
    current_user: User = Depends(require_owner),
):
    listing = db.query(Listing).filter(Listing.id == listing_id).first()
    if not listing:
        raise HTTPException(status_code=404, detail="Listing not found")

    try:
        url = upload_listing_photo(file.file, listing_id)
    except CloudinaryError as exc:
        raise HTTPException(status_code=502, detail=f"Photo upload failed: {exc}") from exc

    listing.photo_urls = [*listing.photo_urls, url]
    db.commit()
    db.refresh(listing)
    return listing


@router.get("/dashboard/sold", response_model=list[ListingDashboardOut])
def sold_listings(db: Session = Depends(get_db), current_user: User = Depends(require_owner)):
    return db.query(Listing).filter(Listing.status == ListingStatus.sold).order_by(Listing.sold_at.desc()).all()


@router.get("/dashboard/papers-pending", response_model=list[ListingDashboardOut])
def papers_pending_listings(db: Session = Depends(get_db), current_user: User = Depends(require_owner)):
    return (
        db.query(Listing)
        .filter(Listing.status == ListingStatus.papers_pending)
        .order_by(Listing.created_at.desc())
        .all()
    )


@router.get("/dashboard/buy-requests", response_model=list[BuyRequestDashboardOut])
def buy_requests_dashboard(db: Session = Depends(get_db), current_user: User = Depends(require_owner)):
    """Pending buy requests across all listings, newest first — owner approves or rejects
    before following up with the buyer by phone."""
    return (
        db.query(BuyRequest)
        .filter(BuyRequest.status == BuyRequestStatus.pending)
        .order_by(BuyRequest.created_at.desc())
        .all()
    )


@router.post("/buy-requests/{request_id}/review", response_model=BuyRequestDashboardOut)
def review_buy_request(
    request_id: str,
    payload: BuyRequestReviewAction,
    background_tasks: BackgroundTasks,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_owner),
):
    """Owner approves or rejects a buyer's interest in a listing. Approving moves the
    listing to papers-pending at its asking price (the actual negotiation happens over
    the phone before the owner clicks approve) — it's not sold until the registration
    paperwork is finalized via POST /listings/{id}/finalize-sale."""
    buy_request = db.query(BuyRequest).filter(BuyRequest.id == request_id).first()
    if not buy_request:
        raise HTTPException(status_code=404, detail="Buy request not found")

    if payload.approve and buy_request.listing.status != ListingStatus.live:
        raise HTTPException(status_code=400, detail="Listing is no longer live")

    buy_request.status = BuyRequestStatus.approved if payload.approve else BuyRequestStatus.rejected
    buy_request.reviewed_by = current_user.id
    buy_request.reviewed_at = datetime.now(timezone.utc)

    other_pending_requests = []
    if payload.approve:
        listing = buy_request.listing
        listing.status = ListingStatus.papers_pending
        listing.sold_price = listing.price
        listing.sold_to_name = buy_request.buyer_name
        listing.sold_to_phone = buy_request.buyer_phone
        # sold_at stays unset until finalize-sale — papers-pending isn't a closed deal yet.

        # Any other buyers who requested this same listing are moot now — auto-reject them
        # rather than leaving them pending against a listing that's no longer live.
        other_pending_requests = (
            db.query(BuyRequest)
            .filter(
                BuyRequest.listing_id == buy_request.listing_id,
                BuyRequest.id != buy_request.id,
                BuyRequest.status == BuyRequestStatus.pending,
            )
            .all()
        )
        for other in other_pending_requests:
            other.status = BuyRequestStatus.rejected
            other.reviewed_by = current_user.id
            other.reviewed_at = datetime.now(timezone.utc)

    db.commit()
    db.refresh(buy_request)

    background_tasks.add_task(
        send_push_notification,
        buy_request.user,
        "Buy request approved" if payload.approve else "Buy request rejected",
        f"Your request to buy {buy_request.listing.ref_code} was "
        + ("approved. The owner will follow up to finalize the registration paperwork." if payload.approve else "not approved."),
    )

    for other in other_pending_requests:
        background_tasks.add_task(
            send_push_notification,
            other.user,
            "Buy request rejected",
            f"Your request to buy {other.listing.ref_code} was not approved — the listing went to another buyer.",
        )

    if payload.approve:
        background_tasks.add_task(
            send_push_notification,
            buy_request.listing.submitted_by_user,
            "Papers pending",
            f"Your listing {buy_request.listing.ref_code} has a buyer — papers are now pending before the sale is finalized.",
        )

    return buy_request


@router.post("/{listing_id}/papers-pending", response_model=ListingDashboardOut)
def mark_listing_papers_pending(
    listing_id: str,
    payload: ListingSaleAction,
    background_tasks: BackgroundTasks,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_owner),
):
    """Owner records a deal agreed by phone (no in-app buy request involved) — moves
    the listing to papers-pending, not straight to sold, same as an approved buy
    request. Finalized later via POST /listings/{id}/finalize-sale."""
    listing = db.query(Listing).filter(Listing.id == listing_id).first()
    if not listing:
        raise HTTPException(status_code=404, detail="Listing not found")
    if listing.status != ListingStatus.live:
        raise HTTPException(status_code=400, detail="Only live listings can be moved to papers pending")

    listing.status = ListingStatus.papers_pending
    listing.sold_price = payload.sold_price
    listing.sold_to_name = payload.sold_to_name
    listing.sold_to_phone = payload.sold_to_phone
    db.commit()
    db.refresh(listing)

    background_tasks.add_task(
        send_push_notification,
        listing.submitted_by_user,
        "Papers pending",
        f"Your listing {listing.ref_code} has a buyer — papers are now pending before the sale is finalized.",
    )

    return listing


@router.post("/{listing_id}/finalize-sale", response_model=ListingDashboardOut)
def finalize_sale(
    listing_id: str,
    background_tasks: BackgroundTasks,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_owner),
):
    """Owner confirms the registration paperwork is done — the sale is now 100% closed."""
    listing = db.query(Listing).filter(Listing.id == listing_id).first()
    if not listing:
        raise HTTPException(status_code=404, detail="Listing not found")
    if listing.status != ListingStatus.papers_pending:
        raise HTTPException(status_code=400, detail="Only listings with papers pending can be finalized")

    listing.status = ListingStatus.sold
    listing.sold_at = datetime.now(timezone.utc)
    db.commit()
    db.refresh(listing)

    background_tasks.add_task(
        send_push_notification,
        listing.submitted_by_user,
        "Listing sold",
        f"Your listing {listing.ref_code} sale is finalized.",
    )

    return listing


@router.post("/{listing_id}/revert-to-live", response_model=ListingDashboardOut)
def revert_papers_pending_to_live(
    listing_id: str,
    background_tasks: BackgroundTasks,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_owner),
):
    """Owner reports the deal fell through during paperwork — listing goes back on
    the market. Doesn't resurrect any buy requests that were auto-rejected when the
    listing first moved to papers-pending; interested buyers need to request again.
    The buy request that got the listing to papers-pending in the first place (if
    any) is reset from approved to rejected — otherwise it would keep showing as
    "Bought" for that buyer if the listing later sells to someone else."""
    listing = db.query(Listing).filter(Listing.id == listing_id).first()
    if not listing:
        raise HTTPException(status_code=404, detail="Listing not found")
    if listing.status != ListingStatus.papers_pending:
        raise HTTPException(status_code=400, detail="Only listings with papers pending can be reverted")

    stale_approved_requests = (
        db.query(BuyRequest)
        .filter(BuyRequest.listing_id == listing_id, BuyRequest.status == BuyRequestStatus.approved)
        .all()
    )
    for request in stale_approved_requests:
        request.status = BuyRequestStatus.rejected
        request.reviewed_by = current_user.id
        request.reviewed_at = datetime.now(timezone.utc)

    listing.status = ListingStatus.live
    listing.sold_price = None
    listing.sold_to_name = None
    listing.sold_to_phone = None
    db.commit()
    db.refresh(listing)

    for request in stale_approved_requests:
        background_tasks.add_task(
            send_push_notification,
            request.user,
            "Deal fell through",
            f"The sale for {listing.ref_code} fell through — it's back on the market.",
        )

    background_tasks.add_task(
        send_push_notification,
        listing.submitted_by_user,
        "Listing back on the market",
        f"The deal for {listing.ref_code} fell through — it's live again.",
    )

    return listing
