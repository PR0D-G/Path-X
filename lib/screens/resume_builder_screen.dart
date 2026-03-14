import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/job_model.dart';
import '../services/job_service.dart';

class ResumeBuilderScreen extends StatefulWidget {
  const ResumeBuilderScreen({super.key});

  @override
  State<ResumeBuilderScreen> createState() => _ResumeBuilderScreenState();
}

class _ResumeBuilderScreenState extends State<ResumeBuilderScreen> {
  // Form fields
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _summaryController = TextEditingController();
  final TextEditingController _experienceController = TextEditingController();
  final TextEditingController _skillsController = TextEditingController();

  Job? _targetJob;
  List<Job> _availableJobs = [];
  bool _isLoadingJobs = true;
  int _currentStep = 0;

  // Premium Theme Colors
  // Premium Theme Colors (Light Mode)
  static const Color premiumGold = Color(0xFFB8860B);
  static const Color premiumDarkBlue = Color(0xFF1E293B); 
  static const Color premiumBackground = Color(0xFFF8FAFC);
  static const Color premiumCardBg = Colors.white;

  @override
  void initState() {
    super.initState();
    _loadJobs();
  }

  Future<void> _loadJobs() async {
    try {
      final jobs = await JobService.getJobs();
      setState(() {
        _availableJobs = jobs;
        _isLoadingJobs = false;
      });
    } catch (e) {
      debugPrint('Error loading jobs: $e');
      setState(() => _isLoadingJobs = false);
    }
  }

  void _generateSuggestions() {
    if (_targetJob == null) return;
    
    final jobSkills = _targetJob!.coreSkills;
    final userSkills = _skillsController.text.toLowerCase();
    
    List<String> missing = [];
    for (var s in jobSkills) {
      if (!userSkills.contains(s.toLowerCase())) {
        missing.add(s);
      }
    }

    if (missing.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('AI Suggestion: Consider adding skills like ${missing.take(2).join(", ")} for ${_targetJob!.roleTitle}'),
          backgroundColor: premiumGold,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: premiumBackground,
      appBar: AppBar(
        title: Text('Smart Resume Builder', style: GoogleFonts.outfit(color: premiumGold, fontWeight: FontWeight.w700, fontSize: 22, letterSpacing: 0.5)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: const BackButton(color: premiumDarkBlue),
      ),
      body: _isLoadingJobs 
        ? const Center(child: CircularProgressIndicator(color: premiumGold))
        : Theme(
            data: Theme.of(context).copyWith(
              canvasColor: premiumBackground,
              colorScheme: ColorScheme.light(primary: premiumGold, secondary: premiumGold, onSurface: premiumDarkBlue),
            ),
            child: Stepper(
              type: StepperType.vertical,
              currentStep: _currentStep,
              onStepContinue: () {
                if (_currentStep < 3) {
                  setState(() => _currentStep++);
                  if (_currentStep == 3) _generateSuggestions();
                } else {
                  // Final submission
                  _showFinishDialog();
                }
              },
              onStepCancel: () {
                if (_currentStep > 0) setState(() => _currentStep--);
              },
              controlsBuilder: (context, details) {
                return Padding(
                  padding: const EdgeInsets.only(top: 20),
                  child: Row(
                    children: [
                      ElevatedButton(
                        onPressed: details.onStepContinue,
                        style: ElevatedButton.styleFrom(backgroundColor: premiumGold, foregroundColor: premiumDarkBlue),
                        child: Text(_currentStep == 3 ? 'FINISH' : 'NEXT'),
                      ),
                      if (_currentStep > 0)
                        TextButton(
                          onPressed: details.onStepCancel,
                          child: Text('BACK', style: TextStyle(color: premiumDarkBlue.withOpacity(0.5))),
                        ),
                    ],
                  ),
                );
              },
              steps: [
                Step(
                  title: Text('Target Career', style: GoogleFonts.outfit(color: premiumDarkBlue)),
                  content: _buildJobSelector(),
                  isActive: _currentStep >= 0,
                ),
                Step(
                  title: Text('Personal Info', style: GoogleFonts.outfit(color: premiumDarkBlue)),
                  content: Column(
                    children: [
                      _buildTextField(_nameController, 'Full Name', Icons.person),
                      const SizedBox(height: 12),
                      _buildTextField(_emailController, 'Email Address', Icons.email),
                    ],
                  ),
                  isActive: _currentStep >= 1,
                ),
                Step(
                  title: Text('Professional Summary', style: GoogleFonts.outfit(color: premiumDarkBlue)),
                  content: _buildTextField(_summaryController, 'Briefly describe yourself...', Icons.description, maxLines: 4),
                  isActive: _currentStep >= 2,
                ),
                Step(
                  title: Text('Skills & Experience', style: GoogleFonts.outfit(color: premiumDarkBlue)),
                  content: Column(
                    children: [
                      _buildTextField(_skillsController, 'List your skills (comma separated)', Icons.bolt, hint: 'e.g. Python, SQL, Project Management'),
                      const SizedBox(height: 12),
                      _buildTextField(_experienceController, 'Briefly list your work experience', Icons.work, maxLines: 5),
                    ],
                  ),
                  isActive: _currentStep >= 3,
                ),
              ],
            ),
          ),
    );
  }

  Widget _buildJobSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: premiumCardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<Job>(
          isExpanded: true,
          dropdownColor: premiumCardBg,
          hint: Text('Select target role', style: TextStyle(color: Colors.white.withOpacity(0.5))),
          value: _targetJob,
          items: _availableJobs.map((job) {
            return DropdownMenuItem<Job>(
              value: job,
              child: Text(job.roleTitle, style: const TextStyle(color: premiumDarkBlue)),
            );
          }).toList(),
          onChanged: (val) => setState(() => _targetJob = val),
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, IconData icon, {int maxLines = 1, String? hint}) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      style: const TextStyle(color: premiumDarkBlue),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
        labelStyle: const TextStyle(color: premiumGold),
        prefixIcon: Icon(icon, color: premiumGold),
        filled: true,
        fillColor: premiumCardBg,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: premiumDarkBlue.withOpacity(0.1))),
      ),
    );
  }

  void _showFinishDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: premiumCardBg,
        title: Text('Resume Ready!', style: GoogleFonts.outfit(color: premiumGold)),
        content: Text(
          'Your resume draft has been created. Based on your target role as ${_targetJob?.roleTitle}, we recommend emphasizing your ${(_targetJob?.coreSkills.take(2).join(" and ") ?? "relevant")} skills.',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text('DOWNLOAD PDF', style: TextStyle(color: premiumGold)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('EDIT', style: TextStyle(color: Colors.white54)),
          ),
        ],
      ),
    );
  }
}
