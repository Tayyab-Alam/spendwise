from datetime import date
from decimal import Decimal

from app.db.database import SessionLocal
from app.crud.transaction import (
    create_transaction,
    list_transactions,
    update_transaction,
    delete_transaction,
)
from app.crud.category import get_categories_by_type
from app.schemas.transaction_schema import TransactionCreate, TransactionUpdate


db = SessionLocal()
try:
    USER_ID = 4

    # Test 1: Create expense
    print("--- Test 1: Create expense ---")
    t1 = create_transaction(
        db, USER_ID,
        TransactionCreate(
            type="expense",
            amount=Decimal("500.50"),
            category_id=4,
            date=date(2026, 9, 19),
            note="Lunch at cafe",
        ),
    )
    print(f"Created: id={t1.id}, type={t1.type}, amount={t1.amount}, note={t1.note}")

    # Test 2: Create income
    print("--- Test 2: Create income ---")
    income_cats = get_categories_by_type(db, USER_ID, "income")
    income_cat_id = income_cats[0].id
    t2 = create_transaction(
        db, USER_ID,
        TransactionCreate(
            type="income",
            amount=Decimal("50000.00"),
            category_id=income_cat_id,
            date=date(2026, 9, 1),
            note="Monthly salary",
        ),
    )
    print(f"Created: id={t2.id}, type={t2.type}, amount={t2.amount}")

    # Test 3: List all
    print("--- Test 3: List all ---")
    txns = list_transactions(db, USER_ID)
    print(f"Total: {len(txns)}")
    for t in txns:
        print(f"  - {t.date} {t.type} {t.amount} ({t.category.name})")

    # Test 4: Filter by type
    print("--- Test 4: Filter expense ---")
    txns = list_transactions(db, USER_ID, type_filter="expense")
    print(f"Expenses: {len(txns)}")

    # Test 5: Search by note
    print("--- Test 5: Search ---")
    txns = list_transactions(db, USER_ID, search="salary")
    print(f"Found with 'salary': {len(txns)}")

    # Test 6: Update
    print("--- Test 6: Update ---")
    updated = update_transaction(db, t1, TransactionUpdate(amount=Decimal("600.00")))
    print(f"Updated amount: {updated.amount}")

    # Test 7: Delete
    print("--- Test 7: Delete ---")
    delete_transaction(db, t2)
    print("Deleted income transaction")

finally:
    db.close()