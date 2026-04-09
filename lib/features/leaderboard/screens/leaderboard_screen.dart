import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../shared/services/firestore_service.dart';
import '../../../shared/theme/app_theme.dart';
import '../../../shared/widgets/shramdaan_network_image.dart';
import '../../profile/screens/public_profile_screen.dart';
import '../models/leaderboard_entry_model.dart';

enum _LeaderboardRange { daily, monthly, allTime }

extension on _LeaderboardRange {
  String get label {
    switch (this) {
      case _LeaderboardRange.daily:
        return 'Daily';
      case _LeaderboardRange.monthly:
        return 'Monthly';
      case _LeaderboardRange.allTime:
        return 'All Time';
    }
  }

  DateTime? get sinceDate {
    final now = DateTime.now();
    switch (this) {
      case _LeaderboardRange.daily:
        return DateTime(now.year, now.month, now.day);
      case _LeaderboardRange.monthly:
        return DateTime(now.year, now.month, 1);
      case _LeaderboardRange.allTime:
        return null;
    }
  }
}

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  static String formatVerifiedTime(int verifiedMinutes) {
    final hours = verifiedMinutes ~/ 60;
    final minutes = verifiedMinutes % 60;
    if (hours == 0) {
      return '$minutes min';
    }
    if (minutes == 0) {
      return '$hours hr';
    }
    return '$hours hr $minutes min';
  }

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final String? _currentUserId = FirebaseAuth.instance.currentUser?.uid;
  _LeaderboardRange _selectedRange = _LeaderboardRange.allTime;
  late Future<List<LeaderboardEntry>> _leaderboardFuture;

  @override
  void initState() {
    super.initState();
    _leaderboardFuture = _loadLeaderboard();
  }

  Future<List<LeaderboardEntry>> _loadLeaderboard() {
    return _firestoreService.getLeaderboardData(
      fromDate: _selectedRange.sinceDate,
    );
  }

  void _selectRange(_LeaderboardRange range) {
    if (_selectedRange == range) {
      return;
    }
    setState(() {
      _selectedRange = range;
      _leaderboardFuture = _loadLeaderboard();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.neutral,
      appBar: AppBar(
        backgroundColor: AppColors.neutral,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Leaderboard',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w800,
            fontFamily: 'Manrope',
          ),
        ),
      ),
      body: Column(
          children: [
            const SizedBox(height: 6),
            _LeaderboardRangeTabs(
              selectedRange: _selectedRange,
              onChanged: _selectRange,
            ),
            const SizedBox(height: 12),
            Expanded(
              child: FutureBuilder<List<LeaderboardEntry>>(
                future: _leaderboardFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting &&
                      !snapshot.hasData) {
                    return const Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    );
                  }
                  if (snapshot.hasError) {
                    return Center(
                      child: Text(
                        'Something went wrong while loading the leaderboard.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppColors.textPrimary,
                              fontFamily: 'Inter',
                            ),
                      ),
                    );
                  }

                  final leaderboard = snapshot.data ?? const <LeaderboardEntry>[];
                  if (leaderboard.isEmpty) {
                    return const _EmptyLeaderboardState();
                  }

                  final topThree = leaderboard.take(3).toList();
                  final others = leaderboard.skip(3).toList();

                  return RefreshIndicator(
                    onRefresh: () async {
                      setState(() {
                        _leaderboardFuture = _loadLeaderboard();
                      });
                      await _leaderboardFuture;
                    },
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                      children: [
                        _LeaderboardHero(
                          totalParticipants: leaderboard.length,
                          rangeLabel: _selectedRange.label,
                        ),
                        const SizedBox(height: 18),
                        _PodiumSection(
                          topThree: topThree,
                          currentUserId: _currentUserId,
                        ),
                        if (others.isNotEmpty) ...[
                          const SizedBox(height: 18),
                          Text(
                            'All Rankings',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  color: AppColors.textPrimary,
                                  fontWeight: FontWeight.w800,
                                  fontFamily: 'Manrope',
                                ),
                          ),
                          const SizedBox(height: 10),
                          ...List.generate(others.length, (index) {
                            final rank = index + 4;
                            return _LeaderboardListRow(
                              entry: others[index],
                              rank: rank,
                              isCurrentUser: others[index].userId == _currentUserId,
                            );
                          }),
                        ],
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
    );
  }
}

class _LeaderboardRangeTabs extends StatelessWidget {
  final _LeaderboardRange selectedRange;
  final ValueChanged<_LeaderboardRange> onChanged;

  const _LeaderboardRangeTabs({
    required this.selectedRange,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: _LeaderboardRange.values.map((range) {
          final active = range == selectedRange;
          return Expanded(
            child: _PressableScale(
              onTap: () => onChanged(range),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutCubic,
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(999),
                  gradient: active
                      ? const LinearGradient(
                          colors: [Color(0xFF005EB8), Color(0xFF2D8CE9)],
                        )
                      : null,
                  color: active ? null : Colors.transparent,
                  boxShadow: active
                      ? [
                          BoxShadow(
                            color: const Color(0xFF002E5A).withOpacity(0.32),
                            blurRadius: 16,
                            offset: const Offset(0, 8),
                          ),
                        ]
                      : null,
                ),
                alignment: Alignment.center,
                child: Text(
                  range.label,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: active ? Colors.white : AppColors.textSecondary,
                        fontWeight: FontWeight.w700,
                        fontFamily: 'Inter',
                      ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _LeaderboardHero extends StatelessWidget {
  final int totalParticipants;
  final String rangeLabel;

  const _LeaderboardHero({
    required this.totalParticipants,
    required this.rangeLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFFEAF3FF),
            Color(0xFFDCEEFF),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFB8D7F7)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF005EB8).withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.emoji_events_rounded, color: AppColors.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$rangeLabel Impact Rankings',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w800,
                        fontFamily: 'Manrope',
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$totalParticipants volunteers competing with verified contribution points.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                        fontFamily: 'Inter',
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

class _PodiumSection extends StatelessWidget {
  final List<LeaderboardEntry> topThree;
  final String? currentUserId;

  const _PodiumSection({
    required this.topThree,
    required this.currentUserId,
  });

  @override
  Widget build(BuildContext context) {
    final second = topThree.length > 1 ? topThree[1] : null;
    final first = topThree.isNotEmpty ? topThree[0] : null;
    final third = topThree.length > 2 ? topThree[2] : null;

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 16, 14, 14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF0069CB).withOpacity(0.42),
            const Color(0xFF0052A3).withOpacity(0.55),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: second == null
                ? const SizedBox.shrink()
                : _PodiumAvatarTile(
                    entry: second,
                    rank: 2,
                    isCurrentUser: second.userId == currentUserId,
                  ),
          ),
          Expanded(
            child: first == null
                ? const SizedBox.shrink()
                : _PodiumAvatarTile(
                    entry: first,
                    rank: 1,
                    isCurrentUser: first.userId == currentUserId,
                  ),
          ),
          Expanded(
            child: third == null
                ? const SizedBox.shrink()
                : _PodiumAvatarTile(
                    entry: third,
                    rank: 3,
                    isCurrentUser: third.userId == currentUserId,
                  ),
          ),
        ],
      ),
    );
  }
}

class _PodiumAvatarTile extends StatelessWidget {
  final LeaderboardEntry entry;
  final int rank;
  final bool isCurrentUser;

  const _PodiumAvatarTile({
    required this.entry,
    required this.rank,
    required this.isCurrentUser,
  });

  @override
  Widget build(BuildContext context) {
    final isFirst = rank == 1;
    final avatarSize = isFirst ? 86.0 : 70.0;
    final glowColor = isFirst ? const Color(0xFFFFC857) : Colors.white;

    return Padding(
      padding: EdgeInsets.only(top: isFirst ? 0 : 20),
      child: _PressableScale(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => PublicProfileScreen(userId: entry.userId),
            ),
          );
        },
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                Container(
                  width: avatarSize + 12,
                  height: avatarSize + 12,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: glowColor.withOpacity(isFirst ? 0.42 : 0.16),
                        blurRadius: isFirst ? 28 : 14,
                        spreadRadius: isFirst ? 4 : 1,
                      ),
                    ],
                  ),
                ),
                _LeaderboardAvatar(
                  photoUrl: entry.photoUrl,
                  size: avatarSize,
                  borderColor: isFirst
                      ? const Color(0xFFFFD773)
                      : Colors.white.withOpacity(0.90),
                  borderWidth: isCurrentUser ? 3 : 2,
                ),
                if (isFirst)
                  const Positioned(
                    top: -18,
                    child: Icon(
                      Icons.workspace_premium_rounded,
                      size: 24,
                      color: Color(0xFFFFD773),
                    ),
                  ),
                Positioned(
                  bottom: -8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0D1C3D),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: Colors.white.withOpacity(0.24)),
                    ),
                    child: Text(
                      '#$rank',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: rank == 1
                                ? const Color(0xFFFFD773)
                                : Colors.white,
                            fontWeight: FontWeight.w800,
                            fontFamily: 'Inter',
                          ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              isCurrentUser ? '${entry.userName} (YOU)' : entry.userName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontFamily: 'Manrope',
                  ),
            ),
            const SizedBox(height: 3),
            Text(
              '${entry.totalPoints} pts',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.white.withOpacity(0.84),
                    fontWeight: FontWeight.w700,
                    fontFamily: 'Inter',
                  ),
            ),
            Text(
              '${LeaderboardScreen.formatVerifiedTime(entry.verifiedMinutes)} | ${entry.attendedEvents} events',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.white.withOpacity(0.68),
                    fontFamily: 'Inter',
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LeaderboardListRow extends StatelessWidget {
  final LeaderboardEntry entry;
  final int rank;
  final bool isCurrentUser;

  const _LeaderboardListRow({
    required this.entry,
    required this.rank,
    required this.isCurrentUser,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: _PressableScale(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => PublicProfileScreen(userId: entry.userId),
            ),
          );
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isCurrentUser
                  ? const [Color(0xFF6941C6), Color(0xFF8A56E8)]
                  : const [Color(0xFF3F2E85), Color(0xFF5A3CB0)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isCurrentUser
                  ? const Color(0xFFFFD773).withOpacity(0.85)
                  : Colors.white.withOpacity(0.15),
              width: isCurrentUser ? 1.4 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF1A0F43).withOpacity(0.26),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            children: [
              SizedBox(
                width: 34,
                child: Text(
                  '$rank',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontFamily: 'Manrope',
                      ),
                ),
              ),
              _LeaderboardAvatar(
                photoUrl: entry.photoUrl,
                size: 46,
                borderColor: Colors.white.withOpacity(0.9),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isCurrentUser ? '${entry.userName} (YOU)' : entry.userName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontFamily: 'Manrope',
                          ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${LeaderboardScreen.formatVerifiedTime(entry.verifiedMinutes)} | ${entry.attendedEvents} events',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.white.withOpacity(0.76),
                            fontFamily: 'Inter',
                          ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${entry.totalPoints} pts',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: rank <= 3 ? const Color(0xFFFFD773) : Colors.white,
                      fontWeight: FontWeight.w800,
                      fontFamily: 'Inter',
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LeaderboardAvatar extends StatelessWidget {
  final String photoUrl;
  final double size;
  final Color borderColor;
  final double borderWidth;

  const _LeaderboardAvatar({
    required this.photoUrl,
    required this.size,
    required this.borderColor,
    this.borderWidth = 2,
  });

  @override
  Widget build(BuildContext context) {
    final hasPhoto = photoUrl.trim().isNotEmpty;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: borderColor, width: borderWidth),
      ),
      child: ClipOval(
        child: hasPhoto
            ? ShramdaanNetworkImage(
                imageUrl: photoUrl,
                width: size,
                height: size,
                fit: BoxFit.cover,
                errorWidget: Container(
                  color: const Color(0xFFE5E7EB),
                  alignment: Alignment.center,
                  child: Icon(
                    Icons.person_outline,
                    color: AppColors.textSecondary,
                    size: size * 0.58,
                  ),
                ),
              )
            : Container(
                color: const Color(0xFFE5E7EB),
                alignment: Alignment.center,
                child: Icon(
                  Icons.person_outline,
                  color: AppColors.textSecondary,
                  size: size * 0.58,
                ),
              ),
      ),
    );
  }
}

class _PressableScale extends StatefulWidget {
  final VoidCallback onTap;
  final Widget child;

  const _PressableScale({
    required this.onTap,
    required this.child,
  });

  @override
  State<_PressableScale> createState() => _PressableScaleState();
}

class _PressableScaleState extends State<_PressableScale> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapCancel: () => setState(() => _pressed = false),
      onTapUp: (_) => setState(() => _pressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        duration: const Duration(milliseconds: 110),
        scale: _pressed ? 0.98 : 1,
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}

class _EmptyLeaderboardState extends StatelessWidget {
  const _EmptyLeaderboardState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(26),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.emoji_events_outlined,
                size: 34,
                color: AppColors.primary,
              ),
              const SizedBox(height: 12),
              Text(
                'No rankings yet',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w800,
                      fontFamily: 'Manrope',
                    ),
              ),
              const SizedBox(height: 6),
              Text(
                'Once attendance is verified, leaderboard standings will appear here.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                      fontFamily: 'Inter',
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
