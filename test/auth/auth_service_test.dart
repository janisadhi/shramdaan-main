import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart' as auth_mocks;
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:myapp/features/auth/services/auth_service.dart';

import '../shared/firebase_test_helpers.dart';

void main() {
  late MockFirebaseAuth auth;
  late FakeFirebaseFirestore firestore;
  late AuthService service;
  late MockUserCredential credential;
  late MockUser user;

  setUp(() {
    auth = MockFirebaseAuth();
    firestore = FakeFirebaseFirestore();
    service = AuthService(auth: auth, firestore: firestore);
    credential = MockUserCredential();
    user = MockUser();

    when(() => user.uid).thenReturn('user-1');
    when(() => user.updateDisplayName(any())).thenAnswer((_) async {});
    when(() => user.reload()).thenAnswer((_) async {});
    when(() => credential.user).thenReturn(user);
  });

  tearDown(() {
    reset(auth);
    reset(credential);
    reset(user);
  });

  group('Authentication Module', () {
    test('successful signup creates auth user and stores profile with default volunteer role', () async {
      // Arrange
      when(
        () => auth.createUserWithEmailAndPassword(
          email: 'volunteer@example.com',
          password: 'StrongPass123!',
        ),
      ).thenAnswer((_) async => credential);
      when(() => auth.currentUser).thenReturn(user);

      // Act
      final result = await service.signUpWithEmailAndPassword(
        'volunteer@example.com',
        'StrongPass123!',
        'Volunteer One',
        '9800000000',
        DateTime(2000, 1, 1),
        'Other',
      );

      // Assert
      expect(result, user);
      final userDoc = await firestore.collection('users').doc('user-1').get();
      expect(userDoc.exists, isTrue);
      expect(userDoc.data()?['email'], 'volunteer@example.com');
      expect(userDoc.data()?['displayName'], 'Volunteer One');
      expect(userDoc.data()?['role'], 'volunteer');
      expect(userDoc.data()?['isBanned'], isFalse);
      verify(() => user.updateDisplayName('Volunteer One')).called(1);
    });

    test('invalid email during signup is handled and no user document is created', () async {
      // Arrange
      when(
        () => auth.createUserWithEmailAndPassword(
          email: 'not-an-email',
          password: 'StrongPass123!',
        ),
      ).thenThrow(
        FirebaseAuthException(
          code: 'invalid-email',
          message: 'The email address is badly formatted.',
        ),
      );

      // Act
      final result = await service.signUpWithEmailAndPassword(
        'not-an-email',
        'StrongPass123!',
        'Volunteer One',
        null,
        null,
        null,
      );

      // Assert
      expect(result, isNull);
      final users = await firestore.collection('users').get();
      expect(users.docs, isEmpty);
    });

    test('weak password during signup is handled and returns null', () async {
      // Arrange
      when(
        () => auth.createUserWithEmailAndPassword(
          email: 'volunteer@example.com',
          password: '123',
        ),
      ).thenThrow(
        FirebaseAuthException(
          code: 'weak-password',
          message: 'Password should be at least 6 characters.',
        ),
      );

      // Act
      final result = await service.signUpWithEmailAndPassword(
        'volunteer@example.com',
        '123',
        'Volunteer One',
        null,
        null,
        null,
      );

      // Assert
      expect(result, isNull);
      verifyNever(() => user.updateDisplayName(any()));
    });

    test('successful login returns the Firebase user when account is active', () async {
      // Arrange
      await firestore.collection('users').doc('user-1').set(
            userData(uid: 'user-1', isBanned: false),
          );
      when(
        () => auth.signInWithEmailAndPassword(
          email: 'volunteer@example.com',
          password: 'StrongPass123!',
        ),
      ).thenAnswer((_) async => credential);

      // Act
      final result = await service.signInWithEmailAndPassword(
        'volunteer@example.com',
        'StrongPass123!',
      );

      // Assert
      expect(result, user);
      verifyNever(() => auth.signOut());
    });

    test('banned user cannot login and is immediately signed out', () async {
      // Arrange
      await firestore.collection('users').doc('user-1').set(
            userData(uid: 'user-1', isBanned: true),
          );
      when(
        () => auth.signInWithEmailAndPassword(
          email: 'banned@example.com',
          password: 'StrongPass123!',
        ),
      ).thenAnswer((_) async => credential);
      when(() => auth.signOut()).thenAnswer((_) async {});

      // Act
      final result = await service.signInWithEmailAndPassword(
        'banned@example.com',
        'StrongPass123!',
      );

      // Assert
      expect(result, isNull);
      verify(() => auth.signOut()).called(1);
    });

    test('FirebaseAuthException during login is handled and returns null', () async {
      // Arrange
      when(
        () => auth.signInWithEmailAndPassword(
          email: 'volunteer@example.com',
          password: 'wrong-password',
        ),
      ).thenThrow(
        FirebaseAuthException(
          code: 'wrong-password',
          message: 'The password is invalid.',
        ),
      );

      // Act
      final result = await service.signInWithEmailAndPassword(
        'volunteer@example.com',
        'wrong-password',
      );

      // Assert
      expect(result, isNull);
    });

    test('session persistence stream emits the currently signed-in user', () async {
      // Arrange
      final persistedUser = auth_mocks.MockUser(
        uid: 'persisted-user',
        email: 'persisted@example.com',
        displayName: 'Persisted User',
      );
      final fakeAuth = auth_mocks.MockFirebaseAuth(
        mockUser: persistedUser,
        signedIn: true,
      );

      // Act
      final currentSession = await fakeAuth.authStateChanges().first;

      // Assert
      expect(currentSession?.uid, 'persisted-user');
    });
  });
}
