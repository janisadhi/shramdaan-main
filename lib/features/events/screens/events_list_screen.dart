import 'package:flutter/material.dart';

import '../../../shared/models/event_model.dart';
import '../../../shared/services/firestore_service.dart';
import '../../../shared/theme/app_theme.dart';
import '../../../shared/utils/location_utils.dart';
import '../widgets/event_card.dart';

enum EventTimeFilter {
  any,
  today,
  thisWeek,
  thisMonth,
}

class EventsListScreen extends StatefulWidget {
  final bool isEmbedded;
  final Widget? headerPrefix;
  final bool showSearchBar;
  final String searchQuery;
  final EventTimeFilter timeFilter;
  final double? maxDistanceKm;

  const EventsListScreen({
    super.key,
    this.isEmbedded = false,
    this.headerPrefix,
    this.showSearchBar = false,
    this.searchQuery = '',
    this.timeFilter = EventTimeFilter.any,
    this.maxDistanceKm,
  });

  @override
  State<EventsListScreen> createState() => _EventsListScreenState();
}

class _EventsListScreenState extends State<EventsListScreen> {
  final FirestoreService _firestoreService = FirestoreService();

  String _selectedCategory = 'All';
  double? _userLatitude;
  double? _userLongitude;

  final Map<String, IconData> _categoryIcons = {
    'All': Icons.apps_outlined,
    'Clean Up': Icons.cleaning_services_outlined,
    'Plantation': Icons.park_outlined,
    'Donation': Icons.volunteer_activism_outlined,
    'Construction': Icons.construction_outlined,
    'General': Icons.public_outlined,
  };

  final List<String> _categories = [
    'All',
    'Clean Up',
    'Plantation',
    'Donation',
    'Construction',
    'General',
  ];

  @override
  void initState() {
    super.initState();
    _loadUserLocation();
  }

  Future<void> _loadUserLocation() async {
    final position = await LocationUtils.getCurrentPosition();
    if (!mounted) {
      return;
    }

    setState(() {
      _userLatitude = position?.latitude;
      _userLongitude = position?.longitude;
    });
  }

  double? _distanceForEvent(Event event) {
    if (_userLatitude == null || _userLongitude == null || !event.hasCoordinates) {
      return null;
    }

    return LocationUtils.haversineDistanceKm(
      startLatitude: _userLatitude!,
      startLongitude: _userLongitude!,
      endLatitude: event.latitude!,
      endLongitude: event.longitude!,
    );
  }

  bool _matchesTimeFilter(Event event) {
    final now = DateTime.now();
    switch (widget.timeFilter) {
      case EventTimeFilter.any:
        return true;
      case EventTimeFilter.today:
        return event.eventDate.year == now.year &&
            event.eventDate.month == now.month &&
            event.eventDate.day == now.day;
      case EventTimeFilter.thisWeek:
        final weekEnd = now.add(const Duration(days: 7));
        return !event.eventDate.isBefore(now) && !event.eventDate.isAfter(weekEnd);
      case EventTimeFilter.thisMonth:
        return event.eventDate.year == now.year &&
            event.eventDate.month == now.month &&
            !event.eventDate.isBefore(now);
    }
  }

  bool _matchesDistanceFilter(Event event) {
    if (widget.maxDistanceKm == null) {
      return true;
    }
    final distance = _distanceForEvent(event);
    if (distance == null) {
      return false;
    }
    return distance <= widget.maxDistanceKm!;
  }

  int _compareEvents(Event a, Event b) {
    if (a.isCompleted != b.isCompleted) {
      return a.isCompleted ? 1 : -1;
    }

    if (_userLatitude != null && _userLongitude != null) {
      final distanceA = _distanceForEvent(a);
      final distanceB = _distanceForEvent(b);
      if (distanceA == null && distanceB == null) {
        return b.eventDate.compareTo(a.eventDate);
      }
      if (distanceA == null) {
        return 1;
      }
      if (distanceB == null) {
        return -1;
      }
      final distanceCompare = distanceA.compareTo(distanceB);
      if (distanceCompare != 0) {
        return distanceCompare;
      }
    }

    return b.eventDate.compareTo(a.eventDate);
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isEmbedded) {
      return CustomScrollView(
        slivers: [
          if (widget.headerPrefix != null)
            SliverToBoxAdapter(child: widget.headerPrefix!),
          SliverPersistentHeader(
            pinned: true,
            delegate: _StickyFiltersDelegate(
              extentValue: widget.showSearchBar ? 132 : 66,
              builder: (context) => Container(
                color: AppColors.neutral,
                padding: const EdgeInsets.fromLTRB(16, 1, 16, 15),
                child: _buildFiltersCard(context),
              ),
            ),
          ),
          StreamBuilder<List<Event>>(
            stream: _firestoreService.getEventsStream(
              category: _selectedCategory,
              searchQuery: widget.searchQuery,
            ),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              if (snapshot.hasError) {
                return SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(child: Text('Error: ${snapshot.error}')),
                );
              }
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 24, 24, 28),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(minHeight: 220),
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.event_busy_outlined,
                              size: 44,
                              color: Colors.grey.shade400,
                            ),
                            const SizedBox(height: 10),
                            Text(
                              'No events found',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Try a different search or explore another category.',
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: Colors.grey.shade700,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }

              final events = List<Event>.from(snapshot.data!);
              events.retainWhere((event) {
                return _matchesTimeFilter(event) && _matchesDistanceFilter(event);
              });
              events.sort(_compareEvents);

              if (events.isEmpty) {
                return SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 24, 24, 28),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(minHeight: 220),
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.event_busy_outlined,
                              size: 44,
                              color: Colors.grey.shade400,
                            ),
                            const SizedBox(height: 10),
                            Text(
                              'No events match these filters',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Try changing the search, time, or distance filters.',
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: Colors.grey.shade700,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }

              return SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 28),
                sliver: SliverList.builder(
                  itemCount: events.length,
                  itemBuilder: (context, index) {
                    final event = events[index];
                    final distance = _distanceForEvent(event);

                    return EventCard(
                      event: event,
                      distanceLabel: distance == null
                          ? null
                          : LocationUtils.formatDistanceKm(distance),
                    );
                  },
                ),
              );
            },
          ),
        ],
      );
    }

    final content = StreamBuilder<List<Event>>(
            stream: _firestoreService.getEventsStream(
              category: _selectedCategory,
              searchQuery: widget.searchQuery,
            ),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return ListView(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 28),
                  children: [
                    ConstrainedBox(
                      constraints: const BoxConstraints(minHeight: 180),
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.event_busy_outlined,
                              size: 44,
                              color: Colors.grey.shade400,
                            ),
                            const SizedBox(height: 10),
                            Text(
                              'No events found',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Try a different search or explore another category.',
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

              final events = List<Event>.from(snapshot.data!);
              events.retainWhere((event) {
                return _matchesTimeFilter(event) && _matchesDistanceFilter(event);
              });
              events.sort(_compareEvents);

              if (events.isEmpty) {
                return ListView(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 28),
                  children: [
                    ConstrainedBox(
                      constraints: const BoxConstraints(minHeight: 180),
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.event_busy_outlined,
                              size: 44,
                              color: Colors.grey.shade400,
                            ),
                            const SizedBox(height: 10),
                            Text(
                              'No events match these filters',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Try changing the search, time, or distance filters.',
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

              return ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 28),
                itemCount: events.length,
                itemBuilder: (context, index) {
                  final event = events[index];
                  final distance = _distanceForEvent(event);

                  return EventCard(
                    event: event,
                    distanceLabel: distance == null
                        ? null
                        : LocationUtils.formatDistanceKm(distance),
                  );
                },
              );
            },
          );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 1, 16, 15),
          child: _buildFiltersCard(context),
        ),
        Expanded(child: content),
      ],
    );
  }

  Widget _buildFiltersCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            // ignore: deprecated_member_use
            color: const Color(0xFF101828).withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          if (widget.showSearchBar) ...[
            TextField(
              decoration: InputDecoration(
                hintText: 'Search by title or discover a nearby cause',
                hintStyle: const TextStyle(color: AppColors.disabled),
                prefixIcon: const Icon(
                  Icons.search_rounded,
                  color: AppColors.textSecondary,
                ),
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
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              onChanged: (_) {},
              enabled: false,
            ),
            const SizedBox(height: 8),
          ],
          SizedBox(
            height: 34,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _categories.length,
              itemBuilder: (context, index) {
                final category = _categories[index];
                final isSelected = _selectedCategory == category;

                return Padding(
                  padding: EdgeInsets.only(
                    right: index == _categories.length - 1 ? 0 : 8,
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        setState(() => _selectedCategory = category);
                      },
                      borderRadius: BorderRadius.circular(999),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 140),
                        curve: Curves.easeOut,
                        height: 34,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 0,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected ? AppColors.primary : AppColors.neutral,
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(
                            color: isSelected ? AppColors.primary : AppColors.border,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Icon(
                              _categoryIcons[category],
                              size: 15,
                              color: isSelected
                                  ? Colors.white
                                  : AppColors.textSecondary,
                            ),
                            const SizedBox(width: 7),
                            Text(
                              category,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                height: 1.0,
                                color: isSelected
                                    ? Colors.white
                                    : AppColors.textPrimary,
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
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

class _StickyFiltersDelegate extends SliverPersistentHeaderDelegate {
  final double extentValue;
  final Widget Function(BuildContext context) builder;

  const _StickyFiltersDelegate({
    required this.extentValue,
    required this.builder,
  });

  @override
  double get minExtent => extentValue;

  @override
  double get maxExtent => extentValue;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return builder(context);
  }

  @override
  bool shouldRebuild(covariant _StickyFiltersDelegate oldDelegate) {
    return extentValue != oldDelegate.extentValue || builder != oldDelegate.builder;
  }
}
