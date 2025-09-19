import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';

import 'providers/auth_provider.dart';
import 'screens/splash_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/signup_screen.dart';
import 'screens/home_screen.dart';
import 'screens/questionnaire_screen.dart';
import 'screens/job_recommendations_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/learning_path_screen.dart';

// Make the main function asynchronous to initialize Firebase
void main() async {
  // Ensure that Flutter bindings are initialized before calling Firebase
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  runApp(const CareerGuideApp());
}

class CareerGuideApp extends StatelessWidget {
  const CareerGuideApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Wrap your app with MultiProvider to provide the Auth state
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => AppAuthProvider(), // ✅ updated provider class
        ),
        // You can add more providers here later
      ],
      child: MaterialApp(
        title: 'Career Guide',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          primarySwatch: Colors.blue,
          visualDensity: VisualDensity.adaptivePlatformDensity,
          textTheme: GoogleFonts.poppinsTextTheme(
            Theme.of(context).textTheme,
          ),
          appBarTheme: const AppBarTheme(
            elevation: 0,
            centerTitle: true,
            backgroundColor: Colors.transparent,
            iconTheme: IconThemeData(color: Colors.black87),
            titleTextStyle: TextStyle(
              color: Colors.black87,
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        initialRoute: '/',
        routes: {
          '/': (context) => const SplashScreen(),
          '/login': (context) => const LoginScreen(),
          '/signup': (context) => const SignupScreen(),
          '/home': (context) => const HomeScreen(),
          '/questionnaire': (context) => const QuestionnaireScreen(
                name: "",
                educationLevel: "",
                skills: [],
                interests: "",
              ),
          '/job-recommendations': (context) =>
              const JobRecommendationsScreen(assessmentResults: {}),
          '/profile': (context) => const ProfileScreen(),
          '/learning-path': (context) => const LearningPathScreen(),
        },
      ),
    );
  }
}
