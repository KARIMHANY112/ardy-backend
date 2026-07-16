/// Mirrors backend app.models.models.UserRole. Every signup is a buyer — a
/// buyer can browse/favorite listings and also submit their own; there's no
/// separate seller account. Owner accounts are created manually server-side.
enum UserRole { buyer, owner }

extension UserRoleLabel on UserRole {
  String get label {
    switch (this) {
      case UserRole.buyer:
        return 'Buyer';
      case UserRole.owner:
        return 'Owner';
    }
  }
}
