import secrets
from datetime import datetime, timedelta, timezone

from fastapi import APIRouter, Depends, HTTPException, status
from fastapi.security import OAuth2PasswordRequestForm
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.core.deps import get_current_user
from app.core.email import send_password_reset_code
from app.core.security import hash_password, verify_password, create_access_token
from app.models.models import User, UserRole, UserStatus
from app.schemas.schemas import FcmTokenUpdate, ForgotPasswordRequest, ResetPasswordRequest, UserCreate, Token, UserOut

router = APIRouter(prefix="/auth", tags=["auth"])

RESET_CODE_TTL_MINUTES = 15


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
        role=UserRole.buyer,
        status=UserStatus.pending,
    )
    db.add(user)
    db.commit()
    db.refresh(user)

    token = create_access_token({"sub": str(user.id), "role": user.role.value})
    return Token(access_token=token, user=UserOut.model_validate(user))


@router.post("/forgot-password")
def forgot_password(payload: ForgotPasswordRequest, db: Session = Depends(get_db)):
    """Always returns the same response whether or not the email exists, so this
    endpoint can't be used to enumerate registered accounts."""
    user = db.query(User).filter(User.email == payload.email).first()
    if user:
        code = f"{secrets.randbelow(1_000_000):06d}"
        user.reset_code_hash = hash_password(code)
        user.reset_code_expires_at = datetime.now(timezone.utc) + timedelta(minutes=RESET_CODE_TTL_MINUTES)
        db.commit()
        send_password_reset_code(user.email, code)

    return {"message": "If that email is registered, a reset code has been sent."}


@router.post("/reset-password", response_model=Token)
def reset_password(payload: ResetPasswordRequest, db: Session = Depends(get_db)):
    user = db.query(User).filter(User.email == payload.email).first()
    invalid = HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Invalid or expired reset code")

    if not user or not user.reset_code_hash or not user.reset_code_expires_at:
        raise invalid
    if datetime.now(timezone.utc) > user.reset_code_expires_at:
        raise invalid
    if not verify_password(payload.code, user.reset_code_hash):
        raise invalid

    user.password_hash = hash_password(payload.new_password)
    user.reset_code_hash = None
    user.reset_code_expires_at = None
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
def login(form_data: OAuth2PasswordRequestForm = Depends(), db: Session = Depends(get_db)):
    # OAuth2PasswordRequestForm's "username" field is the user's email.
    user = db.query(User).filter(User.email == form_data.username).first()
    if not user or not verify_password(form_data.password, user.password_hash):
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid email or password")

    if user.status == UserStatus.pending:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Your account is pending owner approval")
    if user.status == UserStatus.rejected:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Your account was not approved")

    token = create_access_token({"sub": str(user.id), "role": user.role.value})
    return Token(access_token=token, user=UserOut.model_validate(user))
