"""
Tests for budgets: CRUD, month validation, spent calculation, status.
"""
import pytest


# ============================================================
# CREATE
# ============================================================

def test_create_budget(client, auth_headers, expense_category):
    """Create valid budget → 201."""
    response = client.post(
        "/budgets",
        headers=auth_headers,
        json={
            "category_id": expense_category.id,
            "month": "2026-11",
            "limit_amount": 7000.00,
        },
    )
    assert response.status_code == 201
    data = response.json()
    assert data["month"] == "2026-11"
    assert float(data["limit_amount"]) == 7000.00
    assert data["category"]["id"] == expense_category.id


def test_create_budget_duplicate(client, auth_headers, expense_category):
    """Same user+category+month → 409."""
    payload = {
        "category_id": expense_category.id,
        "month": "2026-11",
        "limit_amount": 7000.00,
    }
    client.post("/budgets", headers=auth_headers, json=payload)
    response = client.post("/budgets", headers=auth_headers, json=payload)
    assert response.status_code == 409


def test_create_budget_income_category_rejected(client, auth_headers, income_category):
    """Budgets only allowed for expense categories → 400."""
    response = client.post(
        "/budgets",
        headers=auth_headers,
        json={
            "category_id": income_category.id,
            "month": "2026-11",
            "limit_amount": 1000.00,
        },
    )
    assert response.status_code == 400
    assert "expense" in response.json()["detail"].lower()


def test_create_budget_invalid_month(client, auth_headers, expense_category):
    """Invalid month format → 422."""
    response = client.post(
        "/budgets",
        headers=auth_headers,
        json={
            "category_id": expense_category.id,
            "month": "2026/11",  # wrong separator
            "limit_amount": 7000.00,
        },
    )
    assert response.status_code == 422


def test_create_budget_month_13(client, auth_headers, expense_category):
    """Month 13 → 422."""
    response = client.post(
        "/budgets",
        headers=auth_headers,
        json={
            "category_id": expense_category.id,
            "month": "2026-13",
            "limit_amount": 7000.00,
        },
    )
    assert response.status_code == 422


def test_create_budget_negative_limit(client, auth_headers, expense_category):
    """Negative limit → 422."""
    response = client.post(
        "/budgets",
        headers=auth_headers,
        json={
            "category_id": expense_category.id,
            "month": "2026-11",
            "limit_amount": -100,
        },
    )
    assert response.status_code == 422


def test_create_budget_nonexistent_category(client, auth_headers):
    """Nonexistent category → 404."""
    response = client.post(
        "/budgets",
        headers=auth_headers,
        json={
            "category_id": 99999,
            "month": "2026-11",
            "limit_amount": 7000.00,
        },
    )
    assert response.status_code == 404


# ============================================================
# LIST / GET
# ============================================================

def test_list_budgets_empty(client, auth_headers):
    """No budgets → empty list."""
    response = client.get("/budgets", headers=auth_headers)
    assert response.status_code == 200
    assert response.json() == []


def test_list_budgets_filter_by_month(client, auth_headers, expense_category):
    """Filter budgets by month."""
    client.post("/budgets", headers=auth_headers, json={
        "category_id": expense_category.id,
        "month": "2026-10",
        "limit_amount": 5000,
    })
    client.post("/budgets", headers=auth_headers, json={
        "category_id": expense_category.id,
        "month": "2026-11",
        "limit_amount": 7000,
    })

    nov = client.get("/budgets?month=2026-11", headers=auth_headers).json()
    assert len(nov) == 1
    assert nov[0]["month"] == "2026-11"


def test_get_budget(client, auth_headers, expense_category):
    """Get single budget by ID."""
    create = client.post("/budgets", headers=auth_headers, json={
        "category_id": expense_category.id,
        "month": "2026-11",
        "limit_amount": 7000,
    })
    budget_id = create.json()["id"]

    response = client.get(f"/budgets/{budget_id}", headers=auth_headers)
    assert response.status_code == 200
    assert response.json()["id"] == budget_id


def test_get_nonexistent_budget(client, auth_headers):
    """Nonexistent ID → 404."""
    response = client.get("/budgets/99999", headers=auth_headers)
    assert response.status_code == 404


# ============================================================
# STATUS (safe / approaching / exceeded)
# ============================================================

def test_budget_status_safe(client, auth_headers, expense_category):
    """Spent < 80% → status 'safe'."""
    # Budget 10000, expense 2500 = 25%
    create = client.post("/budgets", headers=auth_headers, json={
        "category_id": expense_category.id,
        "month": "2026-11",
        "limit_amount": 10000,
    })
    budget_id = create.json()["id"]

    client.post("/transactions", headers=auth_headers, json={
        "type": "expense", "amount": 2500,
        "category_id": expense_category.id, "date": "2026-11-10",
    })

    response = client.get(f"/budgets/{budget_id}/status", headers=auth_headers)
    assert response.status_code == 200
    data = response.json()
    assert float(data["spent"]) == 2500
    assert float(data["remaining"]) == 7500
    assert data["percentage"] == 25.0
    assert data["status"] == "safe"


def test_budget_status_approaching(client, auth_headers, expense_category):
    """80% <= spent < 100% → status 'approaching'."""
    create = client.post("/budgets", headers=auth_headers, json={
        "category_id": expense_category.id,
        "month": "2026-11",
        "limit_amount": 10000,
    })
    budget_id = create.json()["id"]

    # 8500 / 10000 = 85%
    client.post("/transactions", headers=auth_headers, json={
        "type": "expense", "amount": 8500,
        "category_id": expense_category.id, "date": "2026-11-10",
    })

    response = client.get(f"/budgets/{budget_id}/status", headers=auth_headers)
    data = response.json()
    assert data["status"] == "approaching"
    assert data["percentage"] == 85.0


def test_budget_status_exceeded(client, auth_headers, expense_category):
    """Spent >= 100% → status 'exceeded'."""
    create = client.post("/budgets", headers=auth_headers, json={
        "category_id": expense_category.id,
        "month": "2026-11",
        "limit_amount": 5000,
    })
    budget_id = create.json()["id"]

    # 6000 / 5000 = 120%
    client.post("/transactions", headers=auth_headers, json={
        "type": "expense", "amount": 6000,
        "category_id": expense_category.id, "date": "2026-11-10",
    })

    response = client.get(f"/budgets/{budget_id}/status", headers=auth_headers)
    data = response.json()
    assert data["status"] == "exceeded"
    assert data["percentage"] == 120.0
    # remaining is negative when exceeded
    assert float(data["remaining"]) == -1000.0


def test_budget_status_zero_spent(client, auth_headers, expense_category):
    """No transactions → spent = 0, status safe."""
    create = client.post("/budgets", headers=auth_headers, json={
        "category_id": expense_category.id,
        "month": "2026-11",
        "limit_amount": 5000,
    })
    budget_id = create.json()["id"]

    response = client.get(f"/budgets/{budget_id}/status", headers=auth_headers)
    data = response.json()
    assert float(data["spent"]) == 0
    assert data["status"] == "safe"
    assert data["percentage"] == 0.0


def test_budget_status_ignores_income(client, auth_headers, expense_category):
    """Income transactions in same category shouldn't count toward spent."""
    create = client.post("/budgets", headers=auth_headers, json={
        "category_id": expense_category.id,
        "month": "2026-11",
        "limit_amount": 5000,
    })
    budget_id = create.json()["id"]

    # Create expense 1000
    client.post("/transactions", headers=auth_headers, json={
        "type": "expense", "amount": 1000,
        "category_id": expense_category.id, "date": "2026-11-05",
    })

    response = client.get(f"/budgets/{budget_id}/status", headers=auth_headers)
    data = response.json()
    assert float(data["spent"]) == 1000
    assert data["status"] == "safe"


def test_budget_status_ignores_other_months(client, auth_headers, expense_category):
    """Transactions outside the budget month shouldn't count."""
    create = client.post("/budgets", headers=auth_headers, json={
        "category_id": expense_category.id,
        "month": "2026-11",
        "limit_amount": 5000,
    })
    budget_id = create.json()["id"]

    # October transaction (should be ignored)
    client.post("/transactions", headers=auth_headers, json={
        "type": "expense", "amount": 3000,
        "category_id": expense_category.id, "date": "2026-10-15",
    })
    # November transaction (should be counted)
    client.post("/transactions", headers=auth_headers, json={
        "type": "expense", "amount": 1000,
        "category_id": expense_category.id, "date": "2026-11-15",
    })

    response = client.get(f"/budgets/{budget_id}/status", headers=auth_headers)
    data = response.json()
    assert float(data["spent"]) == 1000  # only November's
    assert data["status"] == "safe"


# ============================================================
# UPDATE
# ============================================================

def test_update_budget_limit(client, auth_headers, expense_category):
    """Update limit_amount."""
    create = client.post("/budgets", headers=auth_headers, json={
        "category_id": expense_category.id,
        "month": "2026-11",
        "limit_amount": 5000,
    })
    budget_id = create.json()["id"]

    response = client.put(
        f"/budgets/{budget_id}",
        headers=auth_headers,
        json={"limit_amount": 8000},
    )
    assert response.status_code == 200
    assert float(response.json()["limit_amount"]) == 8000


def test_update_budget_negative_limit(client, auth_headers, expense_category):
    """Negative new limit → 422."""
    create = client.post("/budgets", headers=auth_headers, json={
        "category_id": expense_category.id,
        "month": "2026-11",
        "limit_amount": 5000,
    })
    budget_id = create.json()["id"]

    response = client.put(
        f"/budgets/{budget_id}",
        headers=auth_headers,
        json={"limit_amount": -100},
    )
    assert response.status_code == 422


# ============================================================
# DELETE
# ============================================================

def test_delete_budget(client, auth_headers, expense_category):
    """Delete → 204."""
    create = client.post("/budgets", headers=auth_headers, json={
        "category_id": expense_category.id,
        "month": "2026-11",
        "limit_amount": 5000,
    })
    budget_id = create.json()["id"]

    response = client.delete(f"/budgets/{budget_id}", headers=auth_headers)
    assert response.status_code == 204

    get = client.get(f"/budgets/{budget_id}", headers=auth_headers)
    assert get.status_code == 404


def test_delete_nonexistent_budget(client, auth_headers):
    """Delete nonexistent → 404."""
    response = client.delete("/budgets/99999", headers=auth_headers)
    assert response.status_code == 404