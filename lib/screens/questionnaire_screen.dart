import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../models/user_model.dart';
import '../providers/auth_provider.dart';
import '../services/question_service.dart';
import 'home_screen.dart';

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
  final Map<int, dynamic> _answers = {};
  final PageController _pageController = PageController();

  List<Map<String, dynamic>> _questions = [];
  bool _isLoadingQuestions = false;

  // Form controllers for user information
  late final TextEditingController _nameController;
  late final TextEditingController _educationController;
  late final TextEditingController _skillsController;
  late final TextEditingController _interestsController;

  // Track if we're showing the info form or questions
  bool _showInfoForm = true;

  // Math Question Timer Logic
  Timer? _questionTimer;
  int _timeLeft = 7;
  bool _mathPopupShown = false;

  // Initialize controllers with widget values if they exist
  @override
  void initState() {
    super.initState();
    final authProvider = Provider.of<AppAuthProvider>(context, listen: false);
    final profile = authProvider.userProfile;

    // Use widget values if present, otherwise fallback to existing profile data
    _nameController =
        TextEditingController(text: widget.name ?? profile?.displayName ?? '');
    _educationController = TextEditingController(
        text: widget.educationLevel ?? profile?.educationLevel ?? '');
    _skillsController = TextEditingController(
        text: widget.skills?.join(', ') ?? profile?.skills?.join(', ') ?? '');
    _interestsController = TextEditingController(
        text: widget.interests ?? profile?.interests ?? '');

    // Auto-skip logic: If name is already provided, skip the info form and load questions
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_nameController.text.isNotEmpty) {
        debugPrint(
            'DEBUG: Auto-skipping info form as name exists: ${_nameController.text}');
        _loadQuestions();
      }
    });
  }

  Future<void> _loadQuestions() async {
    setState(() {
      _isLoadingQuestions = true;
    });
    try {
      final fetchedQuestions = await QuestionService.fetchQuizQuestions();
      if (mounted) {
        setState(() {
          _questions = fetchedQuestions;
          _showInfoForm = false;
          _isLoadingQuestions = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingQuestions = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load questions: $e')),
        );
      }
    }
  }

  void _fillDummyDataAndSubmit() async {
    setState(() {
      _isLoadingQuestions = true;
    });

    for (int i = 0; i < _questions.length; i++) {
      final q = _questions[i];
      final category = q['category'] as String?;
      final isMath = q['isMath'] == true;
      final options = q['options'] as List<dynamic>?;

      if ([
        'Realistic',
        'Investigative',
        'Artistic',
        'Social',
        'Enterprising',
        'Conventional'
      ].contains(category)) {
        _answers[i] = 4.0; // High rating
      } else if (isMath || options != null) {
        _answers[i] = q['correct_answer'] ?? (options?.first ?? 'Option A');
      } else {
        _answers[i] = 'Dummy Answer';
      }
    }

    await _submitQuestionnaire();
  }

  @override
  void dispose() {
    _questionTimer?.cancel();
    _nameController.dispose();
    _educationController.dispose();
    _skillsController.dispose();
    _interestsController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _submitQuestionnaire() async {
    try {
      final authProvider = Provider.of<AppAuthProvider>(context, listen: false);
      final user = authProvider.user;

      if (user != null) {
        // --- SCORING LOGIC ---
        final Map<String, int> riasecScores = {
          'Realistic': 0,
          'Investigative': 0,
          'Artistic': 0,
          'Social': 0,
          'Enterprising': 0,
          'Conventional': 0,
        };

        int logicScore = 0;
        int reasoningScore = 0;
        int patternScore = 0;
        int mathScore = 0;

        _answers.forEach((index, rawAnswer) {
          if (index >= _questions.length)
            return; // Fix: Skip any indices that are out of bounds

          final question = _questions[index];
          final category = question['category'] as String?;
          final isMath = question['isMath'] == true;

          if (category != null && riasecScores.containsKey(category)) {
            // Personality Phase (Stars + 'Not sure')
            int points = 0;
            if (rawAnswer is double) {
              points = rawAnswer.toInt();
            } else if (rawAnswer == 'Not sure') {
              points = 3;
            }
            riasecScores[category] = (riasecScores[category] ?? 0) + points;
          } else {
            // Aptitude + Math Phase (Multiple choice options)
            final selectedStr = rawAnswer.toString().trim();
            final correctStr =
                (question['correct_answer'] ?? '').toString().trim();

            if (selectedStr == correctStr) {
              if (isMath) {
                mathScore++;
              } else if (category == 'Logic') {
                logicScore++;
              } else if (category == 'Reasoning') {
                reasoningScore++;
              } else if (category == 'Pattern') {
                patternScore++;
              }
            }
          }
        });

        // Pack the final assessment map
        final Map<String, dynamic> finalScores = {
          "logic": logicScore,
          "reasoning": reasoningScore,
          "pattern": patternScore,
          "math": mathScore,
          'riasec_realistic': riasecScores['Realistic'] ?? 0,
          'riasec_investigative': riasecScores['Investigative'] ?? 0,
          'riasec_artistic': riasecScores['Artistic'] ?? 0,
          'riasec_social': riasecScores['Social'] ?? 0,
          'riasec_enterprising': riasecScores['Enterprising'] ?? 0,
          'riasec_conventional': riasecScores['Conventional'] ?? 0,
        };

        // 1️⃣ Store Assessment Results to Supabase (Update if exists, else insert)
        try {
          debugPrint('Saving assessment results for user: ${user.id}');

          final existingResponse = await Supabase.instance.client
              .from('assessment_results')
              .select('user_id')
              .eq('user_id', user.id)
              .maybeSingle();

          final assessmentData = {
            'user_id': user.id,
            'math': mathScore,
            'logic': logicScore,
            'pattern': patternScore,
            'reasoning': reasoningScore,
            'riasec_realistic': riasecScores['Realistic'] ?? 0,
            'riasec_investigative': riasecScores['Investigative'] ?? 0,
            'riasec_artistic': riasecScores['Artistic'] ?? 0,
            'riasec_social': riasecScores['Social'] ?? 0,
            'riasec_enterprising': riasecScores['Enterprising'] ?? 0,
            'riasec_conventional': riasecScores['Conventional'] ?? 0,
          };

          if (existingResponse != null) {
            // Update existing record
            await Supabase.instance.client
                .from('assessment_results')
                .update(assessmentData)
                .eq('user_id', user.id);
            debugPrint('Assessment results updated successfully.');
          } else {
            // Insert new record
            await Supabase.instance.client
                .from('assessment_results')
                .insert(assessmentData);
            debugPrint('Assessment results inserted successfully.');
          }
        } catch (e) {
          debugPrint('CRITICAL: Error inserting assessment_results: $e');
          // Rethrow to show in UI
          rethrow;
        }

        // Get user skills from the form
        final skills = _skillsController.text
            .split(',')
            .map((s) => s.trim())
            .where((s) => s.isNotEmpty)
            .toList();

        // Update user profile with assessment results
        final updatedProfile = UserProfile(
          uid: user.id,
          email: user.email,
          displayName: _nameController.text.trim(),
          educationLevel: _educationController.text.trim(),
          skills: skills,
          interests: _interestsController.text.trim(),
          assessmentResults: finalScores,
          hasCompletedQuestionnaire: true,
          createdAt: authProvider.userProfile?.createdAt,
          updatedAt: DateTime.now(),
        );

        // Save to Firestore / Supabase
        await authProvider.updateUserProfile(updatedProfile);

        if (mounted) {
          // Navigate to home screen
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => const HomeScreen(),
            ),
          );
        }
      }
    } on Exception catch (e) {
      debugPrint('Error submitting questionnaire: ${e.toString()}');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
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

  void _startMathTimer() {
    _questionTimer?.cancel();
    setState(() {
      _timeLeft = 7;
    });

    _questionTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      setState(() {
        if (_timeLeft > 0) {
          _timeLeft--;
        } else {
          timer.cancel();
          // Auto answer 0.0 or default to move on when out of time
          _answerQuestion(0.0);
        }
      });
    });
  }

  Future<void> _showMathPopup() async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            'Get Ready!',
            style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
          ),
          content: Text(
            'The following questions are quick math problems. You will only have 7 seconds for each question!\n\nAre you ready?',
            style: GoogleFonts.poppins(),
          ),
          actions: <Widget>[
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade600),
              child: Text('Start',
                  style: GoogleFonts.poppins(
                      color: Colors.white, fontWeight: FontWeight.bold)),
              onPressed: () {
                Navigator.of(dialogContext).pop();
                if (mounted) {
                  _startMathTimer();
                }
              },
            ),
          ],
        );
      },
    );
  }

  void _answerQuestion(dynamic answer) async {
    _questionTimer?.cancel(); // Cancel timer when an answer is clicked!

    setState(() {
      _answers[_currentQuestionIndex] = answer;
    });

    if (_currentQuestionIndex < _questions.length - 1) {
      if (answer is String) {
        // Add a tiny delay for UX so they see the button they clicked
        await Future.delayed(const Duration(milliseconds: 300));
        if (!mounted) return;
      }

      final nextIndex = _currentQuestionIndex + 1;
      final isNextMath = _questions[nextIndex]['isMath'] == true;

      setState(() {
        _currentQuestionIndex = nextIndex;
      });
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );

      // Trigger math logic if next question is Math
      if (isNextMath) {
        if (!_mathPopupShown) {
          _mathPopupShown = true;
          await _showMathPopup(); // Pauses and waits for user to hit start
        } else {
          _startMathTimer(); // Just start timer for subsequent math problems
        }
      }
    } else {
      // All questions answered, submit the questionnaire
      setState(() {
        _isLoadingQuestions =
            true; // Use this to show a full-screen loader while submitting
      });
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
                _questions.isEmpty
                    ? '0/0'
                    : '${(_currentQuestionIndex + 1).clamp(1, _questions.length)}/${_questions.length}',
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
            : _isLoadingQuestions
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text('Submitting your results...'),
                      ],
                    ),
                  )
                : Column(
                    children: [
                      // Progress Bar
                      LinearProgressIndicator(
                        value: _questions.isEmpty
                            ? 0
                            : ((_currentQuestionIndex + 1) / _questions.length)
                                .clamp(0.0, 1.0),
                        backgroundColor: Colors.grey.shade200,
                        valueColor:
                            AlwaysStoppedAnimation<Color>(Colors.blue.shade600),
                        minHeight: 4,
                      ),

                      // Questions
                      Expanded(
                        child: _questions.isEmpty
                            ? const Center(
                                child: CircularProgressIndicator(),
                              )
                            : PageView.builder(
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Tell us about yourself',
                style: GoogleFonts.poppins(
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                  color: Colors.blue.shade800,
                ),
              ),
              TextButton.icon(
                onPressed: () {
                  setState(() {
                    _nameController.text = "Dummy User";
                    _educationController.text = "Undergraduate (Bachelor's)";
                    _skillsController.text = "Java, Flutter, SQL";
                    _interestsController.text = "Software Development, AI";
                  });
                },
                icon: const Icon(Icons.flash_on, size: 18),
                label: const Text('Dummy Data'),
                style: TextButton.styleFrom(
                    foregroundColor: Colors.orange.shade800),
              ),
            ],
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
          DropdownButtonFormField<String>(
            value: _educationController.text.isNotEmpty &&
                    [
                      "Higher Secondary (11-12)",
                      "Diploma",
                      "Undergraduate (Bachelor's)",
                      "Postgraduate (Master's)",
                      "Doctorate (PhD)",
                      "Working Professional",
                      "Other"
                    ].contains(_educationController.text)
                ? _educationController.text
                : null,
            decoration: InputDecoration(
              labelText: 'Highest Education Level',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            items: [
              "Higher Secondary (11-12)",
              "Diploma",
              "Undergraduate (Bachelor's)",
              "Postgraduate (Master's)",
              "Doctorate (PhD)",
              "Working Professional",
              "Other"
            ].map((String value) {
              return DropdownMenuItem<String>(
                value: value,
                child: Text(value),
              );
            }).toList(),
            onChanged: (String? newValue) {
              if (newValue != null) {
                _educationController.text = newValue;
              }
            },
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
              onPressed: _isLoadingQuestions ? null : _loadQuestions,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                backgroundColor: Colors.blue.shade600,
              ),
              child: _isLoadingQuestions
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : Text(
                      'Start Assessment',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionCard(int questionIndex) {
    if (_questions.isEmpty || questionIndex >= _questions.length) {
      return const Center(child: CircularProgressIndicator());
    }

    final question = _questions[questionIndex];
    final currentAnswer = _answers[questionIndex];
    final questionText =
        question['question_text'] ?? question['quiz'] ?? 'Unknown Question';
    final category = question['category'] ?? 'General';
    final isMath = question['isMath'] == true;
    final isRiasec = [
      'Realistic',
      'Investigative',
      'Artistic',
      'Social',
      'Enterprising',
      'Conventional'
    ].contains(category);
    final options = question['options'] as List<dynamic>?;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row: Category Tag and (Optional) Timer
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  category,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.blue.shade700,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              if (isMath)
                Row(
                  children: [
                    Icon(
                      Icons.timer_outlined,
                      color: _timeLeft <= 3 ? Colors.red : Colors.orange,
                      size: 20,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '$_timeLeft s',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: _timeLeft <= 3 ? Colors.red : Colors.orange,
                      ),
                    ),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 24),

          // Question
          Text(
            questionText,
            style: GoogleFonts.poppins(
              fontSize: 24,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade800,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 40),

          // Options or Rating Bar
          if (options != null && options.isNotEmpty && !isRiasec)
            ...options.map((option) {
              final isSelected = currentAnswer == option.toString();
              return Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: InkWell(
                  onTap: () {
                    _answerQuestion(option.toString());
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.blue.shade50 : Colors.white,
                      border: Border.all(
                        color: isSelected
                            ? Colors.blue.shade400
                            : Colors.grey.shade300,
                        width: isSelected ? 2 : 1,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      option.toString(),
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        color: isSelected
                            ? Colors.blue.shade800
                            : Colors.grey.shade800,
                        fontWeight:
                            isSelected ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                  ),
                ),
              );
            }).toList()
          else
            Column(
              children: [
                Center(
                  child: RatingBar.builder(
                    initialRating:
                        currentAnswer is double ? currentAnswer : 0.0,
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
                if (isRiasec) ...[
                  const SizedBox(height: 32),
                  InkWell(
                    onTap: () => _answerQuestion('Not sure'),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: currentAnswer == 'Not sure'
                            ? Colors.blue.shade50
                            : Colors.white,
                        border: Border.all(
                          color: currentAnswer == 'Not sure'
                              ? Colors.blue.shade400
                              : Colors.grey.shade300,
                          width: currentAnswer == 'Not sure' ? 2 : 1,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        'Not sure',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: currentAnswer == 'Not sure'
                              ? FontWeight.w600
                              : FontWeight.normal,
                          color: currentAnswer == 'Not sure'
                              ? Colors.blue.shade800
                              : Colors.grey.shade800,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),

          const SizedBox(height: 40),

          // Navigation Buttons
          if (questionIndex > 0 && !isMath)
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

          if (questionIndex == 0)
            Padding(
              padding: const EdgeInsets.only(top: 20),
              child: Center(
                child: TextButton.icon(
                  onPressed: _fillDummyDataAndSubmit,
                  icon: const Icon(Icons.bolt, color: Colors.orange),
                  label: Text(
                    'DEBUG: Fill Dummy & Submit',
                    style: GoogleFonts.poppins(
                        color: Colors.orange, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
