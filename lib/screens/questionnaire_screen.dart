import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import 'job_recommendations_screen.dart';

class QuestionnaireScreen extends StatefulWidget {
  final String name;
  final String educationLevel;
  final List<String> skills;
  final String interests;

  const QuestionnaireScreen({
    super.key,
    required this.name,
    required this.educationLevel,
    required this.skills,
    required this.interests,
  });

  @override
  State<QuestionnaireScreen> createState() => _QuestionnaireScreenState();
}

class _QuestionnaireScreenState extends State<QuestionnaireScreen> {
  int _currentQuestionIndex = 0;
  final Map<int, double> _answers = {};
  final PageController _pageController = PageController();

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

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _answerQuestion(double rating) async {
    // Added async
    setState(() {
      _answers[_currentQuestionIndex] = rating;
    });

    if (_currentQuestionIndex < _questions.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    } else {
      // All questions answered, process and navigate
      try {
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        await authProvider.completeQuestionnaire(); // Ensured await

        if (mounted) {
          // Navigate to recommendations screen, replacing the current screen
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => JobRecommendationsScreen(
                // name: widget.name, // These were causing errors before, JobRecommendationsScreen doesn't expect them
                // educationLevel: widget.educationLevel,
                // skills: widget.skills,
                // interests: widget.interests,
                // skillLevel: '', // Passing empty string for now
                assessmentResults: _answers,
              ),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text(
                    'Failed to save questionnaire results. Please try again.')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(builder: (context, authProvider, _) {
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
                '\${_currentQuestionIndex + 1}/\${_questions.length}',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w500,
                  color: Colors.blue.shade800,
                ),
              ),
            ),
          ],
        ),
        body: Column(
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

  Widget _buildQuestionCard(int questionIndex) {
    final question = _questions[questionIndex];
    final currentRating = _answers[questionIndex] ?? 0.0;

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
