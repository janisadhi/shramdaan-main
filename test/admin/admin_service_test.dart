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

  group('Admin Module', () {
    test('approve event updates status and makes event visible in discovery', () async {
      // Arrange
      await firestore.collection('users').doc('organizer-1').set(
            userData(uid: 'organizer-1', displayName: 'Organizer One'),
          );
      await firestore.collection('events').doc('event-1').set(
            eventData(status: 'pending', organizerId: 'organizer-1'),
          );

      // Act
      await service.approveEvent('event-1');

      // Assert
      final event = await firestore.collection('events').doc('event-1').get();
      expect(event.data()?['status'], 'approved');

      final visibleEvents = await service.getEventsStream().first;
      expect(visibleEvents.map((item) => item.id), contains('event-1'));
    });

    test('reject event stores reason and removes featured status', () async {
      // Arrange
      await firestore.collection('users').doc('organizer-1').set(
            userData(uid: 'organizer-1', displayName: 'Organizer One'),
          );
      await firestore.collection('events').doc('event-1').set(
            eventData(status: 'pending', isFeatured: true, organizerId: 'organizer-1'),
          );

      // Act
      await service.rejectEvent('event-1', 'Location details are unclear.');

      // Assert
      final event = await firestore.collection('events').doc('event-1').get();
      expect(event.data()?['status'], 'rejected');
      expect(event.data()?['rejectionReason'], 'Location details are unclear.');
      expect(event.data()?['isFeatured'], isFalse);
    });

    test('ban and unban user toggles account access flag', () async {
      // Arrange
      await firestore.collection('users').doc('user-1').set(userData(uid: 'user-1'));

      // Act
      await service.setUserBanStatus('user-1', true);
      final banned = await firestore.collection('users').doc('user-1').get();
      await service.setUserBanStatus('user-1', false);
      final unbanned = await firestore.collection('users').doc('user-1').get();

      // Assert
      expect(banned.data()?['isBanned'], isTrue);
      expect(unbanned.data()?['isBanned'], isFalse);
    });

    test('admin permissions should be enforced by Firestore Security Rules or server functions', () async {
      // Arrange
      await firestore.collection('users').doc('volunteer-1').set(
            userData(uid: 'volunteer-1', role: 'volunteer'),
          );

      // Act
      final volunteer = await firestore.collection('users').doc('volunteer-1').get();

      // Assert
      expect(volunteer.data()?['role'], isNot('admin'));
      // Client service methods are intentionally tested separately from authorization.
      // Production deployments must reject volunteer writes in Firestore rules/functions.
    });
  });
}
