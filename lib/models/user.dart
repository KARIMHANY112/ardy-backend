enum UserRole { buyer, seller, owner }

UserRole userRoleFromString(String value) => UserRole.values.firstWhere(
      (r) => r.name == value,
      orElse: () => UserRole.buyer,
    );

class AppUser {
  final String id;
  final String name;
  final String phone;
  final String email;
  final UserRole role;

  AppUser({
    required this.id,
    required this.name,
    required this.phone,
    required this.email,
    required this.role,
  });

  factory AppUser.fromJson(Map<String, dynamic> json) => AppUser(
        id: json['id'] as String,
        name: json['name'] as String,
        phone: json['phone'] as String,
        email: json['email'] as String,
        role: userRoleFromString(json['role'] as String),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'phone': phone,
        'email': email,
        'role': role.name,
      };
}
