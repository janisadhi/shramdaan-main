import 'package:add_2_calendar/add_2_calendar.dart' as add2cal;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../shared/models/event_model.dart';
import '../../../shared/services/firestore_service.dart';
import '../../../shared/theme/app_theme.dart';
import '../../../shared/utils/location_utils.dart';
import '../../../shared/widgets/shramdaan_network_image.dart';
import '../../attendance/screens/attendance_qr_screen.dart';
import '../../attendance/screens/event_attendance_screen.dart';
import '../../chat/screens/chat_screen.dart';
import '../../profile/screens/public_profile_screen.dart';
import 'edit_event_screen.dart';
import 'event_not_found_screen.dart';

class EventDetailsScreen extends StatelessWidget {
  final String eventId;

  const EventDetailsScreen({super.key, required this.eventId});

  @override
  Widget build(BuildContext context) {
    final firestoreService = FirestoreService();
    final currentUser = FirebaseAuth.instance.currentUser;

    return StreamBuilder<Event?>(
      stream: firestoreService.getEventStream(eventId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: Color(0xFFF5F7FB),
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasError) {
          return const EventNotFoundScreen();
        }
        if (!snapshot.hasData || snapshot.data == null) {
          return const EventNotFoundScreen();
        }

        final event = snapshot.data!;
        if (event.status == 'archived') {
          return const EventNotFoundScreen(isArchived: true);
        }
        final isOwner = currentUser?.uid == event.organizerId;

        return Scaffold(
          backgroundColor: AppColors.neutral,
          bottomNavigationBar: currentUser == null
              ? null
              : _EventBottomBar(
                  firestoreService: firestoreService,
                  event: event,
                  currentUser: currentUser,
                ),
          body: CustomScrollView(
            slivers: [
              SliverAppBar(
                pinned: true,
                expandedHeight: 336,
                leadingWidth: 68,
                backgroundColor: AppColors.neutral,
                surfaceTintColor: Colors.transparent,
                leading: Padding(
                  padding: const EdgeInsets.only(left: 16, top: 10),
                  child: _HeroActionButton(
                    icon: Icons.arrow_back_rounded,
                    onTap: () => Navigator.pop(context),
                  ),
                ),
                actions: [
                  if (isOwner)
                    Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: _HeroActionButton(
                        icon: Icons.fact_check_outlined,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                EventAttendanceScreen(event: event),
                          ),
                        ),
                      ),
                    ),
                  if (isOwner && event.isAttendanceOpen)
                    Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: _HeroActionButton(
                        icon: Icons.qr_code_2_rounded,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => AttendanceQrScreen(event: event),
                          ),
                        ),
                      ),
                    ),
                  if (isOwner && !event.isCompleted)
                    Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: _HeroActionButton(
                        icon: Icons.edit_outlined,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => EditEventScreen(event: event),
                          ),
                        ),
                      ),
                    ),
                  if (isOwner)
                    Padding(
                      padding: const EdgeInsets.only(top: 10, right: 16),
                      child: _HeroActionButton(
                        icon: Icons.delete_outline,
                        onTap: () =>
                            _showDeleteDialog(context, firestoreService, event),
                      ),
                    ),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      ShramdaanNetworkImage(
                        imageUrl: event.imageUrl,
                        fit: BoxFit.cover,
                        errorWidget: Container(
                          color: Colors.grey.shade200,
                          alignment: Alignment.center,
                          child: Icon(
                            Icons.image_not_supported_outlined,
                            size: 48,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ),
                      const DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Color(0x140F172A),
                              Color(0x000F172A),
                              Color(0xD90F172A),
                            ],
                            stops: [0.0, 0.32, 1.0],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Transform.translate(
                  offset: const Offset(0, -20),
                  child: Container(
                    decoration: const BoxDecoration(
                      color: AppColors.neutral,
                      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 20, 16, 28),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _SurfaceSectionCard(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Wrap(
                                  spacing: 10,
                                  runSpacing: 10,
                                  children: [
                                    _EventTag(
                                      label: event.category,
                                      icon: Icons.category_outlined,
                                      backgroundColor: AppColors.infoSoft,
                                      color: AppColors.primary,
                                    ),
                                    if (event.isFeatured)
                                      const _EventTag(
                                        label: 'Featured',
                                        icon: Icons.auto_awesome,
                                        backgroundColor: Color(0xFFE8F5EC),
                                        color: AppColors.tertiary,
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  event.title,
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineMedium
                                      ?.copyWith(
                                        fontWeight: FontWeight.w800,
                                        color: AppColors.textPrimary,
                                        height: 1.08,
                                      ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Show up, help locally, and make the day count.',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyLarge
                                      ?.copyWith(
                                        color: AppColors.textSecondary,
                                        height: 1.45,
                                      ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          _InfoDetailCard(
                            icon: Icons.calendar_today_outlined,
                            title: DateFormat('EEEE, MMMM d, y')
                                .format(event.eventDate),
                            subtitle: DateFormat.jm().format(event.eventDate),
                            accent: AppColors.primary,
                          ),
                          const SizedBox(height: 12),
                          _InfoDetailCard(
                            icon: Icons.location_on_outlined,
                            title: LocationUtils.compactAddressLabel(
                              event.formattedAddress,
                            ),
                            subtitle: event.hasCoordinates
                                ? 'Tap directions below to open maps'
                                : 'Location shared by the organizer',
                            accent: AppColors.secondary,
                          ),
                          if (event.isRsvpOpen && !event.isCompleted) ...[
                            const SizedBox(height: 12),
                            OutlinedButton.icon(
                              onPressed: () => _addEventToCalendar(context, event),
                              style: OutlinedButton.styleFrom(
                                minimumSize: const Size.fromHeight(48),
                                side: const BorderSide(color: AppColors.primary),
                                foregroundColor: AppColors.primary,
                                backgroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 12,
                                ),
                              ),
                              icon: const Icon(Icons.event_available_rounded),
                              label: const Text('Add to Calendar'),
                            ),
                          ],
                          const SizedBox(height: 16),
                          _SurfaceSectionCard(
                            padding: EdgeInsets.zero,
                            child: _OrganizerRow(
                              organizerId: event.organizerId,
                              fallbackName: event.organizerDisplayName,
                            ),
                          ),
                          const SizedBox(height: 16),
                          _SurfaceSectionCard(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _SectionTitle(
                                  title: 'About this event',
                                  caption:
                                      'A quick overview of what the work looks like.',
                                ),
                                const SizedBox(height: 14),
                                Text(
                                  _formatDescription(event.description),
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyLarge
                                      ?.copyWith(
                                        color: AppColors.textSecondary,
                                        height: 1.75,
                                      ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          _SurfaceSectionCard(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _SectionTitle(
                                  title: 'Location',
                                  caption:
                                      'Know where to meet before you head out.',
                                ),
                                const SizedBox(height: 14),
                                Text(
                                  LocationUtils.compactAddressLabel(
                                    event.formattedAddress,
                                  ),
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium
                                      ?.copyWith(
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.textPrimary,
                                      ),
                                ),
                                if (event.hasCoordinates) ...[
                                  const SizedBox(height: 16),
                                  Container(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(20),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.06),
                                          blurRadius: 20,
                                          offset: const Offset(0, 10),
                                        ),
                                      ],
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(20),
                                      child: SizedBox(
                                        height: 220,
                                        child: FlutterMap(
                                          options: MapOptions(
                                            initialCenter: LatLng(
                                              event.latitude!,
                                              event.longitude!,
                                            ),
                                            initialZoom: 15,
                                            interactionOptions:
                                                InteractionOptions(
                                                  flags: InteractiveFlag.drag |
                                                      InteractiveFlag.pinchZoom,
                                                ),
                                          ),
                                          children: [
                                            TileLayer(
                                              urlTemplate:
                                                  'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                              userAgentPackageName:
                                                  'com.example.myapp',
                                            ),
                                            MarkerLayer(
                                              markers: [
                                                Marker(
                                                  point: LatLng(
                                                    event.latitude!,
                                                    event.longitude!,
                                                  ),
                                                  width: 48,
                                                  height: 48,
                                                  child: const Icon(
                                                    Icons.location_pin,
                                                    size: 48,
                                                    color: Color(0xFFDC2626),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 14),
                                  OutlinedButton.icon(
                                    onPressed: () => _openDirections(
                                      event.latitude!,
                                      event.longitude!,
                                      LocationUtils.compactAddressLabel(
                                        event.formattedAddress,
                                      ),
                                    ),
                                    style: OutlinedButton.styleFrom(
                                      minimumSize: const Size.fromHeight(48),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 18,
                                        vertical: 14,
                                      ),
                                      side: const BorderSide(
                                        color: AppColors.primary,
                                      ),
                                      foregroundColor: AppColors.primary,
                                      backgroundColor: AppColors.infoSoft,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                    ),
                                    icon: const Icon(Icons.directions_outlined),
                                    label: const Text('Get directions'),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          if (event.thingsToCarry.isNotEmpty) ...[
                            const SizedBox(height: 16),
                            _SurfaceSectionCard(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _SectionTitle(
                                    title: 'What to bring',
                                    caption:
                                        'A few useful things to carry with you.',
                                  ),
                                  const SizedBox(height: 14),
                                  _InlineChecklist(
                                    items: event.thingsToCarry,
                                    color: const Color(0xFFEA580C),
                                    icon: Icons.shopping_bag_outlined,
                                  ),
                                ],
                              ),
                            ),
                          ],
                          if (event.thingsProvided.isNotEmpty) ...[
                            const SizedBox(height: 16),
                            _SurfaceSectionCard(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _SectionTitle(
                                    title: 'What we provide',
                                    caption:
                                        'Support already arranged for volunteers.',
                                  ),
                                  const SizedBox(height: 14),
                                  _InlineChecklist(
                                    items: event.thingsProvided,
                                    color: AppColors.secondary,
                                    icon: Icons.check_circle_outline,
                                  ),
                                ],
                              ),
                            ),
                          ],
                          if (isOwner && event.hasStarted && !event.isCompleted) ...[
                            const SizedBox(height: 16),
                            _SurfaceSectionCard(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _SectionTitle(
                                    title: 'Organizer controls',
                                    caption:
                                        'End the event once volunteer work is complete.',
                                  ),
                                  const SizedBox(height: 14),
                                  FilledButton.icon(
                                    onPressed: () => _showEndEventConfirmation(
                                      context,
                                      firestoreService,
                                      event,
                                    ),
                                    style: FilledButton.styleFrom(
                                      backgroundColor: const Color(0xFFB42318),
                                      minimumSize: const Size.fromHeight(50),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 18,
                                        vertical: 14,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                    ),
                                    icon: const Icon(Icons.stop_circle_outlined),
                                    label: const Text('End Event'),
                                  ),
                                ],
                              ),
                            ),
                          ],
                          const SizedBox(height: 96),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _formatDescription(String value) {
    final normalized = value.trim().replaceAll(RegExp(r'\r\n?'), '\n');
    final parts = normalized
        .split(RegExp(r'\n+'))
        .map((part) => part.trim())
        .where((part) => part.isNotEmpty)
        .toList();
    return parts.length > 1 ? parts.join('\n\n') : normalized;
  }

  Future<void> _showEndEventConfirmation(
    BuildContext context,
    FirestoreService firestoreService,
    Event event,
  ) async {
    final firstConfirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('End this event?'),
        content: const Text(
          'This will stop any further attendance check-ins and mark the event as completed.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Continue'),
          ),
        ],
      ),
    );

    if (firstConfirmed != true || !context.mounted) {
      return;
    }

    final secondConfirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Confirm end event'),
        content: const Text(
          'Are you absolutely sure? This action should only be used after the event has finished.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Go back'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFB42318),
            ),
            child: const Text('End Event'),
          ),
        ],
      ),
    );

    if (secondConfirmed != true || !context.mounted) {
      return;
    }

    await firestoreService.endEvent(event.id);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Event marked as completed.')),
      );
    }
  }

  Future<void> _openDirections(
    double latitude,
    double longitude,
    String label,
  ) async {
    final directionsUri = Uri.https(
      'www.google.com',
      '/maps/dir/',
      {
        'api': '1',
        'destination': '$latitude,$longitude',
        'query': label,
      },
    );
    if (!await launchUrl(directionsUri, mode: LaunchMode.externalApplication)) {
      throw Exception('Could not open directions');
    }
  }

  Future<void> _addEventToCalendar(BuildContext context, Event event) async {
    final endTime = event.eventDate.add(const Duration(hours: 2));
    final location = LocationUtils.compactAddressLabel(event.formattedAddress);
    final calendarEvent = add2cal.Event(
      title: event.title,
      description: event.description,
      location: location,
      startDate: event.eventDate,
      endDate: endTime,
    );

    try {
      final opened = await add2cal.Add2Calendar.addEvent2Cal(calendarEvent);
      if (!context.mounted) {
        return;
      }
      if (opened == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Calendar opened with pre-filled event details.')),
        );
      } else {
        final fallbackOpened = await _openCalendarFallback(
          event: event,
          endTime: endTime,
          location: location,
        );
        if (!context.mounted) {
          return;
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              fallbackOpened
                  ? 'Calendar opened with pre-filled event details.'
                  : 'No calendar app responded on this device.',
            ),
          ),
        );
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Unable to open calendar right now.')),
        );
      }
    }
  }

  Future<bool> _openCalendarFallback({
    required Event event,
    required DateTime endTime,
    required String location,
  }) async {
    try {
      final uri = Uri.https(
        'calendar.google.com',
        '/calendar/render',
        <String, String>{
          'action': 'TEMPLATE',
          'text': event.title,
          'details': event.description,
          'location': location,
          'dates':
              '${_formatGoogleCalendarDate(event.eventDate)}/${_formatGoogleCalendarDate(endTime)}',
        },
      );

      return launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      return false;
    }
  }

  String _formatGoogleCalendarDate(DateTime value) {
    return DateFormat("yyyyMMdd'T'HHmmss'Z'").format(value.toUtc());
  }

  Future<void> _showDeleteDialog(
    BuildContext context,
    FirestoreService firestoreService,
    Event event,
  ) async {
    return showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Delete Event'),
        content: const Text('Are you sure you want to delete this event?'),
        actions: [
          TextButton(
            child: const Text('Cancel'),
            onPressed: () => Navigator.of(context).pop(),
          ),
          TextButton(
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
            onPressed: () async {
              await firestoreService.deleteEvent(event.id);
              if (context.mounted) {
                Navigator.of(context).pop();
                Navigator.of(context).pop();
              }
            },
          ),
        ],
      ),
    );
  }
}

class _EventTag extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color backgroundColor;
  final Color color;

  const _EventTag({
    required this.label,
    required this.icon,
    required this.backgroundColor,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(999),
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

class _HeroActionButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _HeroActionButton({
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.92),
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Icon(icon, color: AppColors.textPrimary, size: 22),
        ),
      ),
    );
  }
}

class _SurfaceSectionCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;

  const _SurfaceSectionCard({
    required this.child,
    this.padding = const EdgeInsets.all(18),
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: child,
    );
  }
}

class _InfoDetailCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color accent;
  final double? width;

  const _InfoDetailCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.accent,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: accent.withOpacity(0.12),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: accent, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                        height: 1.4,
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

class _OrganizerRow extends StatelessWidget {
  final String organizerId;
  final String fallbackName;

  const _OrganizerRow({
    required this.organizerId,
    required this.fallbackName,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(organizerId)
          .snapshots(),
      builder: (context, snapshot) {
        final data = snapshot.data?.data();
        final displayName = (data?['displayName'] as String?)?.trim();
        final photoUrl = (data?['photoUrl'] as String?)?.trim() ?? '';
        final organizerName = (displayName != null && displayName.isNotEmpty)
            ? displayName
            : fallbackName;

        return InkWell(
          onTap: organizerId.isEmpty
              ? null
              : () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => PublicProfileScreen(userId: organizerId),
                    ),
                  ),
          borderRadius: BorderRadius.circular(20),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: AppColors.infoSoft,
                  borderRadius: BorderRadius.circular(18),
                ),
                clipBehavior: Clip.antiAlias,
                child: photoUrl.isNotEmpty
                    ? ShramdaanNetworkImage(
                        imageUrl: photoUrl,
                        width: 56,
                        height: 56,
                        fit: BoxFit.cover,
                      )
                    : const Icon(
                        Icons.person_outline,
                        color: AppColors.primary,
                        size: 24,
                      ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      organizerName,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Organizer for this community event',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.textSecondary,
                            height: 1.4,
                          ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.disabled,
                size: 26,
              ),
            ],
          ),
        );
      },
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final String caption;

  const _SectionTitle({
    required this.title,
    required this.caption,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
        ),
        const SizedBox(height: 4),
        Text(
          caption,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
              ),
        ),
      ],
    );
  }
}

class _SectionDivider extends StatelessWidget {
  const _SectionDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 1,
      width: double.infinity,
      color: const Color(0xFFEAECF0),
    );
  }
}

class _InlineChecklist extends StatelessWidget {
  final List<String> items;
  final Color color;
  final IconData icon;

  const _InlineChecklist({
    required this.items,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: items.map((item) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 16, color: color),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(
                    item,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: AppColors.textSecondary,
                          height: 1.55,
                        ),
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

class _EventBottomBar extends StatelessWidget {
  final FirestoreService firestoreService;
  final Event event;
  final User currentUser;

  const _EventBottomBar({
    required this.firestoreService,
    required this.event,
    required this.currentUser,
  });

  @override
  Widget build(BuildContext context) {
    final isOwner = currentUser.uid == event.organizerId;

    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.98),
          border: const Border(top: BorderSide(color: AppColors.border)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 20,
              offset: const Offset(0, -8),
            ),
          ],
        ),
        child: StreamBuilder<bool>(
          stream: firestoreService.hasUserJoined(event.id, currentUser.uid),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const SizedBox(
                height: 54,
                child: Center(child: CircularProgressIndicator()),
              );
            }

            final hasJoined = snapshot.data ?? false;
            final rsvpClosed = !event.isRsvpOpen;
            final isCompleted = event.isCompleted;

            return Row(
              children: [
                if (hasJoined || isOwner)
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ChatScreen(
                            eventId: event.id,
                            eventTitle: event.title,
                          ),
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(48),
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        backgroundColor: Colors.white,
                        foregroundColor: AppColors.primary,
                        side: const BorderSide(color: AppColors.primary),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ),
                      icon: const FaIcon(
                        FontAwesomeIcons.paperPlane,
                        size: 16,
                      ),
                      label: const Text('Chat'),
                    ),
                  ),
                if (hasJoined || isOwner) const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: FilledButton.icon(
                    onPressed: isOwner
                        ? null
                        : isCompleted
                            ? null
                        : hasJoined
                            ? () {
                                firestoreService.leaveEvent(event.id, currentUser.uid);
                              }
                            : rsvpClosed
                                ? null
                                : () {
                                    firestoreService.joinEvent(event.id, currentUser.uid);
                                  },
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(48),
                      backgroundColor: isOwner
                          ? AppColors.disabled
                          : isCompleted
                              ? AppColors.disabled
                          : hasJoined
                          ? const Color(0xFFE02424)
                          : AppColors.primary,
                      foregroundColor: Colors.white,
                      elevation: hasJoined ? 0 : 1,
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                    icon: Icon(
                      isOwner
                          ? Icons.event_available_outlined
                          : hasJoined
                              ? Icons.exit_to_app_rounded
                              : Icons.volunteer_activism_outlined,
                      size: 20,
                    ),
                    label: Text(
                      isOwner
                          ? (event.isCompleted
                              ? 'Event Completed'
                              : event.hasStarted
                                  ? 'Event In Progress'
                                  : 'Organizer View')
                          : isCompleted
                              ? 'Event Completed'
                          : hasJoined
                              ? 'Leave Event'
                              : rsvpClosed
                                  ? 'RSVP Closed'
                                  : 'Join Event',
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
