import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'questionnaire_screen.dart';

class ProfileInputScreen extends StatefulWidget {
  const ProfileInputScreen({super.key});

  @override
  State<ProfileInputScreen> createState() => _ProfileInputScreenState();
}

class _ProfileInputScreenState extends State<ProfileInputScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  String? _selectedEducation;
  final List<String> _educationLevels = [
    'High School',
    'Associate Degree',
    'Bachelor\'s Degree',
    'Master\'s Degree',
    'Doctorate',
    'Other'
  ];

  final List<String> _selectedSkills = [];
  final TextEditingController _skillController = TextEditingController();
  final TextEditingController _interestsController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _skillController.dispose();
    _interestsController.dispose();
    super.dispose();
  }

  void _addSkill() {
    if (_skillController.text.trim().isNotEmpty) {
      setState(() {
        _selectedSkills.add(_skillController.text.trim());
        _skillController.clear();
      });
    }
  }

  void _removeSkill(String skill) {
    setState(() {
      _selectedSkills.remove(skill);
    });
  }

  void _submitForm() {
    if (_formKey.currentState!.validate() && _selectedEducation != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => QuestionnaireScreen(
            name: _nameController.text,
            educationLevel: _selectedEducation!,
            skills: _selectedSkills,
            interests: _interestsController.text,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Profile'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Text(
                'Tell us about yourself',
                style: GoogleFonts.poppins(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue.shade800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'This will help us provide better career recommendations',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 30),

              // Name Field
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Full Name',
                  prefixIcon: const Icon(Icons.person_outline),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // Education Level Dropdown
              DropdownButtonFormField<String>(
                value: _selectedEducation,
                decoration: InputDecoration(
                  labelText: 'Education Level',
                  prefixIcon: const Icon(Icons.school_outlined),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                items: _educationLevels
                    .map((level) => DropdownMenuItem(
                          value: level,
                          child: Text(level),
                        ))
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedEducation = value;
                  });
                },
                validator: (value) {
                  if (value == null) {
                    return 'Please select your education level';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // Skills Input
              Text(
                'Your Skills',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _skillController,
                      decoration: InputDecoration(
                        hintText: 'Add a skill (e.g., Python, Leadership)',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onFieldSubmitted: (_) => _addSkill(),
                    ),
                  ),
                  IconButton(
                    onPressed: _addSkill,
                    icon: const Icon(Icons.add_circle_outline),
                    color: Colors.blue,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // Display selected skills as chips
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _selectedSkills
                    .map((skill) => Chip(
                          label: Text(skill),
                          deleteIcon: const Icon(Icons.close, size: 16),
                          onDeleted: () => _removeSkill(skill),
                        ))
                    .toList(),
              ),
              const SizedBox(height: 20),

              // Interests/Dream Job
              TextFormField(
                controller: _interestsController,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'Interests / Dream Job (Optional)',
                  hintText:
                      'E.g., Software Development, Data Science, Entrepreneurship',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 30),

              // Submit Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _submitForm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade600,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    'Continue to Assessment',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
