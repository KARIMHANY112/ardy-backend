from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.core.config import settings
from app.routers import auth, listings, favorites, advisor, users, legal

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
