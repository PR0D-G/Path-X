import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'questionnaire_screen.dart';
import 'job_recommendations_screen.dart';

class UserCheckScreen extends StatefulWidget {
  const UserCheckScreen({super.key});

  @override
  State<UserCheckScreen> createState() => _UserCheckScreenState();
}

class _UserCheckScreenState extends State<UserCheckScreen> {
  @override
  void initState() {
    super.initState();
    // Use addPostFrameCallback to ensure the build context is available
    WidgetsBinding.instance.addPostFrameCallback((_) {
      checkUserAndNavigate();
    });
  }

  Future<void> checkUserAndNavigate() async {
    // Get the current Firebase user
    User? user = FirebaseAuth.instance.currentUser;

    // Ensure there is a logged-in user before proceeding
    if (user != null) {
      // Check for the user's document in the 'users' collection in Firestore
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      // If the document does NOT exist, the user is new.
      if (!doc.exists) {
        // Navigate to the QuestionScreen for new users
        if (mounted) {
          // Check if the widget is still in the tree
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const QuestionnaireScreen()),
          );
        }
      } else {
        // If the document exists, the user is returning.
        if (mounted) {
          // Check if the widget is still in the tree
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
                builder: (context) => JobRecommendationsScreen(
                      assessmentResults: {}, // Pass an empty map or fetch the actual assessment results
                    )),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Display a loading indicator while the check is in progress
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(
          color: Colors.white, // Or your app's theme color
        ),
      ),
    );
  }
}
