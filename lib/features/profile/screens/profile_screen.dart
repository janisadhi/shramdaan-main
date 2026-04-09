import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../shared/models/event_model.dart';
import '../../../shared/services/firestore_service.dart';
import '../../../shared/theme/app_theme.dart';
import '../../../shared/utils/location_utils.dart';
import '../../../shared/widgets/count_badge.dart';
import '../../../shared/widgets/shramdaan_network_image.dart';
import '../../admin/screens/admin_dashboard_screen.dart';
import '../../auth/screens/auth_gate.dart';
import '../../auth/screens/login_screen.dart';
import '../../auth/screens/signup_screen.dart';
import '../../auth/services/auth_service.dart';
import '../../events/screens/event_details_screen.dart';
import '../../events/screens/my_events_screen.dart';
import '../../leaderboard/models/achievement_badge_model.dart';
import '../../notifications/screens/notifications_screen.dart';
import '../../notifications/services/notification_service.dart';
import 'edit_profile_screen.dart';
import 'help_support_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final AuthService _authService = AuthService();
  final FirestoreService _firestoreService = FirestoreService();
  final Map<String, Future<Map<String, dynamic>>> _profileHighlightsFutures = {};
  final Map<String, Map<String, dynamic>> _profileHighlightsCache = {};

  Future<Map<String, dynamic>> _profileHighlightsFuture(String userId) {
    return _profileHighlightsFutures.putIfAbsent(
      userId,
      () => _firestoreService.getUserProfileHighlights(userId).then((value) {
        _profileHighlightsCache[userId] = value;
        return value;
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.userChanges(),
      builder: (context, authSnapshot) {
        final currentUser = authSnapshot.data;
        if (currentUser == null) {
          return Scaffold(
            backgroundColor: AppColors.neutral,
            appBar: AppBar(title: const Text('Profile')),
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Sign in to access your profile',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'You can still open Help & Support without an account.',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: AppColors.textSecondary,
                              ),
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Expanded(
                              child: FilledButton(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => const LoginScreen(),
                                    ),
                                  );
                                },
                                child: const Text('Sign In'),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => const SignupScreen(),
                                    ),
                                  );
                                },
                                child: const Text('Sign Up'),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        TextButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const HelpSupportScreen(),
                              ),
                            );
                          },
                          icon: const Icon(Icons.help_outline_rounded, size: 18),
                          label: const Text('Open Help & Support'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        }

        return StreamBuilder<DocumentSnapshot>(
          stream: _firestoreService.getUserStream(currentUser.uid),
          builder: (context, userDocSnapshot) {
            if (!userDocSnapshot.hasData) {
              return const Scaffold(
                backgroundColor: AppColors.neutral,
                body: Center(child: CircularProgressIndicator()),
              );
            }

            final rawData = userDocSnapshot.data!.data();
            final userData = rawData is Map<String, dynamic>
                ? rawData
                : <String, dynamic>{};
            final userRole = userData['role'] ?? 'volunteer';
            final userName =
                (userData['displayName'] as String?)?.trim().isNotEmpty == true
                ? (userData['displayName'] as String).trim()
                : (currentUser.displayName?.trim().isNotEmpty == true
                      ? currentUser.displayName!.trim()
                      : (currentUser.email ?? 'Profile'));

            return Scaffold(
              backgroundColor: AppColors.neutral,
              appBar: AppBar(
                backgroundColor: AppColors.neutral,
                elevation: 0,
                scrolledUnderElevation: 0,
                titleSpacing: 20,
                title: Text(
                  userName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                actions: [
                  Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: StreamBuilder<int>(
                      stream: FirestoreService()
                          .getUnreadNotificationCountExcludingTypes(
                        currentUser.uid,
                        const ['chat_message'],
                      ),
                      builder: (context, notificationSnapshot) {
                        final count = notificationSnapshot.data ?? 0;
                        return Stack(
                          clipBehavior: Clip.none,
                          children: [
                            IconButton(
                              onPressed: () {
                                NotificationService.instance
                                    .clearDisplayedNotifications();
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        const NotificationsScreen(),
                                  ),
                                );
                              },
                              icon: const Icon(Icons.notifications_none_rounded),
                            ),
                            if (count > 0)
                              Positioned(
                                right: 4,
                                top: 6,
                                child: CountBadge(count: count, minSize: 16),
                              ),
                          ],
                        );
                      },
                    ),
                  ),
                ],
              ),
              body: DefaultTabController(
                length: 2,
                child: NestedScrollView(
                  headerSliverBuilder: (context, innerBoxIsScrolled) {
                    return [
                      SliverToBoxAdapter(
                      child: _OwnProfileHeader(
                          currentUser: currentUser,
                          userData: userData,
                          profileHighlightsFuture: _profileHighlightsFuture(
                            currentUser.uid,
                          ),
                          initialProfileHighlights:
                              _profileHighlightsCache[currentUser.uid],
                          onEditProfile: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => EditProfileScreen(
                                currentUser: currentUser,
                                userData: userData,
                              ),
                            ),
                          ),
                          onOpenAdmin: userRole == 'admin'
                              ? () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          const AdminDashboardScreen(),
                                    ),
                                  )
                              : null,
                          onOpenHelp: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const HelpSupportScreen(),
                            ),
                          ),
                          onSignOut: () async {
                            await _authService.signOut();
                            if (context.mounted) {
                              Navigator.pushAndRemoveUntil(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const AuthGate(),
                                ),
                                (route) => false,
                              );
                            }
                          },
                        ),
                      ),
                      SliverPersistentHeader(
                        pinned: true,
                        delegate: _PinnedTabBarDelegate(
                          child: Container(
                            color: AppColors.neutral,
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: AppColors.surface,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: AppColors.border),
                              ),
                              child: const TabBar(
                                indicatorSize: TabBarIndicatorSize.tab,
                                tabs: [
                                  Tab(text: 'Joined Events'),
                                  Tab(text: 'Organized'),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ];
                  },
                  body: TabBarView(
                    children: [
                      _OwnJoinedEventsTab(
                        currentUser: currentUser,
                        firestoreService: _firestoreService,
                      ),
                      _OwnOrganizedTab(
                        currentUser: currentUser,
                        firestoreService: _firestoreService,
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

}

class _PinnedTabBarDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;

  const _PinnedTabBarDelegate({required this.child});

  @override
  double get minExtent => 68;

  @override
  double get maxExtent => 68;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return child;
  }

  @override
  bool shouldRebuild(covariant _PinnedTabBarDelegate oldDelegate) {
    return child != oldDelegate.child;
  }
}

class _OwnProfileHeader extends StatelessWidget {
  final User currentUser;
  final Map<String, dynamic> userData;
  final Future<Map<String, dynamic>> profileHighlightsFuture;
  final Map<String, dynamic>? initialProfileHighlights;
  final VoidCallback onEditProfile;
  final VoidCallback? onOpenAdmin;
  final VoidCallback onOpenHelp;
  final VoidCallback onSignOut;

  const _OwnProfileHeader({
    required this.currentUser,
    required this.userData,
    required this.profileHighlightsFuture,
    required this.initialProfileHighlights,
    required this.onEditProfile,
    required this.onOpenAdmin,
    required this.onOpenHelp,
    required this.onSignOut,
  });

  @override
  Widget build(BuildContext context) {
    final photoUrl = (userData['photoUrl'] as String?)?.trim().isNotEmpty == true
        ? (userData['photoUrl'] as String).trim()
        : currentUser.photoURL;
    final theme = Theme.of(context);
    final displayName =
        (userData['displayName'] as String?)?.trim().isNotEmpty == true
        ? (userData['displayName'] as String).trim()
        : (currentUser.displayName?.trim().isNotEmpty == true
              ? currentUser.displayName!.trim()
              : 'Anonymous User');
    final email =
        (userData['email'] as String?)?.trim().isNotEmpty == true
        ? (userData['email'] as String).trim()
        : (currentUser.email ?? 'No email provided');

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 84,
                height: 84,
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.border, width: 1.5),
                ),
                child: ClipOval(
                  child: photoUrl != null && photoUrl.isNotEmpty
                      ? ShramdaanNetworkImage(
                          imageUrl: photoUrl,
                          width: 84,
                          height: 84,
                          fit: BoxFit.cover,
                          errorWidget: Container(
                            color: Colors.white,
                            alignment: Alignment.center,
                            child: Icon(
                              Icons.person_outline,
                              size: 38,
                              color: AppColors.disabled,
                            ),
                          ),
                        )
                      : Container(
                          color: Colors.white,
                          alignment: Alignment.center,
                          child: Icon(
                            Icons.person_outline,
                            size: 38,
                            color: AppColors.disabled,
                          ),
                        ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: FutureBuilder<Map<String, dynamic>>(
                  future: profileHighlightsFuture,
                  initialData: initialProfileHighlights,
                  builder: (context, snapshot) {
                    final highlights = snapshot.data ?? const <String, dynamic>{};
                    final joinedEventCount =
                        highlights['joinedEventCount'] as int? ?? 0;
                    final totalPoints = highlights['totalPoints'] as int? ?? 0;
                    final verifiedMinutes = highlights['verifiedMinutes'] as int? ?? 0;

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: _InstagramStat(
                                value: '$joinedEventCount',
                                label: 'Joined',
                              ),
                            ),
                            Expanded(
                              child: _InstagramStat(
                                value: '$totalPoints',
                                label: 'Points',
                              ),
                            ),
                            Expanded(
                              child: _InstagramStat(
                                value: _formatVerifiedTime(verifiedMinutes),
                                label: 'Hours',
                              ),
                            ),
                          ],
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            displayName,
            style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
          ),
          const SizedBox(height: 3),
          Text(
            email,
            style: theme.textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
          const SizedBox(height: 14),
          FutureBuilder<Map<String, dynamic>>(
            future: profileHighlightsFuture,
            initialData: initialProfileHighlights,
            builder: (context, snapshot) {
              final highlights = snapshot.data ?? const <String, dynamic>{};
              final badges =
                  highlights['achievements'] as List<AchievementBadge>? ??
                      const <AchievementBadge>[];

              if (!snapshot.hasData &&
                  snapshot.connectionState == ConnectionState.waiting) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: LinearProgressIndicator(minHeight: 2),
                );
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Achievements',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  if (badges.isEmpty)
                    Text(
                      'Your verified milestones will appear here as you join and complete more Shramdaans.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                        height: 1.4,
                      ),
                    )
                  else
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: badges
                          .map((badge) => _ProfileAchievementChip(badge: badge))
                          .toList(),
                    ),
                ],
              );
            },
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              if (onOpenAdmin != null) ...[
                Expanded(
                  child: _ProfileActionButton(
                    label: 'Admin Dashboard',
                    onTap: onOpenAdmin!,
                  ),
                ),
                const SizedBox(width: 8),
              ],
              Expanded(
                child: _ProfileActionButton(
                  label: 'Help',
                  onTap: onOpenHelp,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _ProfileActionButton(
                  label: 'Edit Profile',
                  onTap: onEditProfile,
                ),
              ),
              const SizedBox(width: 8),
              _ProfileIconButton(
                icon: Icons.logout_rounded,
                onTap: onSignOut,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InstagramStat extends StatelessWidget {
  final String value;
  final String label;

  const _InstagramStat({
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
                fontSize: 12,
              ),
        ),
      ],
    );
  }
}

class _ProfileActionButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _ProfileActionButton({
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(0, 38),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        backgroundColor: AppColors.surface,
        side: const BorderSide(color: AppColors.primary),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}

class _ProfileIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _ProfileIconButton({
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(38, 38),
        padding: EdgeInsets.zero,
        backgroundColor: AppColors.surface,
        side: const BorderSide(color: AppColors.primary),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
      child: Icon(icon, color: AppColors.primary, size: 18),
    );
  }
}

class _HeaderIconAction extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color backgroundColor;
  final VoidCallback onTap;
  final int badgeCount;

  const _HeaderIconAction({
    required this.icon,
    required this.iconColor,
    required this.backgroundColor,
    required this.onTap,
    this.badgeCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(16),
            child: Ink(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: backgroundColor,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: iconColor),
            ),
          ),
        ),
        if (badgeCount > 0)
          Positioned(
            right: -4,
            top: -4,
            child: CountBadge(count: badgeCount, minSize: 16),
          ),
      ],
    );
  }
}

class _ProfileAchievementChip extends StatelessWidget {
  final AchievementBadge badge;

  const _ProfileAchievementChip({required this.badge});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: badge.color.withOpacity(0.16)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              color: badge.backgroundColor,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(badge.icon, size: 12, color: badge.color),
          ),
          const SizedBox(width: 6),
          Text(
            badge.title,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: badge.color,
                  fontWeight: FontWeight.w600,
                  fontSize: 11.5,
                ),
          ),
        ],
      ),
    );
  }
}

class _ProfileStatChip extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final bool compact;

  const _ProfileStatChip({
    required this.label,
    required this.value,
    required this.icon,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final iconBoxSize = compact ? 28.0 : 32.0;
    final iconSize = compact ? 14.0 : 16.0;
    final horizontalPadding = compact ? 8.0 : 10.0;
    final verticalPadding = compact ? 9.0 : 10.0;
    final labelFontSize = compact ? 10.0 : 11.0;
    final valueFontSize = compact ? 14.0 : 15.0;
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: horizontalPadding,
        vertical: verticalPadding,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.72),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.9)),
      ),
      child: Row(
        children: [
          Container(
            width: iconBoxSize,
            height: iconBoxSize,
            decoration: BoxDecoration(
              color: const Color(0xFFEEF2FF),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: iconSize, color: const Color(0xFF4F46E5)),
          ),
          SizedBox(width: compact ? 6 : 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: const Color(0xFF667085),
                        fontWeight: FontWeight.w700,
                        fontSize: labelFontSize,
                      ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: compact ? 1 : 2),
                Text(
                  value,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF172033),
                        fontSize: valueFontSize,
                      ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

String _formatVerifiedTime(int verifiedMinutes) {
  final hours = verifiedMinutes ~/ 60;
  final minutes = verifiedMinutes % 60;
  if (hours == 0) {
    return '${minutes}m';
  }
  if (minutes == 0) {
    return '${hours}h';
  }
  return '${hours}h ${minutes}m';
}

class _OwnJoinedEventsTab extends StatefulWidget {
  final User currentUser;
  final FirestoreService firestoreService;

  const _OwnJoinedEventsTab({
    required this.currentUser,
    required this.firestoreService,
  });

  @override
  State<_OwnJoinedEventsTab> createState() => _OwnJoinedEventsTabState();
}

class _OwnJoinedEventsTabState extends State<_OwnJoinedEventsTab>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return StreamBuilder<List<Event>>(
      stream: widget.firestoreService.getJoinedEventsStream(widget.currentUser.uid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const _OwnEmptyState(
            title: 'No joined events yet',
            message: 'Events you join will show up here.',
          );
        }

        final events = snapshot.data!;
        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          itemCount: events.length,
          itemBuilder: (context, index) {
            final event = events[index];
            return _OwnEventCard(
              event: event,
              badgeLabel: 'Joined',
              badgeColor: Colors.green,
            );
          },
        );
      },
    );
  }
}

class _OwnOrganizedTab extends StatefulWidget {
  final User currentUser;
  final FirestoreService firestoreService;

  const _OwnOrganizedTab({
    required this.currentUser,
    required this.firestoreService,
  });

  @override
  State<_OwnOrganizedTab> createState() => _OwnOrganizedTabState();
}

class _OwnOrganizedTabState extends State<_OwnOrganizedTab>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return StreamBuilder<List<Event>>(
      stream: widget.firestoreService.getCreatedEventsStream(widget.currentUser.uid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const _OwnEmptyState(
            title: 'No organized events yet',
            message: 'Events you organize will show up here.',
          );
        }

        final events = snapshot.data!;
        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Align(
                alignment: Alignment.centerLeft,
                child: FilledButton.tonalIcon(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const MyEventsScreen(),
                    ),
                  ),
                  icon: const Icon(Icons.event_note_outlined),
                  label: const Text('Open My Events'),
                ),
              ),
            ),
            ...events.map(
              (event) => _OwnEventCard(
                event: event,
                badgeLabel: _statusLabel(event.status),
                badgeColor: _statusColor(event.status),
              ),
            ),
          ],
        );
      },
    );
  }

  static String _statusLabel(String status) {
    switch (status) {
      case 'approved':
        return 'Approved';
      case 'rejected':
        return 'Rejected';
      default:
        return 'Pending';
    }
  }

  static Color _statusColor(String status) {
    switch (status) {
      case 'approved':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.orange;
    }
  }
}

class _OwnEventCard extends StatelessWidget {
  final Event event;
  final String badgeLabel;
  final Color badgeColor;

  const _OwnEventCard({
    required this.event,
    required this.badgeLabel,
    required this.badgeColor,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        event.title,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        event.category,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.grey.shade700,
                            ),
                      ),
                    ],
                  ),
                ),
                _OwnBadge(label: badgeLabel, color: badgeColor),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _OwnMetaChip(
                  icon: Icons.calendar_today_outlined,
                  label: DateFormat.yMMMd().add_jm().format(event.eventDate),
                ),
                _OwnMetaChip(
                  icon: Icons.location_on_outlined,
                  label: LocationUtils.compactAddressLabel(event.formattedAddress),
                ),
              ],
            ),
            if (event.rejectionReason != null &&
                event.rejectionReason!.trim().isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Reason: ${event.rejectionReason}',
                  style: TextStyle(color: Colors.red.shade700),
                ),
              ),
            ],
            const SizedBox(height: 12),
            FilledButton.tonalIcon(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => EventDetailsScreen(eventId: event.id),
                ),
              ),
              icon: const Icon(Icons.visibility_outlined),
              label: const Text('View Event'),
            ),
          ],
        ),
      ),
    );
  }
}

class _OwnBadge extends StatelessWidget {
  final String label;
  final Color color;

  const _OwnBadge({
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _OwnMetaChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _OwnMetaChip({
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 260),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Colors.grey.shade700),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _OwnEmptyState extends StatelessWidget {
  final String title;
  final String message;

  const _OwnEmptyState({
    required this.title,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 32),
      children: [
        ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 220),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.person_search_outlined,
                  size: 48,
                  color: Colors.grey.shade400,
                ),
                const SizedBox(height: 12),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey.shade700,
                      ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
