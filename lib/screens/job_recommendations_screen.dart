import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'dart:math' as math;
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
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _jobsFuture = _loadAndFilterJobs();
  }

  Future<List<Job>> _loadAndFilterJobs() async {
    try {
      final authProvider = Provider.of<AppAuthProvider>(context, listen: false);
      return await JobService.getMatchedCareers(authProvider.userSkills);
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

  // Build a detail row for job information
  Widget _buildInfoChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.blue.shade600),
          const SizedBox(width: 6),
          Text(label, style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey.shade800, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildSkillChip(String skill, bool isMatch) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isMatch ? const Color(0xFF004B8D) : Colors.white, // MI Blue
        borderRadius: BorderRadius.circular(8),
        border: isMatch ? null : Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isMatch)
            const Padding(
              padding: EdgeInsets.only(right: 6.0),
              child: Icon(Icons.check, size: 12, color: Color(0xFFFFD700)), // MI Gold
            ),
          Text(
            skill,
            style: GoogleFonts.poppins(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: isMatch ? const Color(0xFFFFD700) : const Color(0xFF2C3E50), // MI Gold if matched
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
        final allJobs = snapshot.data ?? [];
        if (allJobs.isEmpty) {
          return const Center(child: Text('No job recommendations available for your profile.'));
        }

        // Apply filtering logic
        final List<Job> filteredJobs;
        if (_searchQuery.isEmpty) {
          // Default view: Only high-match jobs (>= 40%)
          filteredJobs = allJobs.where((job) => job.matchPercentage >= 40.0).toList();
        } else {
          // Search view: Show all jobs that match the text, regardless of percentage
          final query = _searchQuery.toLowerCase();
          filteredJobs = allJobs.where((job) {
            return job.roleTitle.toLowerCase().contains(query) ||
                   job.description.toLowerCase().contains(query) ||
                   job.coreSkills.any((skill) => skill.toLowerCase().contains(query));
          }).toList();
        }

        return Column(
          children: [
            // Premium Search Bar
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.blue.shade100.withAlpha(80),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: TextField(
                  controller: _searchController,
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                  },
                  decoration: InputDecoration(
                    hintText: 'Search roles, skills, or descriptions...',
                    hintStyle: GoogleFonts.poppins(
                      color: Colors.grey.shade400,
                      fontSize: 14,
                    ),
                    prefixIcon: Icon(Icons.search, color: Colors.blue.shade600),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 20),
                            onPressed: () {
                              setState(() {
                                _searchController.clear();
                                _searchQuery = '';
                              });
                            },
                          )
                        : null,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 15,
                    ),
                  ),
                ),
              ),
            ),
            
            // Results Counter
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Row(
                children: [
                  Text(
                    '${filteredJobs.length} Results',
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.blue.shade800,
                    ),
                  ),
                  if (_searchQuery.isNotEmpty) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Filtering for "$_searchQuery"',
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          color: Colors.blue.shade600,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),

            Expanded(
              child: filteredJobs.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.search_off, size: 64, color: Colors.grey.shade300),
                          const SizedBox(height: 16),
                          Text(
                            'No matches found for "$_searchQuery"',
                            style: GoogleFonts.poppins(color: Colors.grey.shade500),
                          ),
                        ],
                      ),
                    )
                  : LayoutBuilder(
                      builder: (context, constraints) {
                        final crossAxisCount = constraints.maxWidth > 800 ? 2 : 1;
                        return GridView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: crossAxisCount,
                            crossAxisSpacing: 20,
                            mainAxisSpacing: 24,
                            mainAxisExtent: 360, // Tighter fit for the card content
                          ),
                          itemCount: filteredJobs.length,
                          itemBuilder: (context, index) {
                            final job = filteredJobs[index];
                            final authProvider = Provider.of<AppAuthProvider>(context, listen: false);
                            final userSkills = authProvider.userSkills.map((s) => s.toLowerCase()).toSet();
                            
                            final isHighMatch = job.matchPercentage >= 90;

                            return Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: Colors.grey.shade200),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withAlpha(8),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              clipBehavior: Clip.antiAlias,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        if (isHighMatch)
                                          Padding(
                                            padding: const EdgeInsets.only(bottom: 8.0),
                                            child: Row(
                                              children: [
                                                Text(
                                                  "Top Career Match",
                                                  style: GoogleFonts.poppins(
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.w600,
                                                    color: Colors.grey.shade500,
                                                    letterSpacing: 0.5,
                                                  ),
                                                ),
                                                const Expanded(child: Divider(indent: 8, endIndent: 0)),
                                              ],
                                            ),
                                          ),
                                        
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          crossAxisAlignment: CrossAxisAlignment.center,
                                          children: [
                                            Expanded(
                                              child: Text(
                                                job.roleTitle,
                                                style: GoogleFonts.poppins(
                                                  fontSize: 20,
                                                  fontWeight: FontWeight.bold,
                                                  color: const Color(0xFF1A1A1A),
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                              decoration: BoxDecoration(
                                                color: job.matchPercentage >= 80 
                                                  ? const Color(0xFF4CAF50) // Green
                                                  : job.matchPercentage >= 65 
                                                    ? Colors.yellow.shade700 // Yellow
                                                    : job.matchPercentage >= 55 
                                                      ? Colors.orange.shade700 // Orange
                                                      : Colors.red.shade700, // Red
                                                borderRadius: BorderRadius.circular(10),
                                                border: Border.all(
                                                  color: Colors.white.withAlpha(50), 
                                                  width: 1.5,
                                                ),
                                              ),
                                              child: RichText(
                                                text: TextSpan(
                                                  style: GoogleFonts.poppins(
                                                    fontWeight: FontWeight.bold,
                                                    color: job.matchPercentage >= 65 && job.matchPercentage < 80 
                                                      ? Colors.black87 
                                                      : Colors.white,
                                                    fontSize: 15,
                                                  ),
                                                    children: [
                                                      TextSpan(text: job.matchPercentage.toStringAsFixed(0)),
                                                      const TextSpan(text: '%', style: TextStyle(fontSize: 11)),
                                                    const TextSpan(text: ' Match', style: TextStyle(fontSize: 11, fontWeight: FontWeight.normal)),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        
                                        const SizedBox(height: 4),
                                        Text(
                                          '${job.industry} • ${job.demandLevel} Demand',
                                          style: GoogleFonts.poppins(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                            color: const Color(0xFF34495E),
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        
                                        const SizedBox(height: 12),
                                        // Row of Info Chips
                                        Wrap(
                                          spacing: 8,
                                          runSpacing: 8,
                                          children: [
                                            _buildInfoChip(Icons.currency_rupee, '${job.averageSalary} / year'),
                                            _buildInfoChip(job.remotePossible ? Icons.location_on : Icons.location_on_outlined, job.remotePossible ? 'Remote' : 'On-site'),
                                            _buildInfoChip(Icons.person, job.fresherFriendly ? 'Fresher' : 'Exp. req'),
                                          ],
                                        ),

                                        const SizedBox(height: 12),
                                        Row(
                                          children: [
                                            Text(
                                              "Skills",
                                              style: GoogleFonts.poppins(
                                                fontWeight: FontWeight.bold,
                                                color: const Color(0xFF1A1A1A),
                                                fontSize: 14,
                                              ),
                                            ),
                                            const Expanded(child: Divider(indent: 8)),
                                          ],
                                        ),
                                        const SizedBox(height: 12),
                                        SizedBox(
                                          height: 80, // Increased height for skills list
                                          child: job.coreSkills.isEmpty 
                                            ? Center(child: Text("Skills data loading or missing...", style: TextStyle(fontSize: 12, color: Colors.grey.shade400)))
                                            : Wrap(
                                                spacing: 8,
                                                runSpacing: 8,
                                                children: job.coreSkills.take(6).map((skill) {
                                                  return _buildSkillChip(skill, userSkills.contains(skill.toLowerCase()));
                                                }).toList(),
                                              ),
                                        ),

                                        const SizedBox(height: 12),
                                        Row(
                                          children: [
                                            Expanded(
                                              child: ElevatedButton.icon(
                                                icon: const Icon(Icons.assignment_outlined, size: 16),
                                                label: const Text('More Info'),
                                                onPressed: () async {
                                                  final details = await JobService.getCareerDetails(job.id!);
                                                  if (context.mounted) {
                                                    _showJobDetails(context, job, _getMatchingSkills(job), _getMissingSkills(job), details);
                                                  }
                                                },
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: Colors.white,
                                                  foregroundColor: const Color(0xFF2C3E50),
                                                  elevation: 0,
                                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10), side: BorderSide(color: Colors.grey.shade300)),
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Container(
                                                decoration: BoxDecoration(
                                                  gradient: const LinearGradient(
                                                    colors: [Color(0xFF004B8D), Color(0xFF003566)], // MI Blue Gradient
                                                    begin: Alignment.topLeft,
                                                    end: Alignment.bottomRight,
                                                  ),
                                                  borderRadius: BorderRadius.circular(10),
                                                  boxShadow: [
                                                    BoxShadow(
                                                      color: const Color(0xFF004B8D).withAlpha(50),
                                                      blurRadius: 8,
                                                      offset: const Offset(0, 4),
                                                    ),
                                                  ],
                                                ),
                                                child: ElevatedButton.icon(
                                                  icon: const Icon(Icons.auto_fix_high, size: 16, color: Color(0xFFFFD700)), // MI Gold
                                                  label: const Text('Learning Path'),
                                                  onPressed: () => Navigator.pushNamed(context, '/learning-path', arguments: {'job': job}),
                                                  style: ElevatedButton.styleFrom(
                                                    backgroundColor: Colors.transparent,
                                                    foregroundColor: const Color(0xFFFFD700), // MI Gold
                                                    elevation: 0,
                                                    padding: const EdgeInsets.symmetric(vertical: 14),
                                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }

  void _showJobDetails(
    BuildContext context,
    Job job,
    List<String> matchingSkills,
    List<String> missingSkills,
    Map<String, dynamic> details,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.94,
        minChildSize: 0.6,
        maxChildSize: 0.94,
        builder: (_, controller) => Container(
          decoration: const BoxDecoration(
            color: Color(0xFFF8F9FE),
            borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
          ),
          child: Column(
            children: [
              // Custom Modal Handle & App Bar
              Container(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                decoration: const BoxDecoration(
                  color: Color(0xFF1E56A0),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
                ),
                child: Column(
                  children: [
                    Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white.withAlpha(80), borderRadius: BorderRadius.circular(2))),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.arrow_back, color: Colors.white)),
                        Expanded(
                          child: Text(
                            "${job.roleTitle} - Career Details",
                            style: GoogleFonts.poppins(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              Expanded(
                child: ListView(
                  controller: controller,
                  padding: const EdgeInsets.all(20),
                  children: [
                    // Match Breakdown Card
                    _buildSectionHeader("Match Breakdown"),
                    Center(child: _buildRadarChart(job)),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildLegendItem(const Color(0xFF1E56A0), "You"),
                        const SizedBox(width: 24),
                        _buildLegendItem(Colors.green, "Job Fit"),
                      ],
                    ),
                    const SizedBox(height: 32),

                    // Skills Comparison
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildMiniHeader("You Have"),
                              const SizedBox(height: 12),
                              ...matchingSkills.take(4).map((s) => _buildSimpleMatchItem(s, true)),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildMiniHeader("You Need"),
                              const SizedBox(height: 12),
                              ...missingSkills.take(4).map((s) => _buildSimpleMatchItem(s, false)),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),

                    // Day in the Life
                    if (details['tasks']!.isNotEmpty) ...[
                      _buildSectionHeaderWithIcon(Icons.cloud_queue, "Day in the Life"),
                      const SizedBox(height: 12),
                      ...details['tasks']!.map((task) => _buildTaskItem(task)),
                      const SizedBox(height: 32),
                    ],

                    // Salary & Outlook
                    _buildSectionHeaderWithIcon(Icons.insights, "Market Demand & Salary Trends"),
                    const SizedBox(height: 16),
                    _buildMarketTrendChart(job, List<Map<String, dynamic>>.from(details['trends'] ?? [])),
                    const SizedBox(height: 32),

                    // Who Hires
                    _buildSectionHeaderWithIcon(Icons.location_on_outlined, "Who Hires?"),
                    const SizedBox(height: 12),
                    if (details['industries']!.isNotEmpty)
                      _buildDetailRowInline("Industries:", details['industries']!.join(', ')),
                    if (details['companies']!.isNotEmpty)
                      _buildDetailRowInline("Companies:", details['companies']!.join(', ')),
                    
                    const SizedBox(height: 40),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => Navigator.pushNamed(context, '/learning-path', arguments: {'job': job}),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF004B8D), // Mumbai Indians Blue
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 4,
                          shadowColor: const Color(0xFF004B8D).withAlpha(100),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.auto_fix_high, color: Color(0xFFFFD700)), // Gold icon
                            const SizedBox(width: 8),
                            Text(
                              "Start Learning Path", 
                              style: GoogleFonts.poppins(
                                fontSize: 16, 
                                fontWeight: FontWeight.bold, 
                                color: Colors.white
                              )
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRadarChart(Job job) {
    const List<String> riasecLabels = ['R', 'I', 'A', 'S', 'E', 'C'];
    final List<double> userScores = job.userRiasecScores.map((e) => e / 100.0).toList(); // Normalize to 0-1
    final List<double> jobScores = job.jobRiasecScores.map((e) => e / 100.0).toList(); // Normalize to 0-1

    return SizedBox(
      width: 250,
      height: 250,
      child: CustomPaint(
        painter: RadarChartPainter(
          userScores: userScores,
          jobScores: jobScores,
          labels: riasecLabels,
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          const Expanded(child: Divider()),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(title, style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.grey.shade700)),
          ),
          const Expanded(child: Divider()),
        ],
      ),
    );
  }

  Widget _buildSectionHeaderWithIcon(IconData icon, String title) {
    return Row(
      children: [
        Icon(icon, size: 20, color: const Color(0xFF1E56A0)),
        const SizedBox(width: 8),
        Text(title, style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.bold, color: const Color(0xFF1E56A0))),
        const Expanded(child: Divider(indent: 12)),
      ],
    );
  }

  Widget _buildMiniHeader(String title) {
    return Text(title, style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.grey.shade600));
  }

  Widget _buildLegendItem(Color color, String label) {
    return Row(
      children: [
        Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text(label, style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w500)),
      ],
    );
  }

  Widget _buildSimpleMatchItem(String text, bool isHave) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(color: isHave ? Colors.green.withAlpha(10) : Colors.blue.withAlpha(10), borderRadius: BorderRadius.circular(8)),
      child: Row(
        children: [
          Icon(isHave ? Icons.check_circle : Icons.check_circle_outline, size: 16, color: isHave ? Colors.green : Colors.blue),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w500), overflow: TextOverflow.ellipsis)),
        ],
      ),
    );
  }

  Widget _buildTaskItem(String task) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("• ", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E56A0))),
          Expanded(child: Text(task, style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey.shade800))),
        ],
      ),
    );
  }

  Widget _buildDetailRowInline(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: RichText(
        text: TextSpan(
          style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey.shade800),
          children: [
            TextSpan(text: "$label ", style: const TextStyle(fontWeight: FontWeight.bold)),
            TextSpan(text: value),
          ],
        ),
      ),
    );
  }

  Widget _buildMarketTrendChart(Job job, List<Map<String, dynamic>> dbTrends) {
    debugPrint('UI_DEBUG: Building MarketTrendChart for ${job.roleTitle}. dbTrends count: ${dbTrends.length}');
    if (dbTrends.isEmpty) {
      return Container(
        height: 250,
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.blue.withAlpha(20)),
          boxShadow: [
            BoxShadow(
              color: Colors.blue.shade900.withAlpha(10),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 40,
              height: 40,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.blue.shade600),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              "Fetching market trends...",
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.blue.shade900,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    // Use data strictly from DB
    double salaryFresher = 0;
    double salaryMid = 0;
    double salarySenior = 0;
    
    double demandFresher = 0;
    double demandMid = 0;
    double demandSenior = 0;

    // Sort by salary to ensure order: Fresher -> Mid -> Senior
    dbTrends.sort((a, b) => (a['salary'] as num).compareTo(b['salary'] as num));
    
    for (var trend in dbTrends) {
      final level = trend['level']?.toString().toLowerCase() ?? '';
      final salary = (trend['salary'] as num).toDouble() / 100000;
      final demand = (trend['demand_score'] as num?)?.toDouble() ?? 50.0;
      
      if (level.contains('fresh')) {
        salaryFresher = salary;
        demandFresher = demand;
      } else if (level.contains('senior')) {
        salarySenior = salary;
        demandSenior = demand;
      } else {
        salaryMid = salary;
        demandMid = demand;
      }
    }
    
    // If we only have 2 points, interpolate the middle
    if (dbTrends.length == 2) {
      if (salaryMid == 0) salaryMid = (salaryFresher + salarySenior) / 2;
      if (demandMid == 0) demandMid = (demandFresher + demandSenior) / 2;
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.blue.withAlpha(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.shade900.withAlpha(10),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Trend Analysis",
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF1E3A8A),
                    ),
                  ),
                  Text(
                    "Career Growth (India 2024)",
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.grey.shade500,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.trending_up, color: Colors.blue.shade700, size: 20),
              ),
            ],
          ),
          const SizedBox(height: 32),
          SizedBox(
            height: 220,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // Y-Axis Demand
                Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    for (int val in [100, 80, 60, 40, 20, 0])
                      SizedBox(
                        width: 25,
                        child: Text(
                          val.toString(), 
                          textAlign: TextAlign.right,
                          style: GoogleFonts.poppins(fontSize: 10, color: Colors.grey.shade400, fontWeight: FontWeight.w500)
                        )
                      ),
                  ],
                ),
                const SizedBox(width: 12),
                // Chart Area
                Expanded(
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      // Guidelines
                      Column(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: List.generate(6, (index) => Container(
                          height: 1,
                          color: index == 5 ? Colors.grey.shade300 : Colors.grey.shade100,
                        )),
                      ),
                      // Bars
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            _buildTrendBar("Fresher", "0-2 Yrs", salaryFresher, 60),
                            _buildTrendBar("Professional", "2-5 Yrs", salaryMid, 60),
                            _buildTrendBar("Senior", "5+ Yrs", salarySenior, 60),
                          ],
                        ),
                      ),
                      // Line
                      Positioned.fill(
                        child: CustomPaint(
                          painter: TrendLinePainter(
                            points: [demandFresher, demandMid, demandSenior],
                            maxVal: 100,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                // Y-Axis Salary
                Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    for (int val in [60, 50, 40, 30, 20, 10, 0])
                      SizedBox(
                        width: 30,
                        child: Text(
                          "₹${val}L", 
                          style: GoogleFonts.poppins(fontSize: 10, color: Colors.grey.shade400, fontWeight: FontWeight.w500)
                        )
                      ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          // Legend
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildSimpleLegendItem(const Color(0xFF8B5CF6), "Avg Annual Salary"),
              const SizedBox(width: 20),
              _buildSimpleLegendItem(const Color(0xFF3B82F6), "Market Demand"),
            ],
          ),
          const SizedBox(height: 20),
          // Insight
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.blue.shade50.withAlpha(100), Colors.white],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.blue.shade100),
            ),
            child: Row(
              children: [
                Icon(Icons.auto_awesome, size: 18, color: Colors.blue.shade600),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    "Senior positions for this role currently show the highest demand (${demandSenior.toInt()} pts) and earning potential (₹${salarySenior.toInt()}L+ avg).",
                    style: GoogleFonts.poppins(fontSize: 11, color: Colors.blue.shade900, fontWeight: FontWeight.w500, height: 1.4),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrendBar(String label, String subLabel, double value, double maxValue) {
    double heightFactor = (value / maxValue).clamp(0.1, 1.0);
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Container(
          width: 32,
          height: 160 * heightFactor,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFC4B5FD), Color(0xFF8B5CF6)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF8B5CF6).withAlpha(40),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Stack(
            alignment: Alignment.topCenter,
            children: [
               Positioned(
                 top: 6,
                 child: Text(
                   "₹${value.toInt()}L",
                   style: GoogleFonts.poppins(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.white),
                 ),
               ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Text(label, style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.bold, color: const Color(0xFF1E3A8A))),
        Text(subLabel, style: GoogleFonts.poppins(fontSize: 9, color: Colors.grey.shade500, fontWeight: FontWeight.w500)),
      ],
    );
  }

  Widget _buildSimpleLegendItem(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 8),
        Text(label, style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey.shade600, fontWeight: FontWeight.w500)),
      ],
    );
  }
}

class RadarChartPainter extends CustomPainter {
  final List<double> userScores;
  final List<double> jobScores;
  final List<String> labels;

  RadarChartPainter({required this.userScores, required this.jobScores, required this.labels});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 * 0.8;
    final sides = labels.length;
    final angle = (2 * math.pi) / sides;

    // Draw background polygons (5 levels)
    final gridPaint = Paint()..color = Colors.grey.shade300..style = PaintingStyle.stroke..strokeWidth = 1.0;
    for (var i = 1; i <= 5; i++) {
        final path = Path();
        final levelRadius = radius * (i / 5);
        for (var j = 0; j < sides; j++) {
            final x = center.dx + levelRadius * math.cos(j * angle - math.pi / 2);
            final y = center.dy + levelRadius * math.sin(j * angle - math.pi / 2);
            if (j == 0) {
              path.moveTo(x, y);
            } else {
              path.lineTo(x, y);
            }
        }
        path.close();
        canvas.drawPath(path, gridPaint);
    }

    // Draw axes
    for (var i = 0; i < sides; i++) {
        final x = center.dx + radius * math.cos(i * angle - math.pi / 2);
        final y = center.dy + radius * math.sin(i * angle - math.pi / 2);
        canvas.drawLine(center, Offset(x, y), gridPaint);
        
        // Draw Labels
        final textPainter = TextPainter(
          text: TextSpan(text: labels[i], style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey.shade700)),
          textDirection: TextDirection.ltr,
        )..layout();
        final lx = center.dx + (radius + 15) * math.cos(i * angle - math.pi / 2) - textPainter.width / 2;
        final ly = center.dy + (radius + 15) * math.sin(i * angle - math.pi / 2) - textPainter.height / 2;
        textPainter.paint(canvas, Offset(lx, ly));
    }

    // Draw Job Scores Polygon
    _drawPolygon(canvas, center, radius, angle, jobScores, Colors.green.withAlpha(80), Colors.green, 2.0);
    // Draw User Scores Polygon
    _drawPolygon(canvas, center, radius, angle, userScores, const Color(0xFF1E56A0).withAlpha(100), const Color(0xFF1E56A0), 2.5);
  }

  void _drawPolygon(Canvas canvas, Offset center, double radius, double angle, List<double> scores, Color fillColor, Color outlineColor, double strokeWidth) {
    final path = Path();
    for (var i = 0; i < scores.length; i++) {
        final r = radius * scores[i].clamp(0.0, 1.0);
        final x = center.dx + r * math.cos(i * angle - math.pi / 2);
        final y = center.dy + r * math.sin(i * angle - math.pi / 2);
        if (i == 0) {
          path.moveTo(x, y);
        } else {
          path.lineTo(x, y);
        }
    }
    path.close();
    canvas.drawPath(path, Paint()..color = fillColor..style = PaintingStyle.fill);
    canvas.drawPath(path, Paint()..color = outlineColor..style = PaintingStyle.stroke..strokeWidth = strokeWidth);
    
    // Draw points
    final pointPaint = Paint()..color = outlineColor..style = PaintingStyle.fill;
    for (var i = 0; i < scores.length; i++) {
        final r = radius * scores[i].clamp(0.0, 1.0);
        final x = center.dx + r * math.cos(i * angle - math.pi / 2);
        final y = center.dy + r * math.sin(i * angle - math.pi / 2);
        canvas.drawCircle(Offset(x, y), 3.5, pointPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class TrendLinePainter extends CustomPainter {
  final List<double> points;
  final double maxVal;

  TrendLinePainter({required this.points, required this.maxVal});

  @override
  void paint(Canvas canvas, Size size) {
    if (points.length < 2) return;

    final paint = Paint()
      ..color = const Color(0xFF3B82F6)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final dotPaint = Paint()
      ..color = const Color(0xFF3B82F6)
      ..style = PaintingStyle.fill;

    const double xPadding = 24 + 16; // Container padding + half bar width
    final double totalWidth = size.width - (xPadding * 2);

    final List<Offset> offsetPoints = [];
    for (int i = 0; i < points.length; i++) {
      double x = xPadding + (i * totalWidth / (points.length - 1));
      double y = size.height - (points[i] / maxVal) * size.height;
      offsetPoints.add(Offset(x, y));
    }

    // Draw lines
    final path = Path();
    path.moveTo(offsetPoints[0].dx, offsetPoints[0].dy);
    for (int i = 1; i < offsetPoints.length; i++) {
      path.lineTo(offsetPoints[i].dx, offsetPoints[i].dy);
    }
    canvas.drawPath(path, paint);

    // Dots and Demand Labels
    for (int i = 0; i < offsetPoints.length; i++) {
        var point = offsetPoints[i];
        
        // Shadow for dot
        canvas.drawCircle(point, 8, Paint()..color = const Color(0xFF3B82F6).withAlpha(40)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4));
        
        canvas.drawCircle(point, 6, dotPaint);
        canvas.drawCircle(point, 3, Paint()..color = Colors.white);

        // Demand Value Label
        final textPainter = TextPainter(
          text: TextSpan(
            text: points[i].toInt().toString(),
            style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFF2563EB)),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        
        textPainter.paint(canvas, Offset(point.dx - (textPainter.width / 2), point.dy - 25));
    }
  }

  @override
  bool shouldRepaint(TrendLinePainter oldDelegate) => oldDelegate.points != points;
}
