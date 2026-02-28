enum UserRole { user, manager, admin }

class User {
  final String id;
  final String email;
  final String name;
  final UserRole role;
  final String? phone;
  final DateTime? birthDate;
  final String? photoPath;

  User({
    required this.id,
    required this.email,
    required this.name,
    required this.role,
    this.phone,
    this.birthDate,
    this.photoPath,
  });

  factory User.fromJson(Map<String, dynamic> json, String docId) {
    return User(
      id: docId,
      email: json['email'] ?? '',
      name: json['name'] ?? '',
      role: _parseRole(json['role']),
      phone: json['phone'],
      photoPath: json['photoPath'],
      birthDate: json['birthDate'] != null
          ? DateTime.parse(json['birthDate'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "email": email,
      "name": name,
      "role": role.name,
      "phone": phone,
      "photoPath": photoPath,
      "birthDate": birthDate?.toIso8601String(),
    };
  }

  static UserRole _parseRole(String? role) {
    switch (role) {
      case 'manager':
        return UserRole.manager;
      case 'admin':
        return UserRole.admin;
      default:
        return UserRole.user;
    }
  }
}