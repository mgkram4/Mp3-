import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:mp3_app/pages/home.dart';
import 'package:mp3_app/pages/library.dart';
import 'package:mp3_app/pages/login.dart';
import 'package:mp3_app/pages/signup.dart';
import 'package:mp3_app/pages/upload.dart';
import 'package:mp3_app/services/auth.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  static const String homeRoute = '/home';
  static const String loginRoute = '/login';
  static const String signUpRoute = '/signUp';
  static const String libraryRoute = '/library';
  static const String playlistsRoute = '/playlists';
  static const String uploadRoute = '/upload';

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      routes: {
        homeRoute: (context) => const HomePage(),
        loginRoute: (context) => const LoginPage(),
        signUpRoute: (context) => const SignUpPage(),
        uploadRoute: (context) => const UploadPage(),
        libraryRoute: (context) => const LibraryPage(),
      },
      home: const AuthWrapper(),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: AuthService().authStateChanges,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.active) {
          User? user = snapshot.data;
          if (user == null) {
            return const LoginPage();
          } else {
            return const HomePage();
          }
        } else {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
      },
    );
  }
}
