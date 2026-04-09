class AdminAnalytics {
  final int totalEvents;
  final int pendingEvents;
  final int approvedEvents;
  final int rejectedEvents;
  final int totalUsers;
  final int activeUsers;
  final int bannedUsers;
  final int totalBroadcasts;
  final double completionRate;
  final Map<String, int> categoryCounts;
  final Map<String, int> userGrowthByMonth;

  const AdminAnalytics({
    required this.totalEvents,
    required this.pendingEvents,
    required this.approvedEvents,
    required this.rejectedEvents,
    required this.totalUsers,
    required this.activeUsers,
    required this.bannedUsers,
    required this.totalBroadcasts,
    required this.completionRate,
    required this.categoryCounts,
    required this.userGrowthByMonth,
  });
}
