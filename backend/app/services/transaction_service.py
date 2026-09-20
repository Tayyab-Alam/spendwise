from datetime import date as date_type

from sqlalchemy.orm import Session

from app.core.exceptions import (
    BadRequestException,
    NotFoundException,
)
from app.crud import category as category_crud
from app.crud import transaction as transaction_crud
from app.models.transaction import Transaction
from app.schemas.transaction_schema import (
    TransactionCreate,
    TransactionUpdate,
)


# ============================================================
# HELPERS
# ============================================================

def _validate_category_for_user(
    db: Session,
    user_id: int,
    category_id: int,
    expected_type: str,
) -> None:
    """
    Ensure category exists, is visible to user, is active,
    and matches the transaction type.
    """
    category = category_crud.get_category_by_id(db, category_id)

    if not category:
        raise NotFoundException("Category not found")

    # Default categories visible to everyone; custom must belong to user
    if category.user_id is not None and category.user_id != user_id:
        # Return 404 (not 403) to avoid leaking existence of other users' data
        raise NotFoundException("Category not found")

    if not category.is_active:
        raise BadRequestException("Category is inactive")

    if category.type != expected_type:
        raise BadRequestException(
            f"Category type '{category.type}' does not match "
            f"transaction type '{expected_type}'"
        )


# ============================================================
# CREATE
# ============================================================

def create_transaction(
    db: Session,
    user_id: int,
    data: TransactionCreate,
) -> Transaction:
    """Create a transaction after validating the category."""
    _validate_category_for_user(db, user_id, data.category_id, data.type)
    return transaction_crud.create_transaction(db, user_id, data)


# ============================================================
# READ
# ============================================================

def get_transaction_for_user(
    db: Session,
    user_id: int,
    transaction_id: int,
) -> Transaction:
    """
    Get a transaction if it belongs to the user.
    Raises NotFoundException otherwise.
    """
    transaction = transaction_crud.get_transaction_by_id(db, transaction_id)

    if not transaction or transaction.user_id != user_id:
        # 404 not 403 — don't leak existence
        raise NotFoundException("Transaction not found")

    return transaction


def list_user_transactions(
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
    """List transactions for a user with optional filters."""
    # Validate date range
    if date_from and date_to and date_from > date_to:
        raise BadRequestException("date_from cannot be after date_to")

    return transaction_crud.list_transactions(
        db,
        user_id,
        type_filter=type_filter,
        category_id=category_id,
        date_from=date_from,
        date_to=date_to,
        search=search,
        sort_by=sort_by,
        sort_order=sort_order,
        skip=skip,
        limit=limit,
    )


# ============================================================
# UPDATE
# ============================================================

def update_transaction(
    db: Session,
    user_id: int,
    transaction_id: int,
    data: TransactionUpdate,
) -> Transaction:
    """
    Update a transaction owned by the user.
    Re-validates the category if category_id or type is changing.
    """
    transaction = get_transaction_for_user(db, user_id, transaction_id)

    # Determine the resulting type (may be updated)
    new_type = data.type if data.type is not None else transaction.type
    new_category_id = (
        data.category_id if data.category_id is not None else transaction.category_id
    )

    # If type or category is changing, re-validate the combination
    if data.type is not None or data.category_id is not None:
        _validate_category_for_user(db, user_id, new_category_id, new_type)

    return transaction_crud.update_transaction(db, transaction, data)


# ============================================================
# DELETE
# ============================================================

def delete_transaction(
    db: Session,
    user_id: int,
    transaction_id: int,
) -> None:
    """Delete a transaction owned by the user."""
    transaction = get_transaction_for_user(db, user_id, transaction_id)
    transaction_crud.delete_transaction(db, transaction)