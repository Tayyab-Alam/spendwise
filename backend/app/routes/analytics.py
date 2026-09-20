from datetime import date
from typing import Literal

from fastapi import APIRouter, Depends, Query
from sqlalchemy.orm import Session

from app.dependencies.auth import get_current_user
from app.dependencies.db import get_db
from app.models.user import User
from app.schemas.analytics_schema import (
    AnalyticsSummary,
    BalanceSummary,
    CategoryBreakdown,
    MonthlyTrend,
)
from app.services import analytics_service

router = APIRouter()


# ============================================================
# SUMMARY
# ============================================================

@router.get(
    "/summary",
    response_model=AnalyticsSummary,
    summary="Monthly income/expense summary",
)
def get_summary(
    month: str = Query(
        ...,
        pattern=r"^\d{4}-\d{2}$",
        description="Month to summarize (YYYY-MM)",
        examples=["2026-11"],
    ),
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """
    Get total income, expenses, and net balance for a month.
    
    Requires: `Authorization: Bearer <token>`
    """
    return analytics_service.get_monthly_summary(db, current_user.id, month)


# ============================================================
# CATEGORY BREAKDOWN
# ============================================================

@router.get(
    "/categories",
    response_model=CategoryBreakdown,
    summary="Category-wise spending for a month",
)
def get_categories_breakdown(
    month: str = Query(
        ...,
        pattern=r"^\d{4}-\d{2}$",
        description="Month (YYYY-MM)",
        examples=["2026-11"],
    ),
    type_filter: Literal["income", "expense"] = Query(
        "expense",
        alias="type",
        description="Transaction type to aggregate",
    ),
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """
    Get per-category totals for a month with percentage of total.
    
    Perfect for pie charts on the dashboard.
    
    Requires: `Authorization: Bearer <token>`
    """
    return analytics_service.get_category_breakdown(
        db, current_user.id, month, type_filter=type_filter
    )


# ============================================================
# MONTHLY TREND
# ============================================================

@router.get(
    "/monthly",
    response_model=MonthlyTrend,
    summary="12-month income/expense trend",
)
def get_monthly(
    year: int = Query(
        ...,
        ge=2000,
        le=2100,
        description="Year to report",
    ),
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """
    Get income and expense totals for each month of a year.
    Always returns 12 months (missing months have 0 values).
    
    Perfect for bar charts.
    
    Requires: `Authorization: Bearer <token>`
    """
    return analytics_service.get_monthly_trend(db, current_user.id, year)


# ============================================================
# BALANCE (all-time)
# ============================================================

@router.get(
    "/balance",
    response_model=BalanceSummary,
    summary="All-time balance",
)
def get_balance(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """
    Get all-time total income, expense, and current balance.
    
    Balance carries forward across months.
    
    Requires: `Authorization: Bearer <token>`
    """
    return analytics_service.get_balance(db, current_user.id)