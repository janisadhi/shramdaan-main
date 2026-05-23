import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myapp/features/attendance/models/attendance_record_model.dart';
import 'package:myapp/shared/models/event_model.dart';

import 'firebase_test_helpers.dart';

void main() {
  group('Shared Model Parsing', () {
    test('event falls back safely when optional fields are missing', () {
      // Arrange
      final data = {
        'title': 'Minimal Event',
        'eventDate': Timestamp.fromDate(DateTime(2026, 5, 22)),
      };

      // Act
      final event = Event.fromMap('event-1', data);

      // Assert
      expect(event.id, 'event-1');
      expect(event.title, 'Minimal Event');
      expect(event.category, 'General');
      expect(event.status, 'pending');
      expect(event.hasCoordinates, isFalse);
    });

    test('event organizer display name normalizes email fallback', () {
      // Arrange
      final event = Event.fromMap(
        'event-1',
        eventData(organizerName: 'organizer.one@example.com'),
      );

      // Act & Assert
      expect(event.organizerDisplayName, 'Organizer One');
    });

    test('attendance record duration is null before checkout and populated after checkout', () {
      // Arrange
      final withoutCheckout = AttendanceRecord.fromMap(
        'record-1',
        attendanceData(checkOutTime: null),
      );
      final withCheckout = AttendanceRecord.fromMap(
        'record-2',
        attendanceData(
          checkInTime: DateTime(2026, 5, 21, 9),
          checkOutTime: DateTime(2026, 5, 21, 10, 15),
        ),
      );

      // Act & Assert
      expect(withoutCheckout.totalDuration, isNull);
      expect(withCheckout.totalDuration, const Duration(hours: 1, minutes: 15));
    });
  });
}
