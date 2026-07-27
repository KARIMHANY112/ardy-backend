import 'package:flutter/widgets.dart';

import '../l10n/generated/app_localizations.dart';

/// Mirrors backend app.schemas.schemas.ListingOut, trimmed for UI stubbing.
enum ListingCategory { factory, land, shop }

extension ListingCategoryLabel on ListingCategory {
  String label(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    switch (this) {
      case ListingCategory.factory:
        return l10n.categoryFactory;
      case ListingCategory.land:
        return l10n.categoryLand;
      case ListingCategory.shop:
        return l10n.categoryShop;
    }
  }
}

enum LicenseStatus { licensed, pending, notApplicable }

extension LicenseStatusLabel on LicenseStatus {
  String label(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    switch (this) {
      case LicenseStatus.licensed:
        return l10n.licenseLicensed;
      case LicenseStatus.pending:
        return l10n.licensePending;
      case LicenseStatus.notApplicable:
        return l10n.licenseNotApplicable;
    }
  }
}

/// The backend's status values are snake_case (e.g. "not_applicable"), which
/// doesn't match Dart's camelCase enum names, so this needs an explicit wire
/// mapping instead of relying on [name] directly.
extension LicenseStatusWire on LicenseStatus {
  String get wireValue => switch (this) {
        LicenseStatus.notApplicable => 'not_applicable',
        _ => name,
      };
}

LicenseStatus _licenseStatusFromString(String value) => LicenseStatus.values.firstWhere(
      (s) => s.wireValue == value,
      orElse: () => LicenseStatus.pending,
    );

/// Mirrors backend app.models.models.ListingStatus — the moderation workflow
/// state (owner review), distinct from the UI-only [LicenseStatus] above.
enum ListingStatus { pending, live, papersPending, rejected, sold }

extension ListingStatusLabel on ListingStatus {
  String label(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    switch (this) {
      case ListingStatus.pending:
        return l10n.statusPendingReview;
      case ListingStatus.live:
        return l10n.statusLive;
      case ListingStatus.papersPending:
        return l10n.statusPapersPending;
      case ListingStatus.rejected:
        return l10n.statusRejected;
      case ListingStatus.sold:
        return l10n.statusSold;
    }
  }
}

/// The backend's status values are snake_case (e.g. "papers_pending"), which
/// doesn't match Dart's camelCase enum names, so status needs this explicit
/// wire mapping instead of relying on [name] directly.
extension ListingStatusWire on ListingStatus {
  String get wireValue => switch (this) {
        ListingStatus.papersPending => 'papers_pending',
        _ => name,
      };
}

ListingStatus _listingStatusFromString(String value) => ListingStatus.values.firstWhere(
      (s) => s.wireValue == value,
      orElse: () => ListingStatus.pending,
    );

class Listing {
  final String id;
  final String refCode;
  final String title;
  final ListingCategory category;
  final double price;
  final double sizeSqm;
  final String location;
  final String description;
  final LicenseStatus license;
  final ListingStatus status;
  final List<String> photoUrls;
  final bool isFavorite;
  final double? latitude;
  final double? longitude;
  final String? soldToName;
  final String? soldToPhone;

  const Listing({
    required this.id,
    required this.refCode,
    required this.title,
    required this.category,
    required this.price,
    required this.sizeSqm,
    required this.location,
    required this.description,
    required this.license,
    this.status = ListingStatus.live,
    this.photoUrls = const [],
    this.isFavorite = false,
    this.latitude,
    this.longitude,
    this.soldToName,
    this.soldToPhone,
  });

  bool get hasCoordinates => latitude != null && longitude != null;

  /// Maps backend app.schemas.schemas.ListingOut.
  factory Listing.fromJson(Map<String, dynamic> json) => Listing(
        id: json['id'] as String,
        refCode: json['ref_code'] as String,
        title: json['title'] as String,
        category: _categoryFromBackendType(json['type'] as String),
        price: (json['price'] as num).toDouble(),
        sizeSqm: (json['size'] as num).toDouble(),
        location: json['location'] as String,
        description: json['description'] as String? ?? '',
        license: _licenseStatusFromString(json['license_status'] as String? ?? 'pending'),
        status: _listingStatusFromString(json['status'] as String),
        photoUrls: (json['photo_urls'] as List<dynamic>? ?? const []).cast<String>(),
        latitude: (json['latitude'] as num?)?.toDouble(),
        longitude: (json['longitude'] as num?)?.toDouble(),
        soldToName: json['sold_to_name'] as String?,
        soldToPhone: json['sold_to_phone'] as String?,
      );

  /// Round-trips with [fromJson] — used to cache listings locally (e.g. Land Advisor history).
  Map<String, dynamic> toJson() => {
        'id': id,
        'ref_code': refCode,
        'title': title,
        'type': category.name,
        'price': price,
        'size': sizeSqm,
        'location': location,
        'description': description,
        'status': status.wireValue,
        'license_status': license.wireValue,
        'photo_urls': photoUrls,
        'latitude': latitude,
        'longitude': longitude,
      };

  Listing copyWith({bool? isFavorite}) => Listing(
        id: id,
        refCode: refCode,
        title: title,
        category: category,
        price: price,
        sizeSqm: sizeSqm,
        location: location,
        description: description,
        license: license,
        status: status,
        photoUrls: photoUrls,
        isFavorite: isFavorite ?? this.isFavorite,
        latitude: latitude,
        longitude: longitude,
        soldToName: soldToName,
        soldToPhone: soldToPhone,
      );

  static ListingCategory _categoryFromBackendType(String type) => ListingCategory.values.firstWhere(
        (c) => c.name == type,
        orElse: () => ListingCategory.land,
      );
}
