from datetime import date as date_type
from datetime import datetime
from decimal import Decimal
from typing import Literal

from pydantic import BaseModel, ConfigDict, Field

from app.schemas.category_schema import CategoryResponse


# Type alias
TransactionType = Literal["income", "expense"]


# ============================================================
# BASE
# ============================================================

class TransactionBase(BaseModel):
    type: TransactionType
    amount: Decimal = Field(..., gt=0, max_digits=12, decimal_places=2)
    category_id: int = Field(..., gt=0)
    date: date_type
    note: str | None = Field(None, max_length=255)


# ============================================================
# CREATE
# ============================================================

class TransactionCreate(TransactionBase):
    """Schema for creating a transaction."""
    pass


# ============================================================
# UPDATE (all fields optional for partial update)
# ============================================================

class TransactionUpdate(BaseModel):
    type: TransactionType | None = None
    amount: Decimal | None = Field(None, gt=0, max_digits=12, decimal_places=2)
    category_id: int | None = Field(None, gt=0)
    date: date_type | None = None
    note: str | None = Field(None, max_length=255)


# ============================================================
# RESPONSE
# ============================================================

class TransactionResponse(TransactionBase):
    id: int
    user_id: int
    category: CategoryResponse  # nested full category
    created_at: datetime
    updated_at: datetime

    model_config = ConfigDict(from_attributes=True)