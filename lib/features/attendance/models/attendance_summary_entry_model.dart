import 'attendance_record_model.dart';

class AttendanceSummaryEntry {
  final AttendanceRecord record;
  final String volunteerName;
  final String volunteerPhotoUrl;

  AttendanceSummaryEntry({
    required this.record,
    required this.volunteerName,
    required this.volunteerPhotoUrl,
  });
}
