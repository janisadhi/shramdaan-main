import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../shared/models/event_model.dart';
import '../../../shared/services/firestore_service.dart';
import '../../../shared/theme/app_theme.dart';
import '../../../shared/widgets/shramdaan_network_image.dart';
import '../screens/event_details_screen.dart';

class SmallFeaturedCard extends StatelessWidget {
  final Event event;

  const SmallFeaturedCard({super.key, required this.event});

  @override
  Widget build(BuildContext context) {
    final firestoreService = FirestoreService();

    return Container(
      width: 292,
      margin: const EdgeInsets.only(right: 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.10),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(22),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => EventDetailsScreen(eventId: event.id),
            ),
          ),
          child: Stack(
            children: [
              ShramdaanNetworkImage(
                imageUrl: event.imageUrl,
                height: 236,
                width: double.infinity,
              ),
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withOpacity(0.08),
                        Colors.black.withOpacity(0.18),
                        Colors.black.withOpacity(0.74),
                      ],
                      stops: const [0.0, 0.42, 1.0],
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 14,
                left: 14,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.92),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    event.category.toUpperCase(),
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                        ),
                  ),
                ),
              ),
              Positioned(
                left: 16,
                right: 16,
                bottom: 16,
                child: StreamBuilder<int>(
                  stream: firestoreService.getEventParticipantCountStream(event.id),
                  builder: (context, snapshot) {
                    final joinedCount = snapshot.data ?? 0;

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          event.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                height: 1.1,
                              ),
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 14,
                          runSpacing: 6,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            _FeaturedMetaItem(
                              icon: Icons.calendar_today_outlined,
                              label: DateFormat.MMMd().format(event.eventDate),
                            ),
                            _FeaturedMetaItem(
                              icon: Icons.group_outlined,
                              label: '$joinedCount Joined',
                            ),
                          ],
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FeaturedMetaItem extends StatelessWidget {
  final IconData icon;
  final String label;

  const _FeaturedMetaItem({
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 14,
          color: Colors.white.withOpacity(0.88),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.white.withOpacity(0.88),
                fontWeight: FontWeight.w600,
              ),
        ),
      ],
    );
  }
}
