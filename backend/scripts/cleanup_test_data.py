from app.db.database import SessionLocal
from app.models.budget import Budget
from app.models.transaction import Transaction


db = SessionLocal()
try:
    deleted_b = db.query(Budget).delete()
    deleted_t = db.query(Transaction).delete()
    db.commit()
    print(f"Deleted {deleted_b} budgets and {deleted_t} transactions")
finally:
    db.close()