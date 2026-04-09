import 'package:flutter/material.dart';

import '../../../shared/theme/app_theme.dart';

class HelpSupportScreen extends StatelessWidget {
  const HelpSupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AppColors.neutral,
      appBar: AppBar(
        backgroundColor: AppColors.neutral,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: const Text('Help & Support'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Everything you need to use Shramdaan smoothly.',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'This guide covers the normal volunteer experience: discovering events, joining, chatting, QR attendance, notifications, profile, and common fixes.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          const _HelpSection(
            title: 'Getting Started',
            icon: Icons.play_circle_outline_rounded,
            items: [
              'Create an account and complete your profile so other volunteers and organizers can recognize you.',
              'Use the Home screen to browse featured opportunities and discover events near your location.',
              'Tap any event card to open full details, see the organizer, location, things to bring, and join options.',
            ],
          ),
          const _HelpSection(
            title: 'Finding Events',
            icon: Icons.search_rounded,
            items: [
              'Use the Home search bar to search by event title or location.',
              'The category filters help you narrow events like Clean Up, Plantation, or Donation.',
              'Active events appear first in lists. Completed events are shown lower in the list.',
            ],
          ),
          const _HelpSection(
            title: 'Joining An Event',
            icon: Icons.event_available_rounded,
            items: [
              'Tap Join Event on the event detail screen to RSVP.',
              'RSVP stays open until 1 hour before the event starts.',
              'If RSVP is closed, the event is too close to the start time or already completed.',
              'Joined events appear in your profile under Joined Events.',
            ],
          ),
          const _HelpSection(
            title: 'QR Check-In & Check-Out',
            icon: Icons.qr_code_scanner_rounded,
            items: [
              'Use the Scan button to open the QR scanner for attendance.',
              'You can only check in or check out during the event time window.',
              'Scanning once records check-in. Scanning again records check-out for the same event day.',
              'Your verified attendance contributes to points, hours, badges, and leaderboard ranking.',
            ],
          ),
          const _HelpSection(
            title: 'Event Chat',
            icon: Icons.forum_outlined,
            items: [
              'Once you join an event, its group chat appears in your Chats tab.',
              'Active chats stay in Active. Completed-event chats move to Archived automatically.',
              'Use chat to coordinate timing, arrival, updates, and volunteer communication.',
            ],
          ),
          const _HelpSection(
            title: 'Notifications',
            icon: Icons.notifications_none_rounded,
            items: [
              'Notifications keep you updated about approvals, event changes, and new activity.',
              'The Notifications screen lets you review unread and previous updates.',
              'Mark all as read if you want to clear your unread notification state quickly.',
              'You should not receive popup notifications for actions you triggered yourself.',
            ],
          ),
          const _HelpSection(
            title: 'Profile, Points, And Achievements',
            icon: Icons.person_outline_rounded,
            items: [
              'Your profile shows joined events, verified hours, total points, and achievements.',
              'Use Edit Profile to update your name, photo, phone number, gender, and date of birth.',
              'Badges are earned from verified participation and are shown on both private and public profile views.',
            ],
          ),
          const _HelpSection(
            title: 'Leaderboard',
            icon: Icons.emoji_events_outlined,
            items: [
              'The leaderboard ranks volunteers by verified contribution.',
              'Points are based on attendance, not just RSVPs.',
              'More verified time and completed attendance improve your position.',
            ],
          ),
          const _HelpSection(
            title: 'Common Questions',
            icon: Icons.help_outline_rounded,
            items: [
              'If an uploaded image does not appear right away, refresh or reopen the screen after upload completes.',
              'If you cannot check in, confirm that the event has started and has not already ended.',
              'If a chat is missing, confirm that you actually joined the event and that the event is not archived.',
              'If a screen looks outdated after a major app change, a hot restart or app restart usually refreshes the cached UI properly.',
            ],
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.infoSoft,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.primary.withOpacity(0.14)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.support_agent_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Need more help?',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'If something still feels broken or unclear, take a screenshot and share the exact issue with the team so it can be fixed faster.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: AppColors.textSecondary,
                          height: 1.45,
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

class _HelpSection extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<String> items;

  const _HelpSection({
    required this.title,
    required this.icon,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: AppColors.infoSoft,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  size: 18,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    margin: const EdgeInsets.only(top: 7),
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      item,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
