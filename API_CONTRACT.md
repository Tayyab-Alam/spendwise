# SpendWise — API Contract (v1)

Base URL (development): `http://localhost:8000`
Base URL (production): `TBD`

All endpoints (except `/auth/register` and `/auth/login`) require:

```
Authorization: Bearer <access_token>
```

All request/response bodies are JSON unless otherwise noted.

---

## Global Error Responses

All errors follow FastAPI's standard format:

```json
{
  "detail": "Human-readable error message"
}
```

Validation errors (HTTP 422) use a different shape:

```json
{
  "detail": [
    {
      "loc": ["body", "email"],
      "msg": "value is not a valid email address",
      "type": "value_error.email"
    }
  ]
}
```

| Status | Meaning |
|---|---|
| `200 OK` | Success (GET, PUT) |
| `201 Created` | Resource created (POST) |
| `204 No Content` | Resource deleted (DELETE) |
| `400 Bad Request` | Business rule violation |
| `401 Unauthorized` | Missing/invalid token |
| `403 Forbidden` | Action not allowed (e.g., modifying defaults) |
| `404 Not Found` | Resource doesn't exist or isn't owned |
| `409 Conflict` | Duplicate resource |
| `422 Unprocessable Entity` | Validation error |

---

## 1. Authentication

### POST /auth/register

Register a new user.

**Auth:** Not required.

**Request Body:**

```json
{
  "name": "Tayyab Alam",
  "email": "tayyab@example.com",
  "password": "secret12345"
}
```

**Validation:**
- `name`: 1-100 characters
- `email`: valid email, unique
- `password`: 8-72 characters

**Response 201:**

```json
{
  "id": 1,
  "name": "Tayyab Alam",
  "email": "tayyab@example.com",
  "created_at": "2026-09-21T10:30:00+05:00"
}
```

**Response 409:**

```json
{ "detail": "Email is already registered" }
```

---

### POST /auth/login

Login and receive JWT.

**Auth:** Not required.

**Request Body:**

```json
{
  "email": "tayyab@example.com",
  "password": "secret12345"
}
```

**Response 200:**

```json
{
  "access_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "token_type": "bearer"
}
```

**Response 401:**

```json
{ "detail": "Invalid email or password" }
```

---

## 2. Users

### GET /users/me

Get current user's profile.

**Auth:** Required.

**Response 200:**

```json
{
  "id": 1,
  "name": "Tayyab Alam",
  "email": "tayyab@example.com",
  "created_at": "2026-09-21T10:30:00+05:00"
}
```

---

### PUT /users/me

Update profile.

**Auth:** Required.

**Request Body:** (all fields optional)

```json
{
  "name": "Tayyab Alam",
  "email": "new@example.com"
}
```

**Response 200:** Same as `GET /users/me`.

---

## 3. Categories

Default categories are seeded on backend startup. They have `user_id = null` and cannot be modified/deleted.

### GET /categories

List all categories (default + user's custom).

**Auth:** Required.

**Query params:**
- `type` (optional): `income` | `expense`

**Response 200:**

```json
[
  {
    "id": 1,
    "name": "Food",
    "type": "expense",
    "user_id": null,
    "is_active": true,
    "created_at": "2026-09-21T10:30:00+05:00"
  },
  {
    "id": 14,
    "name": "Coffee",
    "type": "expense",
    "user_id": 1,
    "is_active": true,
    "created_at": "2026-09-21T11:00:00+05:00"
  }
]
```

---

### POST /categories

Create a custom category.

**Auth:** Required.

**Request Body:**

```json
{
  "name": "Coffee",
  "type": "expense"
}
```

**Response 201:**

```json
{
  "id": 14,
  "name": "Coffee",
  "type": "expense",
  "user_id": 1,
  "is_active": true,
  "created_at": "2026-09-21T11:00:00+05:00"
}
```

**Response 409:** Duplicate name+type for user or clashes with default.

---

### GET /categories/{id}

Get a single category.

**Auth:** Required.

**Response 200:** Same shape as list item.

**Response 404:** Category doesn't exist or doesn't belong to user.

---

### PUT /categories/{id}

Update a custom category.

**Auth:** Required.

**Request Body:** (all optional)

```json
{
  "name": "Coffee & Tea",
  "is_active": true
}
```

**Response 200:** Updated category.

**Response 403:** Attempted to modify a default category.

**Response 404:** Not owned by user.

**Response 409:** New name clashes.

---

### DELETE /categories/{id}

Delete a custom category.

**Auth:** Required.

**Response 204:** No content.

**Response 403:** Attempted to delete a default category.

**Response 404:** Not owned by user.

---

## 4. Transactions

### GET /transactions

List transactions for current user with filters.

**Auth:** Required.

**Query params:**

| Param | Type | Notes |
|---|---|---|
| `type` | string | `income` \| `expense` |
| `category_id` | int | Filter by category |
| `date_from` | date | `YYYY-MM-DD`, inclusive |
| `date_to` | date | `YYYY-MM-DD`, inclusive |
| `search` | string | Searches `note` field (case-insensitive) |
| `sort_by` | string | `date` (default) \| `amount` |
| `sort_order` | string | `desc` (default) \| `asc` |
| `skip` | int | Pagination offset, default 0 |
| `limit` | int | 1-100, default 50 |

**Response 200:**

```json
[
  {
    "id": 1,
    "user_id": 1,
    "type": "expense",
    "amount": "500.50",
    "category_id": 1,
    "date": "2026-09-21",
    "note": "Lunch",
    "category": {
      "id": 1,
      "name": "Food",
      "type": "expense",
      "user_id": null,
      "is_active": true,
      "created_at": "2026-09-21T10:30:00+05:00"
    },
    "created_at": "2026-09-21T12:00:00+05:00",
    "updated_at": "2026-09-21T12:00:00+05:00"
  }
]
```

**Note:** `amount` is returned as **string** (Decimal) — frontend must parse to `double`/`Decimal`.

---

### POST /transactions

Create a transaction.

**Auth:** Required.

**Request Body:**

```json
{
  "type": "expense",
  "amount": 500.50,
  "category_id": 1,
  "date": "2026-09-21",
  "note": "Lunch"
}
```

**Validation:**
- `type` must match the category's type (`income` category → `income` transaction)
- `amount` > 0
- `category_id` must be visible to user (own custom or default)

**Response 201:** Full transaction object (same as list item).

**Response 400:** Type/category mismatch.

**Response 404:** Category doesn't exist or isn't visible.

---

### GET /transactions/{id}

Get a single transaction.

**Auth:** Required.

**Response 200:** Same shape.

**Response 404:** Not found or not owned.

---

### PUT /transactions/{id}

Partial update. Only send fields you want to change.

**Auth:** Required.

**Request Body:**

```json
{
  "amount": 600.00,
  "note": "Dinner"
}
```

**Response 200:** Updated transaction.

**Response 400:** Type/category mismatch (if you change type or category).

**Response 404:** Not owned.

---

### DELETE /transactions/{id}

**Auth:** Required.

**Response 204.**

**Response 404:** Not owned.

---

## 5. Budgets

### GET /budgets

List budgets for current user.

**Auth:** Required.

**Query params:**
- `month` (optional): `YYYY-MM` format, filters to a specific month

**Response 200:**

```json
[
  {
    "id": 1,
    "user_id": 1,
    "category_id": 1,
    "month": "2026-09",
    "limit_amount": "7000.00",
    "category": { /* full category object */ },
    "created_at": "2026-09-01T00:00:00+05:00",
    "updated_at": "2026-09-01T00:00:00+05:00"
  }
]
```

---

### POST /budgets

Create a budget.

**Auth:** Required.

**Request Body:**

```json
{
  "category_id": 1,
  "month": "2026-09",
  "limit_amount": 7000.00
}
```

**Validation:**
- `category_id` must be an **expense** category visible to user
- `month` format: `YYYY-MM`, valid month (01-12)
- `limit_amount` > 0
- No existing budget for (user, category, month) combination

**Response 201:** Budget object.

**Response 400:** Income category.

**Response 404:** Category not found.

**Response 409:** Duplicate budget.

---

### GET /budgets/{id}

**Auth:** Required.

**Response 200:** Budget object.

**Response 404:** Not owned.

---

### GET /budgets/{id}/status

**⭐ Key endpoint for budget progress UI.**

Returns budget + live calculated spending.

**Auth:** Required.

**Response 200:**

```json
{
  "id": 1,
  "user_id": 1,
  "category_id": 1,
  "month": "2026-09",
  "limit_amount": "7000.00",
  "category": { /* full category object */ },
  "created_at": "2026-09-01T00:00:00+05:00",
  "updated_at": "2026-09-01T00:00:00+05:00",

  "spent": "5800.00",
  "remaining": "1200.00",
  "percentage": 82.86,
  "status": "approaching"
}
```

**Status values:**
- `safe` — percentage < 80
- `approaching` — 80 ≤ percentage < 100
- `exceeded` — percentage ≥ 100

**Note:** `remaining` can be negative when exceeded.

---

### PUT /budgets/{id}

Update limit.

**Auth:** Required.

**Request Body:**

```json
{ "limit_amount": 8000.00 }
```

**Response 200:** Updated budget.

**Response 422:** Negative limit.

**Response 404:** Not owned.

---

### DELETE /budgets/{id}

**Auth:** Required.

**Response 204.**

**Response 404:** Not owned.

---

## 6. Analytics

All analytics endpoints are **read-only** and return aggregates for the authenticated user.

### GET /analytics/summary

**Auth:** Required.

**Query params:**
- `month` (required): `YYYY-MM`

**Response 200:**

```json
{
  "month": "2026-09",
  "total_income": "60000.00",
  "total_expense": "28550.00",
  "net_balance": "31450.00",
  "transaction_count": 42
}
```

---

### GET /analytics/categories

Category-wise spending breakdown for a month.

**Auth:** Required.

**Query params:**
- `month` (required): `YYYY-MM`
- `type` (optional): `income` | `expense` (default: `expense`)

**Response 200:**

```json
{
  "month": "2026-09",
  "total_spent": "28550.00",
  "categories": [
    {
      "category_id": 1,
      "name": "Food",
      "type": "expense",
      "total": "8200.00",
      "percentage": 28.71
    },
    {
      "category_id": 4,
      "name": "Shopping",
      "type": "expense",
      "total": "6500.00",
      "percentage": 22.76
    }
  ]
}
```

**Note:** `categories` sorted by `total` descending.

---

### GET /analytics/monthly

12-month income/expense trend.

**Auth:** Required.

**Query params:**
- `year` (required): integer (2000-2100)

**Response 200:**

```json
{
  "year": 2026,
  "months": [
    { "month": "2026-01", "income": "0.00", "expense": "0.00" },
    { "month": "2026-02", "income": "60000.00", "expense": "32000.00" },
    ...
    { "month": "2026-12", "income": "0.00", "expense": "0.00" }
  ]
}
```

**Note:** Always 12 entries, even if some months have no transactions.

---

### GET /analytics/balance

All-time balance for the user.

**Auth:** Required.

**Response 200:**

```json
{
  "total_income": "360000.00",
  "total_expense": "175000.00",
  "current_balance": "185000.00"
}
```

---

## 7. Decimal Handling

**All monetary values** (`amount`, `limit_amount`, `total`, `income`, `expense`, `balance`, `spent`, `remaining`) are returned as **strings**, e.g. `"500.50"`.

**Frontend MUST:**
- Parse with `double.parse()` or preferably a Decimal library
- Format using `intl`'s `NumberFormat.currency()` for display
- Never do math with floats on money values

---

## 8. Token Lifecycle

- Access tokens expire in **60 minutes** (configurable)
- No refresh tokens in v1 — user must log in again after expiry
- On 401 response, frontend should:
  1. Clear stored token
  2. Redirect to login screen
  3. Show "Session expired" message

---

## 9. Default Categories (Seeded)

| Type | Name |
|---|---|
| expense | Food |
| expense | Transport |
| expense | Bills |
| expense | Shopping |
| expense | Entertainment |
| expense | Health |
| expense | Education |
| expense | Other Expense |
| income | Salary |
| income | Freelance |
| income | Business |
| income | Investment |
| income | Other Income |

**Total: 13 categories.**

Default categories have `user_id: null`. Frontend should display them alongside user's custom categories — **no visual distinction needed** unless user tries to modify them (which will return 403).