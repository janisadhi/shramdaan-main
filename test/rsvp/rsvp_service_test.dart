import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myapp/shared/services/firestore_service.dart';

import '../shared/firebase_test_helpers.dart';

void main() {
  late FakeFirebaseFirestore firestore;
  late FirestoreService service;

  setUp(() {
    firestore = fakeFirestore();
    service = firestoreService(firestore);
  });

  group('RSVP Module', () {
    test('successful RSVP creates a deterministic user-event document', () async {
      // Arrange
      await firestore.collection('events').doc('event-1').set(
            eventData(eventDate: DateTime.now().add(const Duration(days: 1))),
          );

      // Act
      await service.joinEvent('event-1', 'user-1');

      // Assert
      final rsvp = await firestore.collection('rsvps').doc('user-1-event-1').get();
      expect(rsvp.exists, isTrue);
      expect(rsvp.data()?['eventId'], 'event-1');
      expect(rsvp.data()?['userId'], 'user-1');
    });

    test('duplicate RSVP is blocked by deterministic document id', () async {
      // Arrange
      await firestore.collection('events').doc('event-1').set(
            eventData(eventDate: DateTime.now().add(const Duration(days: 1))),
          );

      // Act
      await service.joinEvent('event-1', 'user-1');
      await service.joinEvent('event-1', 'user-1');

      // Assert
      final rsvps = await firestore.collection('rsvps').get();
      expect(rsvps.docs, hasLength(1));
      expect(rsvps.docs.single.id, 'user-1-event-1');
    });

    test('cannot join expired event after RSVP cutoff', () async {
      // Arrange
      await firestore.collection('events').doc('event-1').set(
            eventData(eventDate: DateTime.now().add(const Duration(minutes: 30))),
          );

      // Act
      await service.joinEvent('event-1', 'user-1');

      // Assert
      final rsvps = await firestore.collection('rsvps').get();
      expect(rsvps.docs, isEmpty);
    });

    test('leave event deletes RSVP document', () async {
      // Arrange
      await firestore.collection('events').doc('event-1').set(
            eventData(eventDate: DateTime.now().add(const Duration(days: 1))),
          );
      await service.joinEvent('event-1', 'user-1');

      // Act
      await service.leaveEvent('event-1', 'user-1');

      // Assert
      final rsvp = await firestore.collection('rsvps').doc('user-1-event-1').get();
      expect(rsvp.exists, isFalse);
    });
  });
}
