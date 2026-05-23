# Shramdaan

Shramdaan is a Flutter and Firebase community volunteering platform for discovering, moderating, joining, and managing local service events. It supports the full event lifecycle from submission and admin review to RSVP, attendance verification, chat coordination, reminders, profiles, achievements, and leaderboard ranking.

## Overview

The app is designed around one core idea:

**RSVP shows intent, but verified attendance shows contribution.**

That principle drives event participation rules, QR attendance, hours, points, achievements, reminders, and leaderboard ranking.

## Main Features

- Email/password authentication
- Event creation, editing, approval, rejection, and featuring
- Search by event title and location
- Category, time, and distance filtering
- RSVP with a 1-hour cutoff before event start
- QR-based check-in and check-out during the event window
- Event chat with active and archived chat tabs
- Private and public user profiles
- Achievement badges and leaderboard ranges
- Admin dashboard for moderation, analytics, user control, and broadcasts
- In-app notifications, push notifications, admin review alerts, and event reminders
- Add-to-calendar support from the event detail screen

## Tech Stack

- Flutter
- Dart
- Firebase Authentication
- Cloud Firestore
- Firebase Storage
- Firebase Cloud Messaging
- Firebase Cloud Functions
- Flutter Map
- Geolocator
- Mobile Scanner

## Project Structure

```text
lib/
  features/
    admin/
    attendance/
    auth/
    chat/
    events/
    home/
    leaderboard/
    notifications/
    profile/
  shared/
functions/
web/
android/
```

## Getting Started

### Prerequisites

- Flutter SDK
- Android SDK
- Node.js 20
- Firebase CLI
- FlutterFire CLI

Useful checks:

```bash
flutter doctor
firebase --version
flutterfire --version
node --version
```

Install the Firebase tools if they are not already available:

```bash
npm install -g firebase-tools
dart pub global activate flutterfire_cli
```

If `flutterfire` is not recognized after installation, add Dart's global bin directory to your PATH.

### 1. Clone the Repository

```bash
git clone https://github.com/janisadhi/shramdaan-main.git
cd shramdaan-main
```

### 2. Install Flutter Dependencies

```bash
flutter pub get
```

### 3. Set Up Firebase

Create a Firebase project and enable:

- Authentication
- Cloud Firestore
- Firebase Storage
- Firebase Cloud Messaging
- Cloud Functions

Enable this auth provider:

- Email/Password

Register these app targets:

- Android
- Web

Regenerate the Flutter Firebase config:

```bash
flutterfire configure --project YOUR_PROJECT_ID
```


Important:

- `web/firebase-messaging-sw.js` contains a hardcoded Firebase config block and must be updated if you switch Firebase projects
- Firestore and Storage rules are not currently checked into this repo, so you must recreate or export them separately

### 4. Deploy Firestore Indexes

This repo includes the Firestore index manifest:

- [`firestore.indexes.json`](firestore.indexes.json)

Deploy it with:

```bash
firebase deploy --only firestore:indexes
```

### 5. Deploy Cloud Functions

Install Functions dependencies:

```bash
cd functions
npm install
cd ..
```

Deploy:

```bash
firebase deploy --only functions
```

### 6. Run the App

Run on the default connected device:

```bash
flutter run
```

Run on Android:

```bash
flutter run -d android
```

Run on Chrome:

```bash
flutter run -d chrome
```

If you want web push notifications, provide the VAPID key:

```bash
flutter run -d chrome --dart-define=FCM_WEB_VAPID_KEY=YOUR_VAPID_KEY
```

## Admin Access

To test admin features:

1. Create a user account in the app.
2. Open Firestore.
3. In the `users` collection, set the user document field:

```text
role = admin
```

After restarting the app, the admin dashboard controls will be available for that user.

## Build Commands

```bash
flutter build apk
flutter build apk --split-per-abi
flutter build web
```

## Firebase Deployment Files

These files matter when moving the app to a new Firebase project:

- [`firebase.json`](firebase.json)
- [`firestore.indexes.json`](firestore.indexes.json)
- [`lib/firebase_options.dart`](lib/firebase_options.dart)
- [`android/app/google-services.json`](android/app/google-services.json)
- [`web/firebase-messaging-sw.js`](web/firebase-messaging-sw.js)
- [`functions/index.js`](functions/index.js)
- [`functions/package.json`](functions/package.json)

## Important Notes

- The current Android `applicationId` is still a placeholder in [`android/app/build.gradle.kts`](android/app/build.gradle.kts) and should be changed before production publishing.
- Release signing is not fully configured yet; a real keystore is required before store distribution.
- A new Firebase project will not automatically include old Firestore data, Auth users, Storage files, or rules.
- Web push requires a valid VAPID key.



## Status

This is an actively evolving project. Features, UI, and Firebase setup details may continue to change as the app grows.
