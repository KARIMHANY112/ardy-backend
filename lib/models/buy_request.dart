import 'package:flutter/widgets.dart';

import '../l10n/generated/app_localizations.dart';
import 'listing.dart';

/// Mirrors backend app.models.models.BuyRequestStatus.
enum BuyRequestStatus { pending, approved, rejected }

BuyRequestStatus _buyRequestStatusFromString(String value) => BuyRequestStatus.values.firstWhere(
      (s) => s.name == value,
      orElse: () => BuyRequestStatus.pending,
    );

extension BuyRequestStatusLabel on BuyRequestStatus {
  /// "Bought" only makes sense from the buyer's own point of view — everyone
  /// else just sees the listing itself as "Sold" (see ListingStatusLabel).
  String label(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    switch (this) {
      case BuyRequestStatus.pending:
        return l10n.buyRequestStatusRequested;
      case BuyRequestStatus.approved:
        return l10n.buyRequestStatusBought;
      case BuyRequestStatus.rejected:
        return l10n.statusRejected;
    }
  }
}

/// Maps backend app.schemas.schemas.BuyRequestOut / BuyRequestDashboardOut.
/// `buyerName`/`buyerPhone` are only present on the owner-dashboard endpoint.
class BuyRequest {
  final String id;
  final Listing listing;
  final BuyRequestStatus status;
  final DateTime createdAt;
  final String? buyerName;
  final String? buyerPhone;

  BuyRequest({
    required this.id,
    required this.listing,
    required this.status,
    required this.createdAt,
    this.buyerName,
    this.buyerPhone,
  });

  factory BuyRequest.fromJson(Map<String, dynamic> json) => BuyRequest(
        id: json['id'] as String,
        listing: Listing.fromJson(json['listing'] as Map<String, dynamic>),
        status: _buyRequestStatusFromString(json['status'] as String),
        createdAt: DateTime.parse(json['created_at'] as String),
        buyerName: json['buyer_name'] as String?,
        buyerPhone: json['buyer_phone'] as String?,
      );
}
