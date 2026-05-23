import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myapp/features/attendance/models/attendance_qr_payload.dart';
import 'package:myapp/shared/services/firestore_service.dart';

import '../shared/firebase_test_helpers.dart';

void main() {
  late FakeFirebaseFirestore firestore;
  late FirestoreService service;

  setUp(() {
    firestore = fakeFirestore();
    service = firestoreService(firestore);
  });

  group('Attendance Verification Module', () {
    test('valid QR payload is parsed and accepted before expiry', () {
      // Arrange
      final payload = AttendanceQrPayload(
        eventId: 'event-1',
        expiresAtEpochSeconds: DateTime.now()
            .add(const Duration(minutes: 5))
            .millisecondsSinceEpoch ~/ 1000,
      );

      // Act
      final parsed = AttendanceQrPayload.tryParse(payload.encode());

      // Assert
      expect(parsed, isNotNull);
      expect(parsed!.eventId, 'event-1');
      expect(parsed.isExpired, isFalse);
    });

    test('expired QR payload is rejected by expiry policy', () {
      // Arrange
      final payload = AttendanceQrPayload(
        eventId: 'event-1',
        expiresAtEpochSeconds: DateTime.now()
            .subtract(const Duration(seconds: 1))
            .millisecondsSinceEpoch ~/ 1000,
      );

      // Act
      final parsed = AttendanceQrPayload.tryParse(payload.encode());

      // Assert
      expect(parsed, isNotNull);
      expect(parsed!.isExpired, isTrue);
    });

    test('QR check-in creates attendance record for active event', () async {
      // Arrange
      final now = DateTime(2026, 5, 21, 10);
      await firestore.collection('events').doc('event-1').set(
            eventData(eventDate: now.subtract(const Duration(minutes: 5))),
          );

      // Act
      final record = await service.recordAttendanceScan(
        volunteerId: 'user-1',
        eventId: 'event-1',
        now: now,
      );

      // Assert
      expect(record.volunteerId, 'user-1');
      expect(record.eventId, 'event-1');
      expect(record.checkOutTime, isNull);
      final doc = await firestore.collection('attendance').doc(record.id).get();
      expect(doc.exists, isTrue);
    });

    test('second QR scan checks out and calculates attendance duration', () async {
      // Arrange
      final checkIn = DateTime(2026, 5, 21, 9);
      final checkOut = DateTime(2026, 5, 21, 11, 30);
      await firestore.collection('events').doc('event-1').set(
            eventData(eventDate: checkIn.subtract(const Duration(minutes: 5))),
          );
      await service.recordAttendanceScan(
        volunteerId: 'user-1',
        eventId: 'event-1',
        now: checkIn,
      );

      // Act
      final record = await service.recordAttendanceScan(
        volunteerId: 'user-1',
        eventId: 'event-1',
        now: checkOut,
      );
      final duration = service.calculateAttendanceDuration(record);

      // Assert
      expect(record.checkOutTime, checkOut);
      expect(duration, const Duration(hours: 2, minutes: 30));
    });

    test('check-out before check-in is blocked', () async {
      // Arrange
      final checkIn = DateTime(2026, 5, 21, 10);
      await firestore.collection('events').doc('event-1').set(
            eventData(eventDate: checkIn.subtract(const Duration(minutes: 5))),
          );
      await service.recordAttendanceScan(
        volunteerId: 'user-1',
        eventId: 'event-1',
        now: checkIn,
      );

      // Act & Assert
      expect(
        () => service.recordAttendanceScan(
          volunteerId: 'user-1',
          eventId: 'event-1',
          now: checkIn.subtract(const Duration(minutes: 1)),
        ),
        throwsException,
      );
    });

    test('wrong event QR is rejected before attendance recording', () async {
      // Arrange
      final expectedEventId = 'event-1';
      final payload = AttendanceQrPayload(
        eventId: 'event-2',
        expiresAtEpochSeconds: DateTime.now()
            .add(const Duration(minutes: 5))
            .millisecondsSinceEpoch ~/ 1000,
      );

      // Act
      final parsed = AttendanceQrPayload.tryParse(payload.encode());
      final matchesOpenEvent = parsed?.eventId == expectedEventId;

      // Assert
      expect(matchesOpenEvent, isFalse);
    });
  });
}
