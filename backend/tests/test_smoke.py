"""Smoke tests to verify fixtures are working."""


def test_health_check(client):
    """Basic health endpoint should respond."""
    response = client.get("/health")
    assert response.status_code == 200
    assert response.json()["status"] == "ok"


def test_root(client):
    """Root endpoint should respond."""
    response = client.get("/")
    assert response.status_code == 200
    assert response.json()["app"] == "SpendWise"


def test_test_user_created(test_user):
    """test_user fixture should create a user."""
    assert test_user.id is not None
    assert test_user.email == "testuser@example.com"


def test_auth_headers_valid(client, auth_headers):
    """auth_headers should give access to /users/me."""
    response = client.get("/users/me", headers=auth_headers)
    assert response.status_code == 200
    assert response.json()["email"] == "testuser@example.com"


def test_unauthorized_without_token(client):
    """No token → 401."""
    response = client.get("/users/me")
    assert response.status_code == 401