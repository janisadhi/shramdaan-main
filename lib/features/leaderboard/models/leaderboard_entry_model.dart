import 'achievement_badge_model.dart';

class LeaderboardEntry {
  final String userId;
  final String userName;
  final String photoUrl;
  final int totalPoints;
  final int attendedEvents;
  final int verifiedMinutes;
  final List<AchievementBadge> achievements;

  LeaderboardEntry({
    required this.userId,
    required this.userName,
    required this.photoUrl,
    required this.totalPoints,
    required this.attendedEvents,
    required this.verifiedMinutes,
    required this.achievements,
  });

  double get verifiedHours => verifiedMinutes / 60;
}
