class User {
  final int? id;
  final String name;
  final String email;
  final String? phone;
  final String? role;
  final String? avatarUrl;

  User({
    this.id,
    required this.name,
    required this.email,
    this.phone,
    this.role,
    this.avatarUrl,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    String? role;

    final roles = json['roles'];

    if (roles is List && roles.isNotEmpty) {
      final firstRole = roles.first;

      if (firstRole is Map) {
        role = firstRole['name']?.toString();
      } else {
        role = firstRole.toString();
      }
    }

    return User(
      id: json['id'] is int
          ? json['id']
          : int.tryParse(json['id']?.toString() ?? ''),
      name: json['name']?.toString() ?? '-',
      email: json['email']?.toString() ?? '-',
      phone: json['phone']?.toString(),
      role: role,
      avatarUrl: json['avatar_url']?.toString(),
    );
  }
}