"""
Cross-user authorization tests.

These are the MOST IMPORTANT tests for security.
They prove that user A cannot access, modify, or delete user B's data.
"""
import pytest


# ============================================================
# TRANSACTIONS — CROSS-USER
# ============================================================

def test_user_cannot_read_other_users_transaction(
    client, auth_headers, second_user_headers, expense_category
):
    """User B cannot GET user A's transaction."""
    # User A creates a transaction
    create = client.post("/transactions", headers=auth_headers, json={
        "type": "expense", "amount": 500,
        "category_id": expense_category.id, "date": "2026-11-05",
    })
    txn_id = create.json()["id"]

    # User B tries to read it → 404 (not 403, to hide existence)
    response = client.get(f"/transactions/{txn_id}", headers=second_user_headers)
    assert response.status_code == 404


def test_user_cannot_update_other_users_transaction(
    client, auth_headers, second_user_headers, expense_category
):
    """User B cannot PUT user A's transaction."""
    create = client.post("/transactions", headers=auth_headers, json={
        "type": "expense", "amount": 500,
        "category_id": expense_category.id, "date": "2026-11-05",
    })
    txn_id = create.json()["id"]

    response = client.put(
        f"/transactions/{txn_id}",
        headers=second_user_headers,
        json={"amount": 9999},
    )
    assert response.status_code == 404


def test_user_cannot_delete_other_users_transaction(
    client, auth_headers, second_user_headers, expense_category
):
    """User B cannot DELETE user A's transaction."""
    create = client.post("/transactions", headers=auth_headers, json={
        "type": "expense", "amount": 500,
        "category_id": expense_category.id, "date": "2026-11-05",
    })
    txn_id = create.json()["id"]

    response = client.delete(
        f"/transactions/{txn_id}",
        headers=second_user_headers,
    )
    assert response.status_code == 404

    # Verify it still exists for User A
    still_there = client.get(f"/transactions/{txn_id}", headers=auth_headers)
    assert still_there.status_code == 200


def test_transaction_list_only_returns_own(
    client, auth_headers, second_user_headers, expense_category
):
    """User B's GET /transactions doesn't include User A's data."""
    # User A creates 2 transactions
    for amt in [100, 200]:
        client.post("/transactions", headers=auth_headers, json={
            "type": "expense", "amount": amt,
            "category_id": expense_category.id, "date": "2026-11-05",
        })

    # User B has none
    response = client.get("/transactions", headers=second_user_headers)
    assert response.status_code == 200
    assert response.json() == []


# ============================================================
# CATEGORIES — CROSS-USER
# ============================================================

def test_user_cannot_read_other_users_custom_category(
    client, auth_headers, second_user_headers
):
    """User B cannot read user A's custom category."""
    create = client.post("/categories", headers=auth_headers, json={
        "name": "Private", "type": "expense",
    })
    cat_id = create.json()["id"]

    response = client.get(f"/categories/{cat_id}", headers=second_user_headers)
    assert response.status_code == 404


def test_user_cannot_update_other_users_category(
    client, auth_headers, second_user_headers
):
    """User B cannot modify user A's custom category."""
    create = client.post("/categories", headers=auth_headers, json={
        "name": "Private", "type": "expense",
    })
    cat_id = create.json()["id"]

    response = client.put(
        f"/categories/{cat_id}",
        headers=second_user_headers,
        json={"name": "Hacked"},
    )
    assert response.status_code == 404


def test_user_cannot_delete_other_users_category(
    client, auth_headers, second_user_headers
):
    """User B cannot delete user A's custom category."""
    create = client.post("/categories", headers=auth_headers, json={
        "name": "Private", "type": "expense",
    })
    cat_id = create.json()["id"]

    response = client.delete(
        f"/categories/{cat_id}",
        headers=second_user_headers,
    )
    assert response.status_code == 404


def test_user_categories_list_excludes_other_users_custom(
    client, auth_headers, second_user_headers
):
    """User B's category list should not include User A's custom categories."""
    client.post("/categories", headers=auth_headers, json={
        "name": "UserAOnly", "type": "expense",
    })

    # User B's list
    response = client.get("/categories", headers=second_user_headers)
    cats = response.json()
    names = [c["name"] for c in cats]
    assert "UserAOnly" not in names


# ============================================================
# BUDGETS — CROSS-USER
# ============================================================

def test_user_cannot_read_other_users_budget(
    client, auth_headers, second_user_headers, expense_category
):
    """User B cannot GET user A's budget."""
    create = client.post("/budgets", headers=auth_headers, json={
        "category_id": expense_category.id,
        "month": "2026-11",
        "limit_amount": 5000,
    })
    budget_id = create.json()["id"]

    response = client.get(f"/budgets/{budget_id}", headers=second_user_headers)
    assert response.status_code == 404


def test_user_cannot_read_other_users_budget_status(
    client, auth_headers, second_user_headers, expense_category
):
    """User B cannot access user A's budget status."""
    create = client.post("/budgets", headers=auth_headers, json={
        "category_id": expense_category.id,
        "month": "2026-11",
        "limit_amount": 5000,
    })
    budget_id = create.json()["id"]

    response = client.get(
        f"/budgets/{budget_id}/status",
        headers=second_user_headers,
    )
    assert response.status_code == 404


def test_user_cannot_update_other_users_budget(
    client, auth_headers, second_user_headers, expense_category
):
    """User B cannot modify user A's budget."""
    create = client.post("/budgets", headers=auth_headers, json={
        "category_id": expense_category.id,
        "month": "2026-11",
        "limit_amount": 5000,
    })
    budget_id = create.json()["id"]

    response = client.put(
        f"/budgets/{budget_id}",
        headers=second_user_headers,
        json={"limit_amount": 99999},
    )
    assert response.status_code == 404


def test_user_cannot_delete_other_users_budget(
    client, auth_headers, second_user_headers, expense_category
):
    """User B cannot delete user A's budget."""
    create = client.post("/budgets", headers=auth_headers, json={
        "category_id": expense_category.id,
        "month": "2026-11",
        "limit_amount": 5000,
    })
    budget_id = create.json()["id"]

    response = client.delete(
        f"/budgets/{budget_id}",
        headers=second_user_headers,
    )
    assert response.status_code == 404


def test_budget_list_only_returns_own(
    client, auth_headers, second_user_headers, expense_category
):
    """User B's budget list should not include User A's budgets."""
    client.post("/budgets", headers=auth_headers, json={
        "category_id": expense_category.id,
        "month": "2026-11",
        "limit_amount": 5000,
    })

    response = client.get("/budgets", headers=second_user_headers)
    assert response.status_code == 200
    assert response.json() == []


# ============================================================
# ANALYTICS — CROSS-USER
# ============================================================

def test_analytics_summary_only_counts_own_transactions(
    client, auth_headers, second_user_headers, expense_category
):
    """User B's analytics should not include User A's transactions."""
    # User A adds expenses
    client.post("/transactions", headers=auth_headers, json={
        "type": "expense", "amount": 5000,
        "category_id": expense_category.id, "date": "2026-11-05",
    })

    # User B's summary should be 0
    response = client.get(
        "/analytics/summary?month=2026-11",
        headers=second_user_headers,
    )
    data = response.json()
    assert float(data["total_expense"]) == 0


def test_analytics_balance_only_counts_own(
    client, auth_headers, second_user_headers, expense_category
):
    """User B's balance should not include User A's transactions."""
    client.post("/transactions", headers=auth_headers, json={
        "type": "expense", "amount": 5000,
        "category_id": expense_category.id, "date": "2026-11-05",
    })

    response = client.get("/analytics/balance", headers=second_user_headers)
    data = response.json()
    assert float(data["total_expense"]) == 0
    assert float(data["current_balance"]) == 0


# ============================================================
# UNAUTHENTICATED ACCESS
# ============================================================

@pytest.mark.parametrize("method,path", [
    ("GET", "/transactions"),
    ("GET", "/categories"),
    ("GET", "/budgets"),
    ("GET", "/analytics/summary?month=2026-11"),
    ("GET", "/analytics/balance"),
    ("GET", "/users/me"),
])
def test_endpoints_require_auth(client, method, path):
    """All sensitive endpoints → 401 without token."""
    response = client.request(method, path)
    assert response.status_code == 401


@pytest.mark.parametrize("method,path", [
    ("POST", "/transactions"),
    ("POST", "/categories"),
    ("POST", "/budgets"),
])
def test_post_endpoints_require_auth(client, method, path):
    """POST endpoints → 401 without token."""
    response = client.request(method, path, json={})
    assert response.status_code == 401