// ignore_for_file: avoid_print

import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';

import '../../features/admin/models/admin_analytics_model.dart';
import '../../features/admin/models/admin_broadcast_model.dart';
import '../../features/admin/models/admin_user_model.dart';
import '../../features/attendance/models/event_participant_entry_model.dart';
import '../../features/attendance/models/attendance_record_model.dart';
import '../../features/attendance/models/attendance_summary_entry_model.dart';
import '../../features/chat/models/chat_list_entry_model.dart';
import '../../features/chat/models/chat_message_model.dart';
import '../../features/leaderboard/models/achievement_badge_model.dart';
import '../../features/leaderboard/models/leaderboard_entry_model.dart';
import '../../features/notifications/models/app_notification_model.dart';
import '../models/event_model.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  Stream<List<Event>> getEventsStream({String? category, String? searchQuery}) {
    Query query = _db.collection('events').where('status', isEqualTo: 'approved');

    if (category != null && category != 'All') {
      query = query.where('category', isEqualTo: category);
    }

    return query.snapshots().map((snapshot) {
      final events = snapshot.docs
          .map((doc) => Event.fromMap(doc.id, doc.data() as Map<String, dynamic>))
          .toList();
      final normalizedQuery = searchQuery?.trim().toLowerCase() ?? '';
      final filteredEvents = normalizedQuery.isEmpty
          ? events
          : events.where((event) {
              final title = event.title.toLowerCase();
              final location = event.location.toLowerCase();
              final address = event.formattedAddress.toLowerCase();
              final titleWords = title
                  .split(RegExp(r'[^a-z0-9]+'))
                  .where((word) => word.isNotEmpty)
                  .toList();

              final queryWords = normalizedQuery
                  .split(RegExp(r'\s+'))
                  .where((word) => word.isNotEmpty)
                  .toList();

              final locationMatches = location.contains(normalizedQuery) ||
                  address.contains(normalizedQuery);

              final titleMatches = title.contains(normalizedQuery) ||
                  queryWords.any(
                    (queryWord) => titleWords.any(
                      (titleWord) =>
                          titleWord.contains(queryWord) ||
                          queryWord.contains(titleWord),
                    ),
                  );

              return titleMatches || locationMatches;
            }).toList();
      filteredEvents.sort((a, b) => a.eventDate.compareTo(b.eventDate));
      return filteredEvents;
    });
  }

  Stream<List<Event>> getFeaturedEventsStream() {
    return _db
        .collection('events')
        .where('status', isEqualTo: 'approved')
        .where('isFeatured', isEqualTo: true)
        .snapshots()
        .map((snapshot) {
      final events = snapshot.docs
          .map((doc) => Event.fromMap(doc.id, doc.data()))
          .toList();
      events.sort((a, b) => a.eventDate.compareTo(b.eventDate));
      return events.take(3).toList();
    });
  }

  Future<void> addEvent({
    required String title,
    required String description,
    required String location,
    required String formattedAddress,
    required double latitude,
    required double longitude,
    required DateTime eventDate,
    required String category,
    required String organizerId,
    required String organizerName,
    required String imageUrl,
    required List<String> thingsToCarry,
    required List<String> thingsProvided,
  }) async {
    try {
      await _db.collection('events').add({
        'title': title,
        'title_lowercase': title.toLowerCase(),
        'description': description,
        'location': location,
        'formattedAddress': formattedAddress,
        'latitude': latitude,
        'longitude': longitude,
        'eventDate': Timestamp.fromDate(eventDate),
        'category': category,
        'organizerId': organizerId,
        'organizerName': organizerName,
        'imageUrl': imageUrl,
        'thingsToCarry': thingsToCarry,
        'thingsProvided': thingsProvided,
        'status': 'pending',
        'reviewRequestedAt': FieldValue.serverTimestamp(),
        'rejectionReason': null,
        'isFeatured': false,
      });
      print('Event added successfully! Awaiting approval.');
    } catch (e) {
      print('Error adding event: $e');
    }
  }

  Future<void> updateEvent(String eventId, Map<String, dynamic> data) async {
    try {
      final existingDoc = await _db.collection('events').doc(eventId).get();
      final existingData = existingDoc.data();
      final previousImageUrl = (existingData?['imageUrl'] as String?)?.trim() ?? '';

      if (data['eventDate'] is DateTime) {
        data['eventDate'] = Timestamp.fromDate(data['eventDate']);
      }
      if (data.containsKey('title')) {
        data['title_lowercase'] = (data['title'] as String).toLowerCase();
      }
      if (data['status'] == 'pending') {
        data['reviewRequestedAt'] = FieldValue.serverTimestamp();
      }

      await _db.collection('events').doc(eventId).update(data);

      final nextImageUrl = (data['imageUrl'] as String?)?.trim() ?? previousImageUrl;
      if (nextImageUrl.isNotEmpty &&
          previousImageUrl.isNotEmpty &&
          nextImageUrl != previousImageUrl) {
        await _deleteStorageFileByUrl(previousImageUrl);
      }
      print('Event updated successfully!');
    } catch (e) {
      print('Error updating event: $e');
    }
  }

  Stream<Event?> getEventStream(String eventId) {
    return _db
        .collection('events')
        .doc(eventId)
        .snapshots()
        .map((snapshot) {
      final data = snapshot.data();
      if (!snapshot.exists || data == null) {
        return null;
      }
      return Event.fromMap(snapshot.id, data);
    });
  }

  Future<String?> uploadImage({
    required Uint8List imageBytes,
    required String fileName,
  }) async {
    try {
      final path = 'event_images/${_buildSafeImageFileName(fileName)}';
      final storageRef = _storage.ref().child(path);
      final uploadTask = storageRef.putData(
        imageBytes,
        SettableMetadata(contentType: _guessImageContentType(fileName)),
      );
      final snapshot = await uploadTask;
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      print('Error uploading image: $e');
      return null;
    }
  }

  Future<void> deleteEvent(String eventId) async {
    try {
      final eventDoc = await _db.collection('events').doc(eventId).get();
      final imageUrl = (eventDoc.data()?['imageUrl'] as String?)?.trim() ?? '';
      await _db.collection('events').doc(eventId).delete();
      if (imageUrl.isNotEmpty) {
        await _deleteStorageFileByUrl(imageUrl);
      }
      print('Event deleted successfully!');
    } catch (e) {
      print('Error deleting event: $e');
    }
  }

  Future<void> joinEvent(String eventId, String userId) async {
    try {
      final event = await getEventById(eventId);
      if (event == null || !event.isRsvpOpen) {
        throw Exception('RSVP is closed for this event.');
      }
      final docId = '$userId-$eventId';
      await _db.collection('rsvps').doc(docId).set({
        'eventId': eventId,
        'userId': userId,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error joining event: $e');
    }
  }

  Future<void> leaveEvent(String eventId, String userId) async {
    try {
      final docId = '$userId-$eventId';
      await _db.collection('rsvps').doc(docId).delete();
    } catch (e) {
      print('Error leaving event: $e');
    }
  }

  Stream<bool> hasUserJoined(String eventId, String userId) {
    final docId = '$userId-$eventId';
    return _db.collection('rsvps').doc(docId).snapshots().map((snapshot) => snapshot.exists);
  }

  Future<void> endEvent(String eventId) async {
    try {
      await _db.collection('events').doc(eventId).update({
        'endedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error ending event: $e');
    }
  }

  Future<AttendanceRecord?> getAttendanceRecordForToday({
    required String volunteerId,
    required String eventId,
    DateTime? now,
  }) async {
    final currentTime = now ?? DateTime.now();
    final recordId = _attendanceRecordId(
      volunteerId: volunteerId,
      eventId: eventId,
      date: currentTime,
    );

    final snapshot = await _db.collection('attendance').doc(recordId).get();
    final data = snapshot.data();
    if (!snapshot.exists || data == null) {
      return null;
    }
    return AttendanceRecord.fromMap(snapshot.id, data);
  }

  Future<AttendanceRecord> recordAttendanceScan({
    required String volunteerId,
    required String eventId,
    DateTime? now,
  }) async {
    final currentTime = now ?? DateTime.now();
    final event = await getEventById(eventId);
    if (event == null || !event.isAttendanceOpen) {
      throw Exception('Attendance scanning is unavailable for this event.');
    }
    final dayStart = DateTime(currentTime.year, currentTime.month, currentTime.day);
    final recordId = _attendanceRecordId(
      volunteerId: volunteerId,
      eventId: eventId,
      date: currentTime,
    );
    final recordRef = _db.collection('attendance').doc(recordId);
    final existingSnapshot = await recordRef.get();
    final existingData = existingSnapshot.data();

    if (!existingSnapshot.exists || existingData == null) {
      final createdData = {
        'volunteer_id': volunteerId,
        'event_id': eventId,
        'attendance_date': Timestamp.fromDate(dayStart),
        'check_in_time': Timestamp.fromDate(currentTime),
        'check_out_time': null,
        'updated_at': FieldValue.serverTimestamp(),
      };
      await recordRef.set(createdData);
      return AttendanceRecord.fromMap(recordId, createdData);
    }

    await recordRef.update({
      'check_out_time': Timestamp.fromDate(currentTime),
      'updated_at': FieldValue.serverTimestamp(),
    });

    return AttendanceRecord.fromMap(recordId, {
      ...existingData,
      'check_out_time': Timestamp.fromDate(currentTime),
    });
  }

  Duration? calculateAttendanceDuration(AttendanceRecord record) {
    return record.totalDuration;
  }

  Stream<List<AttendanceSummaryEntry>> getEventAttendanceStream(String eventId) {
    return _db
        .collection('attendance')
        .where('event_id', isEqualTo: eventId)
        .snapshots()
        .asyncMap((snapshot) async {
      if (snapshot.docs.isEmpty) {
        return <AttendanceSummaryEntry>[];
      }

      final records = snapshot.docs
          .map((doc) => AttendanceRecord.fromMap(doc.id, doc.data()))
          .toList()
        ..sort((a, b) => b.checkInTime.compareTo(a.checkInTime));

      final volunteerIds = records.map((record) => record.volunteerId).toSet().toList();
      final userSnapshots = await Future.wait(
        volunteerIds.map((userId) => _db.collection('users').doc(userId).get()),
      );

      final usersById = <String, Map<String, dynamic>>{};
      for (final snapshot in userSnapshots) {
        final data = snapshot.data();
        if (snapshot.exists && data != null) {
          usersById[snapshot.id] = data;
        }
      }

      return records.map((record) {
        final userData = usersById[record.volunteerId];
        return AttendanceSummaryEntry(
          record: record,
          volunteerName: userData?['displayName'] as String? ?? 'Volunteer',
          volunteerPhotoUrl: userData?['photoUrl'] as String? ?? '',
        );
      }).toList();
    });
  }

  Stream<List<EventParticipantEntry>> getEventParticipantsStream(String eventId) {
    return _db
        .collection('rsvps')
        .where('eventId', isEqualTo: eventId)
        .snapshots()
        .asyncMap((snapshot) async {
      if (snapshot.docs.isEmpty) {
        return <EventParticipantEntry>[];
      }

      final userIds = snapshot.docs
          .map((doc) => doc.data()['userId'] as String)
          .toSet()
          .toList();

      final userSnapshots = await Future.wait(
        userIds.map((userId) => _db.collection('users').doc(userId).get()),
      );

      final entries = <EventParticipantEntry>[];
      for (final userSnapshot in userSnapshots) {
        final data = userSnapshot.data();
        if (!userSnapshot.exists || data == null) {
          continue;
        }
        entries.add(
          EventParticipantEntry(
            userId: userSnapshot.id,
            userName: data['displayName'] as String? ?? 'Volunteer',
            photoUrl: data['photoUrl'] as String? ?? '',
          ),
        );
      }

      entries.sort((a, b) => a.userName.toLowerCase().compareTo(b.userName.toLowerCase()));
      return entries;
        });
  }

  Stream<int> getEventParticipantCountStream(String eventId) {
    return _db
        .collection('rsvps')
        .where('eventId', isEqualTo: eventId)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  Future<List<LeaderboardEntry>> getLeaderboardData({DateTime? fromDate}) async {
    try {
      final attendanceSnapshot = await _db.collection('attendance').get();
      if (attendanceSnapshot.docs.isEmpty) {
        return [];
      }

      final pointsByUser = <String, int>{};
      final attendedEventsByUser = <String, int>{};
      final verifiedMinutesByUser = <String, int>{};

      for (final doc in attendanceSnapshot.docs) {
        final record = AttendanceRecord.fromMap(doc.id, doc.data());
        if (record.volunteerId.isEmpty) {
          continue;
        }
        if (fromDate != null && record.checkInTime.isBefore(fromDate)) {
          continue;
        }

        final verifiedMinutes = record.totalDuration?.inMinutes ?? 0;
        final points = 10 + (verifiedMinutes ~/ 15);

        pointsByUser[record.volunteerId] =
            (pointsByUser[record.volunteerId] ?? 0) + points;
        attendedEventsByUser[record.volunteerId] =
            (attendedEventsByUser[record.volunteerId] ?? 0) + 1;
        verifiedMinutesByUser[record.volunteerId] =
            (verifiedMinutesByUser[record.volunteerId] ?? 0) + verifiedMinutes;
      }

      if (pointsByUser.isEmpty) {
        return [];
      }

      final usersSnapshot = await Future.wait(
        pointsByUser.keys.map((userId) => _db.collection('users').doc(userId).get()),
      );
      final usersMap = <String, Map<String, dynamic>>{};
      for (final doc in usersSnapshot) {
        final data = doc.data();
        if (doc.exists && data != null) {
          usersMap[doc.id] = data;
        }
      }

      final leaderboard = <LeaderboardEntry>[];
      pointsByUser.forEach((userId, totalPoints) {
        if (usersMap.containsKey(userId)) {
          leaderboard.add(
            LeaderboardEntry(
              userId: userId,
              userName: usersMap[userId]!['displayName'] ?? 'Anonymous',
              photoUrl: usersMap[userId]!['photoUrl'] ?? '',
              totalPoints: totalPoints,
              attendedEvents: attendedEventsByUser[userId] ?? 0,
              verifiedMinutes: verifiedMinutesByUser[userId] ?? 0,
              achievements: _buildAchievementBadges(
                totalPoints: totalPoints,
                attendedEvents: attendedEventsByUser[userId] ?? 0,
                verifiedMinutes: verifiedMinutesByUser[userId] ?? 0,
              ),
            ),
          );
        }
      });
      leaderboard.sort((a, b) {
        final pointsCompare = b.totalPoints.compareTo(a.totalPoints);
        if (pointsCompare != 0) {
          return pointsCompare;
        }

        final minutesCompare = b.verifiedMinutes.compareTo(a.verifiedMinutes);
        if (minutesCompare != 0) {
          return minutesCompare;
        }

        return b.attendedEvents.compareTo(a.attendedEvents);
      });
      return leaderboard;
    } catch (e) {
      print('Error getting leaderboard data: $e');
      return [];
    }
  }

  Future<List<AchievementBadge>> getUserAchievementBadges(String userId) async {
    try {
      final attendanceSnapshot = await _db
          .collection('attendance')
          .where('volunteer_id', isEqualTo: userId)
          .get();

      if (attendanceSnapshot.docs.isEmpty) {
        return const [];
      }

      var totalPoints = 0;
      var attendedEvents = 0;
      var verifiedMinutes = 0;

      for (final doc in attendanceSnapshot.docs) {
        final record = AttendanceRecord.fromMap(doc.id, doc.data());
        final recordMinutes = record.totalDuration?.inMinutes ?? 0;
        totalPoints += 10 + (recordMinutes ~/ 15);
        attendedEvents += 1;
        verifiedMinutes += recordMinutes;
      }

      return _buildAchievementBadges(
        totalPoints: totalPoints,
        attendedEvents: attendedEvents,
        verifiedMinutes: verifiedMinutes,
      );
    } catch (e) {
      print('Error getting user achievement badges: $e');
      return const [];
    }
  }

  Future<LeaderboardEntry?> getUserContributionSummary(String userId) async {
    try {
      final leaderboard = await getLeaderboardData();
      for (final entry in leaderboard) {
        if (entry.userId == userId) {
          return entry;
        }
      }
      return null;
    } catch (e) {
      print('Error getting user contribution summary: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>> getUserProfileHighlights(String userId) async {
    try {
      final joinedEventCount = await getUserEventCount(userId);
      final contribution = await getUserContributionSummary(userId);

      return {
        'joinedEventCount': joinedEventCount,
        'totalPoints': contribution?.totalPoints ?? 0,
        'verifiedMinutes': contribution?.verifiedMinutes ?? 0,
        'achievements': contribution?.achievements ?? const <AchievementBadge>[],
      };
    } catch (e) {
      print('Error getting user profile highlights: $e');
      return {
        'joinedEventCount': 0,
        'totalPoints': 0,
        'verifiedMinutes': 0,
        'achievements': const <AchievementBadge>[],
      };
    }
  }

  Future<int> getUserEventCount(String userId) async {
    try {
      final countQuery = _db.collection('rsvps').where('userId', isEqualTo: userId).count();
      final snapshot = await countQuery.get();
      return snapshot.count ?? 0;
    } catch (e) {
      print('Error getting user event count: $e');
      return 0;
    }
  }

  Stream<List<ChatMessage>> getChatMessagesStream(String eventId) {
    return _db
        .collection('events')
        .doc(eventId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => ChatMessage.fromMap(doc.data())).toList());
  }

  Future<void> sendMessage(String eventId, ChatMessage message) async {
    try {
      await _db.collection('events').doc(eventId).collection('messages').add(message.toMap());
      final participants = await _db
          .collection('rsvps')
          .where('eventId', isEqualTo: eventId)
          .get();

      final recipientIds = participants.docs
          .map((doc) => doc.data()['userId'] as String)
          .where((userId) => userId != message.senderId)
          .toSet();

      final eventDoc = await _db.collection('events').doc(eventId).get();
      final eventTitle = eventDoc.data()?['title'] ?? 'an event';

      await _db.collection('users').doc(message.senderId).collection('chatSummaries').doc(eventId).set({
        'eventId': eventId,
        'latestMessageText': message.text,
        'latestSenderName': message.senderName,
        'latestMessageAt': message.timestamp,
        'unreadCount': 0,
      }, SetOptions(merge: true));

      for (final userId in recipientIds) {
        await createNotification(
          userId: userId,
          title: 'New chat message',
          body: '${message.senderName} sent a message in $eventTitle.',
          type: 'chat_message',
          targetId: eventId,
          actorUserId: message.senderId,
        );

        await _db.collection('users').doc(userId).collection('chatSummaries').doc(eventId).set({
          'eventId': eventId,
          'latestMessageText': message.text,
          'latestSenderName': message.senderName,
          'latestMessageAt': message.timestamp,
          'unreadCount': FieldValue.increment(1),
        }, SetOptions(merge: true));
      }
    } catch (e) {
      print('Error sending message: $e');
    }
  }

  Stream<List<Event>> getJoinedEventsStream(String userId) {
    return _db
        .collection('rsvps')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .asyncMap((snapshot) async {
      if (snapshot.docs.isEmpty) return [];
      final eventIds = snapshot.docs.map((doc) => doc['eventId'] as String).toList();
      final eventDocs = await _db.collection('events').where(FieldPath.documentId, whereIn: eventIds).get();
      return eventDocs.docs.map((doc) => Event.fromMap(doc.id, doc.data())).toList();
    });
  }

  Stream<List<ChatListEntry>> getJoinedChatListStream(String userId) {
    return _db
        .collection('users')
        .doc(userId)
        .collection('chatSummaries')
        .snapshots()
        .asyncMap((summarySnapshot) async {
      final summaries = {
        for (final doc in summarySnapshot.docs) doc.id: doc.data(),
      };

      final rsvpSnapshot = await _db
          .collection('rsvps')
          .where('userId', isEqualTo: userId)
          .get();
      if (rsvpSnapshot.docs.isEmpty) {
        return <ChatListEntry>[];
      }

      final eventIds = rsvpSnapshot.docs.map((doc) => doc['eventId'] as String).toList();
      final eventDocs = await _db
          .collection('events')
          .where(FieldPath.documentId, whereIn: eventIds)
          .get();

      final entries = eventDocs.docs.map((doc) {
        final event = Event.fromMap(doc.id, doc.data());
        final summary = summaries[event.id];

        return ChatListEntry(
          event: event,
          unreadCount: summary?['unreadCount'] as int? ?? 0,
          latestMessageAt: summary?['latestMessageAt'] as Timestamp?,
          latestMessageText: summary?['latestMessageText'] as String?,
          latestSenderName: summary?['latestSenderName'] as String?,
        );
      }).toList();

      entries.sort((a, b) {
        final unreadCompare = b.unreadCount.compareTo(a.unreadCount);
        if (unreadCompare != 0) {
          return unreadCompare;
        }

        final aTime = a.latestMessageAt?.toDate() ?? a.event.eventDate;
        final bTime = b.latestMessageAt?.toDate() ?? b.event.eventDate;
        return bTime.compareTo(aTime);
      });

      return entries;
    });
  }

  Future<void> markChatSummaryRead(String userId, String eventId) async {
    await _db.collection('users').doc(userId).collection('chatSummaries').doc(eventId).set({
      'eventId': eventId,
      'unreadCount': 0,
    }, SetOptions(merge: true));
  }

  Future<void> _ensureUserInEventChat({
    required String userId,
    required String eventId,
    required DateTime eventDate,
  }) async {
    final docId = '$userId-$eventId';
    await _db.collection('rsvps').doc(docId).set({
      'eventId': eventId,
      'userId': userId,
      'timestamp': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    await _db
        .collection('users')
        .doc(userId)
        .collection('chatSummaries')
        .doc(eventId)
        .set({
      'eventId': eventId,
      'latestMessageAt': Timestamp.fromDate(eventDate),
      'unreadCount': 0,
    }, SetOptions(merge: true));
  }

  Stream<List<Event>> getCreatedEventsStream(String userId) {
    return _db
        .collection('events')
        .where('organizerId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
      final events = snapshot.docs
          .map((doc) => Event.fromMap(doc.id, doc.data()))
          .toList();
      events.sort((a, b) => b.eventDate.compareTo(a.eventDate));
      return events;
    });
  }

  Future<String?> uploadProfilePicture({
    required Uint8List imageBytes,
    required String userId,
    String fileName = 'profile.jpg',
  }) async {
    try {
      final path =
          'profile_pictures/$userId-${DateTime.now().millisecondsSinceEpoch}.${_normalizedImageExtension(fileName)}';
      final storageRef = _storage.ref().child(path);
      final uploadTask = storageRef.putData(
        imageBytes,
        SettableMetadata(contentType: _guessImageContentType(fileName)),
      );
      final snapshot = await uploadTask;
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      print('Error uploading profile picture: $e');
      return null;
    }
  }

  Future<void> updateUserPhotoUrl(String userId, String photoUrl) async {
    try {
      await _db.collection('users').doc(userId).update({'photoUrl': photoUrl});
    } catch (e) {
      print('Error updating user photo URL: $e');
    }
  }

  Future<void> updateUserProfile({
    required String userId,
    String? displayName,
    String? photoUrl,
    String? phoneNumber,
    DateTime? dob,
    String? gender,
  }) async {
    try {
      final updates = <String, dynamic>{};
      if (displayName != null) {
        updates['displayName'] = displayName;
      }
      if (photoUrl != null) {
        updates['photoUrl'] = photoUrl;
      }
      if (phoneNumber != null) {
        updates['phoneNumber'] = phoneNumber;
      }
      if (dob != null) {
        updates['dob'] = Timestamp.fromDate(dob);
      }
      if (gender != null) {
        updates['gender'] = gender;
      }
      if (updates.isEmpty) {
        return;
      }
      await _db.collection('users').doc(userId).update(updates);
    } catch (e) {
      print('Error updating user profile: $e');
    }
  }

  Future<DocumentSnapshot> getUser(String userId) {
    return _db.collection('users').doc(userId).get();
  }

  Stream<DocumentSnapshot> getUserStream(String userId) {
    return _db.collection('users').doc(userId).snapshots();
  }

  Future<Event?> getEventById(String eventId) async {
    final snapshot = await _db.collection('events').doc(eventId).get();
    final data = snapshot.data();
    if (!snapshot.exists || data == null) {
      return null;
    }
    return Event.fromMap(snapshot.id, data);
  }

  Stream<List<Event>> getPendingEventsStream() {
    return _db
        .collection('events')
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => Event.fromMap(doc.id, doc.data())).toList());
  }

  Future<void> approveEvent(String eventId) async {
    final eventDoc = await _db.collection('events').doc(eventId).get();
    final eventData = eventDoc.data();

    await _db.collection('events').doc(eventId).update({
      'status': 'approved',
      'rejectionReason': null,
    });

    if (eventData != null) {
      final organizerId = eventData['organizerId'] as String?;
      final eventTimestamp = eventData['eventDate'];
      final eventDate = eventTimestamp is Timestamp
          ? eventTimestamp.toDate()
          : DateTime.now();

      if (organizerId != null && organizerId.isNotEmpty) {
        await _ensureUserInEventChat(
          userId: organizerId,
          eventId: eventId,
          eventDate: eventDate,
        );
      }

      await createNotification(
        userId: eventData['organizerId'],
        title: 'Event approved',
        body: '${eventData['title']} is now live for volunteers to discover.',
        type: 'event_approved',
        targetId: eventId,
      );
    }
  }

  Future<void> rejectEvent(String eventId, String reason) async {
    final eventDoc = await _db.collection('events').doc(eventId).get();
    final eventData = eventDoc.data();

    await _db.collection('events').doc(eventId).update({
      'status': 'rejected',
      'rejectionReason': reason,
      'isFeatured': false,
    });

    if (eventData != null) {
      await createNotification(
        userId: eventData['organizerId'],
        title: 'Event needs changes',
        body: '${eventData['title']} was sent back for revision. Reason: $reason',
        type: 'event_rejected',
        targetId: eventId,
      );
    }
  }

  Future<void> setFeaturedStatus(String eventId, bool isFeatured) async {
    await _db.collection('events').doc(eventId).update({'isFeatured': isFeatured});
  }

  Stream<List<Event>> getApprovedEventsStream() {
    return _db
        .collection('events')
        .where('status', isEqualTo: 'approved')
        .orderBy('eventDate', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => Event.fromMap(doc.id, doc.data())).toList());
  }

  Stream<List<Event>> getRejectedEventsStream() {
    return _db
        .collection('events')
        .where('status', isEqualTo: 'rejected')
        .orderBy('eventDate', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => Event.fromMap(doc.id, doc.data())).toList());
  }

  Stream<List<AdminUser>> getUsersStream() {
    return _db
        .collection('users')
        .orderBy('displayName')
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => AdminUser.fromMap(doc.id, doc.data())).toList());
  }

  Future<void> setUserBanStatus(String userId, bool isBanned) async {
    await _db.collection('users').doc(userId).update({'isBanned': isBanned});
  }

  Future<AdminAnalytics> getAdminAnalytics() async {
    final eventsSnapshot = await _db.collection('events').get();
    final usersSnapshot = await _db.collection('users').get();
    final broadcastsSnapshot = await _db.collection('broadcasts').get();

    final now = DateTime.now();
    final totalEvents = eventsSnapshot.docs.length;
    var pendingEvents = 0;
    var approvedEvents = 0;
    var rejectedEvents = 0;
    var completedApprovedEvents = 0;
    final categoryCounts = <String, int>{};

    for (final doc in eventsSnapshot.docs) {
      final data = doc.data();
      final status = data['status'] as String? ?? 'pending';
      final category = data['category'] as String? ?? 'General';
      categoryCounts[category] = (categoryCounts[category] ?? 0) + 1;

      switch (status) {
        case 'approved':
          approvedEvents++;
          final eventDate = data['eventDate'];
          if (eventDate is Timestamp && eventDate.toDate().isBefore(now)) {
            completedApprovedEvents++;
          }
          break;
        case 'rejected':
          rejectedEvents++;
          break;
        default:
          pendingEvents++;
      }
    }

    final totalUsers = usersSnapshot.docs.length;
    var bannedUsers = 0;
    final userGrowthByMonth = <String, int>{};
    final months = List.generate(6, (index) {
      final date = DateTime(now.year, now.month - (5 - index), 1);
      return '${_monthLabel(date.month)} ${date.year % 100}'.trim();
    });
    for (final month in months) {
      userGrowthByMonth[month] = 0;
    }

    for (final doc in usersSnapshot.docs) {
      final data = doc.data();
      final isBanned = data['isBanned'] == true;
      if (isBanned) {
        bannedUsers++;
      }
      final createdAt = data['createdAt'];
      if (createdAt is Timestamp) {
        final date = createdAt.toDate();
        final key = '${_monthLabel(date.month)} ${date.year % 100}'.trim();
        if (userGrowthByMonth.containsKey(key)) {
          userGrowthByMonth[key] = (userGrowthByMonth[key] ?? 0) + 1;
        }
      }
    }

    final activeUsers = totalUsers - bannedUsers;
    final totalBroadcasts = broadcastsSnapshot.docs.length;
    final completionRate = approvedEvents == 0 ? 0.0 : completedApprovedEvents / approvedEvents;

    return AdminAnalytics(
      totalEvents: totalEvents,
      pendingEvents: pendingEvents,
      approvedEvents: approvedEvents,
      rejectedEvents: rejectedEvents,
      totalUsers: totalUsers,
      activeUsers: activeUsers,
      bannedUsers: bannedUsers,
      totalBroadcasts: totalBroadcasts,
      completionRate: completionRate,
      categoryCounts: categoryCounts,
      userGrowthByMonth: userGrowthByMonth,
    );
  }

  Future<void> sendBroadcast({
    required String title,
    required String body,
    required String sentBy,
  }) async {
    await _db.collection('broadcasts').add({
      'title': title,
      'body': body,
      'sentBy': sentBy,
      'sentAt': FieldValue.serverTimestamp(),
    });

    final usersSnapshot = await _db.collection('users').get();
    final batch = _db.batch();

    for (final doc in usersSnapshot.docs) {
      final data = doc.data();
      if (data['isBanned'] == true) {
        continue;
      }

      final notificationRef = _db
          .collection('users')
          .doc(doc.id)
          .collection('notifications')
          .doc();

      batch.set(notificationRef, {
        'title': title,
        'body': body,
        'type': 'broadcast',
        'targetId': null,
        'createdAt': FieldValue.serverTimestamp(),
        'isRead': false,
      });
    }

    await batch.commit();
  }

  Stream<List<AdminBroadcast>> getBroadcastsStream() {
    return _db
        .collection('broadcasts')
        .orderBy('sentAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => AdminBroadcast.fromMap(doc.id, doc.data()))
            .toList());
  }

  Future<void> saveUserFcmToken(String userId, String token) async {
    await _db.collection('users').doc(userId).set({
      'fcmTokens': FieldValue.arrayUnion([token]),
    }, SetOptions(merge: true));
  }

  Future<void> createNotification({
    required String userId,
    required String title,
    required String body,
    required String type,
    required String? targetId,
    String? actorUserId,
  }) async {
    await _db.collection('users').doc(userId).collection('notifications').add({
      'title': title,
      'body': body,
      'type': type,
      'targetId': targetId,
      'actorUserId': actorUserId,
      'createdAt': FieldValue.serverTimestamp(),
      'isRead': false,
    });
  }

  Stream<List<AppNotification>> getNotificationsStream(String userId) {
    return _db
        .collection('users')
        .doc(userId)
        .collection('notifications')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => AppNotification.fromMap(doc.id, doc.data()))
            .toList());
  }

  Stream<int> getUnreadNotificationCount(String userId) {
    return _db
        .collection('users')
        .doc(userId)
        .collection('notifications')
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  Stream<int> getUnreadNotificationCountExcludingTypes(
    String userId,
    List<String> excludedTypes,
  ) {
    return _db
        .collection('users')
        .doc(userId)
        .collection('notifications')
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .where((doc) => !excludedTypes.contains(doc.data()['type']))
            .length);
  }

  Stream<int> getUnreadNotificationCountByTypes(String userId, List<String> types) {
    return _db
        .collection('users')
        .doc(userId)
        .collection('notifications')
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .where((doc) => types.contains(doc.data()['type']))
            .length);
  }

  Future<void> markNotificationRead(String userId, String notificationId) async {
    await _db
        .collection('users')
        .doc(userId)
        .collection('notifications')
        .doc(notificationId)
        .update({'isRead': true});
  }

  Future<void> markAllNotificationsRead(String userId) async {
    final snapshot = await _db
        .collection('users')
        .doc(userId)
        .collection('notifications')
        .where('isRead', isEqualTo: false)
        .get();

    final batch = _db.batch();
    for (final doc in snapshot.docs) {
      batch.update(doc.reference, {'isRead': true});
    }
    await batch.commit();
  }

  Future<void> markMatchingNotificationsRead(
    String userId, {
    List<String>? types,
    String? targetId,
  }) async {
    final snapshot = await _db
        .collection('users')
        .doc(userId)
        .collection('notifications')
        .where('isRead', isEqualTo: false)
        .get();

    final batch = _db.batch();
    for (final doc in snapshot.docs) {
      final data = doc.data();
      final type = data['type'] as String?;
      final docTargetId = data['targetId'] as String?;

      final matchesType = types == null || types.contains(type);
      final matchesTarget = targetId == null || docTargetId == targetId;

      if (matchesType && matchesTarget) {
        batch.update(doc.reference, {'isRead': true});
      }
    }

    await batch.commit();
  }

  String _monthLabel(int month) {
    const labels = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return labels[month - 1];
  }

  String _attendanceRecordId({
    required String volunteerId,
    required String eventId,
    required DateTime date,
  }) {
    final dayKey =
        '${date.year.toString().padLeft(4, '0')}${date.month.toString().padLeft(2, '0')}${date.day.toString().padLeft(2, '0')}';
    return '$volunteerId-$eventId-$dayKey';
  }

  String _buildSafeImageFileName(String originalFileName) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final extension = _normalizedImageExtension(originalFileName);
    return 'event-$timestamp.$extension';
  }

  String _normalizedImageExtension(String fileName) {
    final dotIndex = fileName.lastIndexOf('.');
    if (dotIndex == -1 || dotIndex == fileName.length - 1) {
      return 'jpg';
    }

    final rawExtension = fileName.substring(dotIndex + 1).toLowerCase();
    switch (rawExtension) {
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'webp':
      case 'gif':
        return rawExtension;
      default:
        return 'jpg';
    }
  }

  String _guessImageContentType(String fileName) {
    switch (_normalizedImageExtension(fileName)) {
      case 'png':
        return 'image/png';
      case 'webp':
        return 'image/webp';
      case 'gif':
        return 'image/gif';
      case 'jpg':
      case 'jpeg':
      default:
        return 'image/jpeg';
    }
  }

  List<AchievementBadge> _buildAchievementBadges({
    required int totalPoints,
    required int attendedEvents,
    required int verifiedMinutes,
  }) {
    final badges = <AchievementBadge>[];

    if (attendedEvents >= 1) {
      badges.add(
        const AchievementBadge(
          id: 'first_step',
          title: 'First Step',
          description: 'Completed the first verified Shramdaan.',
          icon: Icons.flag_outlined,
          color: Color(0xFF2563EB),
          backgroundColor: Color(0xFFEAF2FF),
        ),
      );
    }

    if (attendedEvents >= 5) {
      badges.add(
        const AchievementBadge(
          id: 'steady_helper',
          title: 'Steady Helper',
          description: 'Showed up for five verified community events.',
          icon: Icons.volunteer_activism_outlined,
          color: Color(0xFF16A34A),
          backgroundColor: Color(0xFFEAF7EC),
        ),
      );
    }

    if (verifiedMinutes >= 300) {
      badges.add(
        const AchievementBadge(
          id: 'time_giver',
          title: 'Time Giver',
          description: 'Contributed five verified hours to the community.',
          icon: Icons.schedule_outlined,
          color: Color(0xFFEA580C),
          backgroundColor: Color(0xFFFFF1E8),
        ),
      );
    }

    if (verifiedMinutes >= 900) {
      badges.add(
        const AchievementBadge(
          id: 'impact_builder',
          title: 'Impact Builder',
          description: 'Reached fifteen verified volunteer hours.',
          icon: Icons.auto_graph_outlined,
          color: Color(0xFF7C3AED),
          backgroundColor: Color(0xFFF3E8FF),
        ),
      );
    }

    if (totalPoints >= 100) {
      badges.add(
        const AchievementBadge(
          id: 'community_force',
          title: 'Community Force',
          description: 'Earned 100 points through verified contribution.',
          icon: Icons.workspace_premium_outlined,
          color: Color(0xFFF59E0B),
          backgroundColor: Color(0xFFFFF7DD),
        ),
      );
    }

    return badges;
  }

  Future<void> _deleteStorageFileByUrl(String imageUrl) async {
    try {
      final uri = Uri.tryParse(imageUrl);
      if (uri == null) {
        return;
      }

      final isFirebaseStorageUrl =
          uri.host.contains('firebasestorage.googleapis.com') ||
          uri.host.contains('storage.googleapis.com');
      if (!isFirebaseStorageUrl) {
        return;
      }

      await _storage.refFromURL(imageUrl).delete();
    } catch (e) {
      print('Error deleting storage file: $e');
    }
  }
}
