from fastapi import APIRouter, Depends, Query, status
from sqlalchemy.orm import Session

from app.dependencies.auth import get_current_user
from app.dependencies.db import get_db
from app.models.user import User
from app.schemas.budget_schema import (
    BudgetCreate,
    BudgetResponse,
    BudgetStatusResponse,
    BudgetUpdate,
)
from app.services import budget_service

router = APIRouter()


# ============================================================
# LIST BUDGETS
# ============================================================

@router.get(
    "",
    response_model=list[BudgetResponse],
    summary="List budgets for current user",
)
def list_budgets(
    month: str | None = Query(
        None,
        pattern=r"^\d{4}-\d{2}$",
        description="Filter by month (YYYY-MM)",
        examples=["2026-11"],
    ),
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """
    List all budgets for the authenticated user.
    
    Optionally filter by **month** (format: YYYY-MM).
    
    Requires: `Authorization: Bearer <token>`
    """
    return budget_service.list_user_budgets(db, current_user.id, month=month)


# ============================================================
# CREATE BUDGET
# ============================================================

@router.post(
    "",
    response_model=BudgetResponse,
    status_code=status.HTTP_201_CREATED,
    summary="Create a budget",
)
def create_budget(
    data: BudgetCreate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """
    Create a monthly budget for an expense category.
    
    - **category_id**: Must be an expense category
    - **month**: Format `YYYY-MM` (e.g., `2026-11`)
    - **limit_amount**: Positive decimal
    
    Requires: `Authorization: Bearer <token>`
    """
    return budget_service.create_budget(db, current_user.id, data)


# ============================================================
# GET ONE BUDGET
# ============================================================

@router.get(
    "/{budget_id}",
    response_model=BudgetResponse,
    summary="Get a single budget",
)
def get_budget(
    budget_id: int,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """
    Get a specific budget.
    Returns 404 if it doesn't belong to the user.
    
    Requires: `Authorization: Bearer <token>`
    """
    return budget_service.get_budget_for_user(db, current_user.id, budget_id)


# ============================================================
# GET BUDGET STATUS (dashboard)
# ============================================================

@router.get(
    "/{budget_id}/status",
    response_model=BudgetStatusResponse,
    summary="Get budget with spending status",
)
def get_budget_status(
    budget_id: int,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """
    Get a budget with calculated spending information:
    
    - **spent**: Total expense in this category for the month
    - **remaining**: limit_amount - spent
    - **percentage**: (spent / limit) * 100
    - **status**: `safe` | `approaching` | `exceeded`
    
    Requires: `Authorization: Bearer <token>`
    """
    return budget_service.get_budget_with_status(db, current_user.id, budget_id)


# ============================================================
# UPDATE BUDGET
# ============================================================

@router.put(
    "/{budget_id}",
    response_model=BudgetResponse,
    summary="Update a budget",
)
def update_budget(
    budget_id: int,
    data: BudgetUpdate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """
    Update a budget's limit amount.
    
    Note: Category and month cannot be changed. Delete and recreate
    the budget if you need to change those.
    
    Requires: `Authorization: Bearer <token>`
    """
    return budget_service.update_budget(db, current_user.id, budget_id, data)


# ============================================================
# DELETE BUDGET
# ============================================================

@router.delete(
    "/{budget_id}",
    status_code=status.HTTP_204_NO_CONTENT,
    summary="Delete a budget",
)
def delete_budget(
    budget_id: int,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """
    Delete a budget. Returns 204 on success.
    Returns 404 if it doesn't belong to the user.
    
    Requires: `Authorization: Bearer <token>`
    """
    budget_service.delete_budget(db, current_user.id, budget_id)