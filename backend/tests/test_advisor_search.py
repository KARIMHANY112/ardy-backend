"""Tests that the accumulated buyer profile maps to the right SQL filters on the
listings vector search. No DB connection — expressions are compiled to SQL text."""
import unittest

from app.routers.advisor import _preference_filters


def _sql(expr) -> str:
    return str(expr.compile(compile_kwargs={"literal_binds": True}))


class TestPreferenceFilters(unittest.TestCase):
    def test_empty_profile_no_filters(self):
        self.assertEqual(_preference_filters({}), [])

    def test_budget_max_filter(self):
        sql = _sql(_preference_filters({"budget_max": 2_000_000})[0])
        self.assertIn("listings.price <=", sql)
        self.assertIn("2000000", sql)

    def test_budget_min_filter(self):
        sql = _sql(_preference_filters({"budget_min": 500_000})[0])
        self.assertIn("listings.price >=", sql)

    def test_size_bounds(self):
        filters = _preference_filters({"size_min": 3, "size_max": 10})
        joined = " ".join(_sql(f) for f in filters)
        self.assertIn("listings.size <=", joined)
        self.assertIn("listings.size >=", joined)

    def test_land_type_ilike(self):
        sql = _sql(_preference_filters({"land_type": "land"})[0]).lower()
        self.assertIn("listings.type", sql)
        self.assertIn("like", sql)  # ILIKE renders as lower(...) LIKE lower(...)

    def test_location_ilike(self):
        sql = _sql(_preference_filters({"location": "giza"})[0]).lower()
        self.assertIn("listings.location", sql)

    def test_full_profile_yields_all_filters(self):
        filters = _preference_filters(
            {
                "budget_min": 1,
                "budget_max": 2,
                "size_min": 3,
                "size_max": 4,
                "land_type": "shop",
                "location": "cairo",
            }
        )
        self.assertEqual(len(filters), 6)


if __name__ == "__main__":
    unittest.main()
