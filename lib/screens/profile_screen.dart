import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/auth_provider.dart';
import '../models/job_model.dart';
import '../services/job_service.dart';

class ProfileScreen extends StatefulWidget {
  final Job? job;

  const ProfileScreen({
    super.key,
    this.job,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _bioController = TextEditingController();
  final _locationController = TextEditingController();
  final _educationLevelController = TextEditingController();
  final _careerGoalController = TextEditingController();

  static const Color premiumGold = Color(0xFFB8860B);
  static const Color premiumDarkBlue = Color(0xFF1E293B);
  static const Color premiumBlue = Color(0xFF1E56A0);
  static const Color background = Color(0xFFF8FAFC);

  String? _profileImageUrl;
  List<Map<String, dynamic>> _enrolledCareers = [];

  @override
  void initState() {
    super.initState();
    _loadUserProfile();

    if (widget.job != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        // Use the consistent 'title' property
        _careerGoalController.text = widget.job!.roleTitle;
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _bioController.dispose();
    _locationController.dispose();
    _educationLevelController.dispose();
    _careerGoalController.dispose();
    super.dispose();
  }

  Future<void> _loadUserProfile() async {
    try {
      final authProvider = Provider.of<AppAuthProvider>(context, listen: false);

      // First, ensure we have the user's profile data
      if (authProvider.userProfile == null && authProvider.user != null) {
        await authProvider.loadUserProfile(authProvider.user!.id);
      }

      if (mounted) {
        final profile = authProvider.userProfile;
        final user = authProvider.user;

        setState(() {
          // Use displayName from profile if available, otherwise use from user object
          _nameController.text = profile?.displayName ??
              user?.userMetadata?['display_name'] ??
              user?.email?.split('@').first ??
              'User';
          _emailController.text = user?.email ?? '';
          _bioController.text = profile?.bio ?? '';
          _locationController.text = profile?.location ?? '';
          _educationLevelController.text = profile?.educationLevel ?? '';
          _careerGoalController.text = profile?.careerGoal ?? '';
          _profileImageUrl =
              profile?.photoURL ?? user?.userMetadata?['avatar_url'];
        });

        // Load enrolled careers
        final enrolled = await JobService.getEnrolledCareers();
        if (mounted) {
          setState(() {
            _enrolledCareers = enrolled;
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading user profile: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to load profile')),
        );
      }
    }
  }


  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'My Profile',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: Consumer<AppAuthProvider>(
        builder: (context, authProvider, _) {
          if (authProvider.isLoading && _nameController.text.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildProfileHeader(),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        Text(
                          _nameController.text,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.poppins(
                              fontSize: 22, fontWeight: FontWeight.bold),
                        ),
                        if (authProvider.user?.email != null)
                          Text(
                            authProvider.user!.email!,
                            style: GoogleFonts.poppins(
                                color: Colors.grey.shade600),
                          ),
                        const SizedBox(height: 24),
                        _buildSectionTitle('About Me'),
                        const SizedBox(height: 12),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.03),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Text(
                            _bioController.text.isEmpty ? 'No bio added yet.' : _bioController.text,
                            style: GoogleFonts.poppins(fontSize: 14, color: premiumDarkBlue.withOpacity(0.8)),
                          ),
                        ),
                        const SizedBox(height: 32),
                        
                        _buildSectionTitle('Verified Skills'),
                        const SizedBox(height: 12),
                        _buildSkillsSection(authProvider.userProfile?.skills ?? []),
                        
                        const SizedBox(height: 32),
                        _buildSectionTitle('Career Context'),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.blue.withOpacity(0.1)),
                          ),
                          child: Column(
                            children: [
                              _buildInfoRow(
                                icon: Icons.location_on_outlined,
                                label: 'Location',
                                value: _locationController.text,
                              ),
                              const Divider(height: 32),
                              _buildInfoRow(
                                icon: Icons.school_outlined,
                                label: 'Education Level',
                                value: _educationLevelController.text,
                              ),
                              const Divider(height: 32),
                              _buildInfoRow(
                                icon: Icons.flag_outlined,
                                label: 'Career Goal',
                                value: _careerGoalController.text,
                                isPrimary: true,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),
                _buildLearningDashboard(),
                if (widget.job != null) _buildJobDetails(),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildProfileHeader() {
    final authProvider = Provider.of<AppAuthProvider>(context);
    final user = authProvider.user;
    final userProfile = authProvider.userProfile;

    // If the path is from the network (http), use Image.network.
    // If it's a local file path, use Image.file.
    // Otherwise, show the icon.
    Widget profileImage;
    if (_profileImageUrl != null) {
      if (_profileImageUrl!.startsWith('http')) {
        profileImage = Image.network(_profileImageUrl!,
            fit: BoxFit.cover, width: 120, height: 120);
      } else {
        profileImage = Image.file(File(_profileImageUrl!),
            fit: BoxFit.cover, width: 120, height: 120);
      }
    } else {
      profileImage =
          Icon(Icons.person, size: 60, color: Colors.white.withOpacity(0.8));
    }

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [premiumBlue, premiumDarkBlue],
        ),
      ),
      padding: const EdgeInsets.fromLTRB(24, 60, 24, 40),
      child: Column(
        children: [
          Stack(
            alignment: Alignment.bottomRight,
            children: [
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 4),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: CircleAvatar(
                  radius: 55,
                  backgroundColor: Colors.white.withOpacity(0.2),
                  child: ClipOval(
                    child: profileImage,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  color: premiumGold,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.edit, size: 16, color: Colors.white),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            userProfile?.displayName ??
                user?.userMetadata?['display_name'] ??
                user?.email?.split('@').first ??
                'User',
            style: GoogleFonts.outfit(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
          if (user?.email != null) ...[
            const SizedBox(height: 4),
            Text(
              user!.email!,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.white.withOpacity(0.7),
                letterSpacing: 0.5,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildJobDetails() {
    final job = widget.job!;
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Related Job Information',
                style: GoogleFonts.poppins(
                    fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            _buildDetailRow('Title', job.roleTitle), // FIX: Consistent property
            if (job.averageSalary.isNotEmpty)
              _buildDetailRow('Salary', job.averageSalary),
            const SizedBox(height: 8),
            Text('Description',
                style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w500, fontSize: 14)),
            const SizedBox(height: 4),
            const SizedBox(height: 12),
            if (job.coreSkills.isNotEmpty) ...[
              Text('Required Skills',
                  style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w500, fontSize: 14)),
              const SizedBox(height: 4),
              Wrap(
                spacing: 8,
                children: job.coreSkills
                    .map((skill) => Chip(label: Text(skill)))
                    .toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$label: ',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w500)),
          Expanded(
              child: Text(value,
                  style: GoogleFonts.poppins(color: Colors.grey.shade700))),
        ],
      ),
    );
  }

  Widget _buildLearningDashboard() {
    if (_enrolledCareers.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('Overall Learning Progress'),
          const SizedBox(height: 16),
          ..._enrolledCareers.map((item) {
            final Job career = item['career'];
            final int completed = item['completedSteps'];
            final int total = item['totalSteps'];
            final double percentage = item['progressPercentage'];

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          career.roleTitle,
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      Text(
                        '${percentage.toInt()}%',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: LinearProgressIndicator(
                      value: percentage / 100,
                      backgroundColor: Colors.grey.shade200,
                      color: Colors.blue.shade600,
                      minHeight: 8,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '$completed of $total steps completed',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(title,
          style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.blue.shade800)),
    );
  }

  Widget _buildSkillsSection(List<String> skills) {
    if (skills.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.withOpacity(0.2)),
        ),
        child: Text(
          'No skills verified yet. Use the Resume Scanner to add skills!',
          style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey[600]),
          textAlign: TextAlign.center,
        ),
      );
    }

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: skills.map((skill) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blue.shade600, Colors.blue.shade800],
          ),
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: Colors.blue.withOpacity(0.2),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.verified, size: 14, color: Colors.white),
            const SizedBox(width: 6),
            Text(
              skill,
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      )).toList(),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
    bool isPrimary = false,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: isPrimary ? Colors.blue.shade50 : Colors.grey.shade50,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, size: 22, color: isPrimary ? Colors.blue.shade700 : Colors.grey.shade600),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: GoogleFonts.poppins(
                      fontSize: 11, color: Colors.grey.shade500, fontWeight: FontWeight.w500)),
              Text(
                value.isEmpty ? 'Not specified' : value,
                style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: isPrimary ? FontWeight.w600 : FontWeight.w500,
                    color: value.isEmpty
                        ? Colors.grey.shade400
                        : premiumDarkBlue),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
