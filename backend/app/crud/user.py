from sqlalchemy.orm import Session

from app.core.security import hash_password
from app.models.user import User
from app.schemas.user_schema import UserRegister


# ============================================================
# CREATE
# ============================================================

def create_user(db: Session, user_data: UserRegister) -> User:
    """
    Create a new user in the database.
    Password is hashed before storing.
    """
    db_user = User(
        name=user_data.name,
        email=user_data.email.lower(),  # normalize email
        password_hash=hash_password(user_data.password),
    )
    db.add(db_user)
    db.commit()
    db.refresh(db_user)
    return db_user


# ============================================================
# READ
# ============================================================

def get_user_by_id(db: Session, user_id: int) -> User | None:
    """Find a user by their ID."""
    return db.query(User).filter(User.id == user_id).first()


def get_user_by_email(db: Session, email: str) -> User | None:
    """Find a user by their email (case-insensitive)."""
    return db.query(User).filter(User.email == email.lower()).first()


# ============================================================
# UPDATE
# ============================================================

def update_user(
    db: Session,
    user: User,
    *,
    name: str | None = None,
    email: str | None = None,
) -> User:
    """Update user's name and/or email."""
    if name is not None:
        user.name = name
    if email is not None:
        user.email = email.lower()
    db.commit()
    db.refresh(user)
    return user