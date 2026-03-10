import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/job_model.dart';
import '../providers/auth_provider.dart';
import '../services/job_service.dart';

class JobRecommendationsScreen extends StatefulWidget {
  const JobRecommendationsScreen({
    super.key,
  });

  @override
  State<JobRecommendationsScreen> createState() =>
      _JobRecommendationsScreenState();
}

class _JobRecommendationsScreenState extends State<JobRecommendationsScreen> {
  late Future<List<Job>> _jobsFuture;

  @override
  void initState() {
    super.initState();
    _jobsFuture = _loadAndFilterJobs();
  }

  Future<List<Job>> _loadAndFilterJobs() async {
    try {
      // Use the new matching algorithm from JobService
      return await JobService.getMatchedCareers();
    } catch (e) {
      debugPrint('Error loading matched jobs: $e');
      throw Exception('Failed to load job recommendations');
    }
  }

  // Calculate matching skills for a job
  List<String> _getMatchingSkills(Job job, [List<String>? userSkills]) {
    try {
      final authProvider = Provider.of<AppAuthProvider>(context, listen: false);
      final skills = userSkills ?? authProvider.userSkills;
      final userSkillsLower = skills.map((s) => s.toLowerCase()).toSet();
      return job.coreSkills
          .where((skill) => userSkillsLower.contains(skill.toLowerCase()))
          .toList();
    } catch (e) {
      debugPrint('Error getting matching skills: $e');
      return [];
    }
  }

  // Calculate missing skills for a job
  List<String> _getMissingSkills(Job job, [List<String>? userSkills]) {
    try {
      final authProvider = Provider.of<AppAuthProvider>(context, listen: false);
      final skills = userSkills ?? authProvider.userSkills;
      final userSkillsLower = skills.map((s) => s.toLowerCase()).toSet();
      return job.coreSkills
          .where((skill) => !userSkillsLower.contains(skill.toLowerCase()))
          .toList();
    } catch (e) {
      debugPrint('Error getting missing skills: $e');
      return job.coreSkills.toList();
    }
  }

  // Get color based on match percentage
  Color _getScoreColor(double score) {
    if (score >= 0.8) return Colors.green;
    if (score >= 0.6) return Colors.orange;
    return Colors.red;
  }

  // Build a detail row for job information
  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$label: ',
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w500,
              fontSize: 13,
              color: Colors.grey.shade700,
            ),
          ),
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

  @override
  Widget build(BuildContext context) {
    // Top-level space/AppBar is removed as it's now embedded in HomeScreen
    return _buildRecommendationsTab(context);
  }

  // Sort jobs by match percentage (highest first) and filter
  List<Job> _sortJobsByMatch(List<Job> jobs) {
    // The jobs coming from getMatchedCareers are already sorted and filtered
    return jobs;
  }

  Widget _buildRecommendationsTab(BuildContext context) {
    return FutureBuilder<List<Job>>(
      future: _jobsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'Error loading jobs: ${snapshot.error}',
                style: const TextStyle(color: Colors.red),
                textAlign: TextAlign.center,
              ),
            ),
          );
        }

        final jobs = snapshot.data ?? [];
        if (jobs.isEmpty) {
          return const Center(child: Text('No job recommendations available.'));
        }

        // Sort jobs by match percentage
        final sortedJobs = _sortJobsByMatch(jobs);

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: sortedJobs.length,
          itemBuilder: (context, index) {
            final job = sortedJobs[index];
            final matchingSkills = _getMatchingSkills(job);
            final missingSkills = _getMissingSkills(job);

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
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            job.roleTitle,
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue.shade900,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: _getScoreColor(job.matchPercentage / 100)
                                .withAlpha((255 * 0.1).round()),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: _getScoreColor(job.matchPercentage / 100)
                                  .withAlpha((255 * 0.3).round()),
                              width: 1,
                            ),
                          ),
                          child: Text(
                            '${job.matchPercentage.toStringAsFixed(0)}% Match',
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w600,
                              color: _getScoreColor(job.matchPercentage / 100),
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Job Details
                    _buildDetailRow('Education', job.education),
                    _buildDetailRow('Salary Range', job.averageSalary),
                    _buildDetailRow('Growth Outlook', job.jobGrowthOutlook),

                    // Matching Skills
                    if (matchingSkills.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Text(
                        "Your Matching Skills",
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w500,
                          color: Colors.green.shade700,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: matchingSkills
                            .map((skill) => Chip(
                                  label: Text(
                                    skill,
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                  backgroundColor: Colors.green.shade50,
                                  side:
                                      BorderSide(color: Colors.green.shade100),
                                  materialTapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                ))
                            .toList(),
                      ),
                    ],

                    // Missing Skills
                    if (missingSkills.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Text(
                        "Skills to Learn",
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w500,
                          color: Colors.orange.shade700,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: missingSkills
                            .map((skill) => Chip(
                                  label: Text(
                                    skill,
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                  backgroundColor: Colors.orange.shade50,
                                  side:
                                      BorderSide(color: Colors.orange.shade100),
                                  materialTapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                ))
                            .toList(),
                      ),
                    ],

                    // Action Buttons
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () async {
                              final details =
                                  await JobService.getCareerDetails(job.id!);
                              if (context.mounted) {
                                _showJobDetails(context, job, matchingSkills,
                                    missingSkills, details);
                              }
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
                              Navigator.pushNamed(
                                context,
                                '/learning-path',
                                arguments: {'job': job},
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
      },
    );
  }

  void _showJobDetails(
    BuildContext context,
    Job job,
    List<String> matchingSkills,
    List<String> missingSkills,
    Map<String, List<String>> details,
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
                  job.roleTitle,
                  style: GoogleFonts.poppins(
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                    color: Colors.blue.shade900,
                  ),
                ),
                const SizedBox(height: 24),

                // Job Details
                _buildDetailItem(
                    Icons.school, 'Education Required', job.education),
                _buildDetailItem(
                    Icons.attach_money, 'Average Salary', job.averageSalary),
                _buildDetailItem(
                    Icons.trending_up, 'Job Growth', job.jobGrowthOutlook),
                const SizedBox(height: 8),

                // Matching Skills
                Text(
                  'Your Matching Skills',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                if (matchingSkills.isEmpty)
                  Text('None',
                      style: GoogleFonts.poppins(color: Colors.grey.shade600))
                else
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: matchingSkills
                        .map((skill) => Chip(
                              label: Text(skill),
                              backgroundColor: Colors.green.shade50,
                              labelStyle:
                                  TextStyle(color: Colors.green.shade800),
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

                const SizedBox(height: 24),
                // Additional Career Details fetched from Supabase
                if (details['tasks']!.isNotEmpty) ...[
                  Text(
                    'Day in the Life (Tasks)',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...details['tasks']!.map((task) => Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('• ', style: TextStyle(fontSize: 16)),
                            Expanded(
                                child:
                                    Text(task, style: GoogleFonts.poppins())),
                          ],
                        ),
                      )),
                  const SizedBox(height: 20),
                ],

                if (details['salary_levels']!.isNotEmpty) ...[
                  Text(
                    'Salary Levels',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...details['salary_levels']!.map((salary) => Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('• ', style: TextStyle(fontSize: 16)),
                            Expanded(
                                child:
                                    Text(salary, style: GoogleFonts.poppins())),
                          ],
                        ),
                      )),
                  const SizedBox(height: 20),
                ],

                if (details['industries']!.isNotEmpty) ...[
                  Text(
                    'Top Industries',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: details['industries']!
                        .map((ind) => Chip(
                              label: Text(ind),
                              backgroundColor: Colors.purple.shade50,
                              labelStyle:
                                  TextStyle(color: Colors.purple.shade800),
                            ))
                        .toList(),
                  ),
                  const SizedBox(height: 20),
                ],

                if (details['companies']!.isNotEmpty) ...[
                  Text(
                    'Top Companies Hiring',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: details['companies']!
                        .map((comp) => Chip(
                              label: Text(comp),
                              backgroundColor: Colors.teal.shade50,
                              labelStyle:
                                  TextStyle(color: Colors.teal.shade800),
                            ))
                        .toList(),
                  ),
                ],

                const SizedBox(height: 30),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context); // Close the modal first
                      Navigator.pushNamed(
                        context,
                        '/learning-path',
                        arguments: {'job': job},
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
                        color: Colors.white,
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
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Colors.blue.shade700),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value.isNotEmpty ? value : 'Not specified',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.grey.shade900,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
