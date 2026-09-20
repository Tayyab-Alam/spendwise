"""
Tests for authentication: registration, login, JWT tokens.
"""
import pytest


# ============================================================
# REGISTRATION TESTS
# ============================================================

def test_register_success(client):
    """Register a new user → 201 with user data (no password)."""
    response = client.post("/auth/register", json={
        "name": "New User",
        "email": "newuser@example.com",
        "password": "secret12345",
    })
    assert response.status_code == 201
    data = response.json()
    assert data["name"] == "New User"
    assert data["email"] == "newuser@example.com"
    assert "id" in data
    assert "created_at" in data
    # Password must NOT be exposed
    assert "password" not in data
    assert "password_hash" not in data


def test_register_duplicate_email(client, test_user):
    """Register with an existing email → 409 Conflict."""
    response = client.post("/auth/register", json={
        "name": "Duplicate",
        "email": test_user.email,  # already registered
        "password": "secret12345",
    })
    assert response.status_code == 409
    assert "already registered" in response.json()["detail"].lower()


def test_register_invalid_email(client):
    """Invalid email format → 422 Validation Error."""
    response = client.post("/auth/register", json={
        "name": "Invalid",
        "email": "not-an-email",
        "password": "secret12345",
    })
    assert response.status_code == 422


def test_register_short_password(client):
    """Password < 8 chars → 422 Validation Error."""
    response = client.post("/auth/register", json={
        "name": "Short Pass",
        "email": "short@example.com",
        "password": "abc",  # too short
    })
    assert response.status_code == 422


def test_register_missing_fields(client):
    """Missing required fields → 422."""
    response = client.post("/auth/register", json={
        "email": "incomplete@example.com",
    })
    assert response.status_code == 422


def test_register_email_normalized_to_lowercase(client):
    """Email should be stored in lowercase."""
    response = client.post("/auth/register", json={
        "name": "Caps User",
        "email": "CAPS@Example.com",
        "password": "secret12345",
    })
    assert response.status_code == 201
    assert response.json()["email"] == "caps@example.com"


# ============================================================
# LOGIN TESTS
# ============================================================

def test_login_success(client, test_user):
    """Valid credentials → 200 with access token."""
    response = client.post("/auth/login", json={
        "email": test_user.email,
        "password": "testpass123",
    })
    assert response.status_code == 200
    data = response.json()
    assert "access_token" in data
    assert data["token_type"] == "bearer"
    assert len(data["access_token"]) > 20


def test_login_wrong_password(client, test_user):
    """Wrong password → 401 with generic message."""
    response = client.post("/auth/login", json={
        "email": test_user.email,
        "password": "wrongpassword",
    })
    assert response.status_code == 401
    # Message should not reveal whether email exists
    assert "invalid email or password" in response.json()["detail"].lower()


def test_login_nonexistent_user(client):
    """Nonexistent email → 401 (same generic message)."""
    response = client.post("/auth/login", json={
        "email": "ghost@example.com",
        "password": "anypassword",
    })
    assert response.status_code == 401
    assert "invalid email or password" in response.json()["detail"].lower()


def test_login_case_insensitive_email(client, test_user):
    """Login should work with different email case."""
    response = client.post("/auth/login", json={
        "email": test_user.email.upper(),
        "password": "testpass123",
    })
    assert response.status_code == 200


# ============================================================
# JWT TOKEN TESTS
# ============================================================

def test_jwt_token_grants_access(client, test_user):
    """Token from /login gives access to /users/me."""
    login = client.post("/auth/login", json={
        "email": test_user.email,
        "password": "testpass123",
    })
    token = login.json()["access_token"]

    response = client.get(
        "/users/me",
        headers={"Authorization": f"Bearer {token}"},
    )
    assert response.status_code == 200
    assert response.json()["email"] == test_user.email


def test_invalid_token_rejected(client):
    """Malformed JWT → 401."""
    response = client.get(
        "/users/me",
        headers={"Authorization": "Bearer invalid.token.here"},
    )
    assert response.status_code == 401


def test_malformed_auth_header(client):
    """Authorization without 'Bearer ' prefix → 401."""
    response = client.get(
        "/users/me",
        headers={"Authorization": "just-a-token"},
    )
    assert response.status_code == 401