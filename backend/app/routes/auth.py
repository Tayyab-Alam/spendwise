from fastapi import APIRouter, Depends, status
from sqlalchemy.orm import Session

from app.dependencies.db import get_db
from app.schemas.user_schema import (
    TokenResponse,
    UserLogin,
    UserRegister,
    UserResponse,
)
from app.services import auth_service

router = APIRouter()


# ============================================================
# REGISTER
# ============================================================

@router.post(
    "/register",
    response_model=UserResponse,
    status_code=status.HTTP_201_CREATED,
    summary="Register a new user",
)
def register(
    user_data: UserRegister,
    db: Session = Depends(get_db),
):
    """
    Register a new user with name, email, and password.
    
    - **name**: User's full name (1-100 chars)
    - **email**: Valid and unique email
    - **password**: At least 8 characters
    
    Returns the created user (without password).
    """
    return auth_service.register_user(db, user_data)


# ============================================================
# LOGIN
# ============================================================

@router.post(
    "/login",
    response_model=TokenResponse,
    summary="Login and get JWT token",
)
def login(
    credentials: UserLogin,
    db: Session = Depends(get_db),
):
    """
    Login with email and password.
    
    Returns a JWT access token (valid for 60 minutes by default).
    Use it in the `Authorization: Bearer <token>` header for protected routes.
    """
    return auth_service.login_user(db, credentials)