import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myapp/shared/models/event_model.dart';
import 'package:myapp/shared/services/firestore_service.dart';
import 'package:myapp/shared/utils/location_utils.dart';

import '../shared/firebase_test_helpers.dart';

void main() {
  late FakeFirebaseFirestore firestore;
  late FirestoreService service;

  setUp(() {
    firestore = fakeFirestore();
    service = firestoreService(firestore);
  });

  group('Event Discovery Module', () {
    test('only approved events are returned from discovery stream', () async {
      // Arrange
      await firestore.collection('events').doc('approved-1').set(
            eventData(title: 'Approved Cleanup', status: 'approved'),
          );
      await firestore.collection('events').doc('pending-1').set(
            eventData(title: 'Pending Cleanup', status: 'pending'),
          );
      await firestore.collection('events').doc('rejected-1').set(
            eventData(title: 'Rejected Cleanup', status: 'rejected'),
          );

      // Act
      final events = await service.getEventsStream().first;

      // Assert
      expect(events.map((event) => event.id), ['approved-1']);
    });

    test('category filtering returns only matching approved events', () async {
      // Arrange
      await firestore.collection('events').doc('cleanup').set(
            eventData(title: 'River Cleanup', category: 'Clean Up'),
          );
      await firestore.collection('events').doc('plantation').set(
            eventData(title: 'Tree Plantation', category: 'Plantation'),
          );

      // Act
      final events = await service.getEventsStream(category: 'Plantation').first;

      // Assert
      expect(events, hasLength(1));
      expect(events.single.title, 'Tree Plantation');
    });

    test('search query matches event title words case-insensitively', () async {
      // Arrange
      await firestore.collection('events').doc('river').set(
            eventData(title: 'River Cleanup Drive', location: 'Patan'),
          );
      await firestore.collection('events').doc('trees').set(
            eventData(title: 'Tree Plantation', location: 'Bhaktapur'),
          );

      // Act
      final events = await service.getEventsStream(searchQuery: 'cleanup').first;

      // Assert
      expect(events, hasLength(1));
      expect(events.single.id, 'river');
    });

    test('search query matches location and formatted address', () async {
      // Arrange
      await firestore.collection('events').doc('patan').set(
            eventData(title: 'Food Donation', location: 'Patan Durbar Square'),
          );
      await firestore.collection('events').doc('ktm').set(
            eventData(title: 'Food Donation', location: 'Balaju'),
          );

      // Act
      final events = await service.getEventsStream(searchQuery: 'durbar').first;

      // Assert
      expect(events, hasLength(1));
      expect(events.single.id, 'patan');
    });

    test('empty results are returned when no approved event matches filters', () async {
      // Arrange
      await firestore.collection('events').doc('event-1').set(
            eventData(title: 'River Cleanup', category: 'Clean Up'),
          );

      // Act
      final events = await service
          .getEventsStream(category: 'Donation', searchQuery: 'hospital')
          .first;

      // Assert
      expect(events, isEmpty);
    });

    test('Haversine distance calculation is accurate for Kathmandu to Lalitpur', () {
      // Arrange
      const kathmanduLat = 27.7172;
      const kathmanduLon = 85.3240;
      const lalitpurLat = 27.6588;
      const lalitpurLon = 85.3247;

      // Act
      final distance = LocationUtils.haversineDistanceKm(
        startLatitude: kathmanduLat,
        startLongitude: kathmanduLon,
        endLatitude: lalitpurLat,
        endLongitude: lalitpurLon,
      );

      // Assert
      expect(distance, closeTo(6.5, 0.4));
    });

    test('nearest/latest sorting comparator places nearest event first, then latest', () {
      // Arrange
      final nearOlder = Event.fromMap(
        'near-older',
        eventData(
          title: 'Near Older',
          latitude: 27.7173,
          longitude: 85.3241,
          eventDate: DateTime(2026, 5, 22),
        ),
      );
      final farLatest = Event.fromMap(
        'far-latest',
        eventData(
          title: 'Far Latest',
          latitude: 27.6588,
          longitude: 85.3247,
          eventDate: DateTime(2026, 5, 24),
        ),
      );

      final events = [farLatest, nearOlder];

      // Act
      events.sort((a, b) {
        final distanceA = LocationUtils.haversineDistanceKm(
          startLatitude: 27.7172,
          startLongitude: 85.3240,
          endLatitude: a.latitude!,
          endLongitude: a.longitude!,
        );
        final distanceB = LocationUtils.haversineDistanceKm(
          startLatitude: 27.7172,
          startLongitude: 85.3240,
          endLatitude: b.latitude!,
          endLongitude: b.longitude!,
        );
        final distanceCompare = distanceA.compareTo(distanceB);
        return distanceCompare != 0
            ? distanceCompare
            : b.eventDate.compareTo(a.eventDate);
      });

      // Assert
      expect(events.first.id, 'near-older');
      expect(events.last.id, 'far-latest');
    });
  });
}
