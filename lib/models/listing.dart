import 'package:flutter/widgets.dart';

import '../l10n/generated/app_localizations.dart';
import '../utils/formatters.dart';

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

/// Mirrors backend app.models.models.OfferType — what the listing is offered as.
/// Every listing declares one; older rows default to [sale].
enum OfferType { sale, rent, resale }

extension OfferTypeLabel on OfferType {
  String label(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    switch (this) {
      case OfferType.sale:
        return l10n.offerTypeSale;
      case OfferType.rent:
        return l10n.offerTypeRent;
      case OfferType.resale:
        return l10n.offerTypeResale;
    }
  }
}

OfferType _offerTypeFromString(String value) => OfferType.values.firstWhere(
      (o) => o.name == value,
      orElse: () => OfferType.sale,
    );

/// Mirrors backend app.models.models.RentPeriod — what a rental's price is charged
/// per. Null on anything that isn't [OfferType.rent], since a sale price has no period.
enum RentPeriod { monthly, yearly }

extension RentPeriodLabel on RentPeriod {
  /// The suffix appended to a rental's price, e.g. "/month".
  String priceSuffix(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    switch (this) {
      case RentPeriod.monthly:
        return l10n.perMonthSuffix;
      case RentPeriod.yearly:
        return l10n.perYearSuffix;
    }
  }
}

RentPeriod? _rentPeriodFromString(String? value) {
  if (value == null) return null;
  for (final period in RentPeriod.values) {
    if (period.name == value) return period;
  }
  return null;
}

/// Mirrors backend app.models.models.SizeUnit — the unit [Listing.size] is in.
/// Land here is traded by the feddan while shops and factories are quoted in m²,
/// so the number on its own is ambiguous: 5 feddan and 5 m² differ 4,200-fold.
enum SizeUnit { sqm, feddan }

/// One feddan is 4,200 m² — the standard Egyptian conversion.
const double sqmPerFeddan = 4200.0;

extension SizeUnitLabel on SizeUnit {
  /// The suffix shown after a size, e.g. "feddan" / "sqm".
  String label(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    switch (this) {
      case SizeUnit.sqm:
        return l10n.sqmSuffix;
      case SizeUnit.feddan:
        return l10n.feddanSuffix;
    }
  }
}

/// Falls back to sqm: rows created before the backend recorded a unit were all
/// entered in m², which is also what the UI used to assume for everyone.
SizeUnit _sizeUnitFromString(String? value) => SizeUnit.values.firstWhere(
      (u) => u.name == value,
      orElse: () => SizeUnit.sqm,
    );

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
  final OfferType offerType;
  final double price;
  /// Only set when [offerType] is rent — see [priceLabel].
  final RentPeriod? rentPeriod;

  /// The advertised size, expressed in [sizeUnit] — never assume m². Display it
  /// with [sizeUnit]; use [sizeSqm] when comparing sizes across listings.
  final double size;
  final SizeUnit sizeUnit;
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
    required this.offerType,
    required this.price,
    this.rentPeriod,
    required this.size,
    this.sizeUnit = SizeUnit.sqm,
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

  /// [size] normalised to m², for comparing listings quoted in different units.
  /// Not for display — showing a feddan plot as 21,000 m² isn't what was advertised.
  double get sizeSqm => sizeUnit == SizeUnit.feddan ? size * sqmPerFeddan : size;

  /// Maps backend app.schemas.schemas.ListingOut.
  factory Listing.fromJson(Map<String, dynamic> json) => Listing(
        id: json['id'] as String,
        refCode: json['ref_code'] as String,
        title: json['title'] as String,
        category: _categoryFromBackendType(json['type'] as String),
        offerType: _offerTypeFromString(json['offer_type'] as String? ?? 'sale'),
        price: (json['price'] as num).toDouble(),
        rentPeriod: _rentPeriodFromString(json['rent_period'] as String?),
        size: (json['size'] as num).toDouble(),
        sizeUnit: _sizeUnitFromString(json['size_unit'] as String?),
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
        'offer_type': offerType.name,
        'price': price,
        'rent_period': rentPeriod?.name,
        'size': size,
        'size_unit': sizeUnit.name,
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
        offerType: offerType,
        price: price,
        rentPeriod: rentPeriod,
        size: size,
        sizeUnit: sizeUnit,
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

extension ListingPriceLabel on Listing {
  /// The price as buyers should read it: "EGP 12,000/month" on a rental that carries
  /// a period, plain "EGP 4.2M" on everything else. Every surface that prints a price
  /// goes through this — a rent figure without its period is ambiguous by orders of
  /// magnitude.
  String priceLabel(BuildContext context) {
    final period = rentPeriod;
    if (period == null) return formatEgp(price);
    return '${formatEgp(price)}${period.priceSuffix(context)}';
  }
}
