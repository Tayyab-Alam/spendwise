from sqlalchemy.orm import Session

from app.db.database import SessionLocal
from app.models.category import Category


# ============================================================
# DEFAULT CATEGORIES
# ============================================================

DEFAULT_CATEGORIES = [
    # Expense categories
    {"name": "Food", "type": "expense"},
    {"name": "Transport", "type": "expense"},
    {"name": "Bills", "type": "expense"},
    {"name": "Shopping", "type": "expense"},
    {"name": "Entertainment", "type": "expense"},
    {"name": "Health", "type": "expense"},
    {"name": "Education", "type": "expense"},
    {"name": "Other Expense", "type": "expense"},
    # Income categories
    {"name": "Salary", "type": "income"},
    {"name": "Freelance", "type": "income"},
    {"name": "Business", "type": "income"},
    {"name": "Investment", "type": "income"},
    {"name": "Other Income", "type": "income"},
]


def seed_default_categories(db: Session) -> int:
    """
    Insert default categories if they don't already exist.
    Returns the number of newly created categories.
    
    Safe to run multiple times — won't create duplicates.
    """
    created_count = 0
    for cat_data in DEFAULT_CATEGORIES:
        existing = (
            db.query(Category)
            .filter(
                Category.user_id.is_(None),
                Category.name == cat_data["name"],
                Category.type == cat_data["type"],
            )
            .first()
        )
        if existing:
            continue

        db.add(Category(
            name=cat_data["name"],
            type=cat_data["type"],
            user_id=None,  # default category
        ))
        created_count += 1

    db.commit()
    return created_count


def run_seed() -> None:
    """Entry point for running the seed script manually."""
    db = SessionLocal()
    try:
        count = seed_default_categories(db)
        if count > 0:
            print(f"✅ Created {count} default categories")
        else:
            print("ℹ️  Default categories already exist — nothing to do")
    finally:
        db.close()


if __name__ == "__main__":
    run_seed()