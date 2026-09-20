from datetime import date
from decimal import Decimal

from app.db.database import SessionLocal
from app.crud.category import get_categories_by_type
from app.crud.transaction import create_transaction
from app.schemas.budget_schema import BudgetCreate, BudgetUpdate
from app.schemas.transaction_schema import TransactionCreate
from app.services.budget_service import (
    create_budget,
    delete_budget,
    get_budget_for_user,
    get_budget_with_status,
    list_user_budgets,
    update_budget,
)
from app.core.exceptions import (
    BadRequestException,
    ConflictException,
    NotFoundException,
)


db = SessionLocal()
try:
    USER_ID = 4
    expense_cats = get_categories_by_type(db, USER_ID, "expense")
    income_cats = get_categories_by_type(db, USER_ID, "income")
    expense_cat = expense_cats[0]
    income_cat = income_cats[0]
    print(f"Expense cat: {expense_cat.name} (id={expense_cat.id})")
    print(f"Income cat: {income_cat.name} (id={income_cat.id})")

    print("\n=== Test 1: Create valid budget ===")
    b = create_budget(db, USER_ID, BudgetCreate(
        category_id=expense_cat.id, month="2026-11",
        limit_amount=Decimal("7000.00"),
    ))
    print(f"Created id={b.id}")

    print("\n=== Test 2: Duplicate budget ===")
    try:
        create_budget(db, USER_ID, BudgetCreate(
            category_id=expense_cat.id, month="2026-11",
            limit_amount=Decimal("8000.00"),
        ))
        print("ERROR: Should have failed!")
    except ConflictException as e:
        print(f"Correctly rejected: {e.detail}")

    print("\n=== Test 3: Budget on income category (should fail) ===")
    try:
        create_budget(db, USER_ID, BudgetCreate(
            category_id=income_cat.id, month="2026-11",
            limit_amount=Decimal("1000.00"),
        ))
        print("ERROR: Should have failed!")
    except BadRequestException as e:
        print(f"Correctly rejected: {e.detail}")

    print("\n=== Test 4: Nonexistent category ===")
    try:
        create_budget(db, USER_ID, BudgetCreate(
            category_id=99999, month="2026-11",
            limit_amount=Decimal("1000.00"),
        ))
        print("ERROR: Should have failed!")
    except NotFoundException as e:
        print(f"Correctly rejected: {e.detail}")

    print("\n=== Test 5: Add transactions and check status (SAFE) ===")
    # Add 4 expense transactions = 2500 total
    for amt in ["500", "700", "800", "500"]:
        create_transaction(db, USER_ID, TransactionCreate(
            type="expense", amount=Decimal(amt),
            category_id=expense_cat.id, date=date(2026, 11, 5),
            note=f"Test {amt}",
        ))
    status = get_budget_with_status(db, USER_ID, b.id)
    print(f"Spent={status.spent}, Remaining={status.remaining}, "
          f"Percentage={status.percentage}%, Status={status.status}")

    print("\n=== Test 6: Push to APPROACHING (spent >= 80%) ===")
    # Add 3200 more = 5700 total → 81.43%
    create_transaction(db, USER_ID, TransactionCreate(
        type="expense", amount=Decimal("3200"),
        category_id=expense_cat.id, date=date(2026, 11, 10),
        note="Big purchase",
    ))
    status = get_budget_with_status(db, USER_ID, b.id)
    print(f"Spent={status.spent}, Percentage={status.percentage}%, "
          f"Status={status.status}")

    print("\n=== Test 7: Push to EXCEEDED (> 100%) ===")
    create_transaction(db, USER_ID, TransactionCreate(
        type="expense", amount=Decimal("1500"),
        category_id=expense_cat.id, date=date(2026, 11, 15),
        note="Over budget",
    ))
    status = get_budget_with_status(db, USER_ID, b.id)
    print(f"Spent={status.spent}, Percentage={status.percentage}%, "
          f"Status={status.status}")

    print("\n=== Test 8: Update limit ===")
    updated = update_budget(db, USER_ID, b.id, BudgetUpdate(
        limit_amount=Decimal("10000.00"),
    ))
    print(f"New limit: {updated.limit_amount}")

    print("\n=== Test 9: List budgets ===")
    bs = list_user_budgets(db, USER_ID, month="2026-11")
    print(f"November budgets: {len(bs)}")

    print("\n=== Test 10: Delete budget ===")
    delete_budget(db, USER_ID, b.id)
    print("Deleted successfully")

    print("\n=== Test 11: Delete again (should 404) ===")
    try:
        delete_budget(db, USER_ID, b.id)
        print("ERROR: Should have failed!")
    except NotFoundException as e:
        print(f"Correctly rejected: {e.detail}")

finally:
    db.close()