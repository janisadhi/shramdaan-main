import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../home/screens/home_screen.dart';
import 'login_screen.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<User?>(
        // Listen to the authentication state changes
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          // 1. While waiting for connection, show a loading indicator
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // 2. If the snapshot has data, it means the user is logged in
          if (snapshot.hasData) {
            return const HomeScreen();
          }

          // 3. If there's an error, show an error message
          if (snapshot.hasError) {
            return const Center(child: Text('Something went wrong!'));
          }

          // 4. If snapshot has no data, the user is logged out
          return const LoginScreen();
        },
      ),
    );
  }
}