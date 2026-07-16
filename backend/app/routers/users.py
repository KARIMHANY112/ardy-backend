from datetime import datetime, timezone

from fastapi import APIRouter, BackgroundTasks, Depends, HTTPException
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.core.deps import require_owner
from app.core.notifications import send_push_notification
from app.models.models import User, UserRole, UserStatus
from app.schemas.schemas import UserOut, UserReviewAction

router = APIRouter(prefix="/users", tags=["users"])


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
