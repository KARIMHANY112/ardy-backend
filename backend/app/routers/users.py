from datetime import datetime, timezone

from fastapi import APIRouter, BackgroundTasks, Depends, HTTPException, Response, status
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.core.deps import get_current_user, require_owner
from app.core.notifications import send_push_notification
from app.models.models import (
    BuyRequest,
    ChatMessage,
    Conversation,
    Favorite,
    Listing,
    User,
    UserRole,
    UserStatus,
)
from app.schemas.schemas import UserOut, UserReviewAction

router = APIRouter(prefix="/users", tags=["users"])


# ---- Account self-service ----

@router.delete("/me", status_code=status.HTTP_204_NO_CONTENT)
def delete_my_account(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """Permanently delete the caller's account and everything attached to it.

    Google Play requires an in-app deletion path for any app that lets users
    create an account, and the Privacy Policy already promises one.

    No foreign key into `users` or `listings` is declared ON DELETE CASCADE, so
    every child row has to be removed explicitly and in dependency order — the
    final DELETE fails with a FK violation otherwise. Deleting a seller also
    takes their listings down with them, along with other users' favourites and
    buy requests against those listings, since a listing can't outlive its owner
    (`listings.submitted_by` is NOT NULL).
    """
    if current_user.role is UserRole.owner:
        # The owner account is the app's admin; deleting it would orphan the
        # dashboard and every listing on the platform.
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="The owner account cannot be deleted from the app",
        )

    user_id = current_user.id
    listing_ids = [row[0] for row in db.query(Listing.id).filter(Listing.submitted_by == user_id)]

    # 1. Rows other users hold against this user's listings.
    if listing_ids:
        db.query(Favorite).filter(Favorite.listing_id.in_(listing_ids)).delete(synchronize_session=False)
        db.query(BuyRequest).filter(BuyRequest.listing_id.in_(listing_ids)).delete(synchronize_session=False)

    # 2. This user's own activity.
    conversation_ids = [row[0] for row in db.query(Conversation.id).filter(Conversation.user_id == user_id)]
    if conversation_ids:
        db.query(ChatMessage).filter(ChatMessage.conversation_id.in_(conversation_ids)).delete(synchronize_session=False)
        db.query(Conversation).filter(Conversation.id.in_(conversation_ids)).delete(synchronize_session=False)
    db.query(Favorite).filter(Favorite.user_id == user_id).delete(synchronize_session=False)
    db.query(BuyRequest).filter(BuyRequest.user_id == user_id).delete(synchronize_session=False)

    # 3. The listings themselves, now that nothing points at them.
    if listing_ids:
        db.query(Listing).filter(Listing.id.in_(listing_ids)).delete(synchronize_session=False)

    # 4. Reviewer back-references are nullable — blank them rather than cascading.
    db.query(Listing).filter(Listing.reviewed_by == user_id).update({"reviewed_by": None}, synchronize_session=False)
    db.query(BuyRequest).filter(BuyRequest.reviewed_by == user_id).update({"reviewed_by": None}, synchronize_session=False)
    db.query(User).filter(User.reviewed_by == user_id).update({"reviewed_by": None}, synchronize_session=False)

    db.query(User).filter(User.id == user_id).delete(synchronize_session=False)
    db.commit()
    return Response(status_code=status.HTTP_204_NO_CONTENT)


# ---- Owner dashboard endpoints ----

@router.get("/dashboard/pending", response_model=list[UserOut])
def pending_buyers(db: Session = Depends(get_db), current_user: User = Depends(require_owner)):
    return db.query(User).filter(User.role == UserRole.buyer, User.status == UserStatus.pending).all()


@router.post("/{user_id}/review", response_model=UserOut)
def review_buyer(
    user_id: str,
    payload: UserReviewAction,
    background_tasks: BackgroundTasks,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_owner),
):
    """Simple approve/reject for a pending buyer signup."""
    user = db.query(User).filter(User.id == user_id, User.role == UserRole.buyer).first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")

    user.status = UserStatus.approved if payload.approve else UserStatus.rejected
    user.reviewed_by = current_user.id
    user.reviewed_at = datetime.now(timezone.utc)
    db.commit()
    db.refresh(user)

    background_tasks.add_task(
        send_push_notification,
        user,
        "Account approved" if payload.approve else "Account rejected",
        "Your account was approved and you can now log in."
        if payload.approve
        else "Your account was not approved.",
    )

    return user
