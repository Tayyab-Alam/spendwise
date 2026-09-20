from datetime import date
from decimal import Decimal

from app.db.database import SessionLocal
from app.crud.category import get_categories_by_type
from app.schemas.transaction_schema import TransactionCreate, TransactionUpdate
from app.services.transaction_service import (
    create_transaction,
    delete_transaction,
    get_transaction_for_user,
    list_user_transactions,
    update_transaction,
)
from app.core.exceptions import BadRequestException, NotFoundException


db = SessionLocal()
try:
    USER_ID = 4

    # Get some category IDs
    expense_cat_id = get_categories_by_type(db, USER_ID, "expense")[0].id
    income_cat_id = get_categories_by_type(db, USER_ID, "income")[0].id

    print("=== Test 1: Create valid transaction ===")
    t1 = create_transaction(
        db, USER_ID,
        TransactionCreate(
            type="expense",
            amount=Decimal("250.00"),
            category_id=expense_cat_id,
            date=date(2026, 9, 19),
            note="Test expense",
        ),
    )
    print(f"Created id={t1.id}, amount={t1.amount}")

    print("=== Test 2: Type/category mismatch ===")
    try:
        create_transaction(
            db, USER_ID,
            TransactionCreate(
                type="income",  # mismatch!
                amount=Decimal("100.00"),
                category_id=expense_cat_id,  # expense category
                date=date(2026, 9, 19),
            ),
        )
        print("ERROR: Should have failed!")
    except BadRequestException as e:
        print(f"Correctly rejected: {e.detail}")

    print("=== Test 3: Nonexistent category ===")
    try:
        create_transaction(
            db, USER_ID,
            TransactionCreate(
                type="expense",
                amount=Decimal("100.00"),
                category_id=99999,
                date=date(2026, 9, 19),
            ),
        )
        print("ERROR: Should have failed!")
    except NotFoundException as e:
        print(f"Correctly rejected: {e.detail}")

    print("=== Test 4: Get transaction (own) ===")
    fetched = get_transaction_for_user(db, USER_ID, t1.id)
    print(f"Fetched id={fetched.id}, note={fetched.note}")

    print("=== Test 5: Get transaction (other user - should 404) ===")
    try:
        get_transaction_for_user(db, 99999, t1.id)
        print("ERROR: Should have failed!")
    except NotFoundException as e:
        print(f"Correctly rejected: {e.detail}")

    print("=== Test 6: List with filters ===")
    txns = list_user_transactions(db, USER_ID, type_filter="expense", search="test")
    print(f"Found: {len(txns)} expense transactions matching 'test'")

    print("=== Test 7: Invalid date range ===")
    try:
        list_user_transactions(
            db, USER_ID,
            date_from=date(2026, 9, 30),
            date_to=date(2026, 9, 1),
        )
        print("ERROR: Should have failed!")
    except BadRequestException as e:
        print(f"Correctly rejected: {e.detail}")

    print("=== Test 8: Update valid ===")
    updated = update_transaction(
        db, USER_ID, t1.id,
        TransactionUpdate(amount=Decimal("300.00")),
    )
    print(f"Updated amount={updated.amount}")

    print("=== Test 9: Update to mismatched type ===")
    try:
        update_transaction(
            db, USER_ID, t1.id,
            TransactionUpdate(type="income", category_id=expense_cat_id),
        )
        print("ERROR: Should have failed!")
    except BadRequestException as e:
        print(f"Correctly rejected: {e.detail}")

    print("=== Test 10: Delete ===")
    delete_transaction(db, USER_ID, t1.id)
    print("Deleted successfully")

    print("=== Test 11: Delete again (should 404) ===")
    try:
        delete_transaction(db, USER_ID, t1.id)
        print("ERROR: Should have failed!")
    except NotFoundException as e:
        print(f"Correctly rejected: {e.detail}")

finally:
    db.close()