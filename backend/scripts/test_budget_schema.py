from decimal import Decimal
from app.schemas.budget_schema import BudgetCreate, BudgetUpdate

print("=== Test 1: Valid budget ===")
b = BudgetCreate(
    category_id=4,
    month="2026-10",
    limit_amount=Decimal("7000.00"),
)
print(f"Valid: {b}")

print("=== Test 2: Invalid month format ===")
try:
    BudgetCreate(category_id=4, month="2026/10", limit_amount=Decimal("100"))
    print("ERROR: Should have failed!")
except Exception as e:
    print(f"Rejected: {type(e).__name__}")

print("=== Test 3: Invalid month number ===")
try:
    BudgetCreate(category_id=4, month="2026-13", limit_amount=Decimal("100"))
    print("ERROR: Should have failed!")
except Exception as e:
    print(f"Rejected: {type(e).__name__}")

print("=== Test 4: Negative limit ===")
try:
    BudgetCreate(category_id=4, month="2026-10", limit_amount=Decimal("-100"))
    print("ERROR: Should have failed!")
except Exception as e:
    print(f"Rejected: {type(e).__name__}")

print("=== Test 5: Zero limit ===")
try:
    BudgetCreate(category_id=4, month="2026-10", limit_amount=Decimal("0"))
    print("ERROR: Should have failed!")
except Exception as e:
    print(f"Rejected: {type(e).__name__}")

print("=== Test 6: Update only limit ===")
u = BudgetUpdate(limit_amount=Decimal("8000.00"))
print(f"Update valid: {u}")

print("=== Test 7: Empty update (all optional) ===")
u = BudgetUpdate()
print(f"Empty update valid: {u}")