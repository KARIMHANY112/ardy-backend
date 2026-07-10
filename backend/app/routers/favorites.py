from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.core.deps import get_current_user
from app.models.models import Favorite, Listing, ListingStatus, User
from app.schemas.schemas import FavoriteOut

router = APIRouter(prefix="/favorites", tags=["favorites"])


@router.get("", response_model=list[FavoriteOut])
def list_favorites(db: Session = Depends(get_db), current_user: User = Depends(get_current_user)):
    return db.query(Favorite).filter(Favorite.user_id == current_user.id).all()


@router.post("/{listing_id}", response_model=FavoriteOut)
def add_favorite(listing_id: str, db: Session = Depends(get_db), current_user: User = Depends(get_current_user)):
    listing = db.query(Listing).filter(Listing.id == listing_id, Listing.status == ListingStatus.live).first()
    if not listing:
        raise HTTPException(status_code=404, detail="Listing not found")

    existing = db.query(Favorite).filter(
        Favorite.user_id == current_user.id, Favorite.listing_id == listing_id
    ).first()
    if existing:
        return existing

    favorite = Favorite(user_id=current_user.id, listing_id=listing_id)
    db.add(favorite)
    db.commit()
    db.refresh(favorite)
    return favorite


@router.delete("/{listing_id}")
def remove_favorite(listing_id: str, db: Session = Depends(get_db), current_user: User = Depends(get_current_user)):
    favorite = db.query(Favorite).filter(
        Favorite.user_id == current_user.id, Favorite.listing_id == listing_id
    ).first()
    if favorite:
        db.delete(favorite)
        db.commit()
    return {"ok": True}
