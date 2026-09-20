from decimal import Decimal

from sqlalchemy.orm import Session

from app.core.exceptions import (
    BadRequestException,
    ConflictException,
    NotFoundException,
)
from app.crud import budget as budget_crud
from app.crud import category as category_crud
from app.models.budget import Budget
from app.schemas.budget_schema import (
    BudgetCreate,
    BudgetStatusResponse,
    BudgetUpdate,
)


# ============================================================
# HELPERS
# ============================================================

def _validate_category_for_budget(
    db: Session,
    user_id: int,
    category_id: int,
) -> None:
    """
    Ensure category exists, is visible to user, is active,
    and is of type 'expense'.
    """
    category = category_crud.get_category_by_id(db, category_id)

    if not category:
        raise NotFoundException("Category not found")

    if category.user_id is not None and category.user_id != user_id:
        raise NotFoundException("Category not found")

    if not category.is_active:
        raise BadRequestException("Category is inactive")

    if category.type != "expense":
        raise BadRequestException(
            "Budgets can only be set for expense categories"
        )


def _calculate_status(spent: Decimal, limit: Decimal) -> tuple[Decimal, float, str]:
    """
    Returns (remaining, percentage, status).
    """
    remaining = limit - spent
    percentage = float((spent / limit) * 100)

    if percentage >= 100:
        status = "exceeded"
    elif percentage >= 80:
        status = "approaching"
    else:
        status = "safe"

    return remaining, round(percentage, 2), status


# ============================================================
# CREATE
# ============================================================

def create_budget(
    db: Session,
    user_id: int,
    data: BudgetCreate,
) -> Budget:
    """
    Create a budget after validating category and checking duplicates.
    """
    _validate_category_for_budget(db, user_id, data.category_id)

    existing = budget_crud.get_budget_by_user_category_month(
        db, user_id, data.category_id, data.month
    )
    if existing:
        raise ConflictException(
            f"A budget for this category already exists for {data.month}"
        )

    return budget_crud.create_budget(db, user_id, data)


# ============================================================
# READ
# ============================================================

def list_user_budgets(
    db: Session,
    user_id: int,
    *,
    month: str | None = None,
) -> list[Budget]:
    """List budgets for a user."""
    return budget_crud.list_budgets(db, user_id, month=month)


def get_budget_for_user(
    db: Session,
    user_id: int,
    budget_id: int,
) -> Budget:
    """
    Get a budget if it belongs to the user.
    Raises NotFoundException otherwise.
    """
    budget = budget_crud.get_budget_by_id(db, budget_id)
    if not budget or budget.user_id != user_id:
        raise NotFoundException("Budget not found")
    return budget


def get_budget_with_status(
    db: Session,
    user_id: int,
    budget_id: int,
) -> BudgetStatusResponse:
    """
    Get a budget plus calculated spent/remaining/percentage/status.
    """
    budget = get_budget_for_user(db, user_id, budget_id)

    spent = budget_crud.get_spent_for_budget(db, budget)
    remaining, percentage, status = _calculate_status(spent, budget.limit_amount)

    return BudgetStatusResponse(
        id=budget.id,
        user_id=budget.user_id,
        category_id=budget.category_id,
        category=budget.category,
        month=budget.month,
        limit_amount=budget.limit_amount,
        created_at=budget.created_at,
        updated_at=budget.updated_at,
        spent=spent,
        remaining=remaining,
        percentage=percentage,
        status=status,
    )


# ============================================================
# UPDATE
# ============================================================

def update_budget(
    db: Session,
    user_id: int,
    budget_id: int,
    data: BudgetUpdate,
) -> Budget:
    """Update a user's budget limit_amount."""
    budget = get_budget_for_user(db, user_id, budget_id)
    return budget_crud.update_budget(db, budget, data)


# ============================================================
# DELETE
# ============================================================

def delete_budget(
    db: Session,
    user_id: int,
    budget_id: int,
) -> None:
    """Delete a user's budget."""
    budget = get_budget_for_user(db, user_id, budget_id)
    budget_crud.delete_budget(db, budget)