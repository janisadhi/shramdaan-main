import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:mocktail/mocktail.dart';
import 'package:myapp/features/chat/models/chat_message_model.dart';
import 'package:myapp/shared/services/firestore_service.dart';

class MockFirebaseAuth extends Mock implements FirebaseAuth {}

class MockUserCredential extends Mock implements UserCredential {}

class MockUser extends Mock implements User {}

class MockFirebaseStorage extends Mock implements FirebaseStorage {}

FakeFirebaseFirestore fakeFirestore() => FakeFirebaseFirestore();

FirestoreService firestoreService(FakeFirebaseFirestore firestore) {
  return FirestoreService(
    firestore: firestore,
    storage: MockFirebaseStorage(),
  );
}

DateTime testNow() => DateTime(2026, 5, 21, 10);

Map<String, dynamic> eventData({
  String title = 'River Cleanup',
  String description = 'Clean the river bank.',
  String location = 'Kathmandu',
  String formattedAddress = 'Thapathali, Kathmandu, Nepal',
  double latitude = 27.693,
  double longitude = 85.315,
  DateTime? eventDate,
  String category = 'Clean Up',
  String organizerId = 'organizer-1',
  String organizerName = 'Organizer One',
  String imageUrl = 'https://example.com/event.jpg',
  String status = 'approved',
  bool isFeatured = false,
  DateTime? endedAt,
}) {
  return {
    'title': title,
    'title_lowercase': title.toLowerCase(),
    'description': description,
    'location': location,
    'formattedAddress': formattedAddress,
    'latitude': latitude,
    'longitude': longitude,
    'eventDate': Timestamp.fromDate(eventDate ?? testNow().add(const Duration(days: 1))),
    'category': category,
    'organizerId': organizerId,
    'organizerName': organizerName,
    'imageUrl': imageUrl,
    'thingsToCarry': const ['Gloves'],
    'thingsProvided': const ['Water'],
    'status': status,
    'rejectionReason': null,
    'isFeatured': isFeatured,
    if (endedAt != null) 'endedAt': Timestamp.fromDate(endedAt),
  };
}

Map<String, dynamic> userData({
  String uid = 'user-1',
  String displayName = 'Volunteer One',
  String email = 'volunteer@example.com',
  String role = 'volunteer',
  bool isBanned = false,
  String photoUrl = '',
}) {
  return {
    'uid': uid,
    'displayName': displayName,
    'email': email,
    'role': role,
    'isBanned': isBanned,
    'photoUrl': photoUrl,
    'createdAt': Timestamp.fromDate(DateTime(2026, 1)),
  };
}

Map<String, dynamic> attendanceData({
  String volunteerId = 'user-1',
  String eventId = 'event-1',
  DateTime? checkInTime,
  DateTime? checkOutTime,
}) {
  final checkIn = checkInTime ?? DateTime(2026, 5, 21, 9);
  return {
    'volunteer_id': volunteerId,
    'event_id': eventId,
    'attendance_date': Timestamp.fromDate(DateTime(checkIn.year, checkIn.month, checkIn.day)),
    'check_in_time': Timestamp.fromDate(checkIn),
    'check_out_time': checkOutTime == null ? null : Timestamp.fromDate(checkOutTime),
    'updated_at': Timestamp.fromDate(checkIn),
  };
}

ChatMessage chatMessage({
  String senderId = 'user-1',
  String senderName = 'Volunteer One',
  String text = 'I am on my way.',
  DateTime? sentAt,
}) {
  return ChatMessage(
    senderId: senderId,
    senderName: senderName,
    text: text,
    timestamp: Timestamp.fromDate(sentAt ?? DateTime(2026, 5, 21, 8)),
  );
}
