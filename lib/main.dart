import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';

import 'features/auth/screens/auth_gate.dart';
import 'features/notifications/services/notification_service.dart';
import 'firebase_options.dart';
import 'shared/navigation_app_navigator.dart';
import 'shared/navigation/app_route_observer.dart';
import 'shared/theme/app_theme.dart';

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
    cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
  );
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  await NotificationService.instance.initializePlatformNotifications();
  print('App connected to Firebase Project ID: ${Firebase.app().options.projectId}');

  runApp(const ShramDaanApp());
}

class ShramDaanApp extends StatelessWidget {
  const ShramDaanApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Shram Daan',
      debugShowCheckedModeBanner: false,
      navigatorKey: appNavigatorKey,
      scaffoldMessengerKey: appScaffoldMessengerKey,
      navigatorObservers: [appRouteObserver],
      theme: AppTheme.light(),
      home: const AuthGate(),
    );
  }
}

