import cloudinary
import cloudinary.uploader

from app.core.config import settings

cloudinary.config(
    cloud_name=settings.cloudinary_cloud_name,
    api_key=settings.cloudinary_api_key,
    api_secret=settings.cloudinary_api_secret,
)


def upload_listing_photo(file, listing_id: str) -> str:
    """Uploads a listing photo to Cloudinary and returns its URL."""
    result = cloudinary.uploader.upload(file, folder=f"ardy/listings/{listing_id}")
    return result["secure_url"]
