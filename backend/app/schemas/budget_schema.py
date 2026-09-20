from datetime import datetime
from decimal import Decimal
from typing import Literal

from pydantic import BaseModel, ConfigDict, Field, field_validator

from app.schemas.category_schema import CategoryResponse


# Status levels
BudgetStatus = Literal["safe", "approaching", "exceeded"]


# ============================================================
# BASE
# ============================================================

class BudgetBase(BaseModel):
    category_id: int = Field(..., gt=0)
    month: str = Field(
        ...,
        pattern=r"^\d{4}-\d{2}$",
        description="Format: YYYY-MM (e.g., 2026-10)",
        examples=["2026-10"],
    )
    limit_amount: Decimal = Field(
        ..., gt=0, max_digits=12, decimal_places=2
    )

    @field_validator("month")
    @classmethod
    def validate_month(cls, v: str) -> str:
        """Ensure month part is 01-12."""
        year_str, month_str = v.split("-")
        month_num = int(month_str)
        if not (1 <= month_num <= 12):
            raise ValueError("Month must be between 01 and 12")
        return v


# ============================================================
# CREATE
# ============================================================

class BudgetCreate(BudgetBase):
    """Schema for creating a budget."""
    pass


# ============================================================
# UPDATE
# ============================================================

class BudgetUpdate(BaseModel):
    """Schema for updating a budget's limit."""
    limit_amount: Decimal | None = Field(
        None, gt=0, max_digits=12, decimal_places=2
    )


# ============================================================
# RESPONSE (basic)
# ============================================================

class BudgetResponse(BudgetBase):
    id: int
    user_id: int
    category: CategoryResponse
    created_at: datetime
    updated_at: datetime

    model_config = ConfigDict(from_attributes=True)


# ============================================================
# RESPONSE (with status — for dashboard)
# ============================================================

class BudgetStatusResponse(BudgetResponse):
    """
    Budget with calculated spending status.
    Used for dashboards and progress indicators.
    """
    spent: Decimal
    remaining: Decimal
    percentage: float  # 0-100+
    status: BudgetStatus  # safe | approaching | exceeded