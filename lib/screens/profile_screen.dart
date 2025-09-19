import 'dart:io'; // Required for Image.file
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../providers/auth_provider.dart';
import '../models/user_model.dart';
import '../models/job_model.dart';
import 'auth/login_screen.dart';

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

  bool _isEditing = false;
  bool _isLoading = false;
  String? _profileImageUrl;
  final ImagePicker _picker = ImagePicker();

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
    final authProvider = Provider.of<AppAuthProvider>(context, listen: false);
    if (authProvider.userProfile != null) {
      final profile = authProvider.userProfile!;
      setState(() {
        _nameController.text = profile.displayName ?? '';
        _emailController.text = profile.email ?? '';
        _bioController.text = profile.bio ?? '';
        _locationController.text = profile.location ?? '';
        _educationLevelController.text = profile.educationLevel ?? '';
        _careerGoalController.text = profile.careerGoal ?? '';
        _profileImageUrl = profile.photoURL;
      });
    }
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );

      if (image != null && mounted) {
        setState(() {
          _profileImageUrl = image.path;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to pick image: $e')),
        );
      }
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final authProvider = Provider.of<AppAuthProvider>(context, listen: false);
      // In a real app, upload the local image file to storage and get a URL first
      // For now, we save the path directly as per the original logic
      final updatedProfile = UserProfile(
        uid: authProvider.user!.uid,
        email: _emailController.text.trim(),
        displayName: _nameController.text.trim(),
        photoURL: _profileImageUrl,
        bio: _bioController.text.trim(),
        location: _locationController.text.trim(),
        educationLevel: _educationLevelController.text.trim(),
        careerGoal: _careerGoalController.text.trim(),
      );

      await authProvider.updateUserProfile(updatedProfile);

      if (mounted) {
        setState(() => _isEditing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update profile: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _signOut() async {
    final authProvider = Provider.of<AppAuthProvider>(context, listen: false);
    await authProvider.signOut();

    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'My Profile',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          if (!_isEditing)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => setState(() => _isEditing = true),
            ),
          if (_isEditing)
            TextButton(
              onPressed:
                  _isLoading ? null : () => setState(() => _isEditing = false),
              child: Text(
                'Cancel',
                style: GoogleFonts.poppins(
                  color: theme.colorScheme.error,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
        ],
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
                        TextFormField(
                          controller: _nameController,
                          enabled: _isEditing,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.poppins(
                              fontSize: 22, fontWeight: FontWeight.bold),
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            hintText: 'Your Name',
                          ),
                          validator: (value) =>
                              value!.isEmpty ? 'Please enter your name' : null,
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
                        TextFormField(
                          controller: _bioController,
                          enabled: _isEditing,
                          maxLines: 3,
                          decoration: _inputDecoration(
                            hintText: 'Tell us about yourself...',
                            isEditing: _isEditing,
                          ),
                        ),
                        const SizedBox(height: 24),
                        _buildSectionTitle('Personal Information'),
                        const SizedBox(height: 12),
                        _buildInfoRow(
                          icon: Icons.location_on_outlined,
                          label: 'Location',
                          controller: _locationController,
                          isEditing: _isEditing,
                        ),
                        const Divider(height: 24),
                        _buildInfoRow(
                          icon: Icons.school_outlined,
                          label: 'Education Level',
                          controller: _educationLevelController,
                          isEditing: _isEditing,
                        ),
                        const Divider(height: 24),
                        _buildInfoRow(
                          icon: Icons.flag_outlined,
                          label: 'Career Goal',
                          controller: _careerGoalController,
                          isEditing: _isEditing,
                        ),
                        const SizedBox(height: 32),
                        if (_isEditing)
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _saveProfile,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: theme.primaryColor,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: _isLoading
                                  ? const SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: CircularProgressIndicator(
                                          color: Colors.white, strokeWidth: 2),
                                    )
                                  : Text(
                                      'Save Changes',
                                      style: GoogleFonts.poppins(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.white),
                                    ),
                            ),
                          ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            icon: const Icon(Icons.logout),
                            label: Text(
                              'Sign Out',
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            onPressed: _signOut,
                            style: OutlinedButton.styleFrom(
                              foregroundColor: theme.colorScheme.error,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              side: BorderSide(color: theme.colorScheme.error),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (widget.job != null) _buildJobDetails(),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildProfileHeader() {
    // If the path is from the network (http), use Image.network.
    // If it's a local file path, use Image.file.
    // Otherwise, show the icon.
    Widget profileImage;
    if (_profileImageUrl != null) {
      if (_profileImageUrl!.startsWith('http')) {
        profileImage = Image.network(_profileImageUrl!,
            fit: BoxFit.cover, width: double.infinity, height: 200);
      } else {
        // FIX: Use Image.file for local paths from ImagePicker
        profileImage = Image.file(File(_profileImageUrl!),
            fit: BoxFit.cover, width: double.infinity, height: 200);
      }
    } else {
      profileImage =
          Icon(Icons.person, size: 80, color: Colors.white.withOpacity(0.8));
    }

    return Center(
      child: Stack(
        children: [
          CircleAvatar(
            radius: 60,
            backgroundColor: Colors.blue.shade100,
            child: ClipOval(
              child: profileImage,
            ),
          ),
          if (_isEditing)
            Positioned(
              bottom: 0,
              right: 0,
              child: CircleAvatar(
                radius: 20,
                backgroundColor: Theme.of(context).primaryColor,
                child: IconButton(
                  icon: const Icon(Icons.camera_alt,
                      color: Colors.white, size: 20),
                  onPressed: _pickImage,
                ),
              ),
            ),
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

  Widget _buildInfoRow(
      {required IconData icon,
      required String label,
      required TextEditingController controller,
      required bool isEditing}) {
    return Row(
      children: [
        Icon(icon, size: 24, color: Colors.grey.shade600),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: GoogleFonts.poppins(
                      fontSize: 12, color: Colors.grey.shade600)),
              isEditing
                  ? TextFormField(
                      controller: controller,
                      decoration: const InputDecoration(
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                          border: InputBorder.none),
                    )
                  : Text(
                      controller.text.isEmpty
                          ? 'Not specified'
                          : controller.text,
                      style: GoogleFonts.poppins(
                          fontSize: 16,
                          color: controller.text.isEmpty
                              ? Colors.grey.shade400
                              : null),
                    ),
            ],
          ),
        ),
      ],
    );
  }

  InputDecoration _inputDecoration(
      {required String hintText, required bool isEditing}) {
    return InputDecoration(
      hintText: hintText,
      filled: !isEditing,
      fillColor: Colors.grey[100],
      contentPadding: const EdgeInsets.all(16),
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
            color: isEditing ? Colors.grey.shade300 : Colors.transparent),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Theme.of(context).primaryColor, width: 2),
      ),
    );
  }
}
