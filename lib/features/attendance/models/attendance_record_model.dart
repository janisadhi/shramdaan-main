import 'package:cloud_firestore/cloud_firestore.dart';

class AttendanceRecord {
  final String id;
  final String volunteerId;
  final String eventId;
  final DateTime attendanceDate;
  final DateTime checkInTime;
  final DateTime? checkOutTime;

  AttendanceRecord({
    required this.id,
    required this.volunteerId,
    required this.eventId,
    required this.attendanceDate,
    required this.checkInTime,
    required this.checkOutTime,
  });

  Duration? get totalDuration {
    if (checkOutTime == null) {
      return null;
    }
    return checkOutTime!.difference(checkInTime);
  }

  factory AttendanceRecord.fromMap(String id, Map<String, dynamic> data) {
    return AttendanceRecord(
      id: id,
      volunteerId: data['volunteer_id'] as String? ?? '',
      eventId: data['event_id'] as String? ?? '',
      attendanceDate: _toDateTime(data['attendance_date']) ?? DateTime.now(),
      checkInTime: _toDateTime(data['check_in_time']) ?? DateTime.now(),
      checkOutTime: _toDateTime(data['check_out_time']),
    );
  }

  static DateTime? _toDateTime(dynamic value) {
    if (value is Timestamp) {
      return value.toDate();
    }
    if (value is DateTime) {
      return value;
    }
    return null;
  }
}
