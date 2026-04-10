import 'package:cloud_firestore/cloud_firestore.dart';

class Event {
  final String id;
  final String title;
  final String description;
  final String location;
  final String formattedAddress;
  final double? latitude;
  final double? longitude;
  final DateTime eventDate;
  final String category;
  final String organizerId;
  final String organizerName;
  final String imageUrl;
  final List<String> thingsToCarry;
  final List<String> thingsProvided;
  final String status;
  final String? rejectionReason;
  final bool isFeatured;
  final DateTime? endedAt;

  Event({
    required this.id,
    required this.title,
    required this.description,
    required this.location,
    required this.formattedAddress,
    required this.latitude,
    required this.longitude,
    required this.eventDate,
    required this.category,
    required this.organizerId,
    required this.organizerName,
    required this.imageUrl,
    required this.thingsToCarry,
    required this.thingsProvided,
    required this.status,
    required this.rejectionReason,
    required this.isFeatured,
    required this.endedAt,
  });

  bool get hasCoordinates => latitude != null && longitude != null;
  bool get hasStarted => !DateTime.now().isBefore(eventDate);
  bool get isCompleted => endedAt != null || status == 'archived';
  bool get isRsvpOpen => !isCompleted && DateTime.now().isBefore(eventDate.subtract(const Duration(hours: 1)));
  bool get isAttendanceOpen => hasStarted && !isCompleted;

  String get organizerDisplayName {
    final trimmed = organizerName.trim();
    if (trimmed.isEmpty) {
      return 'Organizer';
    }

    if (!trimmed.contains('@')) {
      return trimmed;
    }

    final localPart = trimmed.split('@').first.trim();
    if (localPart.isEmpty) {
      return 'Organizer';
    }

    final normalized = localPart
        .replaceAll(RegExp(r'[._-]+'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();

    if (normalized.isEmpty) {
      return 'Organizer';
    }

    return normalized
        .split(' ')
        .map((part) => part.isEmpty
            ? part
            : '${part[0].toUpperCase()}${part.substring(1)}')
        .join(' ');
  }

  factory Event.fromMap(String id, Map<String, dynamic> data) {
    DateTime eventDateTime;
    final coordinatePoint =
        data['coordinates'] is GeoPoint ? data['coordinates'] as GeoPoint : null;

    if (data['eventDate'] is Timestamp) {
      eventDateTime = (data['eventDate'] as Timestamp).toDate();
    } else {
      print(
        "Warning: 'eventDate' field was missing or not a Timestamp for document $id. Using fallback date.",
      );
      eventDateTime = DateTime.now();
    }

    return Event(
      id: id,
      title: data['title'] ?? 'No Title',
      description: data['description'] ?? 'No Description',
      location: data['location'] ?? 'No Location',
      formattedAddress:
          data['formattedAddress'] ?? data['location'] ?? 'No Location',
      latitude: _toDouble(data['latitude']) ?? coordinatePoint?.latitude,
      longitude: _toDouble(data['longitude']) ?? coordinatePoint?.longitude,
      eventDate: eventDateTime,
      category: data['category'] ?? 'General',
      organizerId: data['organizerId'] ?? '',
      organizerName: data['organizerName'] ?? '',
      imageUrl: data['imageUrl'] ?? '',
      thingsToCarry: List<String>.from(data['thingsToCarry'] ?? []),
      thingsProvided: List<String>.from(data['thingsProvided'] ?? []),
      status: data['status'] ?? 'pending',
      rejectionReason: data['rejectionReason'] as String?,
      isFeatured: data['isFeatured'] ?? false,
      endedAt: data['endedAt'] is Timestamp ? (data['endedAt'] as Timestamp).toDate() : null,
    );
  }

  static double? _toDouble(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }
    if (value is String) {
      return double.tryParse(value.trim());
    }
    return null;
  }
}
