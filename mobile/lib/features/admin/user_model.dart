class AdminUser {
  const AdminUser({
    this.id,
    required this.name,
    required this.email,
    required this.role,
    this.isActive = true,
    this.createdAt,
  });

  final String? id;
  final String name;
  final String email;
  final String role;
  final bool isActive;
  final DateTime? createdAt;

  factory AdminUser.fromJson(Map<String, dynamic> json) {
    final created = json['createdAt'];
    return AdminUser(
      id: json['_id']?.toString() ?? json['id']?.toString(),
      name: json['name']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      role: json['role']?.toString() ?? 'member',
      isActive: json['isActive'] == null ? true : json['isActive'] == true,
      createdAt: created != null ? DateTime.tryParse(created.toString()) : null,
    );
  }

  Map<String, dynamic> toJson() => {
        if (id != null) '_id': id,
        'name': name,
        'email': email,
        'role': role,
        'isActive': isActive,
        if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
      };
}
