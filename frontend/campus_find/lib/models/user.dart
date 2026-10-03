class AppUser {
  final String id;
  final String name;
  final String email;
  final String role; // student | staff | admin
  final String? department;
  final String? phone;

  AppUser({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.department,
    this.phone,
  });

  bool get isAdmin => role == 'admin';

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      id: json['_id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      role: json['role']?.toString() ?? 'student',
      department: json['department']?.toString(),
      phone: json['phone']?.toString(),
    );
  }
}
