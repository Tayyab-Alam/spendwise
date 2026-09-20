"""
Tests for transactions: CRUD, filters, pagination, ownership.
"""
from datetime import date
from decimal import Decimal

import pytest


# ============================================================
# CREATE
# ============================================================

def test_create_expense(client, auth_headers, expense_category):
    """Create an expense transaction → 201."""
    response = client.post(
        "/transactions",
        headers=auth_headers,
        json={
            "type": "expense",
            "amount": 500.50,
            "category_id": expense_category.id,
            "date": "2026-11-05",
            "note": "Lunch",
        },
    )
    assert response.status_code == 201
    data = response.json()
    assert data["type"] == "expense"
    assert float(data["amount"]) == 500.50
    assert data["note"] == "Lunch"
    assert data["category"]["id"] == expense_category.id


def test_create_income(client, auth_headers, income_category):
    """Create an income transaction → 201."""
    response = client.post(
        "/transactions",
        headers=auth_headers,
        json={
            "type": "income",
            "amount": 60000.00,
            "category_id": income_category.id,
            "date": "2026-11-01",
            "note": "Salary",
        },
    )
    assert response.status_code == 201
    assert response.json()["type"] == "income"


def test_create_negative_amount_rejected(client, auth_headers, expense_category):
    """Negative amount → 422."""
    response = client.post(
        "/transactions",
        headers=auth_headers,
        json={
            "type": "expense",
            "amount": -100,
            "category_id": expense_category.id,
            "date": "2026-11-05",
        },
    )
    assert response.status_code == 422


def test_create_zero_amount_rejected(client, auth_headers, expense_category):
    """Zero amount → 422."""
    response = client.post(
        "/transactions",
        headers=auth_headers,
        json={
            "type": "expense",
            "amount": 0,
            "category_id": expense_category.id,
            "date": "2026-11-05",
        },
    )
    assert response.status_code == 422


def test_create_type_mismatch_rejected(client, auth_headers, expense_category):
    """Income transaction with expense category → 400."""
    response = client.post(
        "/transactions",
        headers=auth_headers,
        json={
            "type": "income",
            "amount": 100,
            "category_id": expense_category.id,
            "date": "2026-11-05",
        },
    )
    assert response.status_code == 400
    assert "does not match" in response.json()["detail"].lower()


def test_create_with_nonexistent_category(client, auth_headers):
    """Nonexistent category → 404."""
    response = client.post(
        "/transactions",
        headers=auth_headers,
        json={
            "type": "expense",
            "amount": 100,
            "category_id": 99999,
            "date": "2026-11-05",
        },
    )
    assert response.status_code == 404


# ============================================================
# LIST / GET
# ============================================================

def test_list_transactions_empty(client, auth_headers):
    """No transactions yet → empty list."""
    response = client.get("/transactions", headers=auth_headers)
    assert response.status_code == 200
    assert response.json() == []


def test_list_transactions(client, auth_headers, expense_category):
    """Create 3, list should return 3."""
    for i in range(3):
        client.post(
            "/transactions",
            headers=auth_headers,
            json={
                "type": "expense",
                "amount": 100 + i,
                "category_id": expense_category.id,
                "date": "2026-11-05",
            },
        )
    response = client.get("/transactions", headers=auth_headers)
    assert response.status_code == 200
    assert len(response.json()) == 3


def test_get_single_transaction(client, auth_headers, expense_category):
    """Get by ID → 200."""
    create = client.post(
        "/transactions",
        headers=auth_headers,
        json={
            "type": "expense",
            "amount": 500,
            "category_id": expense_category.id,
            "date": "2026-11-05",
        },
    )
    txn_id = create.json()["id"]

    response = client.get(f"/transactions/{txn_id}", headers=auth_headers)
    assert response.status_code == 200
    assert response.json()["id"] == txn_id


def test_get_nonexistent_transaction(client, auth_headers):
    """Get nonexistent → 404."""
    response = client.get("/transactions/99999", headers=auth_headers)
    assert response.status_code == 404


# ============================================================
# FILTERS
# ============================================================

def test_filter_by_type(client, auth_headers, expense_category, income_category):
    """Filter by type → only that type."""
    client.post("/transactions", headers=auth_headers, json={
        "type": "expense", "amount": 100,
        "category_id": expense_category.id, "date": "2026-11-05",
    })
    client.post("/transactions", headers=auth_headers, json={
        "type": "income", "amount": 100,
        "category_id": income_category.id, "date": "2026-11-05",
    })

    expenses = client.get("/transactions?type=expense", headers=auth_headers).json()
    assert len(expenses) == 1
    assert expenses[0]["type"] == "expense"

    incomes = client.get("/transactions?type=income", headers=auth_headers).json()
    assert len(incomes) == 1
    assert incomes[0]["type"] == "income"


def test_filter_by_category(client, auth_headers, test_db, expense_category, test_user):
    """Filter by category_id."""
    from app.models.category import Category
    # Create another custom category
    other_cat = Category(name="Custom", type="expense", user_id=test_user.id)
    test_db.add(other_cat)
    test_db.commit()
    test_db.refresh(other_cat)

    client.post("/transactions", headers=auth_headers, json={
        "type": "expense", "amount": 100,
        "category_id": expense_category.id, "date": "2026-11-05",
    })
    client.post("/transactions", headers=auth_headers, json={
        "type": "expense", "amount": 200,
        "category_id": other_cat.id, "date": "2026-11-05",
    })

    filtered = client.get(
        f"/transactions?category_id={other_cat.id}",
        headers=auth_headers,
    ).json()
    assert len(filtered) == 1
    assert filtered[0]["category"]["id"] == other_cat.id


def test_filter_by_date_range(client, auth_headers, expense_category):
    """Filter by date_from and date_to."""
    # Create in October
    client.post("/transactions", headers=auth_headers, json={
        "type": "expense", "amount": 100,
        "category_id": expense_category.id, "date": "2026-10-15",
    })
    # Create in November
    client.post("/transactions", headers=auth_headers, json={
        "type": "expense", "amount": 200,
        "category_id": expense_category.id, "date": "2026-11-15",
    })

    nov = client.get(
        "/transactions?date_from=2026-11-01&date_to=2026-11-30",
        headers=auth_headers,
    ).json()
    assert len(nov) == 1
    assert float(nov[0]["amount"]) == 200


def test_filter_by_search_note(client, auth_headers, expense_category):
    """Search in note field."""
    client.post("/transactions", headers=auth_headers, json={
        "type": "expense", "amount": 100,
        "category_id": expense_category.id, "date": "2026-11-05",
        "note": "Coffee with client",
    })
    client.post("/transactions", headers=auth_headers, json={
        "type": "expense", "amount": 200,
        "category_id": expense_category.id, "date": "2026-11-06",
        "note": "Groceries",
    })

    results = client.get("/transactions?search=coffee", headers=auth_headers).json()
    assert len(results) == 1
    assert "coffee" in results[0]["note"].lower()


def test_sort_by_amount_desc(client, auth_headers, expense_category):
    """Sort by amount descending."""
    for amt in [100, 300, 200]:
        client.post("/transactions", headers=auth_headers, json={
            "type": "expense", "amount": amt,
            "category_id": expense_category.id, "date": "2026-11-05",
        })

    results = client.get(
        "/transactions?sort_by=amount&sort_order=desc",
        headers=auth_headers,
    ).json()
    amounts = [float(t["amount"]) for t in results]
    assert amounts == [300.0, 200.0, 100.0]


def test_pagination(client, auth_headers, expense_category):
    """Pagination via skip + limit."""
    for i in range(5):
        client.post("/transactions", headers=auth_headers, json={
            "type": "expense", "amount": 100 + i,
            "category_id": expense_category.id, "date": "2026-11-05",
        })

    page1 = client.get("/transactions?limit=2", headers=auth_headers).json()
    assert len(page1) == 2

    page2 = client.get("/transactions?limit=2&skip=2", headers=auth_headers).json()
    assert len(page2) == 2
    assert page1[0]["id"] != page2[0]["id"]


def test_filter_invalid_date_range(client, auth_headers):
    """date_from > date_to → 400."""
    response = client.get(
        "/transactions?date_from=2026-12-01&date_to=2026-11-01",
        headers=auth_headers,
    )
    assert response.status_code == 400


# ============================================================
# UPDATE
# ============================================================

def test_update_transaction_amount(client, auth_headers, expense_category):
    """Update amount."""
    create = client.post("/transactions", headers=auth_headers, json={
        "type": "expense", "amount": 100,
        "category_id": expense_category.id, "date": "2026-11-05",
    })
    txn_id = create.json()["id"]

    response = client.put(
        f"/transactions/{txn_id}",
        headers=auth_headers,
        json={"amount": 250.75},
    )
    assert response.status_code == 200
    assert float(response.json()["amount"]) == 250.75


def test_update_type_mismatch_rejected(client, auth_headers, expense_category, income_category):
    """Update to a type that mismatches category → 400."""
    create = client.post("/transactions", headers=auth_headers, json={
        "type": "expense", "amount": 100,
        "category_id": expense_category.id, "date": "2026-11-05",
    })
    txn_id = create.json()["id"]

    response = client.put(
        f"/transactions/{txn_id}",
        headers=auth_headers,
        json={"type": "income"},  # mismatches expense category
    )
    assert response.status_code == 400


# ============================================================
# DELETE
# ============================================================

def test_delete_transaction(client, auth_headers, expense_category):
    """Delete → 204."""
    create = client.post("/transactions", headers=auth_headers, json={
        "type": "expense", "amount": 100,
        "category_id": expense_category.id, "date": "2026-11-05",
    })
    txn_id = create.json()["id"]

    response = client.delete(f"/transactions/{txn_id}", headers=auth_headers)
    assert response.status_code == 204

    get = client.get(f"/transactions/{txn_id}", headers=auth_headers)
    assert get.status_code == 404


def test_delete_nonexistent(client, auth_headers):
    """Delete nonexistent → 404."""
    response = client.delete("/transactions/99999", headers=auth_headers)
    assert response.status_code == 404