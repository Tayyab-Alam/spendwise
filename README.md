# SpendWise

A personal finance app I built to help people answer a simple question: **where is my money actually going?**

Most people don't have a spending problem — they have a *visibility* problem. Small purchases add up (Rs. 300 for chai, Rs. 500 for food, Rs. 800 for a ride) and by month-end you're staring at your bank statement wondering what happened. SpendWise is my attempt to fix that.

It's a full-stack mobile app — FastAPI backend, PostgreSQL, Flutter frontend — that lets you record income and expenses, organize them by category, set monthly budgets, and see where your money actually goes through charts and summaries.

Built as a portfolio project after my final year at COMSATS, mainly to demonstrate production-style engineering: clean architecture, real authentication, ownership enforcement, automated testing, and Docker.

---

## What It Does

**Track everything.** Record income and expenses with categories, dates, and notes. Filter by type, category, or date range. Search by note. Sort and paginate.

**Understand spending.** Monthly summaries, category-wise breakdowns, 12-month trends, and an all-time balance. Not just numbers — the *shape* of your spending.

**Set budgets.** Per-category monthly limits. The app tracks spent vs remaining, and flags when you're approaching (80%+) or exceeding your limit.

**Stay secure.** JWT auth, bcrypt password hashing, and strict ownership rules — you can only ever see your own data. This is enforced on the backend, not trusted from the client.

---

## Tech Stack

| Layer | Choice | Why |
|---|---|---|
| Backend | FastAPI | Async, auto-generated OpenAPI docs, Pydantic validation built in |
| Database | PostgreSQL 16 | Relational integrity matters for financial data |
| ORM | SQLAlchemy 2.0 | Explicit queries, easy to reason about |
| Migrations | Alembic | Version-controlled schema — no manual SQL |
| Auth | JWT + Bcrypt | Stateless auth, secure password storage |
| Money handling | `Numeric(12,2)` | Never `float` — floating-point errors are unacceptable for money |
| Testing | Pytest | 100 tests, 100% pass rate |
| Containerization | Docker Compose | `docker compose up` and you're done |
| Package manager | uv | Fast, lock-file based, replaces pip/venv |
| Frontend | Flutter + Provider | Mobile-first, one codebase for Android/iOS |

---

## Architecture

```
Flutter App (Provider)
        │
        │ HTTPS / REST
        ▼
FastAPI Backend
        │
        ├── Routes        — HTTP endpoints
        ├── Schemas       — Pydantic request/response validation
        ├── Services      — Business logic (ownership, budget calc, etc.)
        ├── CRUD          — Database queries only
        └── Models        — SQLAlchemy ORM
        │
        ▼
PostgreSQL 16
```

**A few decisions worth calling out:**

- **Layered, not fat controllers.** Routes don't touch the DB directly. Business logic lives in services. DB access lives in CRUD. This makes things testable and keeps HTTP concerns out of business rules.
- **Ownership enforced on the server.** Every query filters by the authenticated user's ID. Client-provided IDs are never trusted. Returns `404` (not `403`) when accessing other users' resources, to avoid leaking existence.
- **N+1 prevention with `joinedload`.** Transaction list endpoints eager-load categories in a single query.
- **Decimal everywhere.** `Numeric(12, 2)` columns and Python `Decimal` throughout. No float arithmetic on money, ever.
- **Soft-delete pattern for categories.** Users can deactivate custom categories instead of hard-deleting them, and categories used by transactions or budgets can't be deleted.

---

## Getting Started

### With Docker (recommended)

You'll need Docker Desktop running.

```bash
git clone https://github.com/Tayyab-Alam/spendwise.git
cd spendwise/backend
cp .env.example .env
docker compose up --build -d
```

The backend container does everything on startup:
1. Waits for PostgreSQL to be healthy
2. Runs Alembic migrations
3. Seeds 13 default categories
4. Starts Uvicorn

Verify it's alive:
- API: http://localhost:8000
- Swagger UI: http://localhost:8000/docs
- Health: http://localhost:8000/health

Shut it down:

```bash
docker compose down       # keeps data
docker compose down -v    # wipes the database volume
```

### Without Docker

You'll need Python 3.11+, PostgreSQL 16, and [uv](https://github.com/astral-sh/uv).

```bash
git clone https://github.com/Tayyab-Alam/spendwise.git
cd spendwise/backend

uv sync

cp .env.example .env
# open .env and set DATABASE_URL to your local PostgreSQL instance

uv run alembic upgrade head
uv run python -m app.db.seed
uv run uvicorn app.main:app --reload
```

You'll also want to create `spendwise_test_db` if you plan to run the test suite.

---

## API Overview

Interactive docs live at `/docs`. Here's the short version:

**Auth** — `POST /auth/register`, `POST /auth/login`

**Users** — `GET /users/me`, `PUT /users/me`

**Categories** — full CRUD at `/categories`, plus `?type=income|expense` filtering. Default categories (seeded) can't be modified or deleted.

**Transactions** — full CRUD at `/transactions`. The `GET` endpoint supports:

| Param | Values |
|---|---|
| `type` | `income` \| `expense` |
| `category_id` | integer |
| `date_from` / `date_to` | `YYYY-MM-DD` |
| `search` | text (searches note) |
| `sort_by` | `date` \| `amount` |
| `sort_order` | `asc` \| `desc` |
| `skip` / `limit` | pagination |

**Budgets** — CRUD at `/budgets`. The interesting endpoint is `GET /budgets/{id}/status`, which returns spent, remaining, percentage, and a status of `safe` / `approaching` / `exceeded` — calculated live from the user's transactions.

**Analytics** — `GET /analytics/summary?month=YYYY-MM`, `GET /analytics/categories`, `GET /analytics/monthly?year=YYYY`, `GET /analytics/balance`.

All endpoints require `Authorization: Bearer <token>` except register/login.

---

## Testing

```bash
cd backend
uv run pytest -v
```

100 tests, all passing, running in about 25 seconds.

| Test file | Count | What it covers |
|---|---|---|
| `test_smoke.py` | 5 | Health endpoints and fixture sanity |
| `test_auth.py` | 13 | Register, login, JWT, validation |
| `test_categories.py` | 16 | Default + custom categories, ownership, protection rules |
| `test_transactions.py` | 21 | CRUD, filters, sorting, pagination, validation |
| `test_budgets.py` | 21 | CRUD, month validation, spent calculation, status transitions |
| `test_authorization.py` | 24 | **Cross-user access** — one user cannot read/update/delete another's data |

Tests run against an **isolated test database** (`spendwise_test_db`). The fixtures in `tests/conftest.py` create the schema once per session, clean up data between tests, and provide authenticated test users (including a second user for cross-user tests).

I also kept a `scripts/` folder with older manual test scripts that I used during development for quick end-to-end checks. They're not part of the automated suite, but they're handy when debugging specific flows.

---

## Project Structure

```
spendwise/
├── backend/
│   ├── app/
│   │   ├── core/           # config, security, exceptions
│   │   ├── db/             # engine, session, seed
│   │   ├── dependencies/   # get_db, get_current_user
│   │   ├── models/         # SQLAlchemy models
│   │   ├── schemas/        # Pydantic schemas
│   │   ├── crud/           # DB queries
│   │   ├── services/       # business logic
│   │   ├── routes/         # API endpoints
│   │   └── main.py
│   ├── alembic/            # migrations
│   ├── tests/              # pytest suite (100 tests)
│   ├── scripts/            # manual test scripts
│   ├── Dockerfile
│   ├── docker-compose.yml
│   ├── pyproject.toml
│   └── .env.example
└── frontend/               # Flutter (in progress)
```

---

## Configuration

Copy `.env.example` to `.env` and fill in your values:

| Variable | Notes |
|---|---|
| `DATABASE_URL` | PostgreSQL connection string |
| `TEST_DATABASE_URL` | Separate DB for the test suite |
| `JWT_SECRET_KEY` | **Use a real secret in production** |
| `ACCESS_TOKEN_EXPIRE_MINUTES` | Default 60 |
| `CORS_ORIGINS` | Comma-separated list |

`.env` is gitignored. Never commit it.

---

## Status

- [x] FastAPI backend with PostgreSQL
- [x] JWT auth + ownership enforcement
- [x] Categories, Transactions, Budgets, Analytics
- [x] 100 automated tests
- [x] Docker Compose setup
- [ ] Flutter frontend (in progress)
- [ ] Dashboard charts + dark/light theme

---

## Notes & Tradeoffs

A few things I'd do differently at scale, and one or two that were deliberate:

- **No refresh tokens yet.** Access tokens expire in 60 minutes and the client re-logs in. For a mobile app this is annoying. A refresh-token flow is on the roadmap.
- **No rate limiting.** Login endpoints should have it. Out of scope for v1.
- **Balance is derived, not stored.** Current balance = sum(income) − sum(expense). This is correct and simple, but at high volume you'd want a materialized view or a running balance column.
- **Seeding runs on every container start.** It's idempotent (checks for existence first), but in a real deployment you'd gate this behind a one-time migration or a CLI flag.

---

## License

MIT.

---

## Author

**Tayyab Alam** — BS Software Engineering, COMSATS Islamabad (Abbottabad)

- GitHub: [@Tayyab-Alam](https://github.com/Tayyab-Alam)
- LinkedIn: [tayyab-alam-2a81a03a1](https://linkedin.com/in/tayyab-alam-2a81a03a1)
- Email: tayyabalam635@gmail.com