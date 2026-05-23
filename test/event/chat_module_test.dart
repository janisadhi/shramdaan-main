import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myapp/shared/services/firestore_service.dart';

import '../shared/firebase_test_helpers.dart';

void main() {
  late FakeFirebaseFirestore firestore;
  late FirestoreService service;

  setUp(() async {
    firestore = fakeFirestore();
    service = firestoreService(firestore);

    await firestore.collection('events').doc('event-1').set(
          eventData(title: 'River Cleanup', organizerId: 'organizer-1'),
        );
    await firestore.collection('rsvps').doc('user-1-event-1').set({
      'userId': 'user-1',
      'eventId': 'event-1',
    });
    await firestore.collection('rsvps').doc('user-2-event-1').set({
      'userId': 'user-2',
      'eventId': 'event-1',
    });
  });

  group('Chat Module', () {
    test('message ordering is newest first', () async {
      // Arrange
      await firestore
          .collection('events')
          .doc('event-1')
          .collection('messages')
          .add(chatMessage(text: 'Older', sentAt: DateTime(2026, 5, 21, 9)).toMap());
      await firestore
          .collection('events')
          .doc('event-1')
          .collection('messages')
          .add(chatMessage(text: 'Newer', sentAt: DateTime(2026, 5, 21, 10)).toMap());

      // Act
      final messages = await service.getChatMessagesStream('event-1').first;

      // Assert
      expect(messages.map((message) => message.text), ['Newer', 'Older']);
    });

    test('unread count updates for recipients when participant sends message', () async {
      // Arrange
      final message = chatMessage(senderId: 'user-1', senderName: 'Volunteer One');

      // Act
      await service.sendMessage('event-1', message);

      // Assert
      final recipientSummary = await firestore
          .collection('users')
          .doc('user-2')
          .collection('chatSummaries')
          .doc('event-1')
          .get();
      final senderSummary = await firestore
          .collection('users')
          .doc('user-1')
          .collection('chatSummaries')
          .doc('event-1')
          .get();

      expect(recipientSummary.data()?['unreadCount'], 1);
      expect(senderSummary.data()?['unreadCount'], 0);
    });

    test('non participant cannot send chat message', () async {
      // Arrange
      final message = chatMessage(senderId: 'outsider', senderName: 'Outsider');

      // Act
      await service.sendMessage('event-1', message);

      // Assert
      final messages = await firestore
          .collection('events')
          .doc('event-1')
          .collection('messages')
          .get();
      expect(messages.docs, isEmpty);
    });

    test('empty message is rejected and not persisted', () async {
      // Arrange
      final message = chatMessage(senderId: 'user-1', text: '   ');

      // Act
      await service.sendMessage('event-1', message);

      // Assert
      final messages = await firestore
          .collection('events')
          .doc('event-1')
          .collection('messages')
          .get();
      expect(messages.docs, isEmpty);
    });
  });
}
