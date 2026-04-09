import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ChatBubble extends StatelessWidget {
  final String text;
  final String senderName;
  final Timestamp timestamp;
  final bool isCurrentUser;

  const ChatBubble({
    super.key,
    required this.text,
    required this.senderName,
    required this.timestamp,
    required this.isCurrentUser,
  });

  @override
  Widget build(BuildContext context) {
    final bubbleColor = isCurrentUser
        ? const Color(0xFF1F2940)
        : Colors.white;
    final textColor = isCurrentUser
        ? Colors.white
        : const Color(0xFF172033);
    final timeLabel = DateFormat.jm().format(timestamp.toDate());

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment:
            isCurrentUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isCurrentUser) ...[
            _ChatAvatar(name: senderName),
            const SizedBox(width: 10),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment: isCurrentUser
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              children: [
                if (!isCurrentUser)
                  Padding(
                    padding: const EdgeInsets.only(left: 2, bottom: 4),
                    child: Text(
                      senderName,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: const Color(0xFF667085),
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                  ),
                Container(
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.72,
                  ),
                  padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
                  decoration: BoxDecoration(
                    color: bubbleColor,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(20),
                      topRight: const Radius.circular(20),
                      bottomLeft: Radius.circular(isCurrentUser ? 20 : 6),
                      bottomRight: Radius.circular(isCurrentUser ? 6 : 20),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF101828).withOpacity(0.06),
                        blurRadius: 14,
                        offset: const Offset(0, 6),
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
                              height: 1.45,
                            ),
                      ),
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerRight,
                        child: Text(
                          timeLabel,
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                color: isCurrentUser
                                    ? Colors.white.withOpacity(0.72)
                                    : const Color(0xFF98A2B3),
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ChatAvatar extends StatelessWidget {
  final String name;

  const _ChatAvatar({required this.name});

  @override
  Widget build(BuildContext context) {
    final initial = name.trim().isEmpty ? '?' : name.trim()[0].toUpperCase();

    return Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).colorScheme.primary.withOpacity(0.16),
            const Color(0xFFEAF4FF),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      alignment: Alignment.center,
      child: Text(
        initial,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: const Color(0xFF2563EB),
              fontWeight: FontWeight.w800,
            ),
      ),
    );
  }
}
