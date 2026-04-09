
# Shram Daan - Community Volunteering App

Shram Daan is a mobile application built with Flutter and Firebase, designed to connect volunteers with community service projects. It aims to revive the traditional practice of "donation of labor" by providing a modern, user-friendly platform for discovering, managing, and participating in local volunteer activities.

## Features

  - **User Authentication**: Secure sign-up and login for volunteers and organizers.
  - **Event Management**: Create, read, update, and delete community events.
  - **Real-time Updates**: Live updates for event lists and chats using Firestore Streams.
  - **Search & Filter**: Find events by title or category.
  - **RSVP System**: Users can join and leave events.
  - **Event Chat**: Real-time group chat for each event's participants.
  - **User Profiles**: View user information and a list of joined events.
  - **Leaderboard**: Gamified ranking of top volunteers based on events joined.
  - **Admin Dashboard**: A special section for admins to approve new events and manage featured posts.

## Getting Started

Follow these instructions to get a copy of the project up and running on your local machine for development and testing purposes.

### **1. Prerequisites**

Make sure you have the following software installed on your machine:

  * **Flutter SDK**: [Installation Guide](https://flutter.dev/docs/get-started/install)
  * **A Code Editor**: We recommend [VS Code](https://code.visualstudio.com/) with the Flutter extension or [Android Studio](https://developer.android.com/studio).
  * **Firebase CLI**: [Installation Guide](https://www.google.com/search?q=https://firebase.google.com/docs/cli%23install-cli-standalone-binary)
  * **FlutterFire CLI**: After installing the Firebase CLI, run this command:
    ```bash
    dart pub global activate flutterfire_cli
    ```

### **2. Setup Instructions**

#### **Step A: Clone the Repository**

Open your terminal and run the following command to clone the project:

```bash
git clone https://github.com/janisadhikari-cloud/shramdaan.git
cd shramdaan
```

#### **Step B: Create and Connect Your Own Firebase Project**

This project requires a Firebase backend. You will need to create your own Firebase project to connect the app to.

1.  **Create a Firebase Project**:

      * Go to the [Firebase Console](https://console.firebase.google.com/).
      * Click **"Add project"** and give it a name (e.g., "My Shram Daan").
      * Follow the on-screen instructions to create the project.

2.  **Connect Your App to Firebase**:

      * In your terminal, at the root of the project folder, run the configure command:
        ```bash
        flutterfire configure
        ```
      * The command will ask you to log in to Firebase and select the project you just created.
      * When prompted to choose platforms, select **Android** and **iOS**.
      * This will automatically generate a `lib/firebase_options.dart` file in your project, which contains the keys to connect to your specific Firebase project.

3.  **Enable Firebase Services**:
    In your new Firebase project's console, you must enable the services we use:

      * **Authentication**:
          * Go to the **Authentication** section.
          * Click the "Sign-in method" tab.
          * Enable the **Email/Password** provider.
      * **Cloud Firestore**:
          * Go to the **Cloud Firestore** section.
          * Click "Create database".
          * Start in **test mode** for now.
      * **Storage**:
          * Go to the **Storage** section.
          * Click "Get started".
          * Start in **test mode** for now.

#### **Step C: Get Flutter Dependencies**

Now that the project is configured, run this command to download all the necessary packages:

```bash
flutter pub get
```

### **3. Running the Application**

1.  **Select a Device**: Open the project in your code editor (VS Code or Android Studio). Make sure an emulator is running or a physical device is connected. Select your target device from the device list.
2.  **Run the App**: Launch the app by pressing **F5** or running the following command in your terminal:
    ```bash
    flutter run
    ```

The app should now build and run on your selected device, connected to your personal Firebase backend.

### **4. (Optional) Set an Admin Role**

To access the Admin Dashboard, you need to assign the "admin" role to your user account.

1.  Sign up for a new account in the app.
2.  Go to your **Cloud Firestore** database in the Firebase Console.
3.  Navigate to the `users` collection and find the document with your user ID.
4.  Add a new field:
      * **Field name**: `role`
      * **Type**: `string`
      * **Value**: `admin`
5.  Save the document. After a hot restart, the "Admin Dashboard" button will appear on your profile screen.