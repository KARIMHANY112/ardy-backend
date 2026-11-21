"""Login must not fail because a phone capitalised the email or added a space.

Pure — no DB. Run with:
    venv/Scripts/python.exe -m unittest discover -s tests
"""
import unittest

from app.routers.auth import find_user_by_email, normalize_email


class _CapturingQuery:
    def __init__(self):
        self.criteria = None

    def filter(self, criterion):
        self.criteria = criterion
        return self

    def first(self):
        return None


class _CapturingSession:
    def __init__(self):
        self.q = _CapturingQuery()

    def query(self, _model):
        return self.q


class TestEmailLookup(unittest.TestCase):
    def test_normalize_strips_and_lowercases(self):
        self.assertEqual(normalize_email("  Admin@ArdiEgy.com \n"), "admin@ardiegy.com")

    def test_lookup_compares_lowercased_column(self):
        db = _CapturingSession()
        find_user_by_email(db, "Admin@ardiegy.com ")
        compiled = db.q.criteria.compile(compile_kwargs={"literal_binds": True})
        sql = str(compiled)
        self.assertIn("lower(users.email)", sql)
        self.assertIn("'admin@ardiegy.com'", sql)


if __name__ == "__main__":
    unittest.main()
