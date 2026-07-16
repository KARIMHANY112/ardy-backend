from pydantic_settings import BaseSettings


class Settings(BaseSettings):
    # Environment — "production" locks CORS to the deployed dashboard origin only.
    environment: str = "development"

    # Database
    database_url: str = "postgresql://ardy:ardy@localhost:5432/ardy"

    # Auth
    secret_key: str = "change-this-in-production"
    algorithm: str = "HS256"
    access_token_expire_minutes: int = 60 * 24 * 7  # 7 days

    # AI provider (for the Land Advisor RAG feature)
    openai_api_key: str = ""
    embedding_model: str = "text-embedding-3-small"
    chat_model: str = "gpt-4o-mini"

    # Photo storage (Cloudinary)
    cloudinary_cloud_name: str = ""
    cloudinary_api_key: str = ""
    cloudinary_api_secret: str = ""

    # Push notifications (Firebase Cloud Messaging) — path to a service account JSON file.
    # Leave blank in dev; notifications are skipped (logged, not sent) when unset.
    firebase_credentials_path: str = ""

    class Config:
        env_file = ".env"


settings = Settings()
