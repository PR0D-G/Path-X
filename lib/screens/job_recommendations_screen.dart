import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/job_model.dart';
import '../providers/auth_provider.dart';
import '../services/job_service.dart';

class JobRecommendationsScreen extends StatefulWidget {
  const JobRecommendationsScreen({super.key});

  @override
  State<JobRecommendationsScreen> createState() =>
      _JobRecommendationsScreenState();
}

class _JobRecommendationsScreenState extends State<JobRecommendationsScreen> {
  late Future<List<Job>> _jobsFuture;
  // final JobService _jobService = JobService(); // Unused

  @override
  void initState() {
    super.initState();
    _loadJobs();
  }

  Future<void> _loadJobs() async {
    try {
      final jobs = await JobService.getJobs();
      setState(() {
        _jobsFuture = Future.value(jobs);
      });
    } catch (e) {
      // Handle error
      setState(() {
        _jobsFuture = Future.error('Failed to load jobs');
      });
    }
  }

  // Calculate match percentage based on skills
  int _calculateMatchPercentage(Job job, [List<String>? userSkills]) {
    // Get user skills from auth provider if not provided
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final skills = userSkills ?? authProvider.userProfile?.skills ?? [];

    // Avoid division by zero if a job has no core skills listed
    if (job.coreSkills.isEmpty) return 0;
    if (skills.isEmpty) return 0;

    final requiredSkills = job.coreSkills.map((s) => s.toLowerCase()).toSet();
    final userSkillsLower = skills.map((s) => s.toLowerCase()).toSet();

    final matchingSkills = requiredSkills.intersection(userSkillsLower).length;
    final matchPercentage =
        (matchingSkills / requiredSkills.length * 100).round();

    return matchPercentage.clamp(0, 100);
  }

  // Calculate matching skills for a job
  List<String> _getMatchingSkills(Job job, [List<String>? userSkills]) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final skills = userSkills ?? authProvider.userProfile?.skills ?? [];
    final userSkillsLower = skills.map((s) => s.toLowerCase()).toSet();
    return job.coreSkills
        .where((skill) => userSkillsLower.contains(skill.toLowerCase()))
        .toList();
  }

  // Calculate missing skills for a job
  List<String> _getMissingSkills(Job job, [List<String>? userSkills]) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final skills = userSkills ?? authProvider.userProfile?.skills ?? [];
    final userSkillsLower = skills.map((s) => s.toLowerCase()).toSet();
    return job.coreSkills
        .where((skill) => !userSkillsLower.contains(skill.toLowerCase()))
        .toList();
  }

  // Get color based on match percentage
  Color _getScoreColor(double score) {
    if (score >= 0.8) return Colors.green;
    if (score >= 0.6) return Colors.orange;
    return Colors.red;
  }

  // Handle job tap
  // void _onJobTap(Job job) { // Unused
  //   showModalBottomSheet(
  //     context: context,
  //     shape: const RoundedRectangleBorder(
  //       borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
  //     ),
  //     builder: (context) => Container(
  //       padding: const EdgeInsets.all(20),
  //       child: Column(
  //         mainAxisSize: MainAxisSize.min,
  //         children: [
  //           Text(
  //             'What would you like to do?',
  //             style: GoogleFonts.poppins(
  //               fontSize: 18,
  //               fontWeight: FontWeight.bold,
  //             ),
  //           ),
  //           const SizedBox(height: 20),
  //           ElevatedButton(
  //             onPressed: () {
  //               Navigator.pop(context);
  //               Navigator.pushNamed(
  //                 context,
  //                 '/profile',
  //                 arguments: {'job': job},
  //               );
  //             },
  //             child: const Text('View Job Profile'),
  //           ),
  //           const SizedBox(height: 10),
  //           OutlinedButton(
  //             onPressed: () {
  //               Navigator.pop(context);
  //               Navigator.pushNamed(
  //                 context,
  //                 '/learning-path',
  //                 arguments: {'job': job},
  //               );
  //             },
  //             child: const Text('View Learning Path'),
  //           ),
  //         ],
  //       ),
  //     ),
  //   );
  // }

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
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            'Job Recommendations',
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w600,
              fontSize: 20,
            ),
          ),
          bottom: TabBar(
            tabs: const [
              Tab(text: 'Recommended Jobs'),
              Tab(text: 'My Profile'),
            ],
            labelStyle: GoogleFonts.poppins(
              fontWeight: FontWeight.w500,
              fontSize: 14,
            ),
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

  // Sort jobs by match percentage (highest first)
  List<Job> _sortJobsByMatch(List<Job> jobs) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userSkills = authProvider.userProfile?.skills ?? [];

    jobs.sort((a, b) {
      final aMatch = _calculateMatchPercentage(a, userSkills);
      final bMatch = _calculateMatchPercentage(b, userSkills);
      return bMatch.compareTo(aMatch);
    });
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
            final matchPercentage = _calculateMatchPercentage(job);
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
                            color: _getScoreColor(matchPercentage / 100)
                                .withAlpha((255 * 0.1)
                                    .round()), // Replaced withOpacity
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: _getScoreColor(matchPercentage / 100)
                                  .withAlpha((255 * 0.3)
                                      .round()), // Replaced withOpacity
                              width: 1,
                            ),
                          ),
                          child: Text(
                            '$matchPercentage% Match',
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w600,
                              color: _getScoreColor(matchPercentage / 100),
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
                            onPressed: () {
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

  Widget _buildProfileTab(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Your Profile',
            style: GoogleFonts.poppins(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.blue.shade900,
            ),
          ),
          const SizedBox(height: 20),
          _buildProfileInfoCard(),
          const SizedBox(height: 20),
          _buildSkillsCard(),
          const SizedBox(height: 20),
          _buildAssessmentResultsCard(),
        ],
      ),
    );
  }

  Widget _buildProfileInfoCard() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userProfile = authProvider.userProfile;

    return Card(
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
              'Profile Information',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.blue.shade900,
              ),
            ),
            const Divider(height: 24),
            _buildInfoRow('Name', userProfile?.uid ?? 'Not provided'),
            _buildInfoRow('Education Level',
                userProfile?.educationLevel ?? 'Not specified'),
            _buildInfoRow(
                'Skill Level',
                userProfile?.skills?.join(', ') ??
                    'Not specified'), // Fixed: join skills list
          ],
        ),
      ),
    );
  }

  Widget _buildSkillsCard() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final skills = authProvider.userProfile?.skills ?? [];

    return Card(
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
              'Your Skills',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.blue.shade900,
              ),
            ),
            const Divider(height: 24),
            if (skills.isEmpty)
              Text(
                'No skills added yet.',
                style: GoogleFonts.poppins(
                  color: Colors.grey.shade600,
                  fontStyle: FontStyle.italic,
                ),
              )
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: skills
                    .map((skill) => Chip(
                          label: Text(skill),
                          backgroundColor: Colors.blue.shade50,
                          labelStyle: TextStyle(color: Colors.blue.shade800),
                        ))
                    .toList(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildAssessmentResultsCard() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final assessmentResults = authProvider.userProfile?.assessmentResults ?? {};

    if (assessmentResults.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
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
              'Assessment Results',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.blue.shade900,
              ),
            ),
            const Divider(height: 24),
            ...assessmentResults.entries.map((entry) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Category ${assessmentResults.keys.toList().indexOf(entry.key) + 1}',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          '${(entry.value * 100).toStringAsFixed(0)}%',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600,
                            color: _getScoreColor(entry.value),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    LinearProgressIndicator(
                      value: entry.value,
                      backgroundColor: Colors.grey.shade200,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        _getScoreColor(entry.value),
                      ),
                      minHeight: 8,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ],
                ),
              );
            }), // Removed unnecessary toList()
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
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
    Job job,
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
