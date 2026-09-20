from datetime import datetime
from typing import Literal

from pydantic import BaseModel, ConfigDict, Field


# Type alias for category type
CategoryType = Literal["income", "expense"]


# ============================================================
# BASE
# ============================================================

class CategoryBase(BaseModel):
    name: str = Field(..., min_length=1, max_length=50)
    type: CategoryType


# ============================================================
# CREATE
# ============================================================

class CategoryCreate(CategoryBase):
    """Schema for creating a custom category."""
    pass


# ============================================================
# UPDATE
# ============================================================

class CategoryUpdate(BaseModel):
    """Schema for updating a custom category."""
    name: str | None = Field(None, min_length=1, max_length=50)
    is_active: bool | None = None


# ============================================================
# RESPONSE
# ============================================================

class CategoryResponse(CategoryBase):
    id: int
    user_id: int | None  # None = default category
    is_active: bool
    created_at: datetime

    model_config = ConfigDict(from_attributes=True)