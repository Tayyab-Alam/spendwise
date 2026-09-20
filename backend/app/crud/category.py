from sqlalchemy.orm import Session

from app.models.category import Category
from app.schemas.category_schema import CategoryCreate, CategoryUpdate


# ============================================================
# CREATE
# ============================================================

def create_category(
    db: Session,
    user_id: int,
    data: CategoryCreate,
) -> Category:
    """Create a custom category for a user."""
    db_category = Category(
        name=data.name,
        type=data.type,
        user_id=user_id,
    )
    db.add(db_category)
    db.commit()
    db.refresh(db_category)
    return db_category


# ============================================================
# READ
# ============================================================

def get_category_by_id(db: Session, category_id: int) -> Category | None:
    """Find a category by its ID."""
    return db.query(Category).filter(Category.id == category_id).first()


def get_category_by_name_type(
    db: Session,
    user_id: int | None,
    name: str,
    type: str,
) -> Category | None:
    """Check if a category with same name+type exists for user or default."""
    return (
        db.query(Category)
        .filter(
            Category.user_id == user_id,
            Category.name == name,
            Category.type == type,
        )
        .first()
    )


def get_user_categories(
    db: Session,
    user_id: int,
    *,
    include_inactive: bool = False,
) -> list[Category]:
    """
    Get all categories visible to a user:
    - Default categories (user_id IS NULL)
    - User's custom categories
    
    By default, only active categories are returned.
    """
    query = db.query(Category).filter(
        (Category.user_id == user_id) | (Category.user_id.is_(None))
    )
    if not include_inactive:
        query = query.filter(Category.is_active.is_(True))
    return query.order_by(Category.type, Category.name).all()


def get_categories_by_type(
    db: Session,
    user_id: int,
    type: str,
) -> list[Category]:
    """Get active categories of a specific type (income/expense)."""
    return (
        db.query(Category)
        .filter(
            ((Category.user_id == user_id) | (Category.user_id.is_(None))),
            Category.type == type,
            Category.is_active.is_(True),
        )
        .order_by(Category.name)
        .all()
    )


# ============================================================
# UPDATE
# ============================================================

def update_category(
    db: Session,
    category: Category,
    data: CategoryUpdate,
) -> Category:
    """Update a custom category's name and/or is_active."""
    if data.name is not None:
        category.name = data.name
    if data.is_active is not None:
        category.is_active = data.is_active
    db.commit()
    db.refresh(category)
    return category


# ============================================================
# DELETE
# ============================================================

def delete_category(db: Session, category: Category) -> None:
    """Hard delete a category."""
    db.delete(category)
    db.commit()