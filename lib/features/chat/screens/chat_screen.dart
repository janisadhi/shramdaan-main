import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../shared/models/event_model.dart';
import '../../../shared/services/firestore_service.dart';
import '../../../shared/theme/app_theme.dart';
import '../../../shared/widgets/count_badge.dart';
import '../../notifications/screens/notifications_screen.dart';
import '../../notifications/services/notification_service.dart';
import '../models/chat_message_model.dart';

class ChatScreen extends StatefulWidget {
  final String eventId;
  final String eventTitle;

  const ChatScreen({
    super.key,
    required this.eventId,
    required this.eventTitle,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FirestoreService _firestoreService = FirestoreService();
  final User? _currentUser = FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    final userId = _currentUser?.uid;
    if (userId != null) {
      _firestoreService.markMatchingNotificationsRead(
        userId,
        types: const ['chat_message'],
        targetId: widget.eventId,
      );
      _firestoreService.markChatSummaryRead(userId, widget.eventId);
    }
    NotificationService.instance.clearDisplayedNotifications(
      types: const ['chat_message'],
      targetId: widget.eventId,
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendMessage() {
    if (_messageController.text.trim().isEmpty || _currentUser == null) {
      return;
    }

    final message = ChatMessage(
      senderId: _currentUser.uid,
      senderName: _currentUser.displayName ?? 'Anonymous',
      text: _messageController.text.trim(),
      timestamp: Timestamp.now(),
    );
    _firestoreService.sendMessage(widget.eventId, message);
    _messageController.clear();
  }

  void _scrollToLatest({bool animated = true}) {
    if (!_scrollController.hasClients) {
      return;
    }

    final target = _scrollController.position.maxScrollExtent;
    if (animated) {
      _scrollController.animateTo(
        target,
        duration: const Duration(milliseconds: 240),
        curve: Curves.easeOut,
      );
    } else {
      _scrollController.jumpTo(target);
    }
  }

  void _openNotifications() {
    NotificationService.instance.clearDisplayedNotifications();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const NotificationsScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Event?>(
      stream: _firestoreService.getEventStream(widget.eventId),
      builder: (context, eventSnapshot) {
        final event = eventSnapshot.data;

        return Scaffold(
          backgroundColor: AppColors.neutral,
          body: SafeArea(
            bottom: false,
            child: Column(
              children: [
                _ChatHeader(
                  eventId: widget.eventId,
                  eventTitle: event?.title ?? widget.eventTitle,
                  currentUser: _currentUser,
                  onBack: () => Navigator.pop(context),
                  onTapNotifications: _openNotifications,
                ),
                Expanded(
                  child: StreamBuilder<List<ChatMessage>>(
                    stream: _firestoreService.getChatMessagesStream(widget.eventId),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (!snapshot.hasData || snapshot.data!.isEmpty) {
                        return _EmptyChatState(eventTitle: widget.eventTitle);
                      }

                      final messages = snapshot.data!;
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (!mounted) return;
                        _scrollToLatest(animated: false);
                      });

                      return ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
                        itemCount: messages.length + 1,
                        itemBuilder: (context, index) {
                          if (index == 0) {
                            return const _TodayDivider();
                          }

                          final message = messages[messages.length - index];
                          final isCurrentUser =
                              message.senderId == _currentUser?.uid;
                          final isOrganizer =
                              event != null && message.senderId == event.organizerId;
                          final previous = index < messages.length
                              ? messages[messages.length - index - 1]
                              : null;
                          final startsGroup = previous == null ||
                              previous.senderId != message.senderId ||
                              !_isSameMinute(
                                previous.timestamp.toDate(),
                                message.timestamp.toDate(),
                              );

                          return _ModernChatBubble(
                            text: message.text,
                            senderName: message.senderName,
                            timestamp: message.timestamp,
                            isCurrentUser: isCurrentUser,
                            isOrganizer: isOrganizer,
                            startsGroup: startsGroup,
                          );
                        },
                      );
                    },
                  ),
                ),
                _buildMessageInput(context),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMessageInput(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        color: AppColors.neutral,
        padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
        child: Container(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.border),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: TextField(
                  controller: _messageController,
                  minLines: 1,
                  maxLines: 4,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: InputDecoration(
                    hintText: 'Type a message',
                    hintStyle: const TextStyle(color: AppColors.disabled),
                    filled: true,
                    fillColor: AppColors.surfaceMuted,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(18),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(18),
                      borderSide: const BorderSide(color: AppColors.border),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(18),
                      borderSide: const BorderSide(
                        color: AppColors.primary,
                        width: 1.3,
                      ),
                    ),
                  ),
                  onSubmitted: (_) => _sendMessage(),
                ),
              ),
              const SizedBox(width: 8),
              InkWell(
                onTap: _sendMessage,
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppColors.primary,
                        Color(0xFF1C74D1),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withOpacity(0.22),
                        blurRadius: 14,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.send_rounded,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  bool _isSameMinute(DateTime a, DateTime b) {
    return a.year == b.year &&
        a.month == b.month &&
        a.day == b.day &&
        a.hour == b.hour &&
        a.minute == b.minute;
  }
}

class _ChatHeader extends StatelessWidget {
  final String eventId;
  final String eventTitle;
  final User? currentUser;
  final VoidCallback onBack;
  final VoidCallback onTapNotifications;

  const _ChatHeader({
    required this.eventId,
    required this.eventTitle,
    required this.currentUser,
    required this.onBack,
    required this.onTapNotifications,
  });

  @override
  Widget build(BuildContext context) {
    final firestoreService = FirestoreService();

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(10, 8, 12, 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          IconButton(
            onPressed: onBack,
            icon: const Icon(Icons.arrow_back_rounded),
            color: AppColors.textPrimary,
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  eventTitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                ),
                const SizedBox(height: 4),
                StreamBuilder<int>(
                  stream: firestoreService.getEventParticipantCountStream(eventId),
                  builder: (context, snapshot) {
                    final participantCount = snapshot.data ?? 0;
                    return Row(
                      children: [
                        Container(
                          width: 7,
                          height: 7,
                          decoration: const BoxDecoration(
                            color: AppColors.secondary,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '$participantCount PARTICIPANTS',
                          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                                color: AppColors.secondary,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.6,
                              ),
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          if (currentUser != null)
            StreamBuilder<int>(
              stream: firestoreService.getUnreadNotificationCountExcludingTypes(
                currentUser!.uid,
                const ['chat_message'],
              ),
              builder: (context, snapshot) {
                return Stack(
                  clipBehavior: Clip.none,
                  children: [
                    _HeaderActionButton(
                      icon: Icons.notifications_none_rounded,
                      onTap: onTapNotifications,
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
            _HeaderActionButton(
              icon: Icons.notifications_none_rounded,
              onTap: onTapNotifications,
            ),
          const SizedBox(width: 10),
          _CurrentUserAvatar(currentUser: currentUser),
        ],
      ),
    );
  }
}

class _HeaderActionButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _HeaderActionButton({
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: AppColors.surfaceMuted,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.border),
        ),
        child: Icon(
          icon,
          color: AppColors.textPrimary,
          size: 22,
        ),
      ),
    );
  }
}

class _CurrentUserAvatar extends StatelessWidget {
  final User? currentUser;

  const _CurrentUserAvatar({required this.currentUser});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 52,
      height: 52,
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Image.asset(
          'assets/icon.png',
          fit: BoxFit.cover,
        ),
      ),
    );
  }
}

class _TodayDivider extends StatelessWidget {
  const _TodayDivider();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 7),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.border),
          ),
          child: Text(
            'TODAY',
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: AppColors.textSecondary,
                  letterSpacing: 1.0,
                  fontWeight: FontWeight.w700,
                ),
          ),
        ),
      ),
    );
  }
}

class _ModernChatBubble extends StatelessWidget {
  final String text;
  final String senderName;
  final Timestamp timestamp;
  final bool isCurrentUser;
  final bool isOrganizer;
  final bool startsGroup;

  const _ModernChatBubble({
    required this.text,
    required this.senderName,
    required this.timestamp,
    required this.isCurrentUser,
    required this.isOrganizer,
    required this.startsGroup,
  });

  @override
  Widget build(BuildContext context) {
    final timeLabel = DateFormat.jm().format(timestamp.toDate());
    final textColor = isOrganizer ? Colors.white : AppColors.textPrimary;
    final timeColor = isOrganizer
        ? Colors.white.withOpacity(0.82)
        : AppColors.disabled;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 14 * (1 - value)),
            child: child,
          ),
        );
      },
      child: Padding(
        padding: EdgeInsets.only(
          top: startsGroup ? 10 : 4,
          bottom: 4,
        ),
        child: Column(
          crossAxisAlignment:
              isCurrentUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            if (startsGroup)
              Padding(
                padding: EdgeInsets.only(
                  left: isCurrentUser ? 0 : 4,
                  right: isCurrentUser ? 4 : 0,
                  bottom: 6,
                ),
                child: Row(
                  mainAxisAlignment: isCurrentUser
                      ? MainAxisAlignment.end
                      : MainAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      isCurrentUser ? 'You' : senderName,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    if (isOrganizer) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.infoSoft,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          'ORGANIZER',
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.4,
                              ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            Align(
              alignment:
                  isCurrentUser ? Alignment.centerRight : Alignment.centerLeft,
              child: Container(
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.76,
                ),
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
                decoration: BoxDecoration(
                  color: isOrganizer ? null : Colors.white,
                  gradient: isOrganizer
                      ? const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Color(0xFF005EB8),
                            Color(0xFF0B6FD5),
                          ],
                        )
                      : null,
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(20),
                    topRight: const Radius.circular(20),
                    bottomLeft: Radius.circular(isCurrentUser ? 20 : 10),
                    bottomRight: Radius.circular(isCurrentUser ? 10 : 20),
                  ),
                  border: isOrganizer
                      ? null
                      : Border.all(color: AppColors.border),
                  boxShadow: [
                    BoxShadow(
                      color: isOrganizer
                          ? AppColors.primary.withOpacity(0.18)
                          : Colors.black.withOpacity(0.05),
                      blurRadius: isOrganizer ? 18 : 12,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      text,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: textColor,
                            height: 1.5,
                          ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          timeLabel,
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                color: timeColor,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                        if (isCurrentUser) ...[
                          const SizedBox(width: 6),
                          Text(
                            '✓✓',
                            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                  color: isOrganizer
                                      ? Colors.white.withOpacity(0.82)
                                      : AppColors.secondary,
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyChatState extends StatelessWidget {
  final String eventTitle;

  const _EmptyChatState({required this.eventTitle});

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
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.chat_bubble_outline_rounded,
                size: 34,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Start the conversation',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'No messages yet in "$eventTitle". Say hello, share meeting details, or coordinate with the team.',
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
