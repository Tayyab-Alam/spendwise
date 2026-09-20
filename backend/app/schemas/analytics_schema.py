from decimal import Decimal

from pydantic import BaseModel, Field


# ============================================================
# SUMMARY
# ============================================================

class AnalyticsSummary(BaseModel):
    """Monthly financial overview."""
    month: str = Field(..., description="Format: YYYY-MM")
    total_income: Decimal
    total_expense: Decimal
    net_balance: Decimal
    transaction_count: int


# ============================================================
# CATEGORY BREAKDOWN
# ============================================================

class CategorySpending(BaseModel):
    """Single category's spending data."""
    category_id: int
    name: str
    type: str  # "income" | "expense"
    total: Decimal
    percentage: float


class CategoryBreakdown(BaseModel):
    """All category spending for a month."""
    month: str
    total_spent: Decimal
    categories: list[CategorySpending]


# ============================================================
# MONTHLY TREND
# ============================================================

class MonthlyTrendItem(BaseModel):
    """One month in the yearly trend."""
    month: str  # "2026-01"
    income: Decimal
    expense: Decimal


class MonthlyTrend(BaseModel):
    """12-month trend for a year."""
    year: int
    months: list[MonthlyTrendItem]


# ============================================================
# BALANCE
# ============================================================

class BalanceSummary(BaseModel):
    """All-time balance summary."""
    total_income: Decimal
    total_expense: Decimal
    current_balance: Decimal