import logging
import smtplib
from email.message import EmailMessage

from app.core.config import settings

logger = logging.getLogger(__name__)


def send_password_reset_code(to_email: str, code: str) -> None:
    """Best-effort send — a missing SMTP config never raises, just logs."""
    if not settings.smtp_host:
        logger.warning("SMTP not configured — password reset code for %s: %s", to_email, code)
        return

    message = EmailMessage()
    message["Subject"] = "Your Ardy password reset code"
    message["From"] = settings.smtp_from
    message["To"] = to_email
    message.set_content(
        f"Your password reset code is: {code}\n\nThis code expires in 15 minutes. "
        "If you didn't request this, you can ignore this email."
    )

    try:
        with smtplib.SMTP(settings.smtp_host, settings.smtp_port) as server:
            server.starttls()
            if settings.smtp_user:
                server.login(settings.smtp_user, settings.smtp_password)
            server.send_message(message)
    except Exception:
        logger.exception("Failed to send password reset email to %s", to_email)
