import 'dart:convert';

class AttendanceQrPayload {
  final String eventId;
  final int expiresAtEpochSeconds;

  const AttendanceQrPayload({
    required this.eventId,
    required this.expiresAtEpochSeconds,
  });

  DateTime get expiresAt =>
      DateTime.fromMillisecondsSinceEpoch(expiresAtEpochSeconds * 1000);

  bool get isExpired =>
      DateTime.now().isAfter(
        DateTime.fromMillisecondsSinceEpoch(expiresAtEpochSeconds * 1000),
      );

  String encode() {
    return jsonEncode({
      'type': 'attendance_qr',
      'e': eventId,
      'x': expiresAtEpochSeconds,
    });
  }

  static AttendanceQrPayload? tryParse(String raw) {
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) {
        return null;
      }
      if (decoded['type'] != 'attendance_qr') {
        return null;
      }
      final eventId = decoded['e'] as String?;
      final expiresAtEpochSeconds = decoded['x'];
      if (eventId == null || expiresAtEpochSeconds is! int) {
        return null;
      }
      return AttendanceQrPayload(
        eventId: eventId,
        expiresAtEpochSeconds: expiresAtEpochSeconds,
      );
    } catch (_) {
      return null;
    }
  }
}
