import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher_string.dart';

class LearningPathScreen extends StatelessWidget {
  final String jobTitle;
  final List<String> missingSkills;

  const LearningPathScreen({
    super.key,
    required this.jobTitle,
    required this.missingSkills,
  });

  // Sample learning resources - in a real app, this would come from an API
  Map<String, List<Map<String, dynamic>>> _getLearningResources() {
    return {
      'Dart': [
        {
          'title': 'Dart Programming - Full Course',
          'platform': 'YouTube',
          'duration': '4.5 hours',
          'level': 'Beginner',
          'url': 'https://www.youtube.com/watch?v=Ej_Pcr4uC2Q',
          'free': true,
        },
        {
          'title': 'Dart Programming Tutorial',
          'platform': 'W3Schools',
          'duration': 'Self-paced',
          'level': 'Beginner',
          'url': 'https://www.w3adda.com/dart-tutorial',
          'free': true,
        },
      ],
      'Flutter': [
        {
          'title': 'Flutter Tutorial for Beginners',
          'platform': 'YouTube',
          'duration': '6 hours',
          'level': 'Beginner',
          'url': 'https://www.youtube.com/watch?v=1ukSR1GRtMU',
          'free': true,
        },
        {
          'title': 'Flutter & Dart - The Complete Guide',
          'platform': 'Udemy',
          'duration': '45 hours',
          'level': 'All Levels',
          'url':
              'https://www.udemy.com/course/learn-flutter-dart-to-build-ios-android-apps/',
          'free': false,
        },
      ],
      'Algorithms': [
        {
          'title': 'Data Structures and Algorithms in Dart',
          'platform': 'GitHub',
          'duration': 'Self-paced',
          'level': 'Intermediate',
          'url': 'https://github.com/TheAlgorithms/Dart',
          'free': true,
        },
        {
          'title': 'Algorithms - NPTEL',
          'platform': 'NPTEL',
          'duration': '12 weeks',
          'level': 'Intermediate',
          'url': 'https://onlinecourses.nptel.ac.in/noc23_cs109/preview',
          'free': true,
        },
      ],
      'Problem Solving': [
        {
          'title': 'Problem Solving with Data Structures',
          'platform': 'Coursera',
          'duration': '4 weeks',
          'level': 'Beginner',
          'url': 'https://www.coursera.org/learn/data-structures-algorithms',
          'free': true,
        },
        {
          'title': 'LeetCode Problems for Beginners',
          'platform': 'LeetCode',
          'duration': 'Self-paced',
          'level': 'Beginner',
          'url': 'https://leetcode.com/explore/learn/card/recursion-i/',
          'free': true,
        },
      ],
    };
  }

  // Launch URL
  void _launchURL(String url) async {
    if (await canLaunchUrlString(url)) {
      await launchUrlString(url);
    } else {
      throw 'Could not launch $url';
    }
  }

  @override
  Widget build(BuildContext context) {
    final learningResources = _getLearningResources();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Learning Path'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Text(
              'Become a $jobTitle',
              style: GoogleFonts.poppins(
                fontSize: 24,
                fontWeight: FontWeight.w600,
                color: Colors.blue.shade900,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Master these skills to become job-ready',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 24),

            // Learning Path Progress
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
                      'Your Learning Progress',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ...missingSkills
                        .map((skill) => _buildSkillProgress(skill))
                        .toList(),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Recommended Resources
            Text(
              'Recommended Learning Resources',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.blue.shade900,
              ),
            ),
            const SizedBox(height: 12),

            // Resources for each missing skill
            ...missingSkills.expand((skill) {
              final resources = learningResources[skill] ?? [];
              if (resources.isEmpty) return <Widget>[];

              return [
                const SizedBox(height: 8),
                Text(
                  'For $skill:',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                ...resources
                    .map((resource) => _buildResourceCard(resource))
                    .toList(),
                const SizedBox(height: 8),
              ];
            }).toList(),

            const SizedBox(height: 24),

            // Additional Resources
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
                      'Additional Learning Platforms',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildAdditionalResource(
                      'Coursera',
                      'Access courses from top universities and companies',
                      'https://www.coursera.org',
                    ),
                    _buildAdditionalResource(
                      'edX',
                      'Online courses from the world\'s best universities',
                      'https://www.edx.org',
                    ),
                    _buildAdditionalResource(
                      'NPTEL',
                      'Free online courses from IITs and IISc',
                      'https://nptel.ac.in',
                    ),
                    _buildAdditionalResource(
                      'freeCodeCamp',
                      'Learn to code for free',
                      'https://www.freecodecamp.org',
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSkillProgress(String skill) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                skill,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                '0%',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          LinearProgressIndicator(
            value: 0.0,
            backgroundColor: Colors.grey.shade200,
            valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
            minHeight: 6,
            borderRadius: BorderRadius.circular(3),
          ),
        ],
      ),
    );
  }

  Widget _buildResourceCard(Map<String, dynamic> resource) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(
          color: Colors.grey.shade200,
          width: 1,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () => _launchURL(resource['url']),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Platform Icon
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      _getPlatformIcon(resource['platform']),
                      size: 20,
                      color: Colors.blue.shade700,
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Title and Platform
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          resource['title'],
                          style: GoogleFonts.poppins(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            color: Colors.blue.shade900,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          resource['platform'],
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Free/Paid Badge
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: resource['free']
                          ? Colors.green.shade50
                          : Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      resource['free'] ? 'FREE' : 'PAID',
                      style: GoogleFonts.poppins(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: resource['free']
                            ? Colors.green.shade800
                            : Colors.orange.shade800,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Duration and Level
              Row(
                children: [
                  _buildInfoChip(
                    Icons.timer_outlined,
                    resource['duration'],
                  ),
                  const SizedBox(width: 8),
                  _buildInfoChip(
                    Icons.school_outlined,
                    resource['level'],
                  ),
                  const Spacer(),
                  Text(
                    'Start Learning →',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.blue.shade600,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAdditionalResource(
      String title, String description, String url) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.blue.shade50,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          Icons.school_outlined,
          color: Colors.blue.shade700,
          size: 20,
        ),
      ),
      title: Text(
        title,
        style: GoogleFonts.poppins(
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: Text(
        description,
        style: GoogleFonts.poppins(
          fontSize: 12,
          color: Colors.grey.shade600,
        ),
      ),
      onTap: () => _launchURL(url),
      trailing: Icon(
        Icons.arrow_forward_ios,
        size: 16,
        color: Colors.grey.shade500,
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 12,
            color: Colors.grey.shade600,
          ),
          const SizedBox(width: 4),
          Text(
            text,
            style: GoogleFonts.poppins(
              fontSize: 10,
              color: Colors.grey.shade800,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  IconData _getPlatformIcon(String platform) {
    switch (platform) {
      case 'YouTube':
        return Icons.play_circle_outline;
      case 'Coursera':
        return Icons.school_outlined;
      case 'Udemy':
        return Icons.laptop_chromebook_outlined;
      case 'GitHub':
        return Icons.code_outlined;
      case 'NPTEL':
        return Icons.school_outlined;
      case 'LeetCode':
        return Icons.psychology_outlined;
      default:
        return Icons.launch_outlined;
    }
  }
}
