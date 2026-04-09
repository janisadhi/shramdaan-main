# Daily Documentation

Date: 2026-03-14

## Summary

Today we focused on roadmap milestone work for location support, Admin Dashboard 2.0, and the start of the organizer-facing event management flow.

## Work Completed

### 1. Location milestone refinements

- Implemented location-based event support with coordinates and formatted addresses.
- Added map-based location picking for create/edit event flows.
- Added event detail mini-map and directions support.
- Added nearest-first event sorting using device location with fallback behavior.
- Improved web/browser location handling and location prewarming.
- Reworked location search into autocomplete/type-ahead suggestions with manual result selection.

### 2. Admin Dashboard 2.0

- Added event rejection workflow with rejection reasons.
- Added rejected events tab and re-approval flow.
- Added user management with ban/unban support.
- Added analytics models and dashboard sections.
- Added broadcast composer/history backed by Firestore.
- Made review, approved, rejected, and user rows clickable.
- Added approved-to-rejected transition with required reason.
- Redesigned the admin dashboard UI.
- Removed the command center/KPI strip after deciding it was not useful.
- Updated rejected event cards to visually match approved event cards more closely.

### 3. Organizer / My Events phase started

- Added a Firestore stream for events created by the current user.
- Added a `My Events` section in the profile screen.
- Displayed created event status: pending, approved, rejected.
- Displayed rejection reason for rejected events.
- Added quick edit action for rejected events.
- Updated edit flow so rejected events are automatically resubmitted as pending after edits.

## Files Updated

- `lib/shared/services/firestore_service.dart`
- `lib/shared/models/event_model.dart`
- `lib/shared/utils/location_utils.dart`
- `lib/features/events/widgets/event_location_picker.dart`
- `lib/features/events/screens/create_event_screen.dart`
- `lib/features/events/screens/edit_event_screen.dart`
- `lib/features/events/screens/event_details_screen.dart`
- `lib/features/events/screens/events_list_screen.dart`
- `lib/features/events/widgets/event_card.dart`
- `lib/features/home/screens/home_screen.dart`
- `lib/features/admin/screens/admin_dashboard_screen.dart`
- `lib/features/admin/models/admin_analytics_model.dart`
- `lib/features/admin/models/admin_broadcast_model.dart`
- `lib/features/admin/models/admin_user_model.dart`
- `lib/features/auth/services/auth_service.dart`
- `lib/features/profile/screens/profile_screen.dart`
- `pubspec.yaml`
- `android/app/src/main/AndroidManifest.xml`

## Notes

- Flutter was not available in this environment, so changes were made as source-level updates without local runtime verification.
- This file is temporary and meant as a simple daily handoff record.

## Suggested Next Step

- Continue the organizer-facing phase by deciding whether `My Events` should remain inside the profile screen or move to its own dedicated screen with richer filtering and management actions.
