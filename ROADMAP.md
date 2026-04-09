# Shram Daan v2 - Future Roadmap & Implementation Plan

This document outlines the planned features and technical implementation details for the next major version of the Shram Daan application.

## 1. Location & Map Features
**Goal:** Enable location-based event discovery and creation.

### Technical Implementation
*   **Dependencies:** `flutter_map` (OpenStreetMap), `latlong2`, `geolocator`.
*   **Create Event:** Add interactive map picker to select event coordinates.
*   **Home Feed:** 
    *   Request user location permission.
    *   Calculate distance to each event.
    *   Sort feed by "Nearest First".
*   **Event Details:** Display a static map preview of the event location.

## 2. Admin Dashboard 2.0
**Goal:** Advanced control and insights for administrators.

### Features
*   **Analytics:** Visual charts for Event Categories, User Growth, and Completion Rates.
*   **User Management:** Ability to Ban/Unban users who violate guidelines.
*   **Broadcast:** Send system-wide notifications to all users.
*   **Rejection Workflow:** 
    *   Admin can reject events with a specific "Reason".
    *   Oraganizer sees the reason and can edit/resubmit the event.

## 3. User Features Enhancements
**Goal:** Better profile management and event tracking.

### Features
*   **My Events:** Dedicated section in Profile to view all posted events (Pending, Approved, Rejected).
*   **Public Profile:** View other users' approved event history.
*   **Resubmission:** Simple flow to fix rejected events.
*   **Calendar Integration:** Option to add joined events to the device's calendar app (e.g., Google Calendar).

## 4. Push Notifications
**Goal:** Real-time engagement.

### Features
*   **Infrastructure:** Firebase Cloud Messaging (FCM) + Local Notifications.
*   **New Message:** Notify participants when a message is sent in an event chat.
*   **New Event:** Notify users when a new event is approved (can be geo-fenced in future).
*   **Settings:** User toggle for specific notification types.

## 5. Event Lifecycle & Archiving
**Goal:** Keep the feed fresh and relevant.

### Logic
*   **Upcoming:** Event Date is in the future.
*   **Ended:** Event Date is past, but less than 24 hours ago. (Label: "Ended").
*   **Archived:** Event Date is more than 24 hours ago. Hidden from main feed, viewable in History.

## 6. Points System & Leaderboard
**Goal:** Reward actual contribution and duration of service.

### Logic
*   **Verification:** Organizers must manually "Verify" attendees after the event.
*   **Formula:** `Points = Event Duration (Hours) * 10`.
*   **Leaderboard:** Ranks users by Total Points (descending) instead of just event count.

## 7. Badge System
**Goal:** Gamification and recognition of specific skills.

### Badge Types
1.  **First Aid Hero** 🚑: Handled medical/safety emergencies.
2.  **DIY Hacker** 🛠️: Creatively solved problems with limited resources.
3.  **Communicator** 📣: Guided volunteers clearly and kept alignment.
4.  **Relentless Ninja** 🔥: Worked tirelessly on demanding tasks.
5.  **All-Rounder** 🔄: Adapted to multiple roles as needed.
6.  **Logistics Ninja** 📦: Manage tools and supplies efficiently.

### Implementation
*   **Awarding:** Organizers verify attendance -> Select Badge to award.
*   **Display:** Badges appear on User Profile with event context.

## 8. UI/UX Overhaul
**Goal:** Premium, modern, and dynamic feel.

### Changes
*   **Theme:** Custom ColorScheme (e.g., Emerald/Slate), Modern Typography (Google Fonts).
*   **Components:** Soft shadows, rounded corners, "Shimmer" loading states.
*   **Animations:** Hero transitions for images, smooth page routing.
