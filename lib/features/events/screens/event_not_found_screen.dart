import 'package:flutter/material.dart';

class EventNotFoundScreen extends StatelessWidget {
  final bool isArchived;

  const EventNotFoundScreen({
    super.key,
    this.isArchived = false,
  });

  @override
  Widget build(BuildContext context) {
    final title = isArchived ? 'Event archived' : 'Event not found';
    final body = isArchived
        ? 'This Shramdaan is no longer active, so it cannot be opened right now.'
        : 'This event may have been deleted or is no longer available.';

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE9EEF9),
                    borderRadius: BorderRadius.circular(32),
                  ),
                  child: Icon(
                    isArchived
                        ? Icons.inventory_2_outlined
                        : Icons.event_busy_outlined,
                    size: 46,
                    color: const Color(0xFF1F2940),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  title,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF172033),
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  body,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: const Color(0xFF667085),
                        height: 1.5,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: () => Navigator.of(context).maybePop(),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF1F2940),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 14,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  icon: const Icon(Icons.arrow_back_rounded),
                  label: const Text('Go back'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
