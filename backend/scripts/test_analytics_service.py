from datetime import date
from decimal import Decimal

from app.db.database import SessionLocal
from app.crud.category import get_categories_by_type
from app.crud.transaction import create_transaction
from app.schemas.transaction_schema import TransactionCreate
from app.services.analytics_service import (
    get_balance,
    get_category_breakdown,
    get_monthly_summary,
    get_monthly_trend,
)


db = SessionLocal()
try:
    USER_ID = 4

    # Cleanup
    from app.models.budget import Budget
    from app.models.transaction import Transaction
    db.query(Budget).delete()
    db.query(Transaction).delete()
    db.commit()
    print("Cleanup done\n")

    # Get some categories
    expense_cats = get_categories_by_type(db, USER_ID, "expense")
    income_cats = get_categories_by_type(db, USER_ID, "income")
    food = expense_cats[0]
    shopping = expense_cats[1] if len(expense_cats) > 1 else expense_cats[0]
    salary = income_cats[0]
    print(f"Using: food={food.name}({food.id}), shopping={shopping.name}({shopping.id}), salary={salary.name}({salary.id})\n")

    # Add sample transactions
    print("=== Adding sample transactions ===")
    # Income (November)
    create_transaction(db, USER_ID, TransactionCreate(
        type="income", amount=Decimal("60000.00"),
        category_id=salary.id, date=date(2026, 11, 1),
        note="November salary",
    ))
    # Expenses (November)
    create_transaction(db, USER_ID, TransactionCreate(
        type="expense", amount=Decimal("8200.00"),
        category_id=food.id, date=date(2026, 11, 5),
        note="Food",
    ))
    create_transaction(db, USER_ID, TransactionCreate(
        type="expense", amount=Decimal("6500.00"),
        category_id=shopping.id, date=date(2026, 11, 10),
        note="Shopping",
    ))
    create_transaction(db, USER_ID, TransactionCreate(
        type="expense", amount=Decimal("4100.00"),
        category_id=food.id, date=date(2026, 11, 15),
        note="Food again",
    ))
    # October
    create_transaction(db, USER_ID, TransactionCreate(
        type="income", amount=Decimal("60000.00"),
        category_id=salary.id, date=date(2026, 10, 1),
        note="October salary",
    ))
    create_transaction(db, USER_ID, TransactionCreate(
        type="expense", amount=Decimal("30000.00"),
        category_id=shopping.id, date=date(2026, 10, 15),
        note="October shopping",
    ))
    print("Transactions added\n")

    # Test 1: Monthly summary (November)
    print("=== Test 1: November Summary ===")
    s = get_monthly_summary(db, USER_ID, "2026-11")
    print(f"Month: {s.month}")
    print(f"Income: {s.total_income}")
    print(f"Expense: {s.total_expense}")
    print(f"Net balance: {s.net_balance}")
    print(f"Transactions: {s.transaction_count}")

    # Test 2: Category breakdown (November)
    print("\n=== Test 2: November Category Breakdown ===")
    cb = get_category_breakdown(db, USER_ID, "2026-11")
    print(f"Total spent: {cb.total_spent}")
    for c in cb.categories:
        print(f"  - {c.name}: {c.total} ({c.percentage}%)")

    # Test 3: Monthly trend (2026)
    print("\n=== Test 3: 2026 Monthly Trend ===")
    mt = get_monthly_trend(db, USER_ID, 2026)
    for m in mt.months:
        if m.income > 0 or m.expense > 0:
            print(f"  {m.month}: income={m.income}, expense={m.expense}")

    # Test 4: Balance (all-time)
    print("\n=== Test 4: All-Time Balance ===")
    b = get_balance(db, USER_ID)
    print(f"Total income:  {b.total_income}")
    print(f"Total expense: {b.total_expense}")
    print(f"Balance:       {b.current_balance}")

    print("\n=== Cleanup ===")
    db.query(Transaction).delete()
    db.commit()
    print("Test data cleaned up")

finally:
    db.close()