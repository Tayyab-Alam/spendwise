"""
Pytest fixtures for SpendWise backend tests.

Provides:
- test_db: isolated test database session
- client: FastAPI TestClient with DB override
- test_user: a registered user
- auth_headers: Authorization header with valid JWT
- second_user / second_user_headers: for cross-user tests
"""
from typing import Generator

import pytest
from fastapi.testclient import TestClient
from sqlalchemy import create_engine
from sqlalchemy.orm import Session, sessionmaker

from app.core.config import settings
from app.core.security import create_access_token
from app.db.database import Base
from app.db.seed import seed_default_categories
from app.dependencies.db import get_db
from app.main import app
from app.models import Budget, Category, Transaction, User  # noqa: F401
from app.core.security import hash_password


# ============================================================
# TEST DATABASE ENGINE (module-level, one per test session)
# ============================================================

test_engine = create_engine(settings.TEST_DATABASE_URL, pool_pre_ping=True)
TestingSessionLocal = sessionmaker(
    autocommit=False,
    autoflush=False,
    bind=test_engine,
    future=True,
)


# ============================================================
# SESSION-LEVEL SETUP
# ============================================================

@pytest.fixture(scope="session", autouse=True)
def setup_test_database() -> Generator[None, None, None]:
    """
    Create all tables in test DB once per test session,
    seed default categories, then drop at the end.
    """
    # Drop any existing tables (clean slate)
    Base.metadata.drop_all(bind=test_engine)
    # Create all tables
    Base.metadata.create_all(bind=test_engine)

    # Seed default categories (they don't belong to any user)
    db = TestingSessionLocal()
    try:
        seed_default_categories(db)
    finally:
        db.close()

    yield

    # Teardown: drop everything
    Base.metadata.drop_all(bind=test_engine)


# ============================================================
# PER-TEST ISOLATION — clean data between tests
# ============================================================

@pytest.fixture(autouse=True)
def clean_between_tests() -> Generator[None, None, None]:
    """
    Ensure each test starts with a clean state:
    - Transactions and budgets deleted
    - Custom categories deleted (keep default ones)
    - Users deleted
    """
    yield

    db = TestingSessionLocal()
    try:
        # Delete in dependency order
        db.query(Transaction).delete()
        db.query(Budget).delete()
        db.query(Category).filter(Category.user_id.isnot(None)).delete()
        db.query(User).delete()
        db.commit()
    finally:
        db.close()


# ============================================================
# DATABASE FIXTURE
# ============================================================

@pytest.fixture
def test_db() -> Generator[Session, None, None]:
    """Yield a database session for the test database."""
    db = TestingSessionLocal()
    try:
        yield db
    finally:
        db.close()


# ============================================================
# TEST CLIENT FIXTURE
# ============================================================

@pytest.fixture
def client(test_db: Session) -> Generator[TestClient, None, None]:
    """
    FastAPI TestClient with DB dependency overridden
    to use the test database.
    """
    def override_get_db():
        try:
            yield test_db
        finally:
            pass  # session closed by test_db fixture

    app.dependency_overrides[get_db] = override_get_db
    with TestClient(app) as c:
        yield c
    app.dependency_overrides.clear()


# ============================================================
# USER FIXTURES
# ============================================================

@pytest.fixture
def test_user(test_db: Session) -> User:
    """Create a registered user in the test DB."""
    user = User(
        name="Test User",
        email="testuser@example.com",
        password_hash=hash_password("testpass123"),
    )
    test_db.add(user)
    test_db.commit()
    test_db.refresh(user)
    return user


@pytest.fixture
def auth_headers(test_user: User) -> dict[str, str]:
    """Authorization header with a valid JWT for test_user."""
    token = create_access_token(subject=test_user.id)
    return {"Authorization": f"Bearer {token}"}


@pytest.fixture
def second_user(test_db: Session) -> User:
    """Second user for cross-user ownership tests."""
    user = User(
        name="Second User",
        email="second@example.com",
        password_hash=hash_password("secondpass123"),
    )
    test_db.add(user)
    test_db.commit()
    test_db.refresh(user)
    return user


@pytest.fixture
def second_user_headers(second_user: User) -> dict[str, str]:
    """Authorization header for second_user."""
    token = create_access_token(subject=second_user.id)
    return {"Authorization": f"Bearer {token}"}


# ============================================================
# HELPER FIXTURES
# ============================================================

@pytest.fixture
def expense_category(test_db: Session):
    """Return a default expense category."""
    return (
        test_db.query(Category)
        .filter(Category.type == "expense", Category.user_id.is_(None))
        .first()
    )


@pytest.fixture
def income_category(test_db: Session):
    """Return a default income category."""
    return (
        test_db.query(Category)
        .filter(Category.type == "income", Category.user_id.is_(None))
        .first()
    )