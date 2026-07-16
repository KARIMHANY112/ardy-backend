/// Mirrors backend app.schemas.schemas.ListingOut, trimmed for UI stubbing.
enum ListingCategory { factory, land, shop }

extension ListingCategoryLabel on ListingCategory {
  String get label {
    switch (this) {
      case ListingCategory.factory:
        return 'Factory';
      case ListingCategory.land:
        return 'Land';
      case ListingCategory.shop:
        return 'Shop';
    }
  }
}

enum LicenseStatus { licensed, pending, notApplicable }

extension LicenseStatusLabel on LicenseStatus {
  String get label {
    switch (this) {
      case LicenseStatus.licensed:
        return 'Licensed';
      case LicenseStatus.pending:
        return 'Pending';
      case LicenseStatus.notApplicable:
        return 'N/A';
    }
  }
}

/// Mirrors backend app.models.models.ListingStatus — the moderation workflow
/// state (owner review), distinct from the UI-only [LicenseStatus] above.
enum ListingStatus { pending, live, rejected, sold }

extension ListingStatusLabel on ListingStatus {
  String get label {
    switch (this) {
      case ListingStatus.pending:
        return 'Pending review';
      case ListingStatus.live:
        return 'Live';
      case ListingStatus.rejected:
        return 'Rejected';
      case ListingStatus.sold:
        return 'Sold';
    }
  }
}

ListingStatus _listingStatusFromString(String value) => ListingStatus.values.firstWhere(
      (s) => s.name == value,
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
  });

  bool get hasCoordinates => latitude != null && longitude != null;

  /// Maps backend app.schemas.schemas.ListingOut. The backend has no licensing
  /// field yet, so `license` defaults to pending until that's added server-side.
  factory Listing.fromJson(Map<String, dynamic> json) => Listing(
        id: json['id'] as String,
        refCode: json['ref_code'] as String,
        title: json['title'] as String,
        category: _categoryFromBackendType(json['type'] as String),
        price: (json['price'] as num).toDouble(),
        sizeSqm: (json['size'] as num).toDouble(),
        location: json['location'] as String,
        description: json['description'] as String? ?? '',
        license: LicenseStatus.pending,
        status: _listingStatusFromString(json['status'] as String),
        photoUrls: (json['photo_urls'] as List<dynamic>? ?? const []).cast<String>(),
        latitude: (json['latitude'] as num?)?.toDouble(),
        longitude: (json['longitude'] as num?)?.toDouble(),
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
        'status': status.name,
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
      );

  static ListingCategory _categoryFromBackendType(String type) => ListingCategory.values.firstWhere(
        (c) => c.name == type,
        orElse: () => ListingCategory.land,
      );
}
