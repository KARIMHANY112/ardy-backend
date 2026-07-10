from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.routers import auth, listings, favorites, advisor

app = FastAPI(title="Ardy API", version="0.1.0")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # tighten this to the dashboard's actual origin before going live
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(auth.router)
app.include_router(listings.router)
app.include_router(favorites.router)
app.include_router(advisor.router)


@app.get("/")
def health_check():
    return {"status": "ok", "service": "ardy-api"}
