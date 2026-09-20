from datetime import datetime

from pydantic import BaseModel, ConfigDict, EmailStr, Field


# ============================================================
# BASE
# ============================================================

class UserBase(BaseModel):
    name: str = Field(..., min_length=1, max_length=100)
    email: EmailStr


# ============================================================
# REGISTER
# ============================================================

class UserRegister(UserBase):
    password: str = Field(..., min_length=8, max_length=72)


# ============================================================
# LOGIN
# ============================================================

class UserLogin(BaseModel):
    email: EmailStr
    password: str = Field(..., min_length=1)


# ============================================================
# RESPONSE
# ============================================================

class UserResponse(UserBase):
    id: int
    created_at: datetime

    model_config = ConfigDict(from_attributes=True)


# ============================================================
# UPDATE (for PUT /users/me)
# ============================================================

class UserUpdate(BaseModel):
    name: str | None = Field(None, min_length=1, max_length=100)
    email: EmailStr | None = None


# ============================================================
# TOKEN
# ============================================================

class TokenResponse(BaseModel):
    access_token: str
    token_type: str = "bearer"