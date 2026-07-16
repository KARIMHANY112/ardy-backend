"""One-off admin helper: promote/approve a user without hand-writing SQL.

Run from backend/ with the venv active, pointed at whichever DATABASE_URL
is in .env (swap .env's database_url, or export DATABASE_URL, to target
production instead of local):

    python scripts/promote_user.py you@example.com --role owner --status approved
    python scripts/promote_user.py buyer@example.com --status approved
"""

import argparse
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))

from app.core.database import SessionLocal
from app.models.models import User, UserRole, UserStatus


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("email")
    parser.add_argument("--role", choices=[r.value for r in UserRole])
    parser.add_argument("--status", choices=[s.value for s in UserStatus])
    args = parser.parse_args()

    if not args.role and not args.status:
        parser.error("pass --role and/or --status")

    db = SessionLocal()
    try:
        user = db.query(User).filter(User.email == args.email).first()
        if not user:
            print(f"No user with email {args.email!r} - sign up first, then re-run this.")
            sys.exit(1)

        if args.role:
            user.role = UserRole(args.role)
        if args.status:
            user.status = UserStatus(args.status)
        db.commit()
        print(f"{user.email}: role={user.role.value} status={user.status.value}")
    finally:
        db.close()


if __name__ == "__main__":
    main()
