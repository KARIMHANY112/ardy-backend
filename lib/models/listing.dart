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
  final bool isFavorite;

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
    this.isFavorite = false,
  });

 