from pathlib import Path

import markdown
from fastapi import APIRouter
from fastapi.responses import HTMLResponse

router = APIRouter(prefix="/legal", tags=["legal"])

LEGAL_DIR = Path(__file__).resolve().parent.parent / "legal_docs"


def _render(filename: str) -> str:
    md_text = (LEGAL_DIR / filename).read_text(encoding="utf-8")
    body = markdown.markdown(md_text)
    return f"""<!DOCTYPE html>
<html>
<head>
<meta charset="utf-8">
<title>Ardy Legal</title>
<style>
  body {{ font-family: -apple-system, Arial, sans-serif; max-width: 720px; margin: 40px auto; padding: 0 20px; line-height: 1.6; color: #222; }}
  h1, h2 {{ color: #0a5c46; }}
</style>
</head>
<body>{body}</body>
</html>"""


@router.get("/privacy", response_class=HTMLResponse)
def privacy_policy():
    return _render("privacy_policy.md")


@router.get("/terms", response_class=HTMLResponse)
def terms_of_service():
    return _render("terms_of_service.md")
