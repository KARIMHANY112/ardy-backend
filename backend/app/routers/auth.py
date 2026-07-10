from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.core.deps import get_current_user
from app.core.security import hash_password, verify_password, create_access_token
from app.models.models import User
from app.schemas.schemas import FcmTokenUpdate, UserCreate, UserLogin, Token, UserOut

router = APIRouter(prefix="/auth", tags=["auth"])


@router.post("/signup", response_model=Token)
def signup(payload: UserCreate, db: Session = Depends(get_db)):
    existing = db.query(User).filter(User.email == payload.email).first()
    if existing:
        raise HTTPException(status_code=400, detail="Email already registered")

    user = User(
        name=payload.name,
        phone=payload.phone,
        email=payload.email,
        password_hash=hash_password(payload.password),
        role=payload.role,
    )
    db.add(user)
    db.commit()
    db.refresh(user)

    token = create_access_token({"sub": str(user.id), "role": user.role.value})
    return Token(access_token=token, user=UserOut.model_validate(user))


@router.post("/me/fcm-token", response_model=UserOut)
def update_fcm_token(
    payload: FcmTokenUpdate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """Client registers its device token here (e.g. right after login) so it can receive push notifications."""
    current_user.fcm_token = payload.fcm_token
    db.commit()
    db.refresh(current_user)
    return current_user


@router.post("/login", response_model=Token)
def login(payload: UserLogin, db: Session = Depends(get_db)):
    user = db.query(User).filter(User.email == payload.email).first()
    if not user or not verify_password(payload.password, user.password_hash):
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid email or password")

    token = create_access_token({"sub": str(user.id), "role": user.role.value})
    return Token(access_token=token, user=UserOut.model_validate(user))
