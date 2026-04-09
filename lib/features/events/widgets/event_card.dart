import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

import '../../../shared/models/event_model.dart';
import '../../../shared/theme/app_theme.dart';
import '../../../shared/utils/location_utils.dart';
import '../../../shared/widgets/shramdaan_network_image.dart';
import '../screens/event_details_screen.dart';

class EventCard extends StatelessWidget {
  final Event event;
  final String? distanceLabel;

  const EventCard({
    super.key,
    required this.event,
    this.distanceLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => EventDetailsScreen(eventId: event.id),
            ),
          ),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Stack(
                    children: [
                      ShramdaanNetworkImage(
                        imageUrl: event.imageUrl,
                        height: 200,
                        width: double.infinity,
                      ),
                      Positioned(
                        top: 12,
                        left: 12,
                        child: _TopBadge(
                          icon: Icons.category_outlined,
                          label: event.category,
                          backgroundColor: AppColors.infoSoft,
                          textColor: AppColors.primary,
                        ),
                      ),
                      if (event.isCompleted)
                        const Positioned(
                          top: 12,
                          right: 12,
                          child: _TopBadge(
                            icon: Icons.check_circle_outline,
                            label: 'Completed',
                            backgroundColor: AppColors.secondary,
                            textColor: Colors.white,
                          ),
                        )
                      else if (distanceLabel != null)
                        Positioned(
                          top: 12,
                          right: 12,
                          child: _TopBadge(
                            icon: Icons.near_me_outlined,
                            label: distanceLabel!,
                            backgroundColor: AppColors.primary,
                            textColor: Colors.white,
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  event.title,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  event.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                        height: 1.45,
                      ),
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    _InfoPill(
                      icon: Icons.calendar_today_outlined,
                      label: DateFormat.yMMMd().add_jm().format(event.eventDate),
                    ),
                    _InfoPill(
                      icon: Icons.location_on_outlined,
                      label: LocationUtils.compactAddressLabel(event.formattedAddress),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: _OrganizerPreview(
                        organizerId: event.organizerId,
                        fallbackName: event.organizerDisplayName,
                      ),
                    ),
                    const SizedBox(width: 12),
                    FilledButton(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => EventDetailsScreen(eventId: event.id),
                        ),
                      ),
                      child: const Text('View'),
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

class _OrganizerPreview extends StatelessWidget {
  final String organizerId;
  final String fallbackName;

  const _OrganizerPreview({
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
        final userData = snapshot.data?.data();
        final displayName = (userData?['displayName'] as String?)?.trim();
        final photoUrl = (userData?['photoUrl'] as String?)?.trim() ?? '';
        final organizerName = (displayName != null && displayName.isNotEmpty)
            ? displayName
            : fallbackName;

        return Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: const BoxDecoration(
                color: AppColors.infoSoft,
                shape: BoxShape.circle,
              ),
              clipBehavior: Clip.antiAlias,
              child: photoUrl.isNotEmpty
                  ? ShramdaanNetworkImage(
                      imageUrl: photoUrl,
                      width: 32,
                      height: 32,
                    )
                  : const Icon(
                      Icons.person_outline,
                      size: 16,
                      color: AppColors.primary,
                    ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                organizerName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _TopBadge extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color backgroundColor;
  final Color textColor;

  const _TopBadge({
    required this.icon,
    required this.label,
    required this.backgroundColor,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: textColor),
          const SizedBox(width: 6),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: textColor,
                  fontWeight: FontWeight.w700,
                ),
          ),
        ],
      ),
    );
  }
}

class _InfoPill extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoPill({
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 280),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(10),
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

