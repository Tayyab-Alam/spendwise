from decimal import Decimal

from sqlalchemy import func
from sqlalchemy.orm import Session

from app.models.category import Category
from app.models.transaction import Transaction
from app.schemas.analytics_schema import (
    AnalyticsSummary,
    BalanceSummary,
    CategoryBreakdown,
    CategorySpending,
    MonthlyTrend,
    MonthlyTrendItem,
)


# ============================================================
# HELPERS
# ============================================================

def _month_date_range(month: str) -> tuple[str, str]:
    """
    Convert "YYYY-MM" to (start_date, end_date_exclusive).
    end_date is exclusive (first day of next month).
    """
    year, month_num = map(int, month.split("-"))
    start = f"{year}-{month_num:02d}-01"
    if month_num == 12:
        end = f"{year + 1}-01-01"
    else:
        end = f"{year}-{month_num + 1:02d}-01"
    return start, end


# ============================================================
# SUMMARY
# ============================================================

def get_monthly_summary(db: Session, user_id: int, month: str) -> AnalyticsSummary:
    """
    Get monthly summary: total income, expense, net balance, transaction count.
    """
    start, end = _month_date_range(month)

    # Income total
    income_result = (
        db.query(func.coalesce(func.sum(Transaction.amount), 0))
        .filter(
            Transaction.user_id == user_id,
            Transaction.type == "income",
            Transaction.date >= start,
            Transaction.date < end,
        )
        .scalar()
    )

    # Expense total
    expense_result = (
        db.query(func.coalesce(func.sum(Transaction.amount), 0))
        .filter(
            Transaction.user_id == user_id,
            Transaction.type == "expense",
            Transaction.date >= start,
            Transaction.date < end,
        )
        .scalar()
    )

    # Transaction count
    count = (
        db.query(func.count(Transaction.id))
        .filter(
            Transaction.user_id == user_id,
            Transaction.date >= start,
            Transaction.date < end,
        )
        .scalar()
    )

    total_income = Decimal(income_result)
    total_expense = Decimal(expense_result)

    return AnalyticsSummary(
        month=month,
        total_income=total_income,
        total_expense=total_expense,
        net_balance=total_income - total_expense,
        transaction_count=count or 0,
    )


# ============================================================
# CATEGORY BREAKDOWN
# ============================================================

def get_category_breakdown(
    db: Session,
    user_id: int,
    month: str,
    *,
    type_filter: str = "expense",
) -> CategoryBreakdown:
    """
    Get spending per category for a given month.
    Defaults to expense categories (most useful for pie charts).
    """
    start, end = _month_date_range(month)

    results = (
        db.query(
            Category.id,
            Category.name,
            Category.type,
            func.sum(Transaction.amount).label("total"),
        )
        .join(Transaction, Transaction.category_id == Category.id)
        .filter(
            Transaction.user_id == user_id,
            Transaction.type == type_filter,
            Transaction.date >= start,
            Transaction.date < end,
        )
        .group_by(Category.id, Category.name, Category.type)
        .order_by(func.sum(Transaction.amount).desc())
        .all()
    )

    total_spent = sum((Decimal(r.total) for r in results), Decimal("0"))

    categories = []
    for r in results:
        amount = Decimal(r.total)
        pct = float((amount / total_spent) * 100) if total_spent > 0 else 0.0
        categories.append(
            CategorySpending(
                category_id=r.id,
                name=r.name,
                type=r.type,
                total=amount,
                percentage=round(pct, 2),
            )
        )

    return CategoryBreakdown(
        month=month,
        total_spent=total_spent,
        categories=categories,
    )


# ============================================================
# MONTHLY TREND
# ============================================================

def get_monthly_trend(db: Session, user_id: int, year: int) -> MonthlyTrend:
    """
    Get income and expense totals for each month of a year.
    Always returns 12 months (missing months have 0 values).
    """
    start = f"{year}-01-01"
    end = f"{year + 1}-01-01"

    results = (
        db.query(
            func.to_char(Transaction.date, "YYYY-MM").label("month"),
            Transaction.type,
            func.sum(Transaction.amount).label("total"),
        )
        .filter(
            Transaction.user_id == user_id,
            Transaction.date >= start,
            Transaction.date < end,
        )
        .group_by("month", Transaction.type)
        .all()
    )

    # Build a dict: {"2026-01": {"income": X, "expense": Y}}
    data: dict[str, dict[str, Decimal]] = {}
    for r in results:
        if r.month not in data:
            data[r.month] = {"income": Decimal("0"), "expense": Decimal("0")}
        data[r.month][r.type] = Decimal(r.total)

    # Fill all 12 months
    months = []
    for m in range(1, 13):
        key = f"{year}-{m:02d}"
        row = data.get(key, {"income": Decimal("0"), "expense": Decimal("0")})
        months.append(
            MonthlyTrendItem(
                month=key,
                income=row["income"],
                expense=row["expense"],
            )
        )

    return MonthlyTrend(year=year, months=months)


# ============================================================
# BALANCE (all-time)
# ============================================================

def get_balance(db: Session, user_id: int) -> BalanceSummary:
    """
    All-time balance: total income - total expense.
    Balance carries forward across months.
    """
    income = (
        db.query(func.coalesce(func.sum(Transaction.amount), 0))
        .filter(
            Transaction.user_id == user_id,
            Transaction.type == "income",
        )
        .scalar()
    )

    expense = (
        db.query(func.coalesce(func.sum(Transaction.amount), 0))
        .filter(
            Transaction.user_id == user_id,
            Transaction.type == "expense",
        )
        .scalar()
    )

    total_income = Decimal(income)
    total_expense = Decimal(expense)

    return BalanceSummary(
        total_income=total_income,
        total_expense=total_expense,
        current_balance=total_income - total_expense,
    )