import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../../../shared/navigation/app_route_observer.dart';
import '../../../shared/navigation_app_navigator.dart';
import '../../../shared/services/firestore_service.dart';
import '../../chat/screens/chat_screen.dart';
import '../../events/screens/event_details_screen.dart';
import 'browser_notification_helper.dart';
import '../screens/notifications_screen.dart';

class NotificationService {
  NotificationService._();

  static const String _webVapidKey = String.fromEnvironment('FCM_WEB_VAPID_KEY');
  static const AndroidNotificationChannel _androidChannel = AndroidNotificationChannel(
    'shramdaan_updates',
    'Shramdaan Updates',
    description: 'Notifications for chats, broadcasts, and event updates.',
    importance: Importance.high,
  );

  static final NotificationService instance = NotificationService._();
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FirestoreService _firestoreService = FirestoreService();
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  final Map<int, Map<String, String?>> _activeForegroundNotifications = {};

  String? _initializedUserId;
  String? _pendingLaunchPayload;
  bool _listenersAttached = false;
  bool _platformInitialized = false;

  Future<void> initializePlatformNotifications() async {
    if (_platformInitialized || kIsWeb) {
      return;
    }

    const androidSettings = AndroidInitializationSettings('ic_notification');
    const settings = InitializationSettings(android: androidSettings);

    await _localNotifications.initialize(
      settings,
      onDidReceiveNotificationResponse: (response) {
        final payload = response.payload;
        if (payload != null && payload.isNotEmpty) {
          _handlePayloadNavigation(payload);
        }
      },
    );

    final launchDetails = await _localNotifications.getNotificationAppLaunchDetails();
    final launchPayload = launchDetails?.notificationResponse?.payload;
    if (launchPayload != null && launchPayload.isNotEmpty) {
      _pendingLaunchPayload = launchPayload;
    }

    final androidImplementation = _localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    await androidImplementation?.createNotificationChannel(_androidChannel);
    await androidImplementation?.requestNotificationsPermission();

    _platformInitialized = true;
  }

  Future<void> initializeForCurrentUser() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null || _initializedUserId == currentUser.uid) {
      return;
    }

    await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (kIsWeb && _webVapidKey.isEmpty) {
      debugPrint(
        'FCM web push is missing FCM_WEB_VAPID_KEY. Browser device notifications will not work until it is provided.',
      );
    }

    final token = await _messaging.getToken(
      vapidKey: kIsWeb && _webVapidKey.isNotEmpty ? _webVapidKey : null,
    );
    if (token != null) {
      await _firestoreService.saveUserFcmToken(currentUser.uid, token);
    }

    _attachMessageListeners();

    _messaging.onTokenRefresh.listen((token) {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        _firestoreService.saveUserFcmToken(user.uid, token);
      }
    });

    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      _handleRemoteMessageNavigation(initialMessage);
    }

    if (_pendingLaunchPayload != null) {
      final payload = _pendingLaunchPayload!;
      _pendingLaunchPayload = null;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _handlePayloadNavigation(payload);
      });
    }

    _initializedUserId = currentUser.uid;
  }

  void _attachMessageListeners() {
    if (_listenersAttached) {
      return;
    }

    FirebaseMessaging.onMessage.listen((message) async {
      final currentUser = FirebaseAuth.instance.currentUser;
      final actorUserId = message.data['actorUserId'] as String?;
      final senderId = message.data['senderId'] as String?;
      final triggeringUserId = actorUserId ?? senderId;
      if (currentUser != null &&
          triggeringUserId != null &&
          triggeringUserId.isNotEmpty &&
          triggeringUserId == currentUser.uid) {
        return;
      }

      final notification = message.notification;
      final title =
          notification?.title ?? (message.data['title'] as String?) ?? 'New update';
      final body = notification?.body ?? (message.data['body'] as String?) ?? '';
      final type = (message.data['type'] as String?) ?? 'general';
      final targetId = message.data['targetId'] as String?;

      if (kIsWeb) {
        await showBrowserNotification(title: title, body: body);
      } else {
        await _showForegroundAndroidNotification(
          title: title,
          body: body,
          type: type,
          targetId: targetId,
        );
        return;
      }

      final messenger = appScaffoldMessengerKey.currentState;
      final navigator = appNavigatorKey.currentState;
      if (messenger == null || navigator == null || !navigator.mounted) {
        return;
      }

      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            action: SnackBarAction(
              label: 'Open',
              onPressed: () => openNotificationDestination(
                type: type,
                targetId: targetId,
              ),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                if (body.isNotEmpty) Text(body),
              ],
            ),
          ),
        );
    });

    FirebaseMessaging.onMessageOpenedApp.listen(_handleRemoteMessageNavigation);
    _listenersAttached = true;
  }

  Future<void> _showForegroundAndroidNotification({
    required String title,
    required String body,
    required String type,
    required String? targetId,
  }) async {
    if (kIsWeb) {
      return;
    }

    final payload = jsonEncode({
      'type': type,
      'targetId': targetId,
    });
    final notificationId = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    _activeForegroundNotifications[notificationId] = {
      'type': type,
      'targetId': targetId,
    };

    await _localNotifications.show(
      notificationId,
      title,
      body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'shramdaan_updates',
          'Shramdaan Updates',
          channelDescription: 'Notifications for chats, broadcasts, and event updates.',
          importance: Importance.high,
          priority: Priority.high,
          icon: 'ic_notification',
          largeIcon: DrawableResourceAndroidBitmap('launcher_icon'),
        ),
      ),
      payload: payload,
    );
  }

  Future<void> clearDisplayedNotifications({
    List<String>? types,
    String? targetId,
  }) async {
    if (kIsWeb) {
      return;
    }

    final idsToRemove = <int>[];
    for (final entry in _activeForegroundNotifications.entries) {
      final metadata = entry.value;
      final matchesType = types == null || types.contains(metadata['type']);
      final matchesTarget = targetId == null || metadata['targetId'] == targetId;
      if (matchesType && matchesTarget) {
        await _localNotifications.cancel(entry.key);
        idsToRemove.add(entry.key);
      }
    }

    for (final id in idsToRemove) {
      _activeForegroundNotifications.remove(id);
    }
  }

  Future<void> openNotificationDestination({
    required String type,
    String? targetId,
  }) async {
    final navigator = appNavigatorKey.currentState;
    if (navigator == null) {
      return;
    }

    final currentRoute = AppRouteObserver.currentRouteName.value;

    if (type == 'chat_message' && targetId != null) {
      if (currentRoute == '/chat/$targetId') {
        return;
      }
      final event = await _firestoreService.getEventById(targetId);
      navigator.push(
        MaterialPageRoute(
          settings: RouteSettings(name: '/chat/$targetId'),
          builder: (_) => ChatScreen(
            eventId: targetId,
            eventTitle: event?.title ?? 'Event Chat',
          ),
        ),
      );
      return;
    }

    if ((type == 'event_approved' ||
            type == 'event_rejected' ||
            type == 'event_reminder_1h' ||
            type == 'event_checkin_reminder') &&
        targetId != null) {
      if (currentRoute == '/event/$targetId') {
        return;
      }
      navigator.push(
        MaterialPageRoute(
          settings: RouteSettings(name: '/event/$targetId'),
          builder: (_) => EventDetailsScreen(eventId: targetId),
        ),
      );
      return;
    }

    if (currentRoute == '/notifications') {
      return;
    }
    navigator.push(
      MaterialPageRoute(
        settings: const RouteSettings(name: '/notifications'),
        builder: (_) => const NotificationsScreen(),
      ),
    );
  }

  void _handlePayloadNavigation(String payload) {
    final decoded = jsonDecode(payload);
    if (decoded is! Map<String, dynamic>) {
      return;
    }

    openNotificationDestination(
      type: decoded['type'] as String? ?? 'general',
      targetId: decoded['targetId'] as String?,
    );
  }

  void _handleRemoteMessageNavigation(RemoteMessage message) {
    openNotificationDestination(
      type: message.data['type'] as String? ?? 'general',
      targetId: message.data['targetId'] as String?,
    );
  }
}




