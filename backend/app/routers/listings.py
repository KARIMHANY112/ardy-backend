import random
from datetime import datetime, timezone

from cloudinary.exceptions import Error as CloudinaryError
from fastapi import APIRouter, BackgroundTasks, Depends, File, HTTPException, UploadFile
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.core.deps import require_owner, require_seller
from app.core.notifications import send_push_notification
from app.core.storage import upload_listing_photo
from app.models.models import Listing, ListingStatus, User
from app.routers.advisor import embed_and_store_listing
from app.schemas.schemas import ListingCreate, ListingOut, ListingReviewAction

router = APIRouter(prefix="/listings", tags=["listings"])


def generate_ref_code(db: Session) -> str:
    """Generates a deed-style reference like REF-0142. Retries on collision."""
    while True:
        code = f"REF-{random.randint(1000, 9999)}"
        if not db.query(Listing).filter(Listing.ref_code == code).first():
            return code


@router.get("", response_model=list[ListingOut])
def browse_listings(db: Session = Depends(get_db)):
    """Public browse — buyers only ever see approved, live listings."""
    return db.query(Listing).filter(Listing.status == ListingStatus.live).all()


@router.get("/{listing_id}", response_model=ListingOut)
def get_listing(listing_id: str, db: Session = Depends(get_db)):
    listing = db.query(Listing).filter(Listing.id == listing_id, Listing.status == ListingStatus.live).first()
    if not listing:
        raise HTTPException(status_code=404, detail="Listing not found")
    return listing


@router.post("", response_model=ListingOut)
def submit_listing_request(
    payload: ListingCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_seller),
):
    """Seller submits a request — goes in as 'pending' until the owner approves it."""
    listing = Listing(
        ref_code=generate_ref_code(db),
        submitted_by=current_user.id,
        status=ListingStatus.pending,
        **payload.model_dump(),
    )
    db.add(listing)
    db.commit()
    db.refresh(listing)
    return listing


@router.post("/{listing_id}/photos", response_model=ListingOut)
def upload_listing_photo_endpoint(
    listing_id: str,
    file: UploadFile = File(...),
    db: Session = Depends(get_db),
    current_user: User = Depends(require_seller),
):
    """Seller adds a photo to their own listing (works regardless of pending/live/rejected status)."""
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
def my_requests(db: Session = Depends(get_db), current_user: User = Depends(require_seller)):
    """A seller checking on the status of their own submitted requests."""
    return db.query(Listing).filter(Listing.submitted_by == current_user.id).all()


# ---- Owner dashboard endpoints ----

@router.get("/dashboard/pending", response_model=list[ListingOut])
def pending_requests(db: Session = Depends(get_db), current_user: User = Depends(require_owner)):
    return db.query(Listing).filter(Listing.status == ListingStatus.pending).all()


@router.post("/{listing_id}/review", response_model=ListingOut)
def review_listing(
    listing_id: str,
    payload: ListingReviewAction,
    background_tasks: BackgroundTasks,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_owner),
):
    """Simple approve/reject — the actual conversation happens over the phone call."""
    listing = db.query(Listing).filter(Listing.id == listing_id).first()
    if not listing:
        raise HTTPException(status_code=404, detail="Listing not found")

    listing.status = ListingStatus.live if payload.approve else ListingStatus.rejected
    listing.reviewed_by = current_user.id
    listing.reviewed_at = datetime.now(timezone.utc)
    db.commit()
    db.refresh(listing)

    if payload.approve:
        # Runs after the response is sent; `db` stays open until this finishes (FastAPI >=0.106).
        background_tasks.add_task(embed_and_store_listing, listing, db)

    background_tasks.add_task(
        send_push_notification,
        listing.submitted_by_user,
        "Listing approved" if payload.approve else "Listing rejected",
        f"Your listing {listing.ref_code} was "
        + ("approved and is now live." if payload.approve else "rejected."),
    )

    return listing
