import 'dart:developer';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../models/user_model.dart';
import '../providers/auth_provider.dart';
import 'job_recommendations_screen.dart';

class QuestionnaireScreen extends StatefulWidget {
  final String? name;
  final String? educationLevel;
  final List<String>? skills;
  final String? interests;

  const QuestionnaireScreen({
    super.key,
    this.name,
    this.educationLevel,
    this.skills,
    this.interests,
  });

  @override
  State<QuestionnaireScreen> createState() => _QuestionnaireScreenState();
}

class _QuestionnaireScreenState extends State<QuestionnaireScreen> {
  int _currentQuestionIndex = 0;
  final Map<int, double> _answers = {};
  final PageController _pageController = PageController();
  
  // Form controllers for user information
  late final TextEditingController _nameController;
  late final TextEditingController _educationController;
  late final TextEditingController _skillsController;
  late final TextEditingController _interestsController;
  
  // Track if we're showing the info form or questions
  bool _showInfoForm = true;
  
  // Initialize controllers with widget values if they exist
  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.name ?? '');
    _educationController = TextEditingController(text: widget.educationLevel ?? '');
    _skillsController = TextEditingController(text: widget.skills?.join(', ') ?? '');
    _interestsController = TextEditingController(text: widget.interests ?? '');
  }
  
  @override
  void dispose() {
    _nameController.dispose();
    _educationController.dispose();
    _skillsController.dispose();
    _interestsController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  final List<Map<String, dynamic>> _questions = [
    {
      'question': 'How would you rate your problem-solving skills?',
      'category': 'Analytical Skills',
    },
    {
      'question': 'How comfortable are you with public speaking?',
      'category': 'Communication',
    },
    {
      'question': 'How would you rate your ability to work in a team?',
      'category': 'Teamwork',
    },
    {
      'question': 'How would you rate your time management skills?',
      'category': 'Organization',
    },
    {
      'question': 'How comfortable are you with learning new technologies?',
      'category': 'Adaptability',
    },
    {
      'question': 'How would you rate your leadership abilities?',
      'category': 'Leadership',
    },
    {
      'question': 'How would you rate your creativity in solving problems?',
      'category': 'Innovation',
    },
    {
      'question': 'How comfortable are you with data analysis?',
      'category': 'Analytical Skills',
    },
    {
      'question': 'How would you rate your written communication skills?',
      'category': 'Communication',
    },
    {
      'question': 'How well do you handle stress and pressure?',
      'category': 'Resilience',
    },
  ];


  Future<void> _submitQuestionnaire() async {
    try {
      final authProvider = Provider.of<AppAuthProvider>(context, listen: false);
      final user = authProvider.user;
      
      if (user != null) {
        // Calculate assessment results by category
        final Map<String, dynamic> assessmentResults = {};
        _answers.forEach((index, value) {
          final category = _questions[index]['category'] as String;
          if (!assessmentResults.containsKey(category)) {
            assessmentResults[category] = {
              'total': 0.0,
              'count': 0,
            };
          }
          assessmentResults[category]['total'] += value;
          assessmentResults[category]['count']++;
        });

        // Calculate average scores
        final Map<String, double> averageScores = {};
        assessmentResults.forEach((category, data) {
          averageScores[category] = (data['total'] as double) / (data['count'] as int);
        });

        // Get user skills from the form
        final skills = _skillsController.text
            .split(',')
            .map((s) => s.trim())
            .where((s) => s.isNotEmpty)
            .toList();

        // Update user profile with assessment results
        final updatedProfile = UserProfile(
          uid: user.uid,
          email: user.email,
          displayName: _nameController.text.trim(),
          educationLevel: _educationController.text.trim(),
          skills: skills,
          interests: _interestsController.text.trim(),
          assessmentResults: averageScores,
          hasCompletedQuestionnaire: true,
          createdAt: authProvider.userProfile?.createdAt,
          updatedAt: DateTime.now(),
        );

        // Save to Firestore
        await authProvider.updateUserProfile(updatedProfile);

        if (mounted) {
          // Navigate to job recommendations with assessment results
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => JobRecommendationsScreen(
                assessmentResults: averageScores,
              ),
            ),
          );
        }
      }
    } on FirebaseException catch (e) {
      debugPrint('Firebase error submitting questionnaire: ${e.message}');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.message}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error submitting questionnaire: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to submit questionnaire. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _answerQuestion(double rating) async {
    setState(() {
      _answers[_currentQuestionIndex] = rating;
    });

    if (_currentQuestionIndex < _questions.length - 1) {
      setState(() {
        _currentQuestionIndex++;
      });
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    } else {
      // All questions answered, submit the questionnaire
      await _submitQuestionnaire();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppAuthProvider>(builder: (context, authProvider, _) {
      if (authProvider.isLoading) {
        return const Scaffold(
          body: Center(
            child: CircularProgressIndicator(),
          ),
        );
      }

      return Scaffold(
        appBar: AppBar(
          title: const Text('Skills Assessment'),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 16.0, top: 16.0),
              child: Text(
                '${_currentQuestionIndex + 1}/${_questions.length}',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w500,
                  color: Colors.blue.shade800,
                ),
              ),
            ),
          ],
        ),
        body: _showInfoForm 
          ? _buildInfoForm() 
          : Column(
              children: [
                // Progress Bar
                LinearProgressIndicator(
                  value: (_currentQuestionIndex + 1) / _questions.length,
                  backgroundColor: Colors.grey.shade200,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.blue.shade600),
                  minHeight: 4,
                ),

                // Questions
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _questions.length,
                    onPageChanged: (index) {
                      setState(() {
                        _currentQuestionIndex = index;
                      });
                    },
                    itemBuilder: (context, index) {
                      return _buildQuestionCard(index);
                    },
                  ),
                ),
              ],
            ),
      );
    });
  }

  Widget _buildInfoForm() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Tell us about yourself',
            style: GoogleFonts.poppins(
              fontSize: 24,
              fontWeight: FontWeight.w600,
              color: Colors.blue.shade800,
            ),
          ),
          const SizedBox(height: 32),
          
          // Name Field
          TextFormField(
            controller: _nameController,
            decoration: InputDecoration(
              labelText: 'Full Name',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(height: 16),
          
          // Education Level Field
          TextFormField(
            controller: _educationController,
            decoration: InputDecoration(
              labelText: 'Highest Education Level',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(height: 16),
          
          // Skills Field
          TextFormField(
            controller: _skillsController,
            decoration: InputDecoration(
              labelText: 'Skills (comma separated)',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            maxLines: 2,
          ),
          const SizedBox(height: 16),
          
          // Interests Field
          TextFormField(
            controller: _interestsController,
            decoration: InputDecoration(
              labelText: 'Career Interests',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            maxLines: 2,
          ),
          const SizedBox(height: 32),
          
          // Start Assessment Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                setState(() {
                  _showInfoForm = false;
                });
              },
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                backgroundColor: Colors.blue.shade600,
              ),
              child: Text(
                'Start Assessment',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionCard(int questionIndex) {
    final question = _questions[questionIndex];
    final currentRating = _answers[questionIndex]?.toDouble() ?? 0.0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Category Tag
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              question['category'],
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: Colors.blue.shade700,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Question
          Text(
            question['question'],
            style: GoogleFonts.poppins(
              fontSize: 24,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade800,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 40),

          // Rating Bar
          Center(
            child: RatingBar.builder(
              initialRating: currentRating,
              minRating: 1,
              direction: Axis.horizontal,
              allowHalfRating: true,
              itemCount: 5,
              itemPadding: const EdgeInsets.symmetric(horizontal: 8.0),
              itemBuilder: (context, _) => const Icon(
                Icons.star,
                color: Colors.amber,
              ),
              onRatingUpdate: (rating) {
                _answerQuestion(rating);
              },
              itemSize: 42,
            ),
          ),
          const SizedBox(height: 24),

          // Rating Labels
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Not at all',
                style: GoogleFonts.poppins(
                  color: Colors.grey.shade600,
                  fontSize: 12,
                ),
              ),
              Text(
                'Very much',
                style: GoogleFonts.poppins(
                  color: Colors.grey.shade600,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 40),

          // Navigation Buttons
          if (questionIndex > 0)
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () {
                  _pageController.previousPage(
                    duration: const Duration(milliseconds: 400),
                    curve: Curves.easeInOut,
                  );
                },
                child: Text(
                  'Previous Question',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    color: Colors.blue.shade700,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
