import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import 'questionnaire_screen.dart';
import 'home_screen.dart';

class UserCheckScreen extends StatefulWidget {
  const UserCheckScreen({super.key});

  @override
  State<UserCheckScreen> createState() => _UserCheckScreenState();
}

class _UserCheckScreenState extends State<UserCheckScreen> {
  bool _navigating = false;

  @override
  Widget build(BuildContext context) {
    return Consumer<AppAuthProvider>(
      builder: (context, authProvider, child) {
        // Wait for the provider to fully load the profile
        if (authProvider.userProfile == null) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(color: Colors.blue),
            ),
          );
        }

        // Once the profile is loaded, safely navigate away
        if (!_navigating) {
          _navigating = true;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;

            if (authProvider.shouldShowQuestionnaire) {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                    builder: (context) => const QuestionnaireScreen()),
              );
            } else {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (context) => const HomeScreen()),
              );
            }
          });
        }

        return const Scaffold(
          body: Center(
            child: CircularProgressIndicator(color: Colors.blue),
          ),
        );
      },
    );
  }
}
