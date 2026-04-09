import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../shared/models/event_model.dart';
import '../../../shared/services/firestore_service.dart';
import '../../../shared/theme/app_theme.dart';
import '../../../shared/utils/location_utils.dart';
import '../../../shared/widgets/shramdaan_network_image.dart';
import '../../events/screens/event_details_screen.dart';
import '../../leaderboard/models/achievement_badge_model.dart';

class PublicProfileScreen extends StatefulWidget {
  final String userId;

  const PublicProfileScreen({super.key, required this.userId});

  @override
  State<PublicProfileScreen> createState() => _PublicProfileScreenState();
}

class _PublicProfileScreenState extends State<PublicProfileScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  late Future<DocumentSnapshot> _userFuture;
  late Future<Map<String, dynamic>> _profileHighlightsFuture;
  DocumentSnapshot? _cachedUserSnapshot;
  Map<String, dynamic>? _cachedProfileHighlights;

  @override
  void initState() {
    super.initState();
    _initializeFutures();
  }

  @override
  void didUpdateWidget(covariant PublicProfileScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.userId != widget.userId) {
      _initializeFutures();
    }
  }

  void _initializeFutures() {
    _cachedUserSnapshot = null;
    _cachedProfileHighlights = null;
    _userFuture = _firestoreService.getUser(widget.userId).then((value) {
      _cachedUserSnapshot = value;
      return value;
    });
    _profileHighlightsFuture = _firestoreService
        .getUserProfileHighlights(widget.userId)
        .then((value) {
          _cachedProfileHighlights = value;
          return value;
        });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<DocumentSnapshot>(
      future: _userFuture,
      initialData: _cachedUserSnapshot,
      builder: (context, userSnapshot) {
        if (!userSnapshot.hasData &&
            userSnapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: AppColors.neutral,
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (userSnapshot.hasError ||
            !userSnapshot.hasData ||
            !userSnapshot.data!.exists) {
          return const Scaffold(
            backgroundColor: AppColors.neutral,
            body: Center(child: Text('User not found.')),
          );
        }

        final userData = userSnapshot.data!.data() as Map<String, dynamic>;
        final userName =
            (userData['displayName'] as String?)?.trim().isNotEmpty == true
            ? (userData['displayName'] as String).trim()
            : 'Anonymous';
        final userEmail =
            (userData['email'] as String?)?.trim().isNotEmpty == true
            ? (userData['email'] as String).trim()
            : null;
        final photoUrl = userData['photoUrl'] ?? '';

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
          ),
          body: DefaultTabController(
            length: 2,
            child: NestedScrollView(
                headerSliverBuilder: (context, innerBoxIsScrolled) {
                  return [
                    SliverToBoxAdapter(
                      child: _PublicProfileHeader(
                        userId: widget.userId,
                        userName: userName,
                        userEmail: userEmail,
                        photoUrl: photoUrl,
                        profileHighlightsFuture: _profileHighlightsFuture,
                        initialProfileHighlights: _cachedProfileHighlights,
                      ),
                    ),
                    SliverPersistentHeader(
                      pinned: true,
                      delegate: _PinnedPublicTabBarDelegate(
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
                    _PublicJoinedEventsTab(
                      userId: widget.userId,
                      firestoreService: _firestoreService,
                    ),
                    _PublicCreatedEventsTab(
                      userId: widget.userId,
                      firestoreService: _firestoreService,
                    ),
                  ],
                ),
            ),
          ),
        );
      },
    );
  }
}

class _PinnedPublicTabBarDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;

  const _PinnedPublicTabBarDelegate({required this.child});

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
  bool shouldRebuild(covariant _PinnedPublicTabBarDelegate oldDelegate) {
    return child != oldDelegate.child;
  }
}

class _PublicProfileHeader extends StatelessWidget {
  final String userId;
  final String userName;
  final String? userEmail;
  final String photoUrl;
  final Future<Map<String, dynamic>> profileHighlightsFuture;
  final Map<String, dynamic>? initialProfileHighlights;

  const _PublicProfileHeader({
    required this.userId,
    required this.userName,
    required this.userEmail,
    required this.photoUrl,
    required this.profileHighlightsFuture,
    required this.initialProfileHighlights,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
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
          FutureBuilder<Map<String, dynamic>>(
            future: profileHighlightsFuture,
            initialData: initialProfileHighlights,
            builder: (context, snapshot) {
              final highlights = snapshot.data ?? const <String, dynamic>{};
              final joinedEventCount = highlights['joinedEventCount'] as int? ?? 0;
              final totalPoints = highlights['totalPoints'] as int? ?? 0;
              final verifiedMinutes = highlights['verifiedMinutes'] as int? ?? 0;
              final badges =
                  highlights['achievements'] as List<AchievementBadge>? ??
                      const <AchievementBadge>[];

              if (!snapshot.hasData &&
                  snapshot.connectionState == ConnectionState.waiting) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: CircularProgressIndicator(strokeWidth: 2),
                );
              }

              return Column(
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
                          border: Border.all(
                            color: AppColors.border,
                            width: 1.5,
                          ),
                        ),
                        child: ClipOval(
                          child: photoUrl.isNotEmpty
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
                        child: Row(
                          children: [
                            Expanded(
                              child: _InstagramPublicStat(
                                value: '$joinedEventCount',
                                label: 'Joined',
                              ),
                            ),
                            Expanded(
                              child: _InstagramPublicStat(
                                value: '$totalPoints',
                                label: 'Points',
                              ),
                            ),
                            Expanded(
                              child: _InstagramPublicStat(
                                value: _formatVerifiedTime(verifiedMinutes),
                                label: 'Hours',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    userName,
                    style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                  ),
                  if (userEmail != null) ...[
                    const SizedBox(height: 3),
                    Text(
                      userEmail!,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                  const SizedBox(height: 14),
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
                      'This volunteer is still collecting verified milestones through Shramdaan.',
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
                          .map((badge) => _PublicAchievementChip(badge: badge))
                          .toList(),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _PublicJoinedEventsTab extends StatefulWidget {
  final String userId;
  final FirestoreService firestoreService;

  const _PublicJoinedEventsTab({
    required this.userId,
    required this.firestoreService,
  });

  @override
  State<_PublicJoinedEventsTab> createState() => _PublicJoinedEventsTabState();
}

class _PublicJoinedEventsTabState extends State<_PublicJoinedEventsTab>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return StreamBuilder<List<Event>>(
      stream: widget.firestoreService.getJoinedEventsStream(widget.userId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const _EmptyProfileState(
            title: 'No joined events yet',
            message: 'This volunteer has not joined any events yet.',
          );
        }

        final events = snapshot.data!;
        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          itemCount: events.length,
          itemBuilder: (context, index) {
            final event = events[index];
            return _PublicEventCard(
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

class _PublicCreatedEventsTab extends StatefulWidget {
  final String userId;
  final FirestoreService firestoreService;

  const _PublicCreatedEventsTab({
    required this.userId,
    required this.firestoreService,
  });

  @override
  State<_PublicCreatedEventsTab> createState() => _PublicCreatedEventsTabState();
}

class _PublicCreatedEventsTabState extends State<_PublicCreatedEventsTab>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return StreamBuilder<List<Event>>(
      stream: widget.firestoreService.getCreatedEventsStream(widget.userId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const _EmptyProfileState(
            title: 'No organized events yet',
            message: 'This volunteer has not organized any events yet.',
          );
        }

        final approvedEvents = snapshot.data!
            .where((event) => event.status == 'approved')
            .toList();

        if (approvedEvents.isEmpty) {
          return const _EmptyProfileState(
            title: 'No public organized events yet',
            message: 'Approved events organized by this volunteer will appear here.',
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          itemCount: approvedEvents.length,
          itemBuilder: (context, index) {
            final event = approvedEvents[index];
            return _PublicEventCard(
              event: event,
              badgeLabel: 'Organized',
              badgeColor: Colors.blue,
            );
          },
        );
      },
    );
  }
}

class _PublicEventCard extends StatelessWidget {
  final Event event;
  final String badgeLabel;
  final Color badgeColor;

  const _PublicEventCard({
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
                _PublicBadge(label: badgeLabel, color: badgeColor),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _PublicMetaChip(
                  icon: Icons.calendar_today_outlined,
                  label: DateFormat.yMMMd().add_jm().format(event.eventDate),
                ),
                _PublicMetaChip(
                  icon: Icons.location_on_outlined,
                  label: LocationUtils.compactAddressLabel(event.formattedAddress),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              event.description,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey.shade800,
                    height: 1.4,
                  ),
            ),
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

class _PublicBadge extends StatelessWidget {
  final String label;
  final Color color;

  const _PublicBadge({
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

class _PublicMetaChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _PublicMetaChip({
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

class _PublicStatChip extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final bool compact;

  const _PublicStatChip({
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

class _InstagramPublicStat extends StatelessWidget {
  final String value;
  final String label;

  const _InstagramPublicStat({
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

class _PublicAchievementChip extends StatelessWidget {
  final AchievementBadge badge;

  const _PublicAchievementChip({required this.badge});

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

class _EmptyProfileState extends StatelessWidget {
  final String title;
  final String message;

  const _EmptyProfileState({
    required this.title,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
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
    );
  }
}
