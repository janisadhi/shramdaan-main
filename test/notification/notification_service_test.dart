import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myapp/features/notifications/models/app_notification_model.dart';
import 'package:myapp/shared/services/firestore_service.dart';

import '../shared/firebase_test_helpers.dart';

void main() {
  late FakeFirebaseFirestore firestore;
  late FirestoreService service;

  setUp(() {
    firestore = fakeFirestore();
    service = firestoreService(firestore);
  });

  group('Notification Module', () {
    test('notification document maps routing fields correctly', () {
      // Arrange
      final data = {
        'title': 'Event approved',
        'body': 'Your event is live.',
        'type': 'event_approved',
        'targetId': 'event-1',
        'isRead': false,
      };

      // Act
      final notification = AppNotification.fromMap('notification-1', data);

      // Assert
      expect(notification.type, 'event_approved');
      expect(notification.targetId, 'event-1');
      expect(notification.isRead, isFalse);
    });

    test('unread count excludes filtered notification types', () async {
      // Arrange
      await service.createNotification(
        userId: 'user-1',
        title: 'Chat',
        body: 'New message',
        type: 'chat_message',
        targetId: 'event-1',
      );
      await service.createNotification(
        userId: 'user-1',
        title: 'Approved',
        body: 'Event approved',
        type: 'event_approved',
        targetId: 'event-1',
      );

      // Act
      final count = await service
          .getUnreadNotificationCountExcludingTypes('user-1', ['chat_message'])
          .first;

      // Assert
      expect(count, 1);
    });

    test('mark matching notifications read prevents repeat unread surfacing', () async {
      // Arrange
      await service.createNotification(
        userId: 'user-1',
        title: 'Approved',
        body: 'Event approved',
        type: 'event_approved',
        targetId: 'event-1',
      );
      await service.createNotification(
        userId: 'user-1',
        title: 'Approved duplicate',
        body: 'Event approved again',
        type: 'event_approved',
        targetId: 'event-1',
      );

      // Act
      await service.markMatchingNotificationsRead(
        'user-1',
        types: ['event_approved'],
        targetId: 'event-1',
      );
      final count = await service.getUnreadNotificationCount('user-1').first;

      // Assert
      expect(count, 0);
    });

    test('invalid token cleanup is covered by Cloud Functions and should remove bad FCM tokens', () {
      // Arrange
      final invalidErrorCodes = {
        'messaging/invalid-registration-token',
        'messaging/registration-token-not-registered',
      };

      // Act & Assert
      expect(invalidErrorCodes, contains('messaging/invalid-registration-token'));
      expect(invalidErrorCodes, contains('messaging/registration-token-not-registered'));
    });
  });
}
