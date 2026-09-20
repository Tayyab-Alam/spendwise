from datetime import date as date_type
from typing import Literal

from fastapi import APIRouter, Depends, Query, status
from sqlalchemy.orm import Session

from app.dependencies.auth import get_current_user
from app.dependencies.db import get_db
from app.models.user import User
from app.schemas.transaction_schema import (
    TransactionCreate,
    TransactionResponse,
    TransactionUpdate,
)
from app.services import transaction_service

router = APIRouter()


# ============================================================
# LIST TRANSACTIONS (with filters)
# ============================================================

@router.get(
    "",
    response_model=list[TransactionResponse],
    summary="List transactions with filters",
)
def list_transactions(
    type_filter: Literal["income", "expense"] | None = Query(
        None, alias="type", description="Filter by transaction type"
    ),
    category_id: int | None = Query(None, description="Filter by category ID"),
    date_from: date_type | None = Query(None, description="Filter from date (inclusive)"),
    date_to: date_type | None = Query(None, description="Filter to date (inclusive)"),
    search: str | None = Query(None, max_length=255, description="Search in note"),
    sort_by: Literal["date", "amount"] = Query("date", description="Sort field"),
    sort_order: Literal["asc", "desc"] = Query("desc", description="Sort order"),
    skip: int = Query(0, ge=0, description="Pagination offset"),
    limit: int = Query(50, ge=1, le=100, description="Pagination limit"),
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """
    List transactions belonging to the authenticated user.
    
    Supports:
    - Filter by **type**, **category**, **date range**, **search** in note
    - Sort by **date** or **amount** (asc/desc)
    - Pagination via **skip** and **limit**
    
    Requires: `Authorization: Bearer <token>`
    """
    return transaction_service.list_user_transactions(
        db,
        user_id=current_user.id,
        type_filter=type_filter,
        category_id=category_id,
        date_from=date_from,
        date_to=date_to,
        search=search,
        sort_by=sort_by,
        sort_order=sort_order,
        skip=skip,
        limit=limit,
    )


# ============================================================
# CREATE TRANSACTION
# ============================================================

@router.post(
    "",
    response_model=TransactionResponse,
    status_code=status.HTTP_201_CREATED,
    summary="Create a transaction",
)
def create_transaction(
    data: TransactionCreate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """
    Create a new income or expense transaction.
    
    - **type**: `"income"` or `"expense"`
    - **amount**: Positive decimal (e.g., 500.50)
    - **category_id**: Must belong to user or be a default category
    - **date**: Transaction date
    - **note**: Optional description
    
    Requires: `Authorization: Bearer <token>`
    """
    return transaction_service.create_transaction(db, current_user.id, data)


# ============================================================
# GET ONE
# ============================================================

@router.get(
    "/{transaction_id}",
    response_model=TransactionResponse,
    summary="Get a single transaction",
)
def get_transaction(
    transaction_id: int,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """
    Get details of a specific transaction.
    
    Returns 404 if the transaction doesn't belong to the user.
    
    Requires: `Authorization: Bearer <token>`
    """
    return transaction_service.get_transaction_for_user(
        db, current_user.id, transaction_id
    )


# ============================================================
# UPDATE
# ============================================================

@router.put(
    "/{transaction_id}",
    response_model=TransactionResponse,
    summary="Update a transaction",
)
def update_transaction(
    transaction_id: int,
    data: TransactionUpdate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """
    Partially update a transaction.
    
    Only the fields you send will be updated.
    Category + type are re-validated if changed.
    
    Requires: `Authorization: Bearer <token>`
    """
    return transaction_service.update_transaction(
        db, current_user.id, transaction_id, data
    )


# ============================================================
# DELETE
# ============================================================

@router.delete(
    "/{transaction_id}",
    status_code=status.HTTP_204_NO_CONTENT,
    summary="Delete a transaction",
)
def delete_transaction(
    transaction_id: int,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """
    Delete a transaction.
    
    Returns 204 No Content on success.
    Returns 404 if the transaction doesn't belong to the user.
    
    Requires: `Authorization: Bearer <token>`
    """
    transaction_service.delete_transaction(db, current_user.id, transaction_id)