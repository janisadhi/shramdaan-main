class AdminUser {
  final String id;
  final String displayName;
  final String email;
  final String role;
  final String photoUrl;
  final bool isBanned;

  const AdminUser({
    required this.id,
    required this.displayName,
    required this.email,
    required this.role,
    required this.photoUrl,
    required this.isBanned,
  });

  factory AdminUser.fromMap(String id, Map<String, dynamic> data) {
    return AdminUser(
      id: id,
      displayName: data['displayName'] ?? 'Anonymous',
      email: data['email'] ?? 'No email',
      role: data['role'] ?? 'volunteer',
      photoUrl: data['photoUrl'] ?? '',
      isBanned: data['isBanned'] ?? false,
    );
  }
}
