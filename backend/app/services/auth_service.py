from sqlalchemy.orm import Session

from app.core.exceptions import ConflictException, UnauthorizedException
from app.core.security import create_access_token, verify_password
from app.crud import user as user_crud
from app.models.user import User
from app.schemas.user_schema import TokenResponse, UserLogin, UserRegister


# ============================================================
# REGISTER
# ============================================================

def register_user(db: Session, user_data: UserRegister) -> User:
    """
    Register a new user.
    Raises ConflictException if email already exists.
    """
    # Check if email already exists
    existing_user = user_crud.get_user_by_email(db, user_data.email)
    if existing_user:
        raise ConflictException("Email is already registered")

    # Create user
    return user_crud.create_user(db, user_data)


# ============================================================
# LOGIN
# ============================================================

def authenticate_user(db: Session, credentials: UserLogin) -> User:
    """
    Authenticate a user with email + password.
    Raises UnauthorizedException if credentials are invalid.
    """
    user = user_crud.get_user_by_email(db, credentials.email)

    # User not found OR wrong password
    if not user or not verify_password(credentials.password, user.password_hash):
        # Same error message for both cases — don't leak which one failed
        raise UnauthorizedException("Invalid email or password")

    return user


def login_user(db: Session, credentials: UserLogin) -> TokenResponse:
    """
    Authenticate user and return JWT token.
    """
    user = authenticate_user(db, credentials)
    token = create_access_token(subject=user.id)
    return TokenResponse(access_token=token, token_type="bearer")