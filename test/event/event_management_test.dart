import 'dart:typed_data';

import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myapp/shared/services/firestore_service.dart';
import 'package:myapp/shared/utils/location_utils.dart';

import '../shared/firebase_test_helpers.dart';

void main() {
  late FakeFirebaseFirestore firestore;
  late FirestoreService service;

  setUp(() {
    firestore = fakeFirestore();
    service = FirestoreService(firestore: firestore);
  });

  group('Event Management Module', () {
    test('create event stores required event data with pending lifecycle status', () async {
      // Arrange
      final eventDate = DateTime(2026, 5, 25, 9);

      // Act
      await service.addEvent(
        title: 'Park Cleanup',
        description: 'Clean the local park.',
        location: 'Patan',
        formattedAddress: 'Patan, Lalitpur, Nepal',
        latitude: 27.6588,
        longitude: 85.3247,
        eventDate: eventDate,
        category: 'Clean Up',
        organizerId: 'organizer-1',
        organizerName: 'Organizer One',
        imageUrl: 'https://example.com/park.jpg',
        thingsToCarry: const ['Gloves'],
        thingsProvided: const ['Water'],
      );

      // Assert
      final snapshot = await firestore.collection('events').get();
      expect(snapshot.docs, hasLength(1));
      final data = snapshot.docs.single.data();
      expect(data['title'], 'Park Cleanup');
      expect(data['status'], 'pending');
      expect(data['isFeatured'], isFalse);
      expect(data['rejectionReason'], isNull);
    });

    test('edit event updates mutable fields and maintains lowercase search field', () async {
      // Arrange
      await firestore.collection('events').doc('event-1').set(
            eventData(title: 'Old Title', imageUrl: ''),
          );

      // Act
      await service.updateEvent('event-1', {
        'title': 'New Community Cleanup',
        'category': 'Clean Up',
      });

      // Assert
      final doc = await firestore.collection('events').doc('event-1').get();
      expect(doc.data()?['title'], 'New Community Cleanup');
      expect(doc.data()?['title_lowercase'], 'new community cleanup');
    });

    test('completed event cannot be edited', () async {
      // Arrange
      await firestore.collection('events').doc('event-1').set(
            eventData(
              title: 'Completed Event',
              endedAt: DateTime(2026, 5, 20),
            ),
          );

      // Act
      await service.updateEvent('event-1', {'title': 'Should Not Change'});

      // Assert
      final doc = await firestore.collection('events').doc('event-1').get();
      expect(doc.data()?['title'], 'Completed Event');
    });

    test('image upload returns download URL when Firebase Storage succeeds', () async {
      // Arrange
      const downloadUrl = 'https://storage.example.com/event.jpg';
      final uploadService = FirestoreService(
        firestore: firestore,
        uploadHandler: ({
          required imageBytes,
          required path,
          required fileName,
        }) async {
          expect(path, startsWith('event_images/event-'));
          expect(fileName, 'event.png');
          expect(imageBytes, isNotEmpty);
          return downloadUrl;
        },
      );

      // Act
      final result = await uploadService.uploadImage(
        imageBytes: Uint8List.fromList([1, 2, 3]),
        fileName: 'event.png',
      );

      // Assert
      expect(result, downloadUrl);
    });

    test('image upload returns null when Firebase Storage fails', () async {
      // Arrange
      final uploadService = FirestoreService(
        firestore: firestore,
        uploadHandler: ({
          required imageBytes,
          required path,
          required fileName,
        }) async {
          throw FirebaseException(
            plugin: 'firebase_storage',
            code: 'unauthorized',
          );
        },
      );

      // Act
      final result = await uploadService.uploadImage(
        imageBytes: Uint8List.fromList([1, 2, 3]),
        fileName: 'event.png',
      );

      // Assert
      expect(result, isNull);
    });

    test('geocoding search result object carries selected coordinates', () {
      // Arrange
      const result = LocationSearchResult(
        latitude: 27.7172,
        longitude: 85.3240,
        label: 'Kathmandu, Nepal',
      );

      // Act & Assert
      expect(result.latitude, 27.7172);
      expect(result.longitude, 85.3240);
      expect(result.label, contains('Kathmandu'));
    });
  });
}
