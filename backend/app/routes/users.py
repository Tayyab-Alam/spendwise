from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from app.dependencies.auth import get_current_user
from app.dependencies.db import get_db
from app.models.user import User
from app.schemas.user_schema import UserResponse, UserUpdate
from app.crud import user as user_crud

router = APIRouter()


# ============================================================
# GET /users/me
# ============================================================

@router.get(
    "/me",
    response_model=UserResponse,
    summary="Get current user profile",
)
def get_me(current_user: User = Depends(get_current_user)):
    """
    Get the profile of the currently authenticated user.
    
    Requires: `Authorization: Bearer <token>`
    """
    return current_user


# ============================================================
# PUT /users/me
# ============================================================

@router.put(
    "/me",
    response_model=UserResponse,
    summary="Update current user profile",
)
def update_me(
    update_data: UserUpdate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """
    Update the authenticated user's name and/or email.
    
    Requires: `Authorization: Bearer <token>`
    """
    return user_crud.update_user(
        db,
        current_user,
        name=update_data.name,
        email=update_data.email,
    )