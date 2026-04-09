import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../shared/models/event_model.dart';
import '../../../shared/services/firestore_service.dart';
import '../../../shared/utils/location_utils.dart';
import '../../attendance/screens/event_attendance_screen.dart';
import 'edit_event_screen.dart';
import 'event_details_screen.dart';

class MyEventsScreen extends StatefulWidget {
  const MyEventsScreen({super.key});

  @override
  State<MyEventsScreen> createState() => _MyEventsScreenState();
}

class _MyEventsScreenState extends State<MyEventsScreen> {
  String _selectedFilter = 'all';
  final FirestoreService _firestoreService = FirestoreService();

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('My Events')),
        body: const Center(child: Text('No user is logged in.')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Events'),
      ),
      body: StreamBuilder<List<Event>>(
        stream: _firestoreService.getCreatedEventsStream(currentUser.uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Text('You have not posted any events yet.'),
            );
          }

          final allEvents = snapshot.data!;
          final visibleEvents = _selectedFilter == 'all'
              ? allEvents
              : allEvents.where((event) => event.status == _selectedFilter).toList();

          final pendingCount =
              allEvents.where((event) => event.status == 'pending').length;
          final approvedCount =
              allEvents.where((event) => event.status == 'approved').length;
          final rejectedCount =
              allEvents.where((event) => event.status == 'rejected').length;

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _FilterChip(
                          label: 'All (${allEvents.length})',
                          isSelected: _selectedFilter == 'all',
                          onTap: () => setState(() => _selectedFilter = 'all'),
                        ),
                        _FilterChip(
                          label: 'Pending ($pendingCount)',
                          isSelected: _selectedFilter == 'pending',
                          onTap: () => setState(() => _selectedFilter = 'pending'),
                        ),
                        _FilterChip(
                          label: 'Approved ($approvedCount)',
                          isSelected: _selectedFilter == 'approved',
                          onTap: () => setState(() => _selectedFilter = 'approved'),
                        ),
                        _FilterChip(
                          label: 'Rejected ($rejectedCount)',
                          isSelected: _selectedFilter == 'rejected',
                          onTap: () => setState(() => _selectedFilter = 'rejected'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Track posted events, review feedback, and resubmit rejected ones.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.grey.shade700,
                          ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: visibleEvents.isEmpty
                    ? Center(
                        child: Text(
                          'No ${_selectedFilter == 'all' ? '' : _selectedFilter} events found.',
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                        itemCount: visibleEvents.length,
                        itemBuilder: (context, index) {
                          final event = visibleEvents[index];
                          return _MyEventCard(event: event);
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _MyEventCard extends StatelessWidget {
  final Event event;

  const _MyEventCard({required this.event});

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
                _StatusChip(status: event.status),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _MetaChip(
                  icon: Icons.calendar_today_outlined,
                  label: DateFormat.yMMMd().add_jm().format(event.eventDate),
                ),
                _MetaChip(
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
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                FilledButton.tonalIcon(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => EventDetailsScreen(eventId: event.id),
                    ),
                  ),
                  icon: const Icon(Icons.visibility_outlined),
                  label: const Text('View'),
                ),
                if (event.status == 'rejected')
                  FilledButton.icon(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => EditEventScreen(event: event),
                      ),
                    ),
                    icon: const Icon(Icons.edit_outlined),
                    label: const Text('Edit & Resubmit'),
                  ),
                if (event.status == 'approved')
                  FilledButton.tonalIcon(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => EventAttendanceScreen(event: event),
                      ),
                    ),
                    icon: const Icon(Icons.fact_check_outlined),
                    label: const Text('Attendance'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String status;

  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    final Color color;
    final String label;

    switch (status) {
      case 'approved':
        color = Colors.green;
        label = 'Approved';
        break;
      case 'rejected':
        color = Colors.red;
        label = 'Rejected';
        break;
      default:
        color = Colors.orange;
        label = 'Pending';
    }

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
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _MetaChip({
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

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => onTap(),
    );
  }
}

