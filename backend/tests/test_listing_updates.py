"""Tests for the partial-edit logic behind PATCH /listings/{id}.

Pure — no DB, no HTTP. Run with:
    venv/Scripts/python.exe -m unittest discover -s tests
"""
import unittest

from fastapi import HTTPException

from app.models.models import Listing, LicenseStatus, ListingStatus, OfferType, RentPeriod
from app.routers.listings import resolve_offer_fields, update_listing
from app.schemas.schemas import ListingUpdate


class TestResolveOfferFields(unittest.TestCase):
    def test_untouched_sale_stays_a_sale(self):
        self.assertEqual(
            resolve_offer_fields(OfferType.sale, None, {"price": 500}),
            {"offer_type": OfferType.sale, "rent_period": None},
        )

    def test_untouched_rental_keeps_its_period(self):
        # Editing only the title must not lose the period the listing already had.
        self.assertEqual(
            resolve_offer_fields(OfferType.rent, RentPeriod.yearly, {"title": "New title"}),
            {"offer_type": OfferType.rent, "rent_period": RentPeriod.yearly},
        )

    def test_switch_to_rent_with_period(self):
        self.assertEqual(
            resolve_offer_fields(OfferType.sale, None, {"offer_type": OfferType.rent, "rent_period": RentPeriod.monthly}),
            {"offer_type": OfferType.rent, "rent_period": RentPeriod.monthly},
        )

    def test_switch_to_rent_without_period_is_rejected(self):
        # No safe default — monthly and yearly are 12x apart.
        with self.assertRaises(ValueError):
            resolve_offer_fields(OfferType.sale, None, {"offer_type": OfferType.rent})

    def test_switch_off_rent_drops_the_period(self):
        # "yearly" is meaningless on a resale, so it's cleared rather than erroring.
        self.assertEqual(
            resolve_offer_fields(OfferType.rent, RentPeriod.yearly, {"offer_type": OfferType.resale}),
            {"offer_type": OfferType.resale, "rent_period": None},
        )

    def test_period_on_a_sale_is_rejected(self):
        with self.assertRaises(ValueError):
            resolve_offer_fields(OfferType.sale, None, {"rent_period": RentPeriod.monthly})

    def test_clearing_a_rentals_period_explicitly_is_rejected(self):
        with self.assertRaises(ValueError):
            resolve_offer_fields(OfferType.rent, RentPeriod.monthly, {"rent_period": None})

    def test_changing_only_the_period_of_a_rental(self):
        self.assertEqual(
            resolve_offer_fields(OfferType.rent, RentPeriod.monthly, {"rent_period": RentPeriod.yearly}),
            {"offer_type": OfferType.rent, "rent_period": RentPeriod.yearly},
        )

    def test_empty_update_is_a_no_op(self):
        self.assertEqual(
            resolve_offer_fields(OfferType.resale, None, {}),
            {"offer_type": OfferType.resale, "rent_period": None},
        )


class _StubSession:
    """Just enough Session for the handler: one canned lookup result, no-op writes.
    A real DB isn't needed to check which fields get set and whether a re-embed fires."""

    def __init__(self, result):
        self._result = result

    def query(self, *args):
        return self

    def filter(self, *args):
        return self

    def first(self):
        return self._result

    def commit(self):
        pass

    def refresh(self, obj):
        pass


class _StubTasks:
    def __init__(self):
        self.scheduled = []

    def add_task(self, fn, *args):
        self.scheduled.append(fn.__name__)


def _listing(**overrides):
    fields = dict(
        ref_code="REF-0001",
        title="Shop in Tanta",
        type="shop",
        offer_type=OfferType.sale,
        rent_period=None,
        price=1_000_000.0,
        size=120.0,
        location="Tanta",
        description="Corner unit",
        status=ListingStatus.live,
        license_status=LicenseStatus.licensed,
    )
    fields.update(overrides)
    return Listing(**fields)


class TestUpdateListing(unittest.TestCase):
    def _patch(self, listing, payload):
        tasks = _StubTasks()
        result = update_listing("id", ListingUpdate(**payload), tasks, db=_StubSession(listing), current_user=None)
        return result, tasks.scheduled

    def test_price_edit_reembeds(self):
        result, scheduled = self._patch(_listing(), {"price": 950_000})
        self.assertEqual(result.price, 950_000)
        self.assertEqual(scheduled, ["embed_and_store_listing"])

    def test_license_only_edit_does_not_reembed(self):
        # license_status isn't part of the embedded text — no point paying for a vector.
        _, scheduled = self._patch(_listing(), {"license_status": "pending"})
        self.assertEqual(scheduled, [])

    def test_empty_payload_changes_nothing(self):
        result, scheduled = self._patch(_listing(), {})
        self.assertEqual(result.title, "Shop in Tanta")
        self.assertEqual(scheduled, [])

    def test_title_only_edit_keeps_a_rentals_period(self):
        listing = _listing(offer_type=OfferType.rent, rent_period=RentPeriod.monthly, price=12_000)
        result, _ = self._patch(listing, {"title": "Renamed"})
        self.assertEqual(result.rent_period, RentPeriod.monthly)

    def test_switch_to_rent_without_period_is_a_400(self):
        with self.assertRaises(HTTPException) as ctx:
            self._patch(_listing(), {"offer_type": "rent"})
        self.assertEqual(ctx.exception.status_code, 400)

    def test_missing_listing_is_a_404(self):
        with self.assertRaises(HTTPException) as ctx:
            update_listing("nope", ListingUpdate(), _StubTasks(), db=_StubSession(None), current_user=None)
        self.assertEqual(ctx.exception.status_code, 404)


if __name__ == "__main__":
    unittest.main()
