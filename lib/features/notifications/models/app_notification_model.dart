import 'package:cloud_firestore/cloud_firestore.dart';

class AppNotification {
  final String id;
  final String title;
  final String body;
  final String type;
  final String? targetId;
  final Timestamp? createdAt;
  final bool isRead;

  const AppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    required this.targetId,
    required this.createdAt,
    required this.isRead,
  });

  factory AppNotification.fromMap(String id, Map<String, dynamic> data) {
    return AppNotification(
      id: id,
      title: data['title'] ?? 'Notification',
      body: data['body'] ?? '',
      type: data['type'] ?? 'general',
      targetId: data['targetId'],
      createdAt: data['createdAt'] as Timestamp?,
      isRead: data['isRead'] == true,
    );
  }
}
