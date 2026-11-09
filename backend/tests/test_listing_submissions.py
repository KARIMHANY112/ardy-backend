"""Tests for seller submissions and the owner's review of them.

Pure — no DB, no HTTP. Run with:
    venv/Scripts/python.exe -m unittest discover -s tests
"""
import unittest

from fastapi import HTTPException

from app.models.models import LicenseStatus, Listing, ListingStatus, OfferType, User
from app.routers.listings import review_listing
import uuid
from datetime import datetime, timezone

from pydantic import ValidationError

from app.schemas.schemas import ListingCreate, ListingDashboardOut, ListingOut, ListingReviewAction
from test_listing_updates import _StubSession, _StubTasks


def _pending_listing(**overrides):
    fields = dict(
        ref_code="REF-0002",
        title="Plot near Banha",
        type="land",
        offer_type=OfferType.sale,
        rent_period=None,
        price=2_500_000.0,
        size=3.0,
        location="Banha",
        description="Road frontage",
        status=ListingStatus.pending,
        license_status=LicenseStatus.pending,
        photo_urls=[],
    )
    fields.update(overrides)
    return Listing(**fields)


class _Owner:
    id = "owner-id"


class TestReviewListing(unittest.TestCase):
    def _review(self, listing, approve):
        tasks = _StubTasks()
        result = review_listing("id", ListingReviewAction(approve=approve), tasks, db=_StubSession(listing), current_user=_Owner())
        return result, tasks.scheduled

    def test_approve_goes_live_and_is_embedded(self):
        result, scheduled = self._review(_pending_listing(), approve=True)
        self.assertEqual(result.status, ListingStatus.live)
        self.assertEqual(result.reviewed_by, "owner-id")
        self.assertIsNotNone(result.reviewed_at)
        self.assertEqual(scheduled, ["embed_and_store_listing", "send_push_notification"])

    def test_reject_is_not_embedded(self):
        result, scheduled = self._review(_pending_listing(), approve=False)
        self.assertEqual(result.status, ListingStatus.rejected)
        self.assertEqual(scheduled, ["send_push_notification"])

    def test_already_live_listing_cannot_be_reviewed(self):
        with self.assertRaises(HTTPException) as ctx:
            self._review(_pending_listing(status=ListingStatus.live), approve=False)
        self.assertEqual(ctx.exception.status_code, 400)

    def test_missing_listing_is_a_404(self):
        with self.assertRaises(HTTPException) as ctx:
            self._review(None, approve=True)
        self.assertEqual(ctx.exception.status_code, 404)


_CREATE = dict(title="Plot", type="land", offer_type="sale", price=1.0, size=1.0, location="Banha")


class TestContactPhone(unittest.TestCase):
    def test_phone_is_normalised(self):
        self.assertEqual(ListingCreate(**_CREATE, contact_phone="0122 567-5555").contact_phone, "01225675555")

    def test_garbage_phone_is_rejected(self):
        with self.assertRaises(ValidationError):
            ListingCreate(**_CREATE, contact_phone="call me")

    def _serialised(self, schema):
        listing = _pending_listing(contact_phone="01225675555", id=uuid.uuid4(), size_unit="feddan", created_at=datetime.now(timezone.utc))
        listing.submitted_by_user = User(name="Seller", phone=None)
        return schema.model_validate(listing, from_attributes=True).model_dump()

    def test_public_schema_never_carries_the_sellers_phone(self):
        dumped = self._serialised(ListingOut)
        self.assertNotIn("contact_phone", dumped)
        self.assertNotIn("01225675555", str(dumped))

    def test_admin_dashboard_schema_does(self):
        self.assertEqual(self._serialised(ListingDashboardOut)["contact_phone"], "01225675555")


if __name__ == "__main__":
    unittest.main()
