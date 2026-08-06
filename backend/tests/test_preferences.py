"""Tests for the Land Advisor preference-learning logic.

Pure, deterministic — no DB, no LLM. Run with:
    venv/Scripts/python.exe -m unittest discover -s tests
"""
import unittest

from app.core.preferences import (
    build_profile_summary,
    extract_preferences,
    merge_preferences,
)


class TestExtractPreferences(unittest.TestCase):
    def test_budget_max_from_currency(self):
        self.assertEqual(extract_preferences("under 2 million EGP")["budget_max"], 2_000_000)

    def test_budget_max_from_k_suffix(self):
        self.assertEqual(extract_preferences("budget 500k LE")["budget_max"], 500_000)

    def test_budget_min(self):
        self.assertEqual(extract_preferences("at least 3 million EGP")["budget_min"], 3_000_000)

    def test_budget_range(self):
        prefs = extract_preferences("between 1,000,000 and 3 million EGP")
        self.assertEqual(prefs["budget_min"], 1_000_000)
        self.assertEqual(prefs["budget_max"], 3_000_000)

    def test_budget_from_context_word(self):
        self.assertEqual(extract_preferences("my budget is 1.5m")["budget_max"], 1_500_000)

    def test_size_exact(self):
        # Normalised to m²: 5 feddan is 21,000 m², not 5. Storing the bare number
        # made "5 feddan" and "5 sqm" indistinguishable downstream.
        prefs = extract_preferences("around 5 feddan")
        self.assertEqual(prefs["size_min"], 21_000)
        self.assertEqual(prefs["size_max"], 21_000)
        self.assertEqual(prefs["size_unit"], "feddan")

    def test_size_min_only(self):
        prefs = extract_preferences("at least 10 feddan of farmland")
        self.assertEqual(prefs["size_min"], 42_000)
        self.assertNotIn("size_max", prefs)

    def test_size_in_sqm_is_unconverted(self):
        prefs = extract_preferences("around 500 sqm")
        self.assertEqual(prefs["size_min"], 500)
        self.assertEqual(prefs["size_unit"], "sqm")

    def test_feddan_and_sqm_are_comparable_after_normalising(self):
        # The whole point: a feddan figure must come out larger than a sqm figure
        # that is numerically bigger but physically much smaller.
        feddan = extract_preferences("5 feddan")["size_min"]
        sqm = extract_preferences("500 sqm")["size_min"]
        self.assertGreater(feddan, sqm)

    def test_land_type_keywords(self):
        # Canonical values must match Listing.type exactly (land / factory / shop),
        # since _preference_filters ilike-matches this straight against the DB column.
        self.assertEqual(extract_preferences("agricultural crop land")["land_type"], "land")
        self.assertEqual(extract_preferences("a warehouse")["land_type"], "factory")
        self.assertEqual(extract_preferences("looking for a retail store")["land_type"], "shop")

    def test_land_type_specific_wins_over_generic_land(self):
        self.assertEqual(extract_preferences("factory land in New Cairo")["land_type"], "factory")

    def test_budget_from_bare_magnitude_suffix(self):
        # No currency word or min/max hint nearby — "30M" alone should still read as money.
        self.assertEqual(extract_preferences("is there any land available with 30M?")["budget_max"], 30_000_000)

    def test_magnitude_suffix_before_size_unit_not_treated_as_budget(self):
        prefs = extract_preferences("looking for 5k sqm")
        self.assertNotIn("budget_max", prefs)
        self.assertEqual(prefs["size_max"], 5_000)

    def test_location(self):
        self.assertEqual(extract_preferences("something in Fayoum")["location"], "fayoum")

    def test_size_phrase_not_misread_as_budget(self):
        # "at least 10 feddan" must not leak a budget_min (regression: "le" matched "least").
        self.assertNotIn("budget_min", extract_preferences("at least 10 feddan of farmland"))

    def test_offer_intent_rent(self):
        self.assertEqual(extract_preferences("I want to rent a shop")["offer_intent"], "rent")
        self.assertEqual(extract_preferences("anything for lease in Tanta")["offer_intent"], "rent")

    def test_offer_intent_buy(self):
        self.assertEqual(extract_preferences("I want to buy land")["offer_intent"], "buy")
        self.assertEqual(extract_preferences("what do you have for sale?")["offer_intent"], "buy")

    def test_offer_intent_resale_beats_buy(self):
        # "resale" contains "sale" — the more specific intent has to win.
        self.assertEqual(extract_preferences("looking for a resale unit")["offer_intent"], "resale")

    def test_offer_intent_rent_beats_buy_when_both_mentioned(self):
        self.assertEqual(extract_preferences("buy or rent, either works")["offer_intent"], "rent")

    def test_offer_intent_arabic(self):
        # Arabic prefixes glue onto the keyword ("للإيجار"), so these match as substrings.
        self.assertEqual(extract_preferences("عايز محل للإيجار")["offer_intent"], "rent")
        self.assertEqual(extract_preferences("أرض للبيع في المنيا")["offer_intent"], "buy")

    def test_offer_intent_not_fired_by_substring(self):
        # "current" must not read as "rent".
        self.assertNotIn("offer_intent", extract_preferences("what is the current listing count"))

    def test_no_signal_returns_empty(self):
        self.assertEqual(extract_preferences("show me some listings please"), {})

    def test_combined_message(self):
        prefs = extract_preferences("agricultural, 5 feddan, budget 800k in Minya")
        self.assertEqual(prefs["land_type"], "land")
        self.assertEqual(prefs["budget_max"], 800_000)
        self.assertEqual(prefs["location"], "minya")
        self.assertEqual(prefs["size_min"], 21_000)


class TestMergePreferences(unittest.TestCase):
    def test_new_values_win(self):
        merged = merge_preferences({"budget_max": 1_000_000}, {"budget_max": 2_000_000})
        self.assertEqual(merged["budget_max"], 2_000_000)

    def test_old_values_persist(self):
        merged = merge_preferences({"land_type": "land"}, {"location": "giza"})
        self.assertEqual(merged["land_type"], "land")
        self.assertEqual(merged["location"], "giza")

    def test_empty_and_none_ignored(self):
        merged = merge_preferences({"land_type": "shop"}, {"land_type": None, "location": ""})
        self.assertEqual(merged["land_type"], "shop")
        self.assertNotIn("location", merged)

    def test_accumulates_across_turns(self):
        prefs = {}
        prefs = merge_preferences(prefs, extract_preferences("I want farmland"))
        prefs = merge_preferences(prefs, extract_preferences("in Aswan"))
        prefs = merge_preferences(prefs, extract_preferences("under 900k EGP"))
        self.assertEqual(prefs["land_type"], "land")
        self.assertEqual(prefs["location"], "aswan")
        self.assertEqual(prefs["budget_max"], 900_000)


class TestProfileSummary(unittest.TestCase):
    def test_empty(self):
        self.assertEqual(build_profile_summary({}), "")

    def test_land_type_not_doubled(self):
        self.assertIn("land", build_profile_summary({"land_type": "land"}))
        self.assertNotIn("land land", build_profile_summary({"land_type": "land"}))

    def test_land_type_qualifies_noun(self):
        self.assertIn("factory land", build_profile_summary({"land_type": "factory"}))

    def test_offer_intent_leads_the_summary(self):
        self.assertTrue(build_profile_summary({"offer_intent": "rent", "land_type": "shop"}).startswith("looking to rent"))

    def test_full_profile(self):
        summary = build_profile_summary(
            {"land_type": "land", "location": "giza", "budget_max": 2_000_000, "size_max": 5}
        )
        self.assertIn("land", summary)
        self.assertIn("Giza", summary)
        self.assertIn("2,000,000 EGP", summary)

    def test_size_read_back_in_the_unit_the_buyer_used(self):
        # Bounds are stored in m²; a buyer who said "feddan" should see feddan back,
        # not the 21,000 m² we match on internally.
        summary = build_profile_summary({"size_max": 21_000, "size_unit": "feddan"})
        self.assertIn("5 feddan", summary)
        self.assertNotIn("21000", summary)

    def test_size_defaults_to_sqm_when_unit_unknown(self):
        self.assertIn("500 m^2", build_profile_summary({"size_max": 500}))

    def test_size_round_trips_through_extraction(self):
        prefs = extract_preferences("at least 3 feddan")
        self.assertIn("3 feddan", build_profile_summary(prefs))


if __name__ == "__main__":
    unittest.main()
