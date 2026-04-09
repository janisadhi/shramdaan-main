import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../shared/models/event_model.dart';

class ChatListEntry {
  final Event event;
  final int unreadCount;
  final Timestamp? latestMessageAt;
  final String? latestMessageText;
  final String? latestSenderName;

  const ChatListEntry({
    required this.event,
    required this.unreadCount,
    required this.latestMessageAt,
    required this.latestMessageText,
    required this.latestSenderName,
  });
}
