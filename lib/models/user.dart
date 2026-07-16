enum UserRole { buyer, owner }

UserRole userRoleFromString(String value) => UserRole.values.firstWhere(
      (r) => r.name == value,
      orElse: () => UserRole.buyer,
    );

/// Mirrors backend app.models.models.UserStatus — new buyers start `pending`
/// until the owner approves them (see app.core.deps.require_buyer).
enum AccountStatus { pending, approved, rejected }

AccountStatus accountStatusFromString(String value) => AccountStatus.values.firstWhere(
      (s) => s.name == value,
      orElse: () => AccountStatus.pending,
    );

class AppUser {
  final String id;
  final String name;
  final String phone;
  final String email;
  final UserRole role;
  final AccountStatus status;

  AppUser({
    required this.id,
    required this.name,
    required this.phone,
    required this.email,
    required this.role,
    required this.status,
  });

  factory AppUser.fromJson(Map<String, dynamic> json) => AppUser(
        id: json['id'] as String,
        name: json['name'] as String,
        phone: json['phone'] as String,
        email: json['email'] as String,
        role: userRoleFromString(json['role'] as String),
        status: accountStatusFromString(json['status'] as String),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'phone': phone,
        'email': email,
        'role': role.name,
        'status': status.name,
      };
}
