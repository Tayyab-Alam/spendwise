# Manual Test Scripts

These scripts are **manual** verification tools used during development.
They are **not** part of the automated test suite (`tests/`).

## Purpose

- Quick end-to-end verification of specific features
- Debugging complex logic (budget status, analytics aggregations)
- Reference implementation examples

## Usage

Each script connects to the **main database** (`spendwise_db`), not the test database.

**Run from `backend/` folder using `-m` flag:**

```bash
uv run python -m scripts.test_transactions
uv run python -m scripts.test_transaction_service
uv run python -m scripts.test_budget_service
uv run python -m scripts.test_analytics_service