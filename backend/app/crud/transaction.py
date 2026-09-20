from datetime import date as date_type
from decimal import Decimal

from sqlalchemy import asc, desc, or_
from sqlalchemy.orm import Session, joinedload

from app.models.transaction import Transaction
from app.schemas.transaction_schema import TransactionCreate, TransactionUpdate


# ============================================================
# CREATE
# ============================================================

def create_transaction(
    db: Session,
    user_id: int,
    data: TransactionCreate,
) -> Transaction:
    """Create a transaction owned by user_id."""
    db_txn = Transaction(
        user_id=user_id,
        category_id=data.category_id,
        type=data.type,
        amount=data.amount,
        date=data.date,
        note=data.note,
    )
    db.add(db_txn)
    db.commit()
    db.refresh(db_txn)
    return db_txn


# ============================================================
# READ
# ============================================================

def get_transaction_by_id(
    db: Session,
    transaction_id: int,
) -> Transaction | None:
    """Find a transaction by ID (with category eagerly loaded)."""
    return (
        db.query(Transaction)
        .options(joinedload(Transaction.category))
        .filter(Transaction.id == transaction_id)
        .first()
    )


def list_transactions(
    db: Session,
    user_id: int,
    *,
    type_filter: str | None = None,
    category_id: int | None = None,
    date_from: date_type | None = None,
    date_to: date_type | None = None,
    search: str | None = None,
    sort_by: str = "date",
    sort_order: str = "desc",
    skip: int = 0,
    limit: int = 50,
) -> list[Transaction]:
    """
    List transactions for a user with filters, sorting, and pagination.
    
    All filters are optional. Results are always restricted to the user.
    """
    query = (
        db.query(Transaction)
        .options(joinedload(Transaction.category))
        .filter(Transaction.user_id == user_id)
    )

    # Filters
    if type_filter:
        query = query.filter(Transaction.type == type_filter)
    if category_id:
        query = query.filter(Transaction.category_id == category_id)
    if date_from:
        query = query.filter(Transaction.date >= date_from)
    if date_to:
        query = query.filter(Transaction.date <= date_to)
    if search:
        like_pattern = f"%{search}%"
        query = query.filter(
            or_(
                Transaction.note.ilike(like_pattern),
            )
        )

    # Sorting
    sort_column = Transaction.amount if sort_by == "amount" else Transaction.date
    order_func = asc if sort_order == "asc" else desc
    # Secondary sort by id for stable pagination
    query = query.order_by(order_func(sort_column), desc(Transaction.id))

    # Pagination
    return query.offset(skip).limit(limit).all()


def count_user_transactions(db: Session, user_id: int) -> int:
    """Count total transactions for a user (for pagination info)."""
    return db.query(Transaction).filter(Transaction.user_id == user_id).count()


def count_category_transactions(db: Session, category_id: int) -> int:
    """Count how many transactions use a category (any user)."""
    return db.query(Transaction).filter(Transaction.category_id == category_id).count()


# ============================================================
# UPDATE
# ============================================================

def update_transaction(
    db: Session,
    transaction: Transaction,
    data: TransactionUpdate,
) -> Transaction:
    """Partially update a transaction."""
    update_data = data.model_dump(exclude_unset=True)
    for field, value in update_data.items():
        setattr(transaction, field, value)
    db.commit()
    db.refresh(transaction)
    return transaction


# ============================================================
# DELETE
# ============================================================

def delete_transaction(db: Session, transaction: Transaction) -> None:
    """Delete a transaction."""
    db.delete(transaction)
    db.commit()