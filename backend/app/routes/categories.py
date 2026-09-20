from typing import Literal

from fastapi import APIRouter, Depends, Query, status
from sqlalchemy.orm import Session

from app.dependencies.auth import get_current_user
from app.dependencies.db import get_db
from app.models.user import User
from app.schemas.category_schema import (
    CategoryCreate,
    CategoryResponse,
    CategoryUpdate,
)
from app.services import category_service

router = APIRouter()


# ============================================================
# LIST CATEGORIES
# ============================================================

@router.get(
    "",
    response_model=list[CategoryResponse],
    summary="List all categories for current user",
)
def list_categories(
    type_filter: Literal["income", "expense"] | None = Query(
        None, alias="type", description="Filter by category type"
    ),
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """
    List all categories available to the authenticated user.
    Includes both default categories and the user's custom categories.
    
    Requires: `Authorization: Bearer <token>`
    """
    return category_service.list_user_categories(
        db,
        user_id=current_user.id,
        type_filter=type_filter,
    )


# ============================================================
# CREATE CATEGORY
# ============================================================

@router.post(
    "",
    response_model=CategoryResponse,
    status_code=status.HTTP_201_CREATED,
    summary="Create a custom category",
)
def create_category(
    data: CategoryCreate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """
    Create a new custom category for the authenticated user.
    
    - **name**: Category name (1-50 chars)
    - **type**: Either `"income"` or `"expense"`
    
    Requires: `Authorization: Bearer <token>`
    """
    return category_service.create_custom_category(db, current_user.id, data)


# ============================================================
# GET ONE CATEGORY
# ============================================================

@router.get(
    "/{category_id}",
    response_model=CategoryResponse,
    summary="Get a single category",
)
def get_category(
    category_id: int,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """
    Get details of a specific category.
    
    Returns 404 if the category doesn't exist or doesn't belong to the user.
    
    Requires: `Authorization: Bearer <token>`
    """
    return category_service.get_category_for_user(db, current_user.id, category_id)


# ============================================================
# UPDATE CATEGORY
# ============================================================

@router.put(
    "/{category_id}",
    response_model=CategoryResponse,
    summary="Update a custom category",
)
def update_category(
    category_id: int,
    data: CategoryUpdate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """
    Update a custom category's name or active status.
    
    - Default categories cannot be modified (403)
    - Other users' categories return 404
    
    Requires: `Authorization: Bearer <token>`
    """
    return category_service.update_custom_category(
        db, current_user.id, category_id, data
    )


# ============================================================
# DELETE CATEGORY
# ============================================================

@router.delete(
    "/{category_id}",
    status_code=status.HTTP_204_NO_CONTENT,
    summary="Delete a custom category",
)
def delete_category(
    category_id: int,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """
    Delete a custom category.
    
    - Default categories cannot be deleted (403)
    - Other users' categories return 404
    - Returns 204 No Content on success
    
    Requires: `Authorization: Bearer <token>`
    """
    category_service.delete_custom_category(db, current_user.id, category_id)