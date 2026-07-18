# Ardy API

FastAPI backend for the Ardy land & real estate marketplace.

## Stack
- FastAPI (Python)
- PostgreSQL + pgvector (data and Land Advisor embeddings in one database)
- JWT auth
- OpenAI for embeddings + chat (swap providers in `app/core/config.py` / `app/routers/advisor.py`)
- Cloudinary for listing photo storage
- Firebase Cloud Messaging for push notifications

## Setup

1. Start the database:
   ```
   docker compose up -d
   ```

2. Install dependencies:
   ```
   python -m venv venv
   source venv/bin/activate
   pip install -r requirements.txt
   ```

3. Copy the env template and fill in your keys:
   ```
   cp .env.example .env
   ```
   - `OPENAI_API_KEY` — needed for `/advisor/ask` and for embedding a listing on approval.
   - `CLOUDINARY_*` — needed for `POST /listings/{id}/photos`. Get these from your Cloudinary dashboard.
   - `FIREBASE_CREDENTIALS_PATH` — path to a Firebase service account JSON (Project Settings → Service Accounts → Generate new private key). Leave blank in dev — push notifications are skipped (and logged) rather than failing when unset.

4. Apply migrations (creates the schema — there's no more auto-create-on-startup):
   ```
   alembic upgrade head
   ```

5. Run the API:
   ```
   uvicorn app.main:app --reload
   ```

   Visit `http://localhost:8000/docs` for interactive API docs (Swagger UI) — useful for testing endpoints from the browser before the Flutter app or dashboard are wired up.

## Listing lifecycle

| Step | Endpoint | Who |
|---|---|---|
| Seller submits a listing — goes live immediately | `POST /listings` | seller |
| Seller adds photos to their listing | `POST /listings/{id}/photos` | seller |
| Seller checks their own listings | `GET /listings/mine/requests` | seller |
| Buyers browse only live listings | `GET /listings` | anyone |
| Buyer asks the Land Advisor | `POST /advisor/ask` | anyone |

Submitting a listing (`POST /listings`, or `POST /listings/dashboard` for owners) embeds it for the Land Advisor in the background (`app/routers/advisor.py::embed_and_store_listing`) — best-effort, failures are logged not raised, since the listing is already live either way.

## Migrations

Schema changes go through Alembic — there's no more auto-create-on-startup.

```
alembic revision --autogenerate -m "describe the change"
alembic upgrade head
```

## Project structure

```
app/
  core/       config, database session, JWT/password helpers, auth dependencies
  models/     SQLAlchemy models (User, Listing, Favorite)
  schemas/    Pydantic request/response schemas
  routers/    auth, listings (incl. approval flow), favorites, advisor (RAG)
  main.py     app entrypoint, wires up routers
```
