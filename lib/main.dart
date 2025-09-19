import 'package:career_guide/screens/auth/login_screen.dart';
import 'package:career_guide/screens/user_check_screen.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';
import 'screens/job_recommendations_screen.dart';
import 'package:career_guide/screens/auth/login_screen.dart';
import 'package:career_guide/screens/user_check_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'PathX',
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color.fromRGBO(0, 0, 0, 1),
      ),
      home: Scaffold(
        body: StreamBuilder(
          stream: FirebaseAuth.instance.authStateChanges(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.active) {
              // If the snapshot has data, it means we have a user
              if (snapshot.hasData) {
                // *** THIS IS THE CHANGED LINE ***
                // Instead of going to recommendations, go to the checker screen.
                return const UserCheckScreen();
              }
              // If there's an error with the stream
              else if (snapshot.hasError) {
                return Center(
                  child: Text('${snapshot.error}'),
                );
              }
            }
            // While waiting for connection, show a loading indicator
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }
            // If none of the above, user is not logged in, show LoginScreen
            return const LoginScreen();
          },
        ),
      ),
    );
  }
}
