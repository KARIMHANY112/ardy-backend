from fastapi import Depends, HTTPException, status
from fastapi.security import OAuth2PasswordBearer
from sqlalchemy.orm import Session
from jose import JWTError

from app.core.database import get_db
from app.core.security import decode_access_token
from app.models.models import User, UserRole

oauth2_scheme = OAuth2PasswordBearer(tokenUrl="auth/login")
# Same scheme, but doesn't 401 when the Authorization header is missing — used by
# endpoints that are open to anonymous callers yet want to link a logged-in user.
optional_oauth2_scheme = OAuth2PasswordBearer(tokenUrl="auth/login", auto_error=False)


def get_current_user(token: str = Depends(oauth2_scheme), db: Session = Depends(get_db)) -> User:
    credentials_error = HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail="Could not validate credentials",
        headers={"WWW-Authenticate": "Bearer"},
    )
    try:
        payload = decode_access_token(token)
        user_id = payload.get("sub")
        if user_id is None:
            raise credentials_error
    except JWTError:
        raise credentials_error

    user = db.query(User).filter(User.id == user_id).first()
    if user is None:
        raise credentials_error
    return user


def get_optional_user(
    token: str | None = Depends(optional_oauth2_scheme), db: Session = Depends(get_db)
) -> User | None:
    """Returns the authenticated user if a valid token is present, else None.
    Never raises — anonymous callers are allowed through."""
    if not token:
        return None
    try:
        payload = decode_access_token(token)
        user_id = payload.get("sub")
        if user_id is None:
            return None
    except JWTError:
        return None
    return db.query(User).filter(User.id == user_id).first()


def require_owner(current_user: User = Depends(get_current_user)) -> User:
    """Guard for dashboard endpoints — only the app owner can review listings."""
    if current_user.role != UserRole.owner:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Owner access only")
    return current_user


def require_seller(current_user: User = Depends(get_current_user)) -> User:
    if current_user.role != UserRole.seller:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Seller access only")
    return current_user
