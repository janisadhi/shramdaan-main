# Shramdaan Comprehensive Project Documentation

## Abstract

Shramdaan is a mobile-first community volunteering platform designed to organize local service activities such as clean-up drives, plantation campaigns, donation efforts, construction support, and general public-interest events. The system connects volunteers, organizers, and administrators inside one workflow that covers authentication, event creation, moderation, discovery, participation, attendance verification, communication, contribution tracking, and notification delivery.

The current implementation is significantly more advanced than the earlier mid-defense stage. The application now includes a unified design system, redesigned authentication screens, a modern home and discovery experience, a feature-rich event detail flow, organizer attendance tools, QR-based check-in and check-out, public and private profile systems, gamified leaderboard ranges, achievement badges, active and archived event chats, in-app and push notifications, scheduled event reminders, admin review alerts, and calendar integration.

The platform is built with Flutter and Dart on the frontend and uses Firebase Authentication, Cloud Firestore, Firebase Storage, Firebase Cloud Messaging, and Cloud Functions for the backend. The application emphasizes trust and accountability by clearly separating RSVP intent from verified attendance. This principle drives its points system, achievement logic, leaderboard ranking, reminder strategy, and overall participation credibility.

## 1. Introduction

### 1.1 Background

Shramdaan traditionally refers to collective labor performed for the public good. In many communities, people are willing to contribute to local causes, but coordination often remains informal, fragmented, and difficult to verify. Events may be shared through chat groups or word of mouth, organizer credibility may be unclear, attendance may be unverified, and volunteers may have no persistent record of their contribution.

Shramdaan digitizes this process while keeping the spirit of local service intact. Rather than focusing on commercial events or generic volunteering directories, the application is tailored to community action and verified participation.

### 1.2 Problem Statement

Before this system, several practical problems affected community volunteering:

- event opportunities were difficult to discover in one trusted place
- anyone could claim to organize an event without moderation
- joining an event and actually attending it were often treated as the same thing
- organizers lacked structured tools for coordination and attendance tracking
- volunteers had no clear public contribution history
- reminder and follow-up systems were weak or missing
- communication around an event was fragmented across external channels

These gaps reduce turnout, weaken trust, and make it harder to scale community service participation.

### 1.3 Aim of the Project

The aim of Shramdaan is to provide a verified, mobile-first volunteer coordination platform that enables communities to create, moderate, discover, join, communicate around, and verify attendance for real-world service events.

### 1.4 Objectives

The current implemented objectives of the project are:

- provide a trusted platform where only approved events become publicly discoverable
- help volunteers find relevant local events quickly through search, filters, and location-aware ordering
- help organizers publish, manage, edit, monitor, and complete events
- enforce clear participation rules such as RSVP windows and attendance windows
- support verified contribution through QR-based check-in and check-out
- surface contribution history using points, verified hours, achievements, and leaderboards
- improve attendance through reminders, chat coordination, and notifications
- give administrators moderation, analytics, broadcast, and user-control tools

### 1.5 Scope

The current application scope includes:

- sign up and sign in using email and password
- user profile creation and editing
- volunteer, organizer, and admin role behavior
- event creation and event moderation
- event discovery through featured and list-based browsing
- search by event title and location text
- category, time, and distance filtering
- RSVP join and leave behavior
- automatic organizer enrollment into approved events
- event-specific group chat
- QR-based attendance verification
- organizer attendance views
- admin review notifications
- user reminders for upcoming events
- profile pages with achievements and history
- daily, monthly, and all-time leaderboard ranking
- help and support guidance for normal users

### 1.6 Target Stakeholders

The main stakeholders of the system are:

- volunteers who want to discover and join meaningful local events
- organizers who want to run verified community initiatives
- administrators who moderate platform quality and user behavior
- local communities that benefit from visible civic participation

## 2. Significance of the Project

The significance of Shramdaan lies in turning community volunteering into a structured and trustworthy digital workflow. Its practical importance includes:

- improving discoverability of service opportunities
- strengthening trust through moderation and verified attendance
- reducing organizer coordination burden through built-in event, RSVP, QR, and chat tools
- rewarding real contribution rather than passive sign-up behavior
- building continuity through profiles, achievements, reminders, and notification history

The platform is especially valuable because it does not only advertise events. It manages the full event lifecycle from proposal to completion.

## 3. System Overview

### 3.1 Core Principle

The application is built around one essential rule:

**RSVP expresses intent, but attendance proves contribution.**

This principle influences:

- points calculation
- verified time calculation
- achievement badge eligibility
- leaderboard ranking
- reminder behavior
- attendance and organizer workflows

### 3.2 User Roles

#### Volunteer

Default users can:

- create an account
- maintain a personal profile
- discover approved events
- search by event title and location
- filter events by category, time, and distance
- RSVP before the closing window
- join event chats after becoming part of an event
- scan attendance QR codes during the allowed window
- receive notifications and reminders
- build a public contribution profile
- appear on the leaderboard based on verified attendance

#### Organizer

Any user who creates an event becomes its organizer. Organizers can:

- create events with cover image, description, date, category, location, and preparation details
- edit pending, rejected, or eligible approved events
- resubmit rejected events for review
- delete their own events
- automatically join their event once it is approved
- access participant and attendance views
- open the event QR screen during the attendance window
- open the event chat directly from organizer-facing screens
- end an event after it has started, using double confirmation

#### Admin

Administrators can:

- review pending and resubmitted events
- approve events
- reject events with a reason
- mark approved events as featured
- move approved items back to rejected when needed
- manage users through ban and unban controls
- review analytics about events, users, completion, and growth
- compose broadcasts
- receive admin review notifications whenever a new moderation item requires action

### 3.3 Overall User Journey

At a high level, the system works as follows:

1. A user signs up and a Firestore user document is created.
2. The user browses or searches verified events from the Home screen.
3. An organizer submits a new event, which enters the moderation pipeline.
4. Admins review the event and either approve or reject it.
5. Once approved, the event becomes discoverable to volunteers.
6. Volunteers RSVP while the event is still at least one hour away.
7. Joined users gain chat access and later receive reminder notifications.
8. During the event window, volunteers scan the QR code to check in and later check out.
9. Attendance records generate verified minutes and points.
10. Achievements, profile statistics, and leaderboard positions update from verified participation.
11. When the event ends, organizer controls close, completed badges appear, and chats move to Archived.

## 4. Design System and UI Direction

The current application follows a unified modern visual system that was applied across the major screens.

### 4.1 Global Color System

The application theme uses these core colors:

- Primary: `#005EB8`
- Secondary: `#00875A`
- Tertiary: `#2E7D32`
- Neutral background: `#F8F9FA`

Supporting semantic colors include:

- text primary: `#172033`
- text secondary: `#667085`
- border: `#DCE3EE`
- muted surface: `#F2F4F7`
- info soft: `#EAF3FB`
- success soft: `#E7F6EF`
- error: `#D92D20`
- disabled: `#98A2B3`
- inverted dark action: `#1F2937`

### 4.2 Typography

The theme defines a consistent hierarchy:

- headline large: 32 px, bold
- headline medium: 28 px, bold
- headline small: 24 px, bold
- title large: 20 px, bold
- title medium: 18 px, semi-bold
- title small: 16 px, semi-bold
- body large: 16 px
- body medium: 14 px
- body small: 12 px
- label sizes: 11 px to 14 px

The leaderboard explicitly uses Manrope for headings and Inter-style body treatment, while the rest of the app relies on the shared Flutter text theme.

### 4.3 Component Styling

Shared component rules include:

- light neutral backgrounds
- flat or soft-elevation surfaces
- border-based separation instead of heavy gradients
- consistent 12 px to 16 px radii for most controls
- primary filled buttons for main actions
- outlined buttons for secondary actions
- clear active states for tabs and navigation

### 4.4 Navigation Design

The bottom navigation contains:

- Home
- Chats
- Post
- Leaders
- Account

The active tab is highlighted using the primary blue color. The account tab can display the current user photo, while the chat tab can display unread chat badge counts.

## 5. Technology Stack

### 5.1 Frontend

- Flutter
- Dart
- Material 3 with a customized application theme
- Font Awesome Flutter for selected navigation icons

### 5.2 Firebase Services

- Firebase Authentication for email/password sign-in
- Cloud Firestore for app data
- Firebase Storage for profile and event images
- Firebase Cloud Messaging for push notifications
- Cloud Functions for Firebase for background notification logic and scheduled reminders

### 5.3 Supporting Packages

- `flutter_map` for map rendering
- `latlong2` for map coordinates
- `geolocator` for location access
- `http` for reverse geocoding and address search calls
- `image_picker` for local image selection
- `mobile_scanner` for QR attendance scanning
- `qr_flutter` for organizer QR code generation
- `flutter_local_notifications` for foreground/local notification display on mobile
- `url_launcher` for directions
- `add_2_calendar` for calendar creation flow
- `intl` for date and time formatting

## 6. Architecture and Application Structure

### 6.1 Feature-Oriented Code Structure

The application is organized under `lib/features/` by domain:

- `auth`
- `home`
- `events`
- `attendance`
- `chat`
- `notifications`
- `profile`
- `leaderboard`
- `admin`

Shared concerns are placed under:

- `lib/shared/models`
- `lib/shared/services`
- `lib/shared/utils`
- `lib/shared/widgets`
- `lib/shared/theme`
- `lib/shared/navigation`

### 6.2 App Startup Flow

When the app starts:

1. Flutter bindings are initialized.
2. Firebase is initialized with generated platform-specific options.
3. Firestore persistence is enabled.
4. Firestore cache size is set to unlimited.
5. Firebase Messaging background handling is registered.
6. Platform local notifications are initialized.
7. The app launches using the shared theme and `AuthGate`.

This startup logic is implemented in `lib/main.dart`.

### 6.3 Authentication Gate

`AuthGate` listens to Firebase Authentication state changes and chooses one of three states:

- loading indicator while auth state is unresolved
- Home screen when a user is signed in
- Login screen when no user is signed in

### 6.4 Navigation Strategy

The authenticated shell uses `HomeScreen`, which contains an `IndexedStack`.

This is important because:

- switching tabs does not destroy and recreate every screen
- already opened tabs remain resident where possible
- users get a smoother experience when returning to previously opened screens

### 6.5 Real-Time and Cached Data Strategy

The application combines:

- Firestore streams for live-updating data
- Firestore offline persistence for cached access
- widget-level future caches on selected profile sections
- `AutomaticKeepAliveClientMixin` on profile tab content
- cached current position in `LocationUtils`

This architecture reduces unnecessary reloads while still allowing background updates.

For location specifically, the app tries to reuse cached position data first, then current GPS, then last known position where available. This helps reduce repeated permission-driven delays and unnecessary reloads on discovery screens.

## 7. Requirement Specification

### 7.1 Functional Requirements

The current functional requirements of the implemented system include:

- user authentication and role-based access
- event creation and moderation
- event image upload and management
- location search, selection, and map display
- search by title and location
- featured event surfacing
- category, time, and distance filtering
- RSVP join and leave actions
- event chat and unread tracking
- QR-based attendance verification
- organizer attendance dashboards
- public and private profiles
- notification center and push handling
- scheduled reminder notifications
- achievement and leaderboard tracking
- help and support guidance
- admin moderation, analytics, and broadcast tools

### 7.2 Non-Functional Requirements

The system also addresses non-functional concerns:

- responsive mobile-first UI
- consistent design system
- fast navigation through cached and resident screens
- readable typography and contrast
- real-time updates for chat and event state
- persistent Firestore cache for better revisit performance
- role-aware notification delivery
- reduced notification spam through duplicate prevention and self-notification suppression

### 7.3 Trust and Validation Requirements

The application contains strict trust-oriented requirements:

- events must be approved before public visibility
- RSVP closes one hour before start time
- attendance only opens after the event has started
- completed events block editing and active participation controls
- only verified attendance drives points and hours
- duplicate reminder notifications must be prevented

## 8. Detailed Module Documentation

### 8.1 Authentication Module

The authentication module includes:

- `LoginScreen`
- `SignupScreen`
- `AuthGate`
- `AuthService`

#### Sign Up Flow

During sign-up the user provides:

- full name
- email
- password
- phone number
- date of birth
- gender

On success, the system:

- creates a Firebase Auth account
- updates the Firebase Auth display name
- creates a Firestore `users` document
- sets the default role to `volunteer`
- sets `isBanned` to `false`
- stores `createdAt` with a server timestamp

#### Sign In Flow

On sign-in:

- Firebase Auth validates email and password
- the matching Firestore user document is checked
- if `isBanned` is `true`, the user is immediately signed out and denied entry

#### Auth Screen Design

Both login and signup screens use:

- full-screen blue gradient backgrounds
- white logo box
- top hero text
- a single elevated white form card
- access to Help & Support

#### Current Limitation in Auth

The current implementation does not provide:

- password reset flow
- social login
- email verification

### 8.2 Home Shell and Bottom Navigation

The authenticated shell is built in `HomeScreen`.

Its behavior includes:

- `IndexedStack` page preservation
- prewarming of device location after first frame
- initialization of notification services for the current user
- unread chat badge count on the Chats tab
- optional profile photo in the Account tab
- opening the event creation screen from the center Post action instead of switching to a persistent third tab

### 8.3 Home Screen and Event Discovery

The Home experience is implemented primarily through `HomePage` and `EventsListScreen`.

#### Home Header

The current header contains:

- Shramdaan logo
- compact current location label
- notifications button
- QR scan shortcut

The location label is cleaned to avoid long raw address strings. The app explicitly removes unwanted clutter such as ward numbers, municipality suffixes, province names, and repeated locality segments when possible.

If a fresh device position is unavailable, the system falls back to previously known or cached location information where possible, and otherwise presents a graceful unavailable state instead of blocking the screen.

#### Search Bar

The search bar:

- uses debounced text updates
- supports event title search
- supports partial title word matching
- supports location text search against `location` and `formattedAddress`

This means a user can find an event even when only part of a title word matches, and can also search by place name.

#### Filter Sheet

The Home screen filter sheet provides:

- time filter: Any Time, Today, This Week, This Month
- optional distance filter with slider
- reset and apply actions

#### Featured Events

Featured events:

- are approved events with `isFeatured == true`
- are limited to the top three after sorting
- appear in a horizontally scrollable visual layout
- preserve existing event data and navigation behavior

#### Discover Events

The discover section:

- uses category chips
- applies the global theme
- shows active events above completed events
- supports filtering by the current selected category

### 8.4 Event Listing Behavior

The main event list has several sorting and filtering rules:

- only approved events are fetched for public lists
- search happens against title and location text
- local client-side filters then apply time and optional distance
- incomplete events appear before completed events
- if the user location is available, nearer events are prioritized
- if distance cannot decide the order, more recent upcoming event dates are used

The event card design contains:

- cover image
- category badge
- distance badge or Completed badge
- title
- short description
- date and location pills
- organizer preview with name and profile image
- View button

Completed events replace the distance badge with a `Completed` label.

### 8.5 Event Creation Module

The event creation screen is used from the Post action in the bottom bar.

#### Required Event Inputs

An organizer must provide:

- title
- description
- event date and time
- category
- event cover image
- event location

Optional preparation inputs include:

- things to carry
- things provided

#### Categories

The application currently uses these event categories:

- Clean Up
- Plantation
- Donation
- Construction
- General

#### Location Selection

The event location picker supports:

- typed address search through Nominatim
- search suggestions when at least three characters are typed
- selecting a suggestion from a list
- dropping a pin directly on the map
- a `Use Mine` action that uses the device location
- reverse geocoding selected coordinates into a formatted label

If location resolution fails, the system can fall back to raw coordinates as a formatted address string.

If neither an initial event location nor a cached current position is available, the picker starts from a fallback Kathmandu coordinate so the map can still render immediately.

#### Event Submission Behavior

When the organizer submits:

- the selected image is uploaded to Firebase Storage
- the event is written into Firestore
- the event status is set to `pending`
- `reviewRequestedAt` is stamped
- `title_lowercase` is stored to help text matching
- `rejectionReason` is cleared
- `isFeatured` defaults to `false`

### 8.6 Event Editing Module

The edit event flow allows organizers to modify existing events.

Important current rules include:

- completed events cannot be edited
- organizers can edit pending, rejected, or otherwise eligible events
- if a rejected event is edited and resubmitted, its status returns to `pending`
- resubmission refreshes `reviewRequestedAt`
- featured state is cleared when an event is rejected
- if the event image changes, the previous Firebase Storage image is deleted

The edit screen follows the same updated design language as the creation screen.

### 8.7 My Events Module

The `My Events` screen helps organizers monitor their own submissions.

It includes filters for:

- all
- pending
- approved
- rejected

Each event entry shows:

- title
- category
- status chip
- date/time
- compact location
- rejection reason if applicable
- view action
- edit and resubmit action for rejected items
- attendance action for approved items

### 8.8 Event Moderation and Admin Module

The admin dashboard includes separate tabs for:

- Pending
- Approved
- Rejected
- Users
- Analytics
- Broadcast

#### Pending Events

Pending items are moderation candidates waiting for action.

#### Approved Events

Approved items can be:

- reviewed
- marked or unmarked as featured
- moved back to rejected if needed

#### Rejected Events

Rejected items display moderation outcomes and reasons.

#### Users

Admin user management supports:

- viewing display name
- viewing email
- viewing role
- viewing profile image
- banning
- unbanning

#### Analytics

The analytics module computes:

- total events
- pending events
- approved events
- rejected events
- total users
- active users
- banned users
- total broadcasts
- completion rate
- category counts
- user growth by month for the last six months

The completion rate is calculated from approved events that have already passed their time window.

#### Broadcast

The broadcast module:

- stores broadcasts in the `broadcasts` collection
- writes corresponding notifications for non-banned users
- preserves sent history in an admin-accessible list

### 8.9 Event Detail Screen

The event detail screen is one of the richest modules in the system.

#### Hero Area

It contains:

- large event image
- immersive top bar over the image
- back button
- organizer-only actions such as attendance, QR, edit, and delete when allowed

#### Event Summary Content

Below the image, the screen shows:

- category badge
- optional featured badge
- title
- supporting tagline
- date and time block
- location block

#### Organizer Information

The organizer section displays:

- profile image
- organizer name
- role description
- tappable navigation to the public profile screen

Organizer name resolution prefers the Firestore `displayName`. If that is unavailable, the app falls back to a cleaned display string derived from stored organizer data.

#### About Section

The description is normalized to improve readability:

- unnecessary carriage returns are cleaned
- multi-line paragraphs are preserved
- very long text is formatted into cleaner spacing

#### Location Section

If coordinates are available, the screen provides:

- compact location label
- embedded map using OpenStreetMap
- directions button that launches external maps

#### Preparation Sections

The screen may also show:

- What to bring
- What we provide

These sections are only rendered when relevant lists are not empty.

#### Add to Calendar

The Add to Calendar button:

- appears only when RSVP is still open
- does not appear for completed events
- does not appear after RSVP closes
- pre-fills title, description, location, start time, and a default end time
- uses `add_2_calendar`
- falls back to an Android native calendar intent when needed

#### Organizer Controls

Once an organizer event has started and is still active, the organizer sees:

- an `End Event` action

This action is protected by confirmation flow so it is not ended accidentally.

#### Owner-Only Header Actions

Depending on event state, organizers may see:

- attendance overview action
- QR action during the attendance window
- edit action while editing is still allowed
- delete action

### 8.10 RSVP and Participation Rules

The system enforces multiple participation rules:

- users may join an event only while RSVP is open
- RSVP closes exactly one hour before the event start time
- joining writes a document in `rsvps` using the key `userId-eventId`
- leaving deletes the same RSVP document
- if the event is missing or RSVP is closed, joining is rejected

The organizer is automatically inserted into the event RSVP and chat summary when the event is approved.

### 8.11 Completed and Archived Event Behavior

An event is considered completed when:

- `endedAt` is set, or
- its status is `archived`

Completed behavior affects the system broadly:

- event cards display `Completed`
- completed events move below active ones in event lists
- completed-event chats move to the Archived chat tab
- editing becomes unavailable
- RSVP actions are closed
- attendance actions are closed
- organizer controls change

### 8.12 Attendance and QR Verification Module

Attendance is intentionally stricter than RSVP.

#### Attendance Availability Rules

Users may scan only when:

- the event exists
- the event is not archived
- the event has already started
- the event is not completed
- attendance is open

#### QR Payload

The QR payload stores:

- a type marker: `attendance_qr`
- event identifier
- expiry epoch

#### QR Validity Window

Organizer-generated attendance QR codes are valid for three minutes at a time. Organizers can refresh the QR to generate a new one.

#### Scan Behavior

When a volunteer scans:

- if no attendance record exists for that user, event, and day, the scan creates a check-in
- if a record already exists, the second scan updates check-out

Attendance records are keyed as:

`volunteerId-eventId-YYYYMMDD`

#### Scanner Feedback

The scanner explicitly handles:

- invalid QR code
- expired QR code
- unavailable event
- event not started
- event ended
- successful check-in
- successful check-out

#### Organizer Attendance Screen

Organizers can open an attendance dashboard with two tabs:

- Checked In
- RSVP

The Checked In tab shows:

- volunteer image
- volunteer name
- attendance date
- current attendance state or final duration
- check-in time
- check-out time

The RSVP tab shows who has joined but may not yet have checked in.

### 8.13 Chat Module

The application includes event-specific group chats stored under each event document.

#### Chat Membership

A user gets event chat access through RSVP membership. Organizers are automatically inserted when their event is approved.

#### Chat Storage

Messages are stored in:

`events/{eventId}/messages`

Each message stores:

- senderId
- senderName
- text
- timestamp

#### Chat Summary Storage

Per-user chat summary documents are stored in:

`users/{uid}/chatSummaries/{eventId}`

These summaries store:

- eventId
- latestMessageText
- latestSenderName
- latestMessageAt
- unreadCount

#### Chat List Screen

The chat list screen now includes:

- a fixed top header with logo and notifications
- Active tab
- Archived tab
- counts for each tab

Chats are split using `event.isCompleted`.

#### Chat Ordering

Chat list ordering prioritizes:

- higher unread counts first
- newer message activity second
- event date fallback when no chat messages exist yet

#### Chat Screen Behavior

The chat screen includes:

- clean header
- participant count
- notification shortcut
- current user avatar
- Today divider
- modern message bubbles
- organizer-highlighted styling
- fixed message input bar

Although messages are queried in descending timestamp order from Firestore, the UI reverses them during rendering so older messages appear above and the latest message appears at the bottom, matching normal chat behavior.

#### Read and Unread Handling

When a chat opens:

- matching chat notifications are marked read
- the matching chat summary unread count is reset
- matching displayed notifications are cleared from the foreground notification layer

#### Self-Notification Protection

The current sender does not receive notification popups for messages they send themselves. This is enforced in notification handling logic by comparing the message actor or sender identifier to the current user.

### 8.14 Notifications Module

Notifications exist both as stored feed items and as push/local delivery events.

#### Notification Storage

Per-user notifications are stored under:

`users/{uid}/notifications`

Each notification stores:

- title
- body
- type
- targetId
- actorUserId
- createdAt
- isRead

#### Notification Feed Screen

The notification screen uses a flat Instagram-like list design:

- simple rows
- grouped headings
- unread highlight
- optional right-side unread dot
- Mark all as read action

Current groups are:

- Today
- This week
- Earlier

#### Notification Types in Current Use

- `chat_message`
- `event_approved`
- `event_rejected`
- `broadcast`
- `event_reminder_1h`
- `event_checkin_reminder`
- `admin_review_required`

#### Special Handling for Chat Notifications

The dedicated notifications screen excludes `chat_message` entries from its visual list because chat activity is primarily represented through the Chats tab and unread badges.

#### Notification Routing

Notification taps route users as follows:

- chat message -> chat screen
- event approval/rejection -> event detail
- event reminder -> event detail
- check-in reminder -> event detail
- other types -> notifications screen or relevant default

### 8.15 Reminder and Background Notification Module

The backend uses Cloud Functions and Firestore-triggered logic to improve timeliness.

#### Push Fan-Out Function

Whenever a user notification document is created, Cloud Functions:

- read the target user document
- collect FCM tokens
- send push notifications to all valid tokens
- remove invalid tokens from the user document

#### Admin Review Alerts

Admins are notified when:

- a new pending event is created
- a rejected event is resubmitted and becomes pending again

#### One-Hour Reminder

Every minute, the scheduler checks for approved events beginning in the next one-hour window. Joined users receive a reminder notification about the upcoming event.

#### Check-In Reminder

Every minute, the scheduler checks for approved events starting around the current time. Joined users who do not yet have attendance records for that event day receive a check-in reminder.

#### Duplicate Prevention

Reminder and admin review notifications use `notification_dispatch_locks` so retries or repeated scheduler runs do not spam users with duplicates.

### 8.16 Profile Module

The profile system includes:

- private profile screen
- public profile screen
- edit profile screen
- help and support shortcut

If no user is currently signed in, the profile area shows a lightweight access state with:

- Sign In
- Sign Up
- Open Help & Support

This allows unauthenticated users to access guidance even before creating an account.

#### Private Profile

The private profile screen shows:

- current user name in the app bar
- notification icon
- large profile image
- joined event count
- total points
- verified hours
- achievements
- action buttons
- Joined Events and Organized tabs

Profile action buttons include:

- Admin Dashboard for admins
- Help
- Edit Profile
- Sign Out

#### Public Profile

The public profile mirrors the same modern style while removing private-only controls. It shows:

- user image
- joined event count
- total points
- verified hours
- achievements
- Joined Events tab
- Organized tab

#### Profile Editing

The dedicated edit profile page allows the user to change:

- name
- profile photo
- phone number
- gender
- date of birth

The email remains visible but read-only.

#### Profile Image Handling

Profile photos are uploaded to Firebase Storage under:

`profile_pictures/<userId>-<timestamp>.<extension>`

The application uses a custom image widget abstraction so Firebase Storage images display consistently across supported platforms.

### 8.17 Profile Caching and Stability Improvements

Profile screens were specifically improved so sections do not unnecessarily reload while scrolling or switching tabs.

The current implementation uses:

- cached futures for profile highlight requests
- `initialData` in `FutureBuilder` for public profile header sections
- `AutomaticKeepAliveClientMixin` for Joined and Organized tab bodies

These improvements help keep the hero and achievement areas stable instead of constantly showing loading indicators during normal movement.

### 8.18 Leaderboard Module

The leaderboard has been redesigned into a more gamified experience.

#### Ranges

The current ranges are:

- Daily
- Monthly
- All Time

The selected range changes the date cutoff:

- Daily: today from midnight
- Monthly: current month start
- All Time: no cutoff

#### Points Formula

Leaderboard points are generated from attendance records:

- each attendance record contributes a base 10 points
- plus 1 extra point for every 15 verified minutes

Formula:

`points = 10 + floor(verifiedMinutes / 15)`

#### Ranking Order

Entries are sorted by:

1. total points descending
2. verified minutes descending
3. attended events descending

#### Leaderboard Presentation

The screen includes:

- range tabs
- hero summary
- top three podium
- remaining ranking list

The current user is visually highlighted using `(YOU)` and distinct styling.

### 8.19 Achievement Module

Achievement badges are computed from verified attendance statistics, not from RSVP counts.

Current badges are:

- First Step: at least 1 attended event
- Steady Helper: at least 5 attended events
- Time Giver: at least 300 verified minutes
- Impact Builder: at least 900 verified minutes
- Community Force: at least 100 total points

Each badge also has:

- icon
- title
- description
- color
- background color

### 8.20 Help and Support Module

The Help & Support page is intended for normal users rather than admins.

Current help sections cover:

- Getting Started
- Finding Events
- Joining An Event
- QR Check-In & Check-Out
- Event Chat
- Notifications
- Profile, Points, And Achievements
- Leaderboard
- Common Questions

This page can also be opened by a user who is not currently signed in.

## 9. Data Model and Firestore Collections

### 9.1 `users`

Each user document stores core identity and platform state such as:

- `uid`
- `displayName`
- `email`
- `phoneNumber`
- `dob`
- `gender`
- `role`
- `isBanned`
- `createdAt`
- `photoUrl` when uploaded
- `fcmTokens` as an array for push delivery

### 9.2 `events`

Each event document currently supports:

- `title`
- `title_lowercase`
- `description`
- `location`
- `formattedAddress`
- `latitude`
- `longitude`
- `eventDate`
- `category`
- `organizerId`
- `organizerName`
- `imageUrl`
- `thingsToCarry`
- `thingsProvided`
- `status`
- `reviewRequestedAt`
- `rejectionReason`
- `isFeatured`
- `endedAt`

#### Important Derived Meanings

- `status == pending` means waiting for admin review
- `status == approved` means public discovery is allowed
- `status == rejected` means changes are required
- `status == archived` is treated as unavailable and completed
- `endedAt != null` means organizer has completed the event

### 9.3 `rsvps`

RSVP documents use a deterministic document id:

`userId-eventId`

Stored fields include:

- `eventId`
- `userId`
- `timestamp`

### 9.4 `attendance`

Attendance documents use a deterministic document id:

`volunteerId-eventId-YYYYMMDD`

Stored fields include:

- `volunteer_id`
- `event_id`
- `attendance_date`
- `check_in_time`
- `check_out_time`
- `updated_at`

### 9.5 `users/{uid}/notifications`

Per-user notification subcollection storing notification history.

Fields:

- `title`
- `body`
- `type`
- `targetId`
- `actorUserId`
- `createdAt`
- `isRead`

### 9.6 `users/{uid}/chatSummaries`

Per-user chat metadata.

Fields may include:

- `eventId`
- `latestMessageText`
- `latestSenderName`
- `latestMessageAt`
- `unreadCount`

### 9.7 `events/{eventId}/messages`

Message documents for each event chat.

Fields include:

- `senderId`
- `senderName`
- `text`
- `timestamp`

### 9.8 `broadcasts`

Admin broadcast history documents store:

- `title`
- `body`
- `sentBy`
- `sentAt`

### 9.9 `notification_dispatch_locks`

This collection is used by Cloud Functions to prevent duplicate reminder and review notifications.

Stored lock metadata includes:

- `userId`
- `type`
- `targetId`
- `createdAt`

## 10. Business Rules and Validation Rules

The current implementation enforces the following important rules.

### 10.1 Event Visibility Rules

- only approved events are publicly discoverable
- archived events are treated as unavailable

### 10.2 RSVP Rules

- RSVP is allowed only while `event.isRsvpOpen` is true
- RSVP closes one hour before the event starts
- RSVP is not available for completed events

### 10.3 Attendance Rules

- attendance is allowed only during the event time window
- the event must have started
- completed or archived events reject attendance scans
- the first valid scan creates check-in
- the next valid scan updates check-out

### 10.4 Organizer Rules

- organizers can edit only while event editing is still allowed
- organizers can end events only after the event has started
- organizers cannot edit a completed event

### 10.5 Notification Rules

- users should not receive pop-up notifications caused by their own actions
- duplicate reminders must be blocked
- chat notifications are tracked separately from the main notification feed presentation

### 10.6 Leaderboard Rules

- leaderboard ranking depends on attendance, not RSVP
- verified minutes affect both hours and points
- only attendance records produce contribution metrics

### 10.7 Image Rules

- event cover image is required during creation
- uploaded event and profile images are stored in Firebase Storage
- when an event image is replaced, the old Storage file is removed when possible

## 11. Detailed Backend and Notification Logic

### 11.1 Firestore Service Responsibilities

`FirestoreService` is the primary data access layer for:

- event queries
- featured event queries
- creation, update, deletion
- RSVP joins and leaves
- end event updates
- attendance record handling
- chat message sending
- chat summary updates
- user profile updates
- leaderboard calculations
- badge generation
- admin analytics
- broadcasts
- notification CRUD support

### 11.2 Cloud Functions Responsibilities

Cloud Functions currently handle:

- push fan-out for newly created notification documents
- admin review notifications on event creation and resubmission
- one-hour event reminders
- check-in reminders around event start

### 11.3 Device Token Handling

When notification setup runs for a signed-in user:

- permission is requested
- FCM token is fetched
- token is saved in the user document
- token refresh updates the stored token array

Invalid tokens discovered during push fan-out are removed from Firestore.

## 12. State Management, Refresh Strategy, and Performance Notes

The app uses Flutter widget state plus Firestore streams instead of a separate heavy state-management package.

Important performance and stability choices include:

- `IndexedStack` in the main shell to preserve tab state
- Firestore persistence with unlimited cache
- cached current location in `LocationUtils`
- debounced search input on the Home screen
- future caching on profile highlights
- `AutomaticKeepAliveClientMixin` on profile tabs
- in-place refresh indicators instead of full-page replacement

These choices were especially important to reduce:

- repeated loading spinners on screen switches
- header reloads on profile pages
- unnecessary rebuilds of static top sections

## 13. Current Implementation Status

The current application already implements:

- complete authentication flow
- updated themed UI across major screens
- event creation, editing, moderation, and discovery
- featured events and discovery filters
- location-aware search and sorting
- RSVP restrictions based on start time
- completed event handling
- organizer attendance tools
- QR check-in and check-out
- chat list with active and archived tabs
- redesigned chat screen
- redesigned profile and public profile screens
- edit profile screen with photo and personal details
- help and support page
- gamified leaderboard with ranges
- notifications feed redesign
- role-based reminders and admin alerts
- calendar integration from event detail
- organizer auto-RSVP and auto-chat enrollment on approval

## 14. Known Limitations

The current system is functional and extensive, but several limitations still remain:

- no password reset flow is implemented yet
- no social login flow is currently present
- chat supports text only and does not yet support attachments or emoji reactions
- reminder reliability still depends on Firebase scheduler execution and device notification permissions
- calendar opening can depend on platform capabilities and installed apps
- no recurring event system exists
- no advanced search indexing service is used; search is still based on Firestore data plus client-side filtering

## 15. Future Enhancements

Possible next-stage improvements include:

- password reset and account recovery
- social authentication providers
- richer organizer analytics
- recurring events
- multi-day event support
- chat attachments and media sharing
- better moderation audit trails
- stronger role and permission management
- saved searches and event bookmarks
- calendar status syncing back into the app
- offline-friendly queued actions for weak connectivity

## 16. Conclusion

Shramdaan has evolved from an initial concept into a substantial, working volunteer coordination platform with a complete end-to-end workflow. The system now supports verified local event discovery, admin moderation, RSVP participation, QR attendance, contribution tracking, chat coordination, timely notifications, public identity, and leaderboard-based engagement.

The application’s current strength lies in its clear community-first logic: approved events become discoverable, joined users become participants, verified attendance becomes measurable contribution, and contribution becomes visible through profiles, badges, and rankings. This creates a stronger and more trustworthy volunteering ecosystem than informal coordination alone.

In summary, the present version of Shramdaan is no longer only a prototype idea. It is a multi-module, production-oriented community service platform with clear architecture, growing operational depth, and a strong foundation for future expansion.
