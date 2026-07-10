import logging

import firebase_admin
from firebase_admin import credentials, messaging

from app.core.config import settings
from app.models.models import User

logger = logging.getLogger(__name__)

_firebase_app = None
if settings.firebase_credentials_path:
    try:
        _firebase_app = firebase_admin.initialize_app(credentials.Certificate(settings.firebase_credentials_path))
    except Exception:
        logger.exception("Failed to initialize Firebase Admin SDK — push notifications disabled")


def send_push_notification(user: User, title: str, body: str) -> None:
    """Best-effort push — a missing token, missing Firebase config, or FCM error never raises."""
    if _firebase_app is None:
        logger.warning("Firebase not configured — skipping push notification to user %s", user.id)
        return
    if not user.fcm_token:
        logger.info("User %s has no registered FCM token — skipping push notification", user.id)
        return

    message = messaging.Message(
        notification=messaging.Notification(title=title, body=body),
        token=user.fcm_token,
    )
    try:
        messaging.send(message)
    except Exception:
        logger.exception("Failed to send push notification to user %s", user.id)
