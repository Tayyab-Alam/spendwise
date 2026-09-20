"""
Tests for categories: default categories, custom creation,
ownership, update/delete rules, filtering.
"""
import pytest


# ============================================================
# DEFAULT CATEGORIES
# ============================================================

def test_default_categories_are_seeded(client, auth_headers):
    """Default categories should exist for every user."""
    response = client.get("/categories", headers=auth_headers)
    assert response.status_code == 200
    cats = response.json()
    # Seeded script inserts 13 default categories
    assert len(cats) >= 13


def test_default_categories_have_null_user_id(client, auth_headers):
    """Default categories have user_id = None."""
    response = client.get("/categories", headers=auth_headers)
    cats = response.json()
    defaults = [c for c in cats if c["user_id"] is None]
    assert len(defaults) >= 13


def test_filter_by_type_income(client, auth_headers):
    """Filter by type=income."""
    response = client.get("/categories?type=income", headers=auth_headers)
    assert response.status_code == 200
    cats = response.json()
    assert all(c["type"] == "income" for c in cats)
    assert len(cats) >= 1


def test_filter_by_type_expense(client, auth_headers):
    """Filter by type=expense."""
    response = client.get("/categories?type=expense", headers=auth_headers)
    cats = response.json()
    assert all(c["type"] == "expense" for c in cats)
    assert len(cats) >= 1


# ============================================================
# CREATE CUSTOM CATEGORY
# ============================================================

def test_create_custom_category(client, auth_headers, test_user):
    """Create a custom category → 201, user_id = test_user.id."""
    response = client.post(
        "/categories",
        headers=auth_headers,
        json={"name": "Coffee", "type": "expense"},
    )
    assert response.status_code == 201
    data = response.json()
    assert data["name"] == "Coffee"
    assert data["type"] == "expense"
    assert data["user_id"] == test_user.id
    assert data["is_active"] is True


def test_create_custom_category_duplicate(client, auth_headers):
    """Same name+type for same user → 409."""
    payload = {"name": "Coffee", "type": "expense"}
    client.post("/categories", headers=auth_headers, json=payload)
    # Try duplicate
    response = client.post("/categories", headers=auth_headers, json=payload)
    assert response.status_code == 409


def test_create_category_duplicate_with_default(client, auth_headers):
    """Custom category cannot clash with a default category name."""
    # "Food" is seeded default
    response = client.post(
        "/categories",
        headers=auth_headers,
        json={"name": "Food", "type": "expense"},
    )
    assert response.status_code == 409


def test_create_category_invalid_type(client, auth_headers):
    """Type must be 'income' or 'expense' → 422."""
    response = client.post(
        "/categories",
        headers=auth_headers,
        json={"name": "Bad", "type": "invalid"},
    )
    assert response.status_code == 422


def test_create_category_empty_name(client, auth_headers):
    """Empty name → 422."""
    response = client.post(
        "/categories",
        headers=auth_headers,
        json={"name": "", "type": "expense"},
    )
    assert response.status_code == 422


# ============================================================
# LIST / GET
# ============================================================

def test_get_single_category(client, auth_headers):
    """Get a default category by ID → 200."""
    # Get any category first
    all_cats = client.get("/categories", headers=auth_headers).json()
    cat_id = all_cats[0]["id"]

    response = client.get(f"/categories/{cat_id}", headers=auth_headers)
    assert response.status_code == 200
    assert response.json()["id"] == cat_id


def test_get_nonexistent_category(client, auth_headers):
    """Get nonexistent category → 404."""
    response = client.get("/categories/99999", headers=auth_headers)
    assert response.status_code == 404


# ============================================================
# UPDATE
# ============================================================

def test_update_custom_category(client, auth_headers):
    """Rename a custom category → 200."""
    create = client.post(
        "/categories",
        headers=auth_headers,
        json={"name": "OldName", "type": "expense"},
    )
    cat_id = create.json()["id"]

    response = client.put(
        f"/categories/{cat_id}",
        headers=auth_headers,
        json={"name": "NewName"},
    )
    assert response.status_code == 200
    assert response.json()["name"] == "NewName"


def test_update_default_category_forbidden(client, auth_headers):
    """Modifying a default category → 403."""
    # Get a default category
    cats = client.get("/categories?type=expense", headers=auth_headers).json()
    default_cat = next(c for c in cats if c["user_id"] is None)

    response = client.put(
        f"/categories/{default_cat['id']}",
        headers=auth_headers,
        json={"name": "Hacked"},
    )
    assert response.status_code == 403


def test_update_custom_category_duplicate_name(client, auth_headers):
    """Rename to a name that clashes → 409."""
    client.post("/categories", headers=auth_headers, json={"name": "First", "type": "expense"})
    second = client.post("/categories", headers=auth_headers, json={"name": "Second", "type": "expense"})
    second_id = second.json()["id"]

    response = client.put(
        f"/categories/{second_id}",
        headers=auth_headers,
        json={"name": "First"},
    )
    assert response.status_code == 409


# ============================================================
# DELETE
# ============================================================

def test_delete_custom_category(client, auth_headers):
    """Delete a custom category → 204."""
    create = client.post(
        "/categories",
        headers=auth_headers,
        json={"name": "Temp", "type": "expense"},
    )
    cat_id = create.json()["id"]

    response = client.delete(f"/categories/{cat_id}", headers=auth_headers)
    assert response.status_code == 204

    # Verify deleted
    get = client.get(f"/categories/{cat_id}", headers=auth_headers)
    assert get.status_code == 404


def test_delete_default_category_forbidden(client, auth_headers):
    """Deleting a default category → 403."""
    cats = client.get("/categories?type=expense", headers=auth_headers).json()
    default_cat = next(c for c in cats if c["user_id"] is None)

    response = client.delete(
        f"/categories/{default_cat['id']}",
        headers=auth_headers,
    )
    assert response.status_code == 403