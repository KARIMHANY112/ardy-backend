/// Mirrors backend app.models.models.UserRole. Owner accounts are created
/// manually server-side, but the toggle is exposed here too so the demo
/// build can reach the owner dashboard without a seeded account.
enum UserRole { buyer, seller, owner }

extension UserRoleLabel on UserRole {
  String get label {
    switch (this) {
      case UserRole.buyer:
        return 'Buyer';
      case UserRole.seller:
        return 'Seller';
      case UserRole.owner:
        return 'Owner';
    }
  }
}
