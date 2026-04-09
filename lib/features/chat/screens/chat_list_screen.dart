import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../shared/services/firestore_service.dart';
import '../../../shared/theme/app_theme.dart';
import '../../../shared/utils/location_utils.dart';
import '../../../shared/widgets/count_badge.dart';
import '../../../shared/widgets/shramdaan_network_image.dart';
import '../../notifications/screens/notifications_screen.dart';
import '../../notifications/services/notification_service.dart';
import '../models/chat_list_entry_model.dart';
import 'chat_screen.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  int _selectedTabIndex = 0;

  Future<void> _refreshChats() async {
    if (!mounted) {
      return;
    }
    setState(() {});
    await Future<void>.delayed(const Duration(milliseconds: 500));
  }

  @override
  Widget build(BuildContext context) {
    final firestoreService = FirestoreService();
    final currentUser = FirebaseAuth.instance.currentUser;
    final currentUserId = currentUser?.uid;

    return Scaffold(
      backgroundColor: AppColors.neutral,
      body: SafeArea(
        bottom: false,
        child: currentUserId == null
            ? const Center(child: Text('Please log in to see your chats.'))
            : Column(
                children: [
                  const Padding(
                    padding: EdgeInsets.fromLTRB(20, 8, 20, 0),
                    child: _MessagesHeader(),
                  ),
                  const SizedBox(height: 18),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
                    child: StreamBuilder<List<ChatListEntry>>(
                      stream: firestoreService.getJoinedChatListStream(
                        currentUserId,
                      ),
                      builder: (context, snapshot) {
                        final chatEntries = snapshot.data ?? const <ChatListEntry>[];
                        final activeEntries = chatEntries
                            .where((entry) => !entry.event.isCompleted)
                            .toList();
                        final archivedEntries = chatEntries
                            .where((entry) => entry.event.isCompleted)
                            .toList();

                        return _ChatListTabs(
                          selectedIndex: _selectedTabIndex,
                          activeCount: activeEntries.length,
                          archivedCount: archivedEntries.length,
                          onChanged: (index) {
                            if (_selectedTabIndex == index) {
                              return;
                            }
                            setState(() {
                              _selectedTabIndex = index;
                            });
                          },
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 18),
                  Expanded(
                    child: StreamBuilder<List<ChatListEntry>>(
                      stream: firestoreService.getJoinedChatListStream(
                        currentUserId,
                      ),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator());
                        }
                        if (snapshot.hasError) {
                          return Center(child: Text('Error: ${snapshot.error}'));
                        }
                        if (!snapshot.hasData || snapshot.data!.isEmpty) {
                          return RefreshIndicator(
                            onRefresh: _refreshChats,
                            child: ListView(
                              physics: const AlwaysScrollableScrollPhysics(),
                              padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                              children: const [
                                SizedBox(height: 22),
                                _EmptyChatListState(),
                              ],
                            ),
                          );
                        }

                        final chatEntries = snapshot.data!;
                        final activeEntries = chatEntries
                            .where((entry) => !entry.event.isCompleted)
                            .toList();
                        final archivedEntries = chatEntries
                            .where((entry) => entry.event.isCompleted)
                            .toList();
                        final visibleEntries = _selectedTabIndex == 0
                            ? activeEntries
                            : archivedEntries;

                        return RefreshIndicator(
                          onRefresh: _refreshChats,
                          child: ListView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                            children: [
                              if (visibleEntries.isEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(top: 22),
                                  child: _ChatTabEmptyState(
                                    isArchived: _selectedTabIndex == 1,
                                  ),
                                )
                              else
                                ...visibleEntries.map(
                                  (entry) => _ChatEventCard(
                                    entry: entry,
                                    onOpen: () async {
                                      await Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => ChatScreen(
                                            eventId: entry.event.id,
                                            eventTitle: entry.event.title,
                                          ),
                                        ),
                                      );
                                      if (mounted) {
                                        setState(() {});
                                      }
                                    },
                                  ),
                                ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

class _ChatListTabs extends StatelessWidget {
  final int selectedIndex;
  final int activeCount;
  final int archivedCount;
  final ValueChanged<int> onChanged;

  const _ChatListTabs({
    required this.selectedIndex,
    required this.activeCount,
    required this.archivedCount,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: _ChatTabButton(
              label: 'Active',
              count: activeCount,
              isSelected: selectedIndex == 0,
              onTap: () => onChanged(0),
            ),
          ),
          Expanded(
            child: _ChatTabButton(
              label: 'Archived',
              count: archivedCount,
              isSelected: selectedIndex == 1,
              onTap: () => onChanged(1),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChatTabButton extends StatelessWidget {
  final String label;
  final int count;
  final bool isSelected;
  final VoidCallback onTap;

  const _ChatTabButton({
    required this.label,
    required this.count,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: isSelected ? AppColors.primary : Colors.transparent,
                width: 2.5,
              ),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: isSelected
                            ? AppColors.primary
                            : AppColors.textSecondary,
                        fontWeight: isSelected
                            ? FontWeight.w700
                            : FontWeight.w500,
                      ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '$count',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: isSelected
                          ? AppColors.primary
                          : AppColors.disabled,
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MessagesHeader extends StatelessWidget {
  const _MessagesHeader();

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                color: AppColors.infoSoft,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppColors.border),
              ),
              clipBehavior: Clip.antiAlias,
              child: Image.asset(
                'assets/icon.png',
                fit: BoxFit.cover,
                alignment: Alignment.center,
              ),
            ),
            const Spacer(),
            Text(
              'Shramdaan',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const Spacer(),
            if (currentUser != null)
              StreamBuilder<int>(
                stream: FirestoreService().getUnreadNotificationCountExcludingTypes(
                  currentUser.uid,
                  const ['chat_message'],
                ),
                builder: (context, snapshot) {
                  return Stack(
                    clipBehavior: Clip.none,
                    children: [
                      _HeaderIconButton(
                        icon: Icons.notifications_none_rounded,
                        onTap: () {
                          NotificationService.instance.clearDisplayedNotifications();
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const NotificationsScreen(),
                            ),
                          );
                        },
                      ),
                      if ((snapshot.data ?? 0) > 0)
                        Positioned(
                          right: -2,
                          top: -2,
                          child: CountBadge(count: snapshot.data ?? 0, minSize: 16),
                        ),
                    ],
                  );
                },
              )
            else
              _HeaderIconButton(
                icon: Icons.notifications_none_rounded,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const NotificationsScreen(),
                    ),
                  );
                },
              ),
          ],
        ),
        const SizedBox(height: 24),
        Text(
          'Messages',
          style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                fontWeight: FontWeight.w800,
                color: AppColors.primary,
              ),
        ),
        const SizedBox(height: 6),
        Text(
          'Connect with your community',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
        ),
      ],
    );
  }
}

class _HeaderIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _HeaderIconButton({
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        width: 46,
        height: 46,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.border),
        ),
        child: Icon(
          icon,
          color: AppColors.textPrimary,
          size: 24,
        ),
      ),
    );
  }
}

class _ChatEventCard extends StatelessWidget {
  final ChatListEntry entry;
  final VoidCallback onOpen;

  const _ChatEventCard({
    required this.entry,
    required this.onOpen,
  });

  @override
  Widget build(BuildContext context) {
    final event = entry.event;
    final hasUnread = entry.unreadCount > 0;
    final latestActivity = entry.latestMessageAt?.toDate();
    final latestMessage = _previewMessage(entry);

    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onOpen,
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: hasUnread ? const Color(0xFFFBFCFE) : Colors.white,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _ChatCardAvatar(
                  imageUrl: event.imageUrl,
                  label: event.category,
                  hasUnread: hasUnread,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              event.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                    fontSize: 17,
                                    fontWeight: hasUnread
                                        ? FontWeight.w800
                                        : FontWeight.w700,
                                    color: AppColors.textPrimary,
                                  ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            _formatTimestamp(latestActivity),
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: hasUnread
                                      ? AppColors.primary
                                      : AppColors.textSecondary,
                                  fontWeight: hasUnread
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                                ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            child: Text(
                              latestMessage,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontSize: 14,
                                    color: hasUnread
                                        ? AppColors.textPrimary
                                        : AppColors.textSecondary,
                                    fontWeight: hasUnread
                                        ? FontWeight.w600
                                        : FontWeight.w500,
                                  ),
                            ),
                          ),
                          if (hasUnread) ...[
                            const SizedBox(width: 10),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.primary,
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                'NEW',
                                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 0.4,
                                    ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        LocationUtils.compactAddressLabel(
                          event.formattedAddress.isNotEmpty
                              ? event.formattedAddress
                              : event.location,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.disabled,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _previewMessage(ChatListEntry entry) {
    if (entry.latestMessageText == null || entry.latestMessageText!.trim().isEmpty) {
      return 'No messages yet. Start the conversation.';
    }

    if (entry.latestSenderName == null || entry.latestSenderName!.trim().isEmpty) {
      return entry.latestMessageText!;
    }

    return '${entry.latestSenderName}: ${entry.latestMessageText}';
  }

  String _formatTimestamp(DateTime? dateTime) {
    if (dateTime == null) {
      return '';
    }

    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'now';
    }
    if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    }
    if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    }
    if (difference.inDays == 1) {
      return 'Yesterday';
    }
    if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    }

    return DateFormat.MMMd().format(dateTime);
  }
}

class _ChatCardAvatar extends StatelessWidget {
  final String imageUrl;
  final String label;
  final bool hasUnread;

  const _ChatCardAvatar({
    required this.imageUrl,
    required this.label,
    required this.hasUnread,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: AppColors.surfaceMuted,
          ),
          clipBehavior: Clip.antiAlias,
          child: imageUrl.isNotEmpty
              ? ShramdaanNetworkImage(
                  imageUrl: imageUrl,
                  width: 72,
                  height: 72,
                )
              : Center(
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Text(
                      label,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                  ),
                ),
        ),
        if (hasUnread)
          const Positioned(
            right: -2,
            top: -2,
            child: _UnreadDot(),
          ),
      ],
    );
  }
}

class _UnreadDot extends StatelessWidget {
  const _UnreadDot();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 18,
      height: 18,
      decoration: BoxDecoration(
        color: const Color(0xFFE53935),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 3),
      ),
    );
  }
}

class _EmptyChatListState extends StatelessWidget {
  const _EmptyChatListState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 76,
              height: 76,
              decoration: BoxDecoration(
                color: AppColors.infoSoft,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.forum_outlined,
                size: 36,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'No event chats yet',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Join an event to unlock its group chat and coordinate with the rest of the volunteers.',
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

class _ChatTabEmptyState extends StatelessWidget {
  final bool isArchived;

  const _ChatTabEmptyState({required this.isArchived});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 36, 0, 0),
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: isArchived ? AppColors.surfaceMuted : AppColors.infoSoft,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(
              isArchived ? Icons.archive_outlined : Icons.forum_outlined,
              size: 34,
              color: isArchived ? AppColors.textSecondary : AppColors.primary,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            isArchived ? 'No archived chats yet' : 'No active chats right now',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            isArchived
                ? 'Chats from completed events will move here automatically.'
                : 'Join an ongoing event to chat with the rest of the volunteers.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                  height: 1.5,
                ),
          ),
        ],
      ),
    );
  }
}
