import os

import sentry_sdk
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.core.config import settings
from app.routers import auth, listings, favorites, advisor, users, legal

sentry_sdk.init(
    dsn=os.getenv(
        "SENTRY_DSN",
        "https://4fb1f5397220fec83b62134612b869cd@o4511757314162688.ingest.de.sentry.io/4511757322027088",
    ),
    environment=os.getenv("ENVIRONMENT", "production"),
    send_default_pii=True,
    enable_logs=True,
    traces_sample_rate=0.1,
    profile_session_sample_rate=0.1,
    profile_lifecycle="trace",
)

app = FastAPI(title="Ardy API", version="0.1.0")

_origins = ["https://ardy-dashboard.onrender.com"]
if settings.environment != "production":
    _origins.append("http://localhost:5000")

app.add_middleware(
    CORSMiddleware,
    allow_origins=_origins,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(auth.router)
app.include_router(listings.router)
app.include_router(favorites.router)
app.include_router(advisor.router)
app.include_router(users.router)
app.include_router(legal.router)


@app.get("/")
def health_check():
    return {"status": "ok", "service": "ardy-api"}


@app.get("/sentry-debug")
async def trigger_error():
    division_by_zero = 1 / 0
