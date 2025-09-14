import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher_string.dart';
import 'learning_path_screen.dart';

class JobRecommendationsScreen extends StatelessWidget {
  final String name;
  final String educationLevel;
  final List<String> skills;
  final String interests;
  final String skillLevel;
  final Map<int, double> assessmentResults;

  JobRecommendationsScreen({
    super.key,
    required this.name,
    required this.educationLevel,
    required this.skills,
    required this.interests,
    required this.skillLevel,
    required this.assessmentResults,
  });

  // Sample job data - in a real app, this would come from an API
  final List<Map<String, dynamic>> _jobRecommendations = [
    {
      'title': 'Software Developer',
      'match': 87,
      'description':
          'Develop applications and systems that run on computers or mobile devices using programming languages like Dart, JavaScript, Python, etc.',
      'requiredSkills': ['Dart', 'Flutter', 'Algorithms', 'Problem Solving'],
      'averageSalary': '₹6-12 LPA',
      'growth': '27% (Much faster than average)',
    },
    {
      'title': 'Data Analyst',
      'match': 78,
      'description':
          'Collect, process, and perform statistical analyses of data to help organizations make better decisions.',
      'requiredSkills': ['SQL', 'Python', 'Data Visualization', 'Statistics'],
      'averageSalary': '₹5-10 LPA',
      'growth': '25% (Much faster than average)',
    },
    {
      'title': 'UX/UI Designer',
      'match': 72,
      'description':
          'Create user-friendly interfaces that enable users to understand how to use complex technical products.',
      'requiredSkills': [
        'Figma',
        'User Research',
        'Wireframing',
        'UI/UX Principles'
      ],
      'averageSalary': '₹5-12 LPA',
      'growth': '22% (Faster than average)',
    },
  ];

  // Calculate matching skills for a job
  List<String> _getMatchingSkills(List<String> requiredSkills) {
    return requiredSkills
        .where((skill) =>
            skills.any((s) => s.toLowerCase().contains(skill.toLowerCase())))
        .toList();
  }

  // Calculate missing skills for a job
  List<String> _getMissingSkills(List<String> requiredSkills) {
    return requiredSkills
        .where((skill) =>
            !skills.any((s) => s.toLowerCase().contains(skill.toLowerCase())))
        .toList();
  }

  // Get color based on match percentage
  Color _getMatchColor(int match) {
    if (match >= 80) return Colors.green;
    if (match >= 60) return Colors.orange;
    return Colors.red;
  }

  // Launch URL
  void _launchURL(String url) async {
    if (await canLaunchUrlString(url)) {
      await launchUrlString(url);
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Your Career Matches'),
          bottom: TabBar(
            tabs: [
              Tab(text: 'Recommended Jobs'),
              Tab(text: 'Your Profile'),
            ],
            labelColor: Colors.blue.shade800,
            indicatorColor: Colors.blue.shade800,
            unselectedLabelColor: Colors.grey,
          ),
        ),
        body: TabBarView(
          children: [
            // Recommended Jobs Tab
            _buildRecommendationsTab(context),
            // Profile Summary Tab
            _buildProfileTab(context),
          ],
        ),
      ),
    );
  }

  Widget _buildRecommendationsTab(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _jobRecommendations.length,
      itemBuilder: (context, index) {
        final job = _jobRecommendations[index];
        final matchingSkills = _getMatchingSkills(job['requiredSkills']);
        final missingSkills = _getMissingSkills(job['requiredSkills']);

        return Card(
          margin: const EdgeInsets.only(bottom: 20),
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Job Title and Match Score
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        job['title'],
                        style: GoogleFonts.poppins(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: Colors.blue.shade900,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: _getMatchColor(job['match']).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: _getMatchColor(job['match']).withOpacity(0.3),
                        ),
                      ),
                      child: Text(
                        '${job['match']}% Match',
                        style: GoogleFonts.poppins(
                          color: _getMatchColor(job['match']),
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Job Description
                Text(
                  job['description'],
                  style: GoogleFonts.poppins(
                    color: Colors.grey.shade700,
                    fontSize: 14,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 16),

                // Matching Skills
                if (matchingSkills.isNotEmpty) ...[
                  Text(
                    'Your Matching Skills:',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w500,
                      fontSize: 14,
                      color: Colors.green.shade700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: matchingSkills
                        .map((skill) => Chip(
                              label: Text(skill),
                              backgroundColor: Colors.green.shade50,
                              labelStyle:
                                  TextStyle(color: Colors.green.shade800),
                              padding: EdgeInsets.zero,
                              materialTapTargetSize:
                                  MaterialTapTargetSize.shrinkWrap,
                            ))
                        .toList(),
                  ),
                  const SizedBox(height: 12),
                ],

                // Missing Skills
                if (missingSkills.isNotEmpty) ...[
                  Text(
                    'Skills to Develop:',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w500,
                      fontSize: 14,
                      color: Colors.orange.shade700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: missingSkills
                        .map((skill) => Chip(
                              label: Text(skill),
                              backgroundColor: Colors.orange.shade50,
                              labelStyle:
                                  TextStyle(color: Colors.orange.shade800),
                              padding: EdgeInsets.zero,
                              materialTapTargetSize:
                                  MaterialTapTargetSize.shrinkWrap,
                            ))
                        .toList(),
                  ),
                  const SizedBox(height: 12),
                ],

                // Job Details
                _buildInfoRow('Education Level', educationLevel),
                _buildInfoRow('Average Salary', job['averageSalary']),
                _buildInfoRow('Job Growth', job['growth']),

                const SizedBox(height: 16),

                // Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          // Show more details dialog
                          _showJobDetails(
                              context, job, matchingSkills, missingSkills);
                        },
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: Colors.blue.shade600),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Text(
                          'View Details',
                          style: GoogleFonts.poppins(
                            color: Colors.blue.shade600,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => LearningPathScreen(
                                jobTitle: job['title'],
                                missingSkills: missingSkills,
                              ),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue.shade600,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Text(
                          'Learning Path',
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildProfileTab(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Profile Summary Card
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Your Profile Summary',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.blue.shade900,
                    ),
                  ),
                  const Divider(),
                  _buildProfileInfoRow('Name', name),
                  _buildProfileInfoRow('Education Level', educationLevel),
                  _buildProfileInfoRow('Skill Level', skillLevel),
                  const SizedBox(height: 8),
                  Text(
                    'Your Skills:',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w500,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: skills
                        .map((skill) => Chip(
                              label: Text(skill),
                              backgroundColor: Colors.blue.shade50,
                              labelStyle:
                                  TextStyle(color: Colors.blue.shade800),
                            ))
                        .toList(),
                  ),
                  if (interests.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text(
                      'Interests:',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w500,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      interests,
                      style: GoogleFonts.poppins(
                        color: Colors.grey.shade700,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Assessment Results
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Your Skill Assessment',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.blue.shade900,
                    ),
                  ),
                  const Divider(),
                  Text(
                    'Overall Skill Level: $skillLevel',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.blue.shade800,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ..._buildSkillCategories(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildSkillCategories() {
    // Group questions by category
    final Map<String, List<double>> categories = {};

    // Sample questions from the questionnaire
    final List<Map<String, dynamic>> questions = [
      {'category': 'Analytical Skills'},
      {'category': 'Communication'},
      {'category': 'Teamwork'},
      {'category': 'Organization'},
      {'category': 'Adaptability'},
      {'category': 'Leadership'},
      {'category': 'Innovation'},
      {'category': 'Resilience'},
    ];

    // Initialize categories
    for (var q in questions) {
      categories[q['category']] = [];
    }

    // Add scores to categories (in a real app, this would be based on actual answers)
    // For now, we'll use random values for demonstration
    final random = DateTime.now().millisecondsSinceEpoch;
    categories.forEach((key, value) {
      // Generate a random score between 2.5 and 5.0 for demonstration
      final score = 2.5 + (random % 25) / 10.0;
      value.add(score > 5.0 ? 5.0 : score);
    });

    return categories.entries.map((entry) {
      final category = entry.key;
      final score = entry.value.first;
      final percentage = (score / 5.0) * 100;

      return Padding(
        padding: const EdgeInsets.only(bottom: 12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  category,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  '${percentage.toStringAsFixed(0)}%',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: _getPercentageColor(percentage),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            LinearProgressIndicator(
              value: percentage / 100,
              backgroundColor: Colors.grey.shade200,
              valueColor: AlwaysStoppedAnimation<Color>(
                _getPercentageColor(percentage),
              ),
              minHeight: 6,
              borderRadius: BorderRadius.circular(3),
            ),
          ],
        ),
      );
    }).toList();
  }

  Color _getPercentageColor(double percentage) {
    if (percentage >= 70) return Colors.green;
    if (percentage >= 40) return Colors.orange;
    return Colors.red;
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w500,
                fontSize: 13,
                color: Colors.grey.shade700,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: Colors.grey.shade800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.grey.shade800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showJobDetails(
    BuildContext context,
    Map<String, dynamic> job,
    List<String> matchingSkills,
    List<String> missingSkills,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (_, controller) => SingleChildScrollView(
          controller: controller,
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(5),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  job['title'],
                  style: GoogleFonts.poppins(
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                    color: Colors.blue.shade900,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Job Description',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  job['description'],
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    color: Colors.grey.shade800,
                    height: 1.6,
                  ),
                ),
                const SizedBox(height: 20),

                // Matching Skills
                Text(
                  'Your Matching Skills',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: matchingSkills
                      .map((skill) => Chip(
                            label: Text(skill),
                            backgroundColor: Colors.green.shade50,
                            labelStyle: TextStyle(color: Colors.green.shade800),
                          ))
                      .toList(),
                ),

                // Missing Skills
                if (missingSkills.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  Text(
                    'Skills to Develop',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: missingSkills
                        .map((skill) => Chip(
                              label: Text(skill),
                              backgroundColor: Colors.orange.shade50,
                              labelStyle:
                                  TextStyle(color: Colors.orange.shade800),
                            ))
                        .toList(),
                  ),
                ],

                // Job Details
                const SizedBox(height: 24),
                _buildDetailItem(
                    Icons.school, 'Education Level', educationLevel),
                _buildDetailItem(
                    Icons.attach_money, 'Average Salary', job['averageSalary']),
                _buildDetailItem(
                    Icons.trending_up, 'Job Growth', job['growth']),

                const SizedBox(height: 30),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => LearningPathScreen(
                            jobTitle: job['title'],
                            missingSkills: missingSkills,
                          ),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue.shade600,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: Text(
                      'View Learning Path',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailItem(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Colors.blue.shade600),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey.shade900,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
