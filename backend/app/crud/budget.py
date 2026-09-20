from decimal import Decimal

from sqlalchemy import func
from sqlalchemy.orm import Session, joinedload

from app.models.budget import Budget
from app.models.transaction import Transaction
from app.schemas.budget_schema import BudgetCreate, BudgetUpdate


# ============================================================
# CREATE
# ============================================================

def create_budget(
    db: Session,
    user_id: int,
    data: BudgetCreate,
) -> Budget:
    """Create a new budget."""
    db_budget = Budget(
        user_id=user_id,
        category_id=data.category_id,
        month=data.month,
        limit_amount=data.limit_amount,
    )
    db.add(db_budget)
    db.commit()
    db.refresh(db_budget)
    return db_budget


# ============================================================
# READ
# ============================================================

def get_budget_by_id(db: Session, budget_id: int) -> Budget | None:
    """Find a budget by ID (with category eagerly loaded)."""
    return (
        db.query(Budget)
        .options(joinedload(Budget.category))
        .filter(Budget.id == budget_id)
        .first()
    )


def get_budget_by_user_category_month(
    db: Session,
    user_id: int,
    category_id: int,
    month: str,
) -> Budget | None:
    """Check if budget exists for (user, category, month)."""
    return (
        db.query(Budget)
        .filter(
            Budget.user_id == user_id,
            Budget.category_id == category_id,
            Budget.month == month,
        )
        .first()
    )


def list_budgets(
    db: Session,
    user_id: int,
    *,
    month: str | None = None,
) -> list[Budget]:
    """List budgets for a user (optionally filtered by month)."""
    query = (
        db.query(Budget)
        .options(joinedload(Budget.category))
        .filter(Budget.user_id == user_id)
    )
    if month:
        query = query.filter(Budget.month == month)
    return query.order_by(Budget.month.desc(), Budget.id.desc()).all()


def count_category_budgets(db: Session, category_id: int) -> int:
    """Count how many budgets reference a category."""
    return db.query(Budget).filter(Budget.category_id == category_id).count()


# ============================================================
# SPENT CALCULATION (transactions aggregation)
# ============================================================

def get_spent_for_budget(db: Session, budget: Budget) -> Decimal:
    """
    Calculate total spent on a budget's category for its month.
    
    Sums all EXPENSE transactions in that category for the user
    during the budget's month (YYYY-MM).
    """
    # Month string "2026-10" → date range [2026-10-01, 2026-10-31]
    year, month_num = map(int, budget.month.split("-"))
    start_date = f"{year}-{month_num:02d}-01"

    # Calculate end date (last day of month)
    if month_num == 12:
        end_date = f"{year + 1}-01-01"
    else:
        end_date = f"{year}-{month_num + 1:02d}-01"

    result = (
        db.query(func.coalesce(func.sum(Transaction.amount), 0))
        .filter(
            Transaction.user_id == budget.user_id,
            Transaction.category_id == budget.category_id,
            Transaction.type == "expense",
            Transaction.date >= start_date,
            Transaction.date < end_date,
        )
        .scalar()
    )
    return Decimal(result)


# ============================================================
# UPDATE
# ============================================================

def update_budget(
    db: Session,
    budget: Budget,
    data: BudgetUpdate,
) -> Budget:
    """Update a budget's limit_amount."""
    if data.limit_amount is not None:
        budget.limit_amount = data.limit_amount
    db.commit()
    db.refresh(budget)
    return budget


# ============================================================
# DELETE
# ============================================================

def delete_budget(db: Session, budget: Budget) -> None:
    """Delete a budget."""
    db.delete(budget)
    db.commit()