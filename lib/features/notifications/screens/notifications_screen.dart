import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../shared/services/firestore_service.dart';
import '../../../shared/theme/app_theme.dart';
import '../../notifications/services/notification_service.dart';
import '../models/app_notification_model.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final User? _currentUser = FirebaseAuth.instance.currentUser;
  final FirestoreService _firestoreService = FirestoreService();

  @override
  void initState() {
    super.initState();
    NotificationService.instance.clearDisplayedNotifications();
  }

  Future<void> _refreshNotifications() async {
    if (!mounted) {
      return;
    }
    setState(() {});
    await Future<void>.delayed(const Duration(milliseconds: 500));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.neutral,
      appBar: AppBar(
        backgroundColor: AppColors.neutral,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: const Text('Notifications'),
        actions: [
          if (_currentUser != null)
            TextButton(
              onPressed: () {
                _firestoreService.markAllNotificationsRead(_currentUser.uid);
              },
              child: const Text('Mark all as read'),
            ),
        ],
      ),
      body: _currentUser == null
          ? const Center(child: Text('Please sign in to view notifications.'))
          : StreamBuilder<List<AppNotification>>(
              stream: _firestoreService.getNotificationsStream(_currentUser.uid),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final notifications = (snapshot.data ?? [])
                    .where((notification) => notification.type != 'chat_message')
                    .toList();

                if (notifications.isEmpty) {
                  return RefreshIndicator(
                    onRefresh: _refreshNotifications,
                    child: ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: const [
                        SizedBox(height: 120),
                        _EmptyNotificationsState(),
                      ],
                    ),
                  );
                }

                final feedItems = _buildNotificationFeed(notifications);

                return RefreshIndicator(
                  onRefresh: _refreshNotifications,
                  child: ListView.separated(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(0, 8, 0, 24),
                    itemCount: feedItems.length,
                    separatorBuilder: (context, index) {
                      final current = feedItems[index];
                      final next = index + 1 < feedItems.length ? feedItems[index + 1] : null;
                      if (current is String || next is String) {
                        return const SizedBox.shrink();
                      }
                      return const Divider(
                        height: 1,
                        indent: 70,
                        endIndent: 16,
                        color: AppColors.border,
                      );
                    },
                    itemBuilder: (context, index) {
                      final item = feedItems[index];
                      if (item is String) {
                        return _NotificationGroupHeader(label: item);
                      }

                      final notification = item as AppNotification;
                      return _NotificationRow(
                        notification: notification,
                        onTap: () async {
                          await _firestoreService.markNotificationRead(
                            _currentUser.uid,
                            notification.id,
                          );
                          await NotificationService.instance.clearDisplayedNotifications(
                            types: [notification.type],
                            targetId: notification.targetId,
                          );
                          if (notification.type == 'broadcast') {
                            return;
                          }
                          await NotificationService.instance.openNotificationDestination(
                            type: notification.type,
                            targetId: notification.targetId,
                          );
                        },
                      );
                    },
                  ),
                );
              },
            ),
    );
  }

  List<Object> _buildNotificationFeed(List<AppNotification> notifications) {
    final items = <Object>[];
    String? lastGroup;

    for (final notification in notifications) {
      final group = _groupLabel(notification.createdAt?.toDate());
      if (group != lastGroup) {
        items.add(group);
        lastGroup = group;
      }
      items.add(notification);
    }

    return items;
  }

  String _groupLabel(DateTime? timestamp) {
    if (timestamp == null) {
      return 'Earlier';
    }

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final createdDay = DateTime(timestamp.year, timestamp.month, timestamp.day);
    final difference = today.difference(createdDay).inDays;

    if (difference <= 0) {
      return 'Today';
    }
    if (difference <= 7) {
      return 'This week';
    }
    return 'Earlier';
  }

  static IconData _iconForType(String type) {
    switch (type) {
      case 'event_approved':
        return Icons.check_circle_outline;
      case 'event_rejected':
        return Icons.cancel_outlined;
      case 'chat_message':
        return Icons.chat_bubble_outline;
      case 'broadcast':
        return Icons.campaign_outlined;
      case 'event_reminder_1h':
        return Icons.alarm_outlined;
      case 'event_checkin_reminder':
        return Icons.fact_check_outlined;
      case 'admin_review_required':
        return Icons.rate_review_outlined;
      default:
        return Icons.notifications_none_outlined;
    }
  }

  static Color _iconColor(String type) {
    switch (type) {
      case 'event_approved':
        return AppColors.secondary;
      case 'event_rejected':
        return const Color(0xFFDC2626);
      case 'chat_message':
        return AppColors.primary;
      case 'broadcast':
        return AppColors.tertiary;
      case 'event_reminder_1h':
        return AppColors.primary;
      case 'event_checkin_reminder':
        return AppColors.secondary;
      case 'admin_review_required':
        return const Color(0xFF7C3AED);
      default:
        return AppColors.textSecondary;
    }
  }

  static Color _iconBackground(String type) {
    switch (type) {
      case 'event_approved':
        return const Color(0xFFDCFCE7);
      case 'event_rejected':
        return const Color(0xFFFEE2E2);
      case 'chat_message':
        return AppColors.infoSoft;
      case 'broadcast':
        return const Color(0xFFE8F5EC);
      case 'event_reminder_1h':
        return AppColors.infoSoft;
      case 'event_checkin_reminder':
        return const Color(0xFFE8F5EC);
      case 'admin_review_required':
        return const Color(0xFFF3E8FF);
      default:
        return AppColors.surfaceMuted;
    }
  }
}

class _NotificationGroupHeader extends StatelessWidget {
  final String label;

  const _NotificationGroupHeader({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
      child: Text(
        label.toUpperCase(),
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.6,
            ),
      ),
    );
  }
}

class _NotificationRow extends StatelessWidget {
  final AppNotification notification;
  final Future<void> Function() onTap;

  const _NotificationRow({
    required this.notification,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final sentAt = notification.createdAt?.toDate();
    final sentAtLabel = sentAt == null ? 'Just now' : _relativeTime(sentAt);

    return Material(
      color: notification.isRead ? Colors.transparent : AppColors.infoSoft.withOpacity(0.4),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: _NotificationsScreenState._iconBackground(notification.type),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _NotificationsScreenState._iconForType(notification.type),
                  color: _NotificationsScreenState._iconColor(notification.type),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      notification.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      notification.body,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.textSecondary,
                            height: 1.4,
                          ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      sentAtLabel,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.disabled,
                            fontWeight: FontWeight.w500,
                          ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              if (!notification.isRead)
                Container(
                  width: 8,
                  height: 8,
                  margin: const EdgeInsets.only(top: 8),
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                )
              else
                const SizedBox(width: 8),
            ],
          ),
        ),
      ),
    );
  }

  static String _relativeTime(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'Just now';
    }
    if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    }
    if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    }
    if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    }
    return DateFormat.MMMd().format(timestamp);
  }
}

class _EmptyNotificationsState extends StatelessWidget {
  const _EmptyNotificationsState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.infoSoft,
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Icon(
                Icons.notifications_none_outlined,
                size: 34,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'No notifications yet',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Broadcasts, event updates, and chat activity will appear here.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                    height: 1.5,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}


