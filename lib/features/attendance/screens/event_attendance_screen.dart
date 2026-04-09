import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../shared/models/event_model.dart';
import '../../../shared/services/firestore_service.dart';
import '../models/attendance_summary_entry_model.dart';
import '../models/event_participant_entry_model.dart';

class EventAttendanceScreen extends StatelessWidget {
  final Event event;

  const EventAttendanceScreen({
    super.key,
    required this.event,
  });

  @override
  Widget build(BuildContext context) {
    final firestoreService = FirestoreService();

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F7FB),
        appBar: AppBar(
          backgroundColor: const Color(0xFFF5F7FB),
          surfaceTintColor: Colors.transparent,
          title: const Text('Attendance'),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(62),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const TabBar(
                  tabs: [
                    Tab(text: 'Checked In'),
                    Tab(text: 'RSVP'),
                  ],
                ),
              ),
            ),
          ),
        ),
        body: TabBarView(
          children: [
            _AttendanceTab(
              event: event,
              stream: firestoreService.getEventAttendanceStream(event.id),
            ),
            _RsvpTab(
              event: event,
              stream: firestoreService.getEventParticipantsStream(event.id),
            ),
          ],
        ),
      ),
    );
  }
}

class _AttendanceTab extends StatelessWidget {
  final Event event;
  final Stream<List<AttendanceSummaryEntry>> stream;

  const _AttendanceTab({
    required this.event,
    required this.stream,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<AttendanceSummaryEntry>>(
      stream: stream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final entries = snapshot.data ?? const <AttendanceSummaryEntry>[];
        if (entries.isEmpty) {
          return const _EmptyOrganizerState(
            icon: Icons.qr_code_scanner_rounded,
            title: 'No attendance yet',
            message:
                'Once volunteers scan the event QR, their check-in and check-out times will appear here.',
          );
        }

        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          children: [
            _OverviewCard(
              title: event.title,
              subtitle:
                  '${entries.length} attendance record${entries.length == 1 ? '' : 's'} captured',
            ),
            const SizedBox(height: 16),
            ...entries.map(_AttendanceCard.new),
          ],
        );
      },
    );
  }
}

class _RsvpTab extends StatelessWidget {
  final Event event;
  final Stream<List<EventParticipantEntry>> stream;

  const _RsvpTab({
    required this.event,
    required this.stream,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<EventParticipantEntry>>(
      stream: stream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final entries = snapshot.data ?? const <EventParticipantEntry>[];
        if (entries.isEmpty) {
          return const _EmptyOrganizerState(
            icon: Icons.groups_outlined,
            title: 'No RSVPs yet',
            message:
                'Volunteers who join this event will appear here before they scan attendance.',
          );
        }

        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          children: [
            _OverviewCard(
              title: event.title,
              subtitle:
                  '${entries.length} volunteer${entries.length == 1 ? '' : 's'} RSVP’d for this event',
            ),
            const SizedBox(height: 16),
            ...entries.map(_RsvpCard.new),
          ],
        );
      },
    );
  }
}

class _OverviewCard extends StatelessWidget {
  final String title;
  final String subtitle;

  const _OverviewCard({
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF172033),
                ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: const Color(0xFF667085),
                ),
          ),
        ],
      ),
    );
  }
}

class _AttendanceCard extends StatelessWidget {
  final AttendanceSummaryEntry entry;

  const _AttendanceCard(this.entry);

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    if (hours == 0) {
      return '$minutes min';
    }
    if (minutes == 0) {
      return '$hours hr';
    }
    return '$hours hr $minutes min';
  }

  @override
  Widget build(BuildContext context) {
    final checkIn = entry.record.checkInTime;
    final checkOut = entry.record.checkOutTime;
    final duration = entry.record.totalDuration;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF101828).withOpacity(0.04),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: Colors.grey.shade100,
                backgroundImage: entry.volunteerPhotoUrl.isNotEmpty
                    ? NetworkImage(entry.volunteerPhotoUrl)
                    : null,
                child: entry.volunteerPhotoUrl.isEmpty
                    ? const Icon(Icons.person_outline)
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.volunteerName,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF172033),
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      DateFormat('MMM d, y').format(entry.record.attendanceDate),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: const Color(0xFF667085),
                          ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: duration == null
                      ? const Color(0xFFFFF4E5)
                      : const Color(0xFFECFDF3),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  duration == null ? 'Checked in' : _formatDuration(duration),
                  style: TextStyle(
                    color: duration == null
                        ? const Color(0xFFB54708)
                        : const Color(0xFF027A48),
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _TimeTile(
                  icon: Icons.login_rounded,
                  label: 'Check-in',
                  value: DateFormat.jm().format(checkIn),
                  accent: const Color(0xFF2563EB),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _TimeTile(
                  icon: Icons.logout_rounded,
                  label: 'Check-out',
                  value: checkOut == null ? 'Pending' : DateFormat.jm().format(checkOut),
                  accent: checkOut == null
                      ? const Color(0xFFB54708)
                      : const Color(0xFF16A34A),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RsvpCard extends StatelessWidget {
  final EventParticipantEntry entry;

  const _RsvpCard(this.entry);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF101828).withOpacity(0.04),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: Colors.grey.shade100,
            backgroundImage:
                entry.photoUrl.isNotEmpty ? NetworkImage(entry.photoUrl) : null,
            child: entry.photoUrl.isEmpty ? const Icon(Icons.person_outline) : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              entry.userName,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF172033),
                  ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFE7F0FF),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              'RSVP',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: const Color(0xFF2563EB),
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TimeTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color accent;

  const _TimeTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: accent),
              const SizedBox(width: 8),
              Text(
                label,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: const Color(0xFF667085),
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: const Color(0xFF172033),
                  fontWeight: FontWeight.w800,
                ),
          ),
        ],
      ),
    );
  }
}

class _EmptyOrganizerState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;

  const _EmptyOrganizerState({
    required this.icon,
    required this.title,
    required this.message,
  });

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
                color: const Color(0xFFEAF4FF),
                borderRadius: BorderRadius.circular(22),
              ),
              child: Icon(
                icon,
                size: 34,
                color: const Color(0xFF2563EB),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF172033),
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: const Color(0xFF667085),
                    height: 1.5,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

