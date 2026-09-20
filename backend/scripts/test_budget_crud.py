from decimal import Decimal
from datetime import date

from app.db.database import SessionLocal
from app.crud.budget import (
    create_budget,
    get_budget_by_id,
    get_budget_by_user_category_month,
    list_budgets,
    get_spent_for_budget,
    update_budget,
    delete_budget,
)
from app.crud.category import get_categories_by_type
from app.crud.transaction import create_transaction
from app.schemas.budget_schema import BudgetCreate, BudgetUpdate
from app.schemas.transaction_schema import TransactionCreate


db = SessionLocal()
try:
    USER_ID = 4
    expense_cat = get_categories_by_type(db, USER_ID, "expense")[0]
    print(f"Using category: {expense_cat.name} (id={expense_cat.id})")

    print("\n=== Test 1: Create budget ===")
    b = create_budget(db, USER_ID, BudgetCreate(
        category_id=expense_cat.id,
        month="2026-10",
        limit_amount=Decimal("5000.00"),
    ))
    print(f"Created: id={b.id}, month={b.month}, limit={b.limit_amount}")

    print("\n=== Test 2: Duplicate (user, cat, month) check ===")
    existing = get_budget_by_user_category_month(db, USER_ID, expense_cat.id, "2026-10")
    print(f"Found existing: id={existing.id}")

    print("\n=== Test 3: List budgets ===")
    bs = list_budgets(db, USER_ID)
    print(f"Total budgets: {len(bs)}")
    for x in bs:
        print(f"  - {x.month} {x.category.name} limit={x.limit_amount}")

    print("\n=== Test 4: Filter by month ===")
    bs = list_budgets(db, USER_ID, month="2026-10")
    print(f"October budgets: {len(bs)}")

    print("\n=== Test 5: Spent calc with NO transactions ===")
    spent = get_spent_for_budget(db, b)
    print(f"Spent: {spent} (should be 0)")

    print("\n=== Test 6: Add transactions, recalc spent ===")
    for amt in ["500.00", "700.00", "1200.00", "900.00"]:
        create_transaction(db, USER_ID, TransactionCreate(
            type="expense",
            amount=Decimal(amt),
            category_id=expense_cat.id,
            date=date(2026, 10, 5),
            note=f"Test expense {amt}",
        ))
    # Add an income in same category - should NOT count
    # (won't work due to type validation, but testing isolation)
    spent = get_spent_for_budget(db, b)
    print(f"Spent after 4 expenses: {spent} (should be 3300.00)")

    print("\n=== Test 7: Update limit ===")
    b = update_budget(db, b, BudgetUpdate(limit_amount=Decimal("6000.00")))
    print(f"Updated limit: {b.limit_amount}")

    print("\n=== Test 8: Delete budget ===")
    delete_budget(db, b)
    print("Deleted successfully")

finally:
    db.close()