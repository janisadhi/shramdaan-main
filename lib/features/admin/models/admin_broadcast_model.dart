class AdminBroadcast {
  final String id;
  final String title;
  final String body;
  final String sentBy;
  final DateTime? sentAt;

  const AdminBroadcast({
    required this.id,
    required this.title,
    required this.body,
    required this.sentBy,
    required this.sentAt,
  });

  factory AdminBroadcast.fromMap(String id, Map<String, dynamic> data) {
    final sentAtRaw = data['sentAt'];
    return AdminBroadcast(
      id: id,
      title: data['title'] ?? 'Untitled broadcast',
      body: data['body'] ?? '',
      sentBy: data['sentBy'] ?? 'Admin',
      sentAt: sentAtRaw is Map ? null : (sentAtRaw?.toDate()),
    );
  }
}
