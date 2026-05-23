import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myapp/shared/services/firestore_service.dart';

import '../shared/firebase_test_helpers.dart';

void main() {
  late FakeFirebaseFirestore firestore;
  late FirestoreService service;

  setUp(() {
    firestore = fakeFirestore();
    service = firestoreService(firestore);
  });

  group('Leaderboard Module', () {
    test('points calculation uses 10 plus floor of verified minutes divided by 15', () async {
      // Arrange
      await firestore.collection('users').doc('user-1').set(userData(uid: 'user-1'));
      await firestore.collection('attendance').doc('record-1').set(
            attendanceData(
              volunteerId: 'user-1',
              checkInTime: DateTime(2026, 5, 21, 9),
              checkOutTime: DateTime(2026, 5, 21, 10),
            ),
          );

      // Act
      final leaderboard = await service.getLeaderboardData();

      // Assert
      expect(leaderboard.single.verifiedMinutes, 60);
      expect(leaderboard.single.totalPoints, 14);
    });

    test('leaderboard is sorted descending by points then minutes then events', () async {
      // Arrange
      await firestore.collection('users').doc('user-a').set(
            userData(uid: 'user-a', displayName: 'A'),
          );
      await firestore.collection('users').doc('user-b').set(
            userData(uid: 'user-b', displayName: 'B'),
          );
      await firestore.collection('attendance').doc('a-1').set(
            attendanceData(
              volunteerId: 'user-a',
              checkInTime: DateTime(2026, 5, 21, 9),
              checkOutTime: DateTime(2026, 5, 21, 10),
            ),
          );
      await firestore.collection('attendance').doc('b-1').set(
            attendanceData(
              volunteerId: 'user-b',
              checkInTime: DateTime(2026, 5, 21, 9),
              checkOutTime: DateTime(2026, 5, 21, 12),
            ),
          );

      // Act
      final leaderboard = await service.getLeaderboardData();

      // Assert
      expect(leaderboard.map((entry) => entry.userId), ['user-b', 'user-a']);
      expect(leaderboard.first.totalPoints, greaterThan(leaderboard.last.totalPoints));
    });

    test('achievements unlock when attendance and verified minutes thresholds are met', () async {
      // Arrange
      await firestore.collection('users').doc('user-1').set(userData(uid: 'user-1'));
      for (var i = 0; i < 5; i++) {
        await firestore.collection('attendance').doc('record-$i').set(
              attendanceData(
                volunteerId: 'user-1',
                eventId: 'event-$i',
                checkInTime: DateTime(2026, 5, 21 + i, 9),
                checkOutTime: DateTime(2026, 5, 21 + i, 10),
              ),
            );
      }

      // Act
      final badges = await service.getUserAchievementBadges('user-1');

      // Assert
      expect(badges.map((badge) => badge.id), containsAll([
        'first_step',
        'steady_helper',
        'time_giver',
      ]));
    });
  });
}
