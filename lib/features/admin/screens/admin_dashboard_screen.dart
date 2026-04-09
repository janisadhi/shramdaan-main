import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../shared/models/event_model.dart';
import '../../../shared/services/firestore_service.dart';
import '../../../shared/theme/app_theme.dart';
import '../../../shared/utils/location_utils.dart';
import '../../admin/models/admin_analytics_model.dart';
import '../../admin/models/admin_broadcast_model.dart';
import '../../admin/models/admin_user_model.dart';
import '../../events/screens/event_details_screen.dart';
import '../../profile/screens/public_profile_screen.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DefaultTabController(
      length: 6,
      child: Scaffold(
        backgroundColor: AppColors.neutral,
        appBar: AppBar(
          toolbarHeight: 84,
          elevation: 0,
          backgroundColor: AppColors.neutral,
          surfaceTintColor: Colors.transparent,
          titleSpacing: 20,
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Admin Dashboard',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Review, moderate, and monitor community activity',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(60),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Container(
                margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                padding: const EdgeInsets.all(6),
                decoration: _adminSurfaceDecoration(radius: 16),
                child: TabBar(
                  isScrollable: true,
                  indicator: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: AppColors.primary,
                  ),
                  labelColor: Colors.white,
                  unselectedLabelColor: AppColors.textSecondary,
                  dividerColor: Colors.transparent,
                  indicatorSize: TabBarIndicatorSize.tab,
                  labelStyle: theme.textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                  tabs: const [
                    Tab(text: 'Review Queue'),
                    Tab(text: 'Approved'),
                    Tab(text: 'Rejected'),
                    Tab(text: 'Users'),
                    Tab(text: 'Analytics'),
                    Tab(text: 'Broadcast'),
                  ],
                ),
              ),
            ),
          ),
        ),
        body: const Column(
          children: [
            Expanded(
              child: TabBarView(
                children: [
                  PendingEventsList(),
                  ApprovedEventsList(),
                  RejectedEventsList(),
                  UsersManagementList(),
                  AnalyticsDashboard(),
                  BroadcastDashboard(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class PendingEventsList extends StatelessWidget {
  const PendingEventsList({super.key});

  @override
  Widget build(BuildContext context) {
    final firestoreService = FirestoreService();

    return StreamBuilder<List<Event>>(
      stream: firestoreService.getPendingEventsStream(),
      builder: (context, snapshot) {
        return _buildBody(
          context,
          snapshot,
          headerTitle: 'Review Queue',
          headerSubtitle: 'New submissions waiting for approval or feedback.',
          onData: (events) => ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
            itemCount: events.length + 1,
            itemBuilder: (context, index) {
              if (index == 0) {
                return const _TabSectionHeader(
                  title: 'Review Queue',
                  subtitle: 'New submissions waiting for approval or feedback.',
                );
              }
              final event = events[index - 1];
              return _EventModerationCard(
                event: event,
                accentColor: AppColors.primary,
                statusText: 'Awaiting review',
                statusIcon: Icons.schedule_outlined,
                primaryActionLabel: 'Approve',
                primaryActionColor: AppColors.secondary,
                onPrimaryAction: () => firestoreService.approveEvent(event.id),
                onSecondaryAction: () =>
                    _showRejectDialog(context, firestoreService, event),
                onOpenDetails: () => _openEventDetails(context, event),
              );
            },
          ),
          emptyTitle: 'No events need review',
          emptyMessage: 'Fresh submissions will show up here for moderation.',
        );
      },
    );
  }
}

class ApprovedEventsList extends StatelessWidget {
  const ApprovedEventsList({super.key});

  @override
  Widget build(BuildContext context) {
    final firestoreService = FirestoreService();

    return StreamBuilder<List<Event>>(
      stream: firestoreService.getApprovedEventsStream(),
      builder: (context, snapshot) {
        return _buildBody(
          context,
          snapshot,
          headerTitle: 'Approved Events',
          headerSubtitle: 'Active events that are currently visible to volunteers.',
          onData: (events) => ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
            itemCount: events.length + 1,
            itemBuilder: (context, index) {
              if (index == 0) {
                return const _TabSectionHeader(
                  title: 'Approved Events',
                  subtitle: 'Active events that are currently visible to volunteers.',
                );
              }
              final event = events[index - 1];
              return _ApprovedEventCard(
                event: event,
                onOpenDetails: () => _openEventDetails(context, event),
                onToggleFeatured: (isFeatured) =>
                    firestoreService.setFeaturedStatus(event.id, isFeatured),
                onReject: () =>
                    _showRejectDialog(context, firestoreService, event),
              );
            },
          ),
          emptyTitle: 'No approved events yet',
          emptyMessage: 'Approved submissions will appear here once they go live.',
        );
      },
    );
  }
}

class RejectedEventsList extends StatelessWidget {
  const RejectedEventsList({super.key});

  @override
  Widget build(BuildContext context) {
    final firestoreService = FirestoreService();

    return StreamBuilder<List<Event>>(
      stream: firestoreService.getRejectedEventsStream(),
      builder: (context, snapshot) {
        return _buildBody(
          context,
          snapshot,
          headerTitle: 'Rejected Events',
          headerSubtitle: 'Submissions that need changes before they can go live again.',
          onData: (events) => ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
            itemCount: events.length + 1,
            itemBuilder: (context, index) {
              if (index == 0) {
                return const _TabSectionHeader(
                  title: 'Rejected Events',
                  subtitle: 'Submissions that need changes before they can go live again.',
                );
              }
              final event = events[index - 1];
              return _RejectedEventCard(
                event: event,
                onReApprove: () => firestoreService.approveEvent(event.id),
                onOpenDetails: () => _openEventDetails(context, event),
              );
            },
          ),
          emptyTitle: 'No rejected events',
          emptyMessage: 'Rejected submissions with feedback will show up here.',
        );
      },
    );
  }
}

class UsersManagementList extends StatelessWidget {
  const UsersManagementList({super.key});

  @override
  Widget build(BuildContext context) {
    final firestoreService = FirestoreService();

    return StreamBuilder<List<AdminUser>>(
      stream: firestoreService.getUsersStream(),
      builder: (context, snapshot) {
        return _buildBody(
          context,
          snapshot,
          headerTitle: 'User Management',
          headerSubtitle: 'Review volunteers and quickly manage access when needed.',
          onData: (users) => ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
            itemCount: users.length + 1,
            itemBuilder: (context, index) {
              if (index == 0) {
                return const _TabSectionHeader(
                  title: 'User Management',
                  subtitle: 'Review volunteers and quickly manage access when needed.',
                );
              }
              final user = users[index - 1];
              return _AdminUserCard(
                user: user,
                onOpenProfile: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => PublicProfileScreen(userId: user.id),
                  ),
                ),
                onBanChanged: (value) =>
                    firestoreService.setUserBanStatus(user.id, value),
              );
            },
          ),
          emptyTitle: 'No users found',
          emptyMessage: 'Registered volunteers will appear here for moderation.',
        );
      },
    );
  }
}

class AnalyticsDashboard extends StatelessWidget {
  const AnalyticsDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final firestoreService = FirestoreService();

    return FutureBuilder<AdminAnalytics>(
      future: firestoreService.getAdminAnalytics(),
      builder: (context, snapshot) {
        return _buildBody(
          context,
          snapshot,
          headerTitle: 'Analytics',
          headerSubtitle: 'A quick pulse on moderation health, growth, and engagement.',
          onData: (analytics) => ListView(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
            children: [
              const _TabSectionHeader(
                title: 'Analytics',
                subtitle: 'A quick pulse on moderation health, growth, and engagement.',
              ),
              Wrap(
                spacing: 14,
                runSpacing: 14,
                children: [
                  _MetricCard(
                    title: 'Total Events',
                    value: '${analytics.totalEvents}',
                    icon: Icons.event_available_outlined,
                    color: AppColors.infoSoft,
                    accent: AppColors.primary,
                  ),
                  _MetricCard(
                    title: 'Total Users',
                    value: '${analytics.totalUsers}',
                    icon: Icons.groups_2_outlined,
                    color: AppColors.surfaceMuted,
                    accent: AppColors.textPrimary,
                  ),
                  _MetricCard(
                    title: 'Active Users',
                    value: '${analytics.activeUsers}',
                    icon: Icons.favorite_border,
                    color: AppColors.successSoft,
                    accent: AppColors.secondary,
                  ),
                  _MetricCard(
                    title: 'Completion Rate',
                    value: '${(analytics.completionRate * 100).toStringAsFixed(0)}%',
                    icon: Icons.insights_outlined,
                    color: const Color(0xFFEAF7EC),
                    accent: AppColors.tertiary,
                  ),
                ],
              ),
              const SizedBox(height: 18),
              _AnalyticsSection(
                title: 'Event Categories',
                subtitle: 'See where volunteer activity is concentrating.',
                child: _DistributionChart(
                  data: analytics.categoryCounts,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 16),
              _AnalyticsSection(
                title: 'User Growth',
                subtitle: 'Monthly registration trend across the last six months.',
                child: _DistributionChart(
                  data: analytics.userGrowthByMonth,
                  color: AppColors.secondary,
                ),
              ),
              const SizedBox(height: 16),
              _AnalyticsSection(
                title: 'Workflow Health',
                subtitle: 'A simple snapshot of moderation flow and account status.',
                child: Column(
                  children: [
                    _MiniStatRow(
                      label: 'Pending Review',
                      value: '${analytics.pendingEvents}',
                      color: AppColors.primary,
                    ),
                    _MiniStatRow(
                      label: 'Approved',
                      value: '${analytics.approvedEvents}',
                      color: AppColors.secondary,
                    ),
                    _MiniStatRow(
                      label: 'Rejected',
                      value: '${analytics.rejectedEvents}',
                      color: AppColors.error,
                    ),
                    _MiniStatRow(
                      label: 'Banned Users',
                      value: '${analytics.bannedUsers}',
                      color: AppColors.tertiary,
                    ),
                  ],
                ),
              ),
            ],
          ),
          emptyTitle: 'Analytics unavailable',
          emptyMessage: 'Try again in a moment once dashboard data loads.',
        );
      },
    );
  }
}
class BroadcastDashboard extends StatefulWidget {
  const BroadcastDashboard({super.key});

  @override
  State<BroadcastDashboard> createState() => _BroadcastDashboardState();
}

class _BroadcastDashboardState extends State<BroadcastDashboard> {
  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();
  bool _isSending = false;

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  Future<void> _sendBroadcast() async {
    final title = _titleController.text.trim();
    final body = _bodyController.text.trim();
    if (title.isEmpty || body.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter both a title and message.')),
      );
      return;
    }

    setState(() => _isSending = true);
    await FirestoreService().sendBroadcast(
      title: title,
      body: body,
      sentBy: 'Admin',
    );
    if (!mounted) {
      return;
    }

    _titleController.clear();
    _bodyController.clear();
    setState(() => _isSending = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Broadcast saved successfully.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final firestoreService = FirestoreService();

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
      children: [
        const _TabSectionHeader(
          title: 'Broadcast Center',
          subtitle: 'Save system-wide announcements and keep admins aligned.',
        ),
        Container(
          decoration: _adminSurfaceDecoration(radius: 18),
          child: Padding(
            padding: const EdgeInsets.all(22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.infoSoft,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: const Text(
                    'Compose Broadcast',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Create a clear update for the whole community.',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'This stores the announcement now so push delivery can plug into it later.',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 18),
                TextField(
                  controller: _titleController,
                  style: const TextStyle(color: AppColors.textPrimary),
                  decoration: _broadcastInputDecoration('Title'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _bodyController,
                  maxLines: 5,
                  style: const TextStyle(color: AppColors.textPrimary),
                  decoration: _broadcastInputDecoration('Message'),
                ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: _isSending ? null : _sendBroadcast,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                  ),
                  icon: _isSending
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.campaign_outlined),
                  label: const Text('Save Broadcast'),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 18),
        _AnalyticsSection(
          title: 'Recent Broadcasts',
          subtitle: 'The latest saved announcements across the dashboard.',
          child: StreamBuilder<List<AdminBroadcast>>(
            stream: firestoreService.getBroadcastsStream(),
            builder: (context, snapshot) {
              return _buildBody(
                context,
                snapshot,
                onData: (broadcasts) => Column(
                  children: broadcasts.take(10).map((broadcast) {
                    final sentAt = broadcast.sentAt == null
                        ? 'Sending...'
                        : DateFormat.yMMMd().add_jm().format(broadcast.sentAt!);
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: _adminSurfaceDecoration(radius: 16),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: AppColors.infoSoft,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.notifications_active_outlined,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  broadcast.title,
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.w700,
                                      ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  broadcast.body,
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                        color: AppColors.textSecondary,
                                        height: 1.4,
                                      ),
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  sentAt,
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                        color: AppColors.disabled,
                                      ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
                emptyTitle: 'No broadcasts yet',
                emptyMessage: 'Saved announcements will appear here once you create one.',
              );
            },
          ),
        ),
      ],
    );
  }

  InputDecoration _broadcastInputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: AppColors.textSecondary),
      filled: true,
      fillColor: AppColors.neutral,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.2),
      ),
    );
  }
}

class _TabSectionHeader extends StatelessWidget {
  final String title;
  final String subtitle;

  const _TabSectionHeader({
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 10, 4, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
        ],
      ),
    );
  }
}

class _EventModerationCard extends StatelessWidget {
  final Event event;
  final Color accentColor;
  final String statusText;
  final IconData statusIcon;
  final String primaryActionLabel;
  final Color primaryActionColor;
  final Future<void> Function() onPrimaryAction;
  final VoidCallback? onSecondaryAction;
  final VoidCallback? onOpenDetails;

  const _EventModerationCard({
    required this.event,
    required this.accentColor,
    required this.statusText,
    required this.statusIcon,
    required this.primaryActionLabel,
    required this.primaryActionColor,
    required this.onPrimaryAction,
    this.onSecondaryAction,
    this.onOpenDetails,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: _adminSurfaceDecoration(radius: 18),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onOpenDetails,
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: const EdgeInsets.all(18),
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
                          _CategoryTag(label: event.category, color: accentColor),
                          const SizedBox(height: 12),
                          Text(
                            event.title,
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.textPrimary,
                                ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            event.description,
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  height: 1.45,
                                  color: AppColors.textSecondary,
                                ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 14),
                    _StatusBadge(
                      label: statusText,
                      icon: statusIcon,
                      color: accentColor,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    _InfoChip(
                      icon: Icons.person_outline,
                      label: event.organizerName,
                    ),
                    _InfoChip(
                      icon: Icons.calendar_today_outlined,
                      label: DateFormat.yMMMd().format(event.eventDate),
                    ),
                    _InfoChip(
                      icon: Icons.place_outlined,
                      label: LocationUtils.compactAddressLabel(event.formattedAddress),
                    ),
                  ],
                ),
                if (event.rejectionReason != null &&
                    event.rejectionReason!.trim().isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEECEC),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFF4C7C3)),
                    ),
                    child: Text(
                      'Reason: ${event.rejectionReason}',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.error,
                          ),
                    ),
                  ),
                ],
                const SizedBox(height: 18),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    FilledButton.icon(
                      onPressed: onPrimaryAction,
                      style: FilledButton.styleFrom(
                        backgroundColor: primaryActionColor,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      ),
                      icon: const Icon(Icons.check_circle_outline),
                      label: Text(primaryActionLabel),
                    ),
                    if (onSecondaryAction != null)
                      OutlinedButton.icon(
                        onPressed: onSecondaryAction,
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          side: const BorderSide(color: AppColors.error),
                          foregroundColor: AppColors.error,
                        ),
                        icon: const Icon(Icons.close),
                        label: const Text('Reject'),
                      ),
                    OutlinedButton.icon(
                      onPressed: onOpenDetails,
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      ),
                      icon: const Icon(Icons.open_in_new_outlined),
                      label: const Text('Open details'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ApprovedEventCard extends StatelessWidget {
  final Event event;
  final VoidCallback onOpenDetails;
  final ValueChanged<bool> onToggleFeatured;
  final VoidCallback onReject;

  const _ApprovedEventCard({
    required this.event,
    required this.onOpenDetails,
    required this.onToggleFeatured,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: _adminSurfaceDecoration(radius: 18),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onOpenDetails,
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: const EdgeInsets.all(18),
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
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              _CategoryTag(
                                label: event.category,
                                color: AppColors.primary,
                              ),
                              _StatusBadge(
                                label: event.isFeatured ? 'Featured' : 'Approved',
                                icon: event.isFeatured
                                    ? Icons.auto_awesome
                                    : Icons.verified_outlined,
                                color: event.isFeatured
                                    ? AppColors.tertiary
                                    : AppColors.secondary,
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            event.title,
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.textPrimary,
                                ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Organizer: ${event.organizerName}',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceMuted,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Feature',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                          ),
                          Switch(
                            value: event.isFeatured,
                            onChanged: onToggleFeatured,
                            activeThumbColor: AppColors.tertiary,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    _InfoChip(
                      icon: Icons.calendar_today_outlined,
                      label: DateFormat.yMMMd().add_jm().format(event.eventDate),
                    ),
                    _InfoChip(
                      icon: Icons.location_on_outlined,
                      label: LocationUtils.compactAddressLabel(event.formattedAddress),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    FilledButton.icon(
                      onPressed: onOpenDetails,
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      ),
                      icon: const Icon(Icons.visibility_outlined),
                      label: const Text('Open details'),
                    ),
                    OutlinedButton.icon(
                      onPressed: onReject,
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        side: const BorderSide(color: AppColors.error),
                        foregroundColor: AppColors.error,
                      ),
                      icon: const Icon(Icons.reply_outlined),
                      label: const Text('Move to Rejected'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RejectedEventCard extends StatelessWidget {
  final Event event;
  final VoidCallback onOpenDetails;
  final Future<void> Function() onReApprove;

  const _RejectedEventCard({
    required this.event,
    required this.onOpenDetails,
    required this.onReApprove,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: _adminSurfaceDecoration(radius: 18),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onOpenDetails,
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: const EdgeInsets.all(18),
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
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              _CategoryTag(
                                label: event.category,
                                color: AppColors.primary,
                              ),
                              const _StatusBadge(
                                label: 'Rejected',
                                icon: Icons.cancel_outlined,
                                color: AppColors.error,
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            event.title,
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.textPrimary,
                                ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Organizer: ${event.organizerName}',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    _InfoChip(
                      icon: Icons.calendar_today_outlined,
                      label: DateFormat.yMMMd().add_jm().format(event.eventDate),
                    ),
                    _InfoChip(
                      icon: Icons.location_on_outlined,
                      label: LocationUtils.compactAddressLabel(event.formattedAddress),
                    ),
                  ],
                ),
                if (event.rejectionReason != null &&
                    event.rejectionReason!.trim().isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEECEC),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFF4C7C3)),
                    ),
                    child: Text(
                      'Reason: ${event.rejectionReason}',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.error,
                          ),
                    ),
                  ),
                ],
                const SizedBox(height: 18),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    FilledButton.icon(
                      onPressed: onOpenDetails,
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      ),
                      icon: const Icon(Icons.visibility_outlined),
                      label: const Text('Open details'),
                    ),
                    FilledButton.icon(
                      onPressed: onReApprove,
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.secondary,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      ),
                      icon: const Icon(Icons.check_circle_outline),
                      label: const Text('Re-Approve'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AdminUserCard extends StatelessWidget {
  final AdminUser user;
  final VoidCallback onOpenProfile;
  final ValueChanged<bool> onBanChanged;

  const _AdminUserCard({
    required this.user,
    required this.onOpenProfile,
    required this.onBanChanged,
  });

  @override
  Widget build(BuildContext context) {
    final roleColor =
        user.role == 'admin' ? AppColors.tertiary : AppColors.primary;
    final statusColor =
        user.isBanned ? AppColors.error : AppColors.secondary;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: _adminSurfaceDecoration(radius: 18),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onOpenProfile,
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: AppColors.infoSoft,
                  backgroundImage:
                      user.photoUrl.isNotEmpty ? NetworkImage(user.photoUrl) : null,
                  child: user.photoUrl.isEmpty
                      ? const Icon(Icons.person, color: AppColors.primary)
                      : null,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.displayName,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        user.email,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _StatusBadge(
                            label: user.role,
                            icon: user.role == 'admin'
                                ? Icons.shield_outlined
                                : Icons.person_outline,
                            color: roleColor,
                          ),
                          _StatusBadge(
                            label: user.isBanned ? 'Banned' : 'Active',
                            icon: user.isBanned
                                ? Icons.block_outlined
                                : Icons.check_circle_outline,
                            color: statusColor,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: user.isBanned
                            ? const Color(0xFFFEECEC)
                            : AppColors.successSoft,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: user.isBanned
                              ? const Color(0xFFF4C7C3)
                              : AppColors.border,
                        ),
                      ),
                      child: Switch(
                        value: user.isBanned,
                        onChanged: onBanChanged,
                        activeThumbColor: AppColors.error,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      user.isBanned ? 'Unban' : 'Ban',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: AppColors.textSecondary,
                          ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final Color accent;

  const _MetricCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 176,
      padding: const EdgeInsets.all(18),
      decoration: _adminSurfaceDecoration(radius: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: accent),
          ),
          const SizedBox(height: 18),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: AppColors.textPrimary,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
        ],
      ),
    );
  }
}
class _AnalyticsSection extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget child;

  const _AnalyticsSection({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: _adminSurfaceDecoration(radius: 18),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
            const SizedBox(height: 18),
            child,
          ],
        ),
      ),
    );
  }
}

class _DistributionChart extends StatelessWidget {
  final Map<String, int> data;
  final Color color;

  const _DistributionChart({
    required this.data,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return const _EmptyCardBody(
        icon: Icons.bar_chart_outlined,
        title: 'No chart data yet',
        message: 'Once activity comes in, this chart will start to populate.',
      );
    }

    final maxValue = data.values.reduce((a, b) => a > b ? a : b);
    return Column(
      children: data.entries.map((entry) {
        final ratio = maxValue == 0 ? 0.0 : entry.value / maxValue;
        return Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: Row(
            children: [
              SizedBox(
                width: 108,
                child: Text(
                  entry.key,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: ratio,
                    minHeight: 12,
                    color: color,
                    backgroundColor: AppColors.border,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              SizedBox(
                width: 32,
                child: Text(
                  '${entry.value}',
                  textAlign: TextAlign.right,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _MiniStatRow extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _MiniStatRow({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
            ),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;

  const _StatusBadge({
    required this.label,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withOpacity(0.14)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w700,
                ),
          ),
        ],
      ),
    );
  }
}

class _CategoryTag extends StatelessWidget {
  final String label;
  final Color color;

  const _CategoryTag({
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withOpacity(0.14)),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoChip({
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 260),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AppColors.textSecondary),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyCardBody extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;

  const _EmptyCardBody({
    required this.icon,
    required this.title,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: _adminSurfaceDecoration(radius: 18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: AppColors.surfaceMuted,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 14),
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
            ),
            const SizedBox(height: 6),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                    height: 1.45,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

BoxDecoration _adminSurfaceDecoration({
  double radius = 16,
  Color color = AppColors.surface,
}) {
  return BoxDecoration(
    color: color,
    borderRadius: BorderRadius.circular(radius),
    border: Border.all(color: AppColors.border),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.035),
        blurRadius: 12,
        offset: const Offset(0, 4),
      ),
    ],
  );
}

void _openEventDetails(BuildContext context, Event event) {
  Navigator.of(context).push(
    MaterialPageRoute(
      builder: (_) => EventDetailsScreen(eventId: event.id),
    ),
  );
}

Future<void> _showRejectDialog(
  BuildContext context,
  FirestoreService firestoreService,
  Event event,
) async {
  final controller = TextEditingController();

  await showDialog<void>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: const Text('Reject Event'),
      content: TextField(
        controller: controller,
        maxLines: 4,
        decoration: const InputDecoration(
          labelText: 'Rejection reason',
          hintText: 'Explain what should change before this event can go live',
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () async {
            final reason = controller.text.trim();
            if (reason.isEmpty) {
              return;
            }
            await firestoreService.rejectEvent(event.id, reason);
            if (dialogContext.mounted) {
              Navigator.of(dialogContext).pop();
            }
          },
          child: const Text('Save reason'),
        ),
      ],
    ),
  );
}

Widget _buildBody<T>(
  BuildContext context,
  AsyncSnapshot<T> snapshot, {
  String? headerTitle,
  String? headerSubtitle,
  required Widget Function(T data) onData,
  required String emptyTitle,
  required String emptyMessage,
}) {
  if (snapshot.connectionState == ConnectionState.waiting) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (headerTitle != null && headerSubtitle != null)
            _TabSectionHeader(title: headerTitle, subtitle: headerSubtitle),
          const Padding(
            padding: EdgeInsets.only(top: 40),
            child: Center(child: CircularProgressIndicator()),
          ),
        ],
      ),
    );
  }
  if (snapshot.hasError) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (headerTitle != null && headerSubtitle != null)
            _TabSectionHeader(title: headerTitle, subtitle: headerSubtitle),
          const _EmptyCardBody(
            icon: Icons.error_outline,
            title: 'Something went wrong',
            message: 'The dashboard could not load this section right now.',
          ),
        ],
      ),
    );
  }
  if (!snapshot.hasData) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (headerTitle != null && headerSubtitle != null)
            _TabSectionHeader(title: headerTitle, subtitle: headerSubtitle),
          _EmptyCardBody(
            icon: Icons.inbox_outlined,
            title: emptyTitle,
            message: emptyMessage,
          ),
        ],
      ),
    );
  }

  final data = snapshot.data;
  if (data is List && data.isEmpty) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (headerTitle != null && headerSubtitle != null)
            _TabSectionHeader(title: headerTitle, subtitle: headerSubtitle),
          _EmptyCardBody(
            icon: Icons.inbox_outlined,
            title: emptyTitle,
            message: emptyMessage,
          ),
        ],
      ),
    );
  }

  return onData(data as T);
}

