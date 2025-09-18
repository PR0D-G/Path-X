import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:provider/provider.dart';
import '../models/job_model.dart';
import '../providers/auth_provider.dart';

class LearningPathScreen extends StatefulWidget {
  const LearningPathScreen({super.key});

  @override
  State<LearningPathScreen> createState() => _LearningPathScreenState();
}

class _LearningPathScreenState extends State<LearningPathScreen> {
  late Job? job;
  late List<String> missingSkills = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    // Get job from route arguments
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args =
          ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>?;
      if (args != null && args['job'] != null) {
        setState(() {
          job = args['job'] as Job;
          // In a real app, calculate missing skills based on user's current skills
          missingSkills = job?.coreSkills.take(3).toList() ?? [];
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    });
  }

  // Get learning resources for the job
  Map<String, List<Map<String, dynamic>>> _getLearningResources() {
    if (job == null) return {};

    // Convert learning resources from job to the format expected by the UI
    final resources = <String, List<Map<String, dynamic>>>{};

    for (final resource in job!.learningResources) {
      final platform = resource.platform;

      // Handle resources with direct courses list
      if (resource.courses != null) {
        for (final course in resource.courses!) {
          resources.putIfAbsent(platform, () => []).add({
            'title': course,
            'platform': platform,
            'duration': 'Self-paced',
            'level': 'Intermediate',
            'url': resource.url ?? '',
            'free':
                !platform.toLowerCase().contains('udemy'), // Simple heuristic
          });
        }
      }

      // Handle resources with direct title and URL
      if (resource.title != null && resource.url != null) {
        resources.putIfAbsent(platform, () => []).add({
          'title': resource.title!,
          'platform': platform,
          'duration': 'Self-paced',
          'level': 'Intermediate',
          'url': resource.url!,
          'free': !platform.toLowerCase().contains('udemy'), // Simple heuristic
        });
      }
    }

    // If no resources found, return some default ones based on job role
    if (resources.isEmpty) {
      final jobTitle = job!.roleTitle.toLowerCase();
      if (jobTitle.contains('flutter') || jobTitle.contains('mobile')) {
        return _getFlutterResources();
      } else if (jobTitle.contains('web') || jobTitle.contains('frontend')) {
        return _getWebDevResources();
      } else if (jobTitle.contains('data') || jobTitle.contains('analyst')) {
        return _getDataScienceResources();
      }
      return _getGeneralResources();
    }

    return resources;
  }

  Map<String, List<Map<String, dynamic>>> _getFlutterResources() {
    return {
      'Flutter': [
        {
          'title': 'Flutter & Dart - The Complete Guide',
          'platform': 'Udemy',
          'duration': '45 hours',
          'level': 'All Levels',
          'url':
              'https://www.udemy.com/course/learn-flutter-dart-to-build-ios-android-apps/',
          'free': false,
        },
        {
          'title': 'Flutter Tutorial for Beginners',
          'platform': 'YouTube',
          'duration': '6 hours',
          'level': 'Beginner',
          'url': 'https://www.youtube.com/watch?v=1ukSR1GRtMU',
          'free': true,
        },
      ],
    };
  }

  Map<String, List<Map<String, dynamic>>> _getWebDevResources() {
    return {
      'Web Development': [
        {
          'title': 'The Web Developer Bootcamp',
          'platform': 'Udemy',
          'duration': '63.5 hours',
          'level': 'Beginner',
          'url': 'https://www.udemy.com/course/the-web-developer-bootcamp/',
          'free': false,
        },
        {
          'title': 'HTML & CSS Full Course',
          'platform': 'freeCodeCamp',
          'duration': '11 hours',
          'level': 'Beginner',
          'url': 'https://www.freecodecamp.org/learn/responsive-web-design/',
          'free': true,
        },
      ],
    };
  }

  Map<String, List<Map<String, dynamic>>> _getDataScienceResources() {
    return {
      'Data Science': [
        {
          'title': 'Data Science Specialization',
          'platform': 'Coursera',
          'duration': '11 months',
          'level': 'Beginner',
          'url': 'https://www.coursera.org/specializations/jhu-data-science',
          'free': false,
        },
        {
          'title': 'Python for Data Science',
          'platform': 'edX',
          'duration': '12 weeks',
          'level': 'Beginner',
          'url': 'https://www.edx.org/course/python-for-data-science',
          'free': true,
        },
      ],
    };
  }

  Map<String, List<Map<String, dynamic>>> _getGeneralResources() {
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

  // Launch URL in browser
  Future<void> _launchURL(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not launch $url')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Learning Path'),
          backgroundColor: Colors.white,
          foregroundColor: Colors.black87,
          elevation: 0,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (job == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Learning Path'),
          backgroundColor: Colors.white,
          foregroundColor: Colors.black87,
          elevation: 0,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'No job selected. Please go back and select a job first.',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(fontSize: 16),
            ),
          ),
        ),
      );
    }

    final resources = _getLearningResources();
    final hasResources = resources.isNotEmpty;

    return Consumer<AuthProvider>(
      builder: (context, authProvider, _) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Learning Path'),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Job Overview Card
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          job!.roleTitle,
                          style: GoogleFonts.poppins(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        if (job!.education.isNotEmpty) ...[
                          Text(
                            'Education: ${job!.education}',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: Colors.grey[700],
                            ),
                          ),
                          const SizedBox(height: 4),
                        ],
                        if (job!.averageSalary.isNotEmpty) ...[
                          Text(
                            'Avg. Salary: ${job!.averageSalary} LPA',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: Colors.green[700],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 4),
                        ],
                        if (job!.jobGrowthOutlook.isNotEmpty) ...[
                          Text(
                            'Growth Outlook: ${job!.jobGrowthOutlook}',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: Colors.blue[700],
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],
                        if (job!.coreSkills.isNotEmpty) ...[
                          Text(
                            'Key Skills:',
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: job!.coreSkills
                                .take(5)
                                .map(
                                  (skill) => Chip(
                                    label: Text(
                                      skill,
                                      style: GoogleFonts.poppins(fontSize: 11),
                                    ),
                                    backgroundColor: Colors.blue.shade50,
                                    labelStyle: GoogleFonts.poppins(
                                      fontSize: 11,
                                      color: Colors.blue.shade800,
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 2),
                                  ),
                                )
                                .toList(),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                !hasResources
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Text(
                            'No learning resources available for ${job!.roleTitle} at the moment.\nCheck back later!',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.poppins(fontSize: 16),
                          ),
                        ),
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
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
                            final resources =
                                _getLearningResources()[skill] ?? [];
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
                              ...resources.map(
                                  (resource) => _buildResourceCard(resource)),
                              const SizedBox(height: 8),
                            ];
                          }),
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
              ],
            ),
          ),
        );
      },
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
