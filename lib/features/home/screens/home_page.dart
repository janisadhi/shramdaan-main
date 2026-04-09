import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../shared/models/event_model.dart';
import '../../../shared/services/firestore_service.dart';
import '../../../shared/theme/app_theme.dart';
import '../../../shared/utils/location_utils.dart';
import '../../../shared/widgets/count_badge.dart';
import '../../attendance/screens/attendance_scanner_screen.dart';
import '../../events/screens/events_list_screen.dart';
import '../../events/widgets/small_featured_card.dart';
import '../../notifications/screens/notifications_screen.dart';
import '../../notifications/services/notification_service.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;
  String _searchQuery = '';
  EventTimeFilter _timeFilter = EventTimeFilter.any;
  double? _distanceRangeKm;
  String _locationLabel = 'Locating you...';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    _loadLocationLabel();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      if (!mounted) return;
      setState(() {
        _searchQuery = _searchController.text.trim();
      });
    });
  }

  Future<void> _loadLocationLabel() async {
    final position = await LocationUtils.getCurrentPosition();
    if (!mounted) return;
    if (position == null) {
      setState(() {
        _locationLabel = 'Location unavailable';
      });
      return;
    }

    final resolvedLabel = await LocationUtils.reverseGeocode(
      latitude: position.latitude,
      longitude: position.longitude,
    );
    if (!mounted) return;
    setState(() {
      _locationLabel = _compactLocationLabel(resolvedLabel);
    });
  }

  String _compactLocationLabel(String? rawLabel) {
    final compact = LocationUtils.compactAddressLabel(rawLabel);
    return compact == 'Location unavailable' ? 'Around your location' : compact;
  }

  Future<void> _openFilterSheet() async {
    var tempTimeFilter = _timeFilter;
    var tempDistance = _distanceRangeKm ?? 25.0;
    var distanceEnabled = _distanceRangeKm != null;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 42,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.border,
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    'Filter events',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Narrow discovery by time and distance.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                  ),
                  const SizedBox(height: 18),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.neutral,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Time',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: EventTimeFilter.values.map((filter) {
                            final selected = tempTimeFilter == filter;
                            return Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: () {
                                  setModalState(() {
                                    tempTimeFilter = filter;
                                  });
                                },
                                borderRadius: BorderRadius.circular(999),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 140),
                                  curve: Curves.easeOut,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: selected
                                        ? AppColors.primary
                                        : AppColors.surface,
                                    borderRadius: BorderRadius.circular(999),
                                    border: Border.all(
                                      color: selected
                                          ? AppColors.primary
                                          : AppColors.border,
                                    ),
                                  ),
                                  child: Text(
                                    _timeFilterLabel(filter),
                                    style: Theme.of(context)
                                        .textTheme
                                        .labelLarge
                                        ?.copyWith(
                                          color: selected
                                              ? Colors.white
                                              : AppColors.textSecondary,
                                          fontWeight: FontWeight.w700,
                                        ),
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
                    decoration: BoxDecoration(
                      color: AppColors.neutral,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Distance range',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.textPrimary,
                                        ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    distanceEnabled
                                        ? 'Show events within ${tempDistance.round()} km'
                                        : 'Any distance',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(
                                          color: AppColors.textSecondary,
                                        ),
                                  ),
                                ],
                              ),
                            ),
                            Switch.adaptive(
                              value: distanceEnabled,
                              onChanged: (value) {
                                setModalState(() {
                                  distanceEnabled = value;
                                });
                              },
                            ),
                          ],
                        ),
                        if (distanceEnabled) ...[
                          const SizedBox(height: 2),
                          Slider(
                            value: tempDistance,
                            min: 5,
                            max: 100,
                            divisions: 19,
                            label: '${tempDistance.round()} km',
                            onChanged: (value) {
                              setModalState(() {
                                tempDistance = value;
                              });
                            },
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (distanceEnabled) ...[
                    const SizedBox(height: 4),
                  ],
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            setState(() {
                              _timeFilter = EventTimeFilter.any;
                              _distanceRangeKm = null;
                            });
                            Navigator.pop(context);
                          },
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: const Text('Reset'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton(
                          onPressed: () {
                            setState(() {
                              _timeFilter = tempTimeFilter;
                              _distanceRangeKm =
                                  distanceEnabled ? tempDistance : null;
                            });
                            Navigator.pop(context);
                          },
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: const Text('Apply'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _refreshHome() async {
    await _loadLocationLabel();
    if (!mounted) {
      return;
    }
    setState(() {});
    await Future<void>.delayed(const Duration(milliseconds: 500));
  }

  void _openNotifications() {
    NotificationService.instance.clearDisplayedNotifications();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const NotificationsScreen(),
      ),
    );
  }

  String _timeFilterLabel(EventTimeFilter filter) {
    switch (filter) {
      case EventTimeFilter.today:
        return 'Today';
      case EventTimeFilter.thisWeek:
        return 'This Week';
      case EventTimeFilter.thisMonth:
        return 'This Month';
      case EventTimeFilter.any:
        return 'Any Time';
    }
  }

  @override
  Widget build(BuildContext context) {
    final firestoreService = FirestoreService();

    return Scaffold(
      backgroundColor: AppColors.neutral,
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: _refreshHome,
          child: EventsListScreen(
            isEmbedded: true,
            showSearchBar: false,
            searchQuery: _searchQuery,
            timeFilter: _timeFilter,
            maxDistanceKm: _distanceRangeKm,
            headerPrefix: Padding(
              padding: EdgeInsets.zero,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _HomeHero(
                    searchController: _searchController,
                    locationLabel: _locationLabel,
                    hasActiveFilter:
                        _timeFilter != EventTimeFilter.any || _distanceRangeKm != null,
                    onTapFilter: _openFilterSheet,
                    onTapNotifications: _openNotifications,
                    onTapScan: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const AttendanceScannerScreen(),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 20),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: _SectionHeader(
                      title: 'Featured Events',
                      subtitle: '',
                      actionLabel: 'View All',
                      onTapAction: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => _AllEventsScreen(
                              searchQuery: _searchQuery,
                              timeFilter: _timeFilter,
                              maxDistanceKm: _distanceRangeKm,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: _FeaturedEventsList(service: firestoreService),
                  ),
                  const SizedBox(height: 20),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: _SectionHeader(
                      title: 'Discover Events',
                      subtitle: '',
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _HomeHero extends StatelessWidget {
  final TextEditingController searchController;
  final String locationLabel;
  final bool hasActiveFilter;
  final VoidCallback onTapFilter;
  final VoidCallback onTapNotifications;
  final VoidCallback onTapScan;

  const _HomeHero({
    required this.searchController,
    required this.locationLabel,
    required this.hasActiveFilter,
    required this.onTapFilter,
    required this.onTapNotifications,
    required this.onTapScan,
  });

  @override
  Widget build(BuildContext context) {
    final firestoreService = FirestoreService();
    final currentUser = FirebaseAuth.instance.currentUser;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      color: AppColors.neutral,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 52,
                height: 52,
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.asset(
                    'assets/icon.png',
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Shramdaan',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                          ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Current location',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: AppColors.textSecondary,
                            letterSpacing: 0.2,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on_outlined,
                          color: AppColors.primary,
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            locationLabel,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: AppColors.textPrimary,
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              if (currentUser != null)
                StreamBuilder<int>(
                  stream: firestoreService.getUnreadNotificationCountExcludingTypes(
                    currentUser.uid,
                    const ['chat_message'],
                  ),
                  builder: (context, snapshot) {
                    return _HeroIconButton(
                      icon: Icons.notifications_none_rounded,
                      onTap: onTapNotifications,
                      badgeCount: snapshot.data ?? 0,
                    );
                  },
                )
              else
                _HeroIconButton(
                  icon: Icons.notifications_none_rounded,
                  onTap: onTapNotifications,
                ),
              const SizedBox(width: 8),
              _HeroIconButton(
                icon: Icons.qr_code_scanner_rounded,
                onTap: onTapScan,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: TextField(
                    controller: searchController,
                    style: const TextStyle(color: AppColors.textPrimary),
                    decoration: InputDecoration(
                      hintText: 'Search volunteer opportunities',
                      hintStyle: const TextStyle(color: AppColors.disabled),
                      prefixIcon: const Icon(
                        Icons.search_rounded,
                        color: AppColors.textSecondary,
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 15,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(color: AppColors.border),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(color: AppColors.border),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(
                          color: AppColors.primary,
                          width: 1.3,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Stack(
                clipBehavior: Clip.none,
                children: [
                  SizedBox(
                    width: 50,
                    height: 50,
                    child: FilledButton(
                      onPressed: onTapFilter,
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: EdgeInsets.zero,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 0,
                      ),
                      child: const Icon(
                        Icons.tune_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                  if (hasActiveFilter)
                    const Positioned(
                      top: 7,
                      right: 7,
                      child: _FilterDot(),
                    ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FilterDot extends StatelessWidget {
  const _FilterDot();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(
        color: AppColors.secondary,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
      ),
    );
  }
}

class _HeroIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final int badgeCount;

  const _HeroIconButton({
    required this.icon,
    required this.onTap,
    this.badgeCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.border),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Icon(icon, color: AppColors.primary, size: 20),
          ),
        ),
        if (badgeCount > 0)
          Positioned(
            right: -2,
            top: -2,
            child: CountBadge(count: badgeCount),
          ),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final String? actionLabel;
  final VoidCallback? onTapAction;

  const _SectionHeader({
    required this.title,
    required this.subtitle,
    this.actionLabel,
    this.onTapAction,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
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
              if (subtitle.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                ),
              ],
            ],
          ),
        ),
        if (actionLabel != null && onTapAction != null)
          TextButton(
            onPressed: onTapAction,
            style: TextButton.styleFrom(
              foregroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
              textStyle: Theme.of(context).textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            child: Text(actionLabel!),
          ),
      ],
    );
  }
}

class _FeaturedEventsList extends StatelessWidget {
  final FirestoreService service;

  const _FeaturedEventsList({required this.service});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Event>>(
      stream: service.getFeaturedEventsStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(
            height: 260,
            child: Center(child: CircularProgressIndicator()),
          );
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Container(
            height: 120,
            width: double.infinity,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: const Center(child: Text('No featured events yet.')),
          );
        }

        final featuredEvents = snapshot.data!;
        return SizedBox(
          height: 260,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 2),
            itemCount: featuredEvents.length,
            itemBuilder: (context, index) {
              return SmallFeaturedCard(event: featuredEvents[index]);
            },
          ),
        );
      },
    );
  }
}

class _AllEventsScreen extends StatelessWidget {
  final String searchQuery;
  final EventTimeFilter timeFilter;
  final double? maxDistanceKm;

  const _AllEventsScreen({
    required this.searchQuery,
    required this.timeFilter,
    required this.maxDistanceKm,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.neutral,
      appBar: AppBar(
        title: const Text('All Events'),
      ),
      body: EventsListScreen(
        searchQuery: searchQuery,
        timeFilter: timeFilter,
        maxDistanceKm: maxDistanceKm,
      ),
    );
  }
}

