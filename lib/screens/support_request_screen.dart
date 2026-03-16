import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

class SupportRequestScreen extends StatefulWidget {
  final bool isSupportOnly;
  const SupportRequestScreen({super.key, this.isSupportOnly = false});

  @override
  State<SupportRequestScreen> createState() => _SupportRequestScreenState();
}

class _SupportRequestScreenState extends State<SupportRequestScreen> {
  final _supabase = Supabase.instance.client;
  bool _isSubmitting = false;

  // Colors
  static const Color premiumBlue = Color(0xFF1E56A0);
  static const Color premiumDarkBlue = Color(0xFF1E293B);
  static const Color premiumGold = Color(0xFFB8860B);

  Future<void> _submitRequest(String type, String title, String description) async {
    final authProvider = Provider.of<AppAuthProvider>(context, listen: false);
    final user = authProvider.user;
    final profile = authProvider.userProfile;

    if (user == null) return;

    setState(() => _isSubmitting = true);

    try {
      await _supabase.from('user_requests').insert({
        'user_id': user.id,
        'username': profile?.displayName ?? user.email?.split('@').first ?? 'Anonymous',
        'type': type,
        'title': title,
        'description': description,
        'created_at': DateTime.now().toIso8601String(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Request submitted successfully!', style: GoogleFonts.poppins()),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to submit request: $e', style: GoogleFonts.poppins()),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _showRequestDialog(String type) {
    final titleController = TextEditingController();
    final descController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Raise a Request: $type', 
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: premiumBlue)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: InputDecoration(
                labelText: 'Title',
                labelStyle: GoogleFonts.poppins(fontSize: 14),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: descController,
              maxLines: 4,
              decoration: InputDecoration(
                labelText: 'Description / Details',
                labelStyle: GoogleFonts.poppins(fontSize: 14),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: premiumBlue,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              if (titleController.text.isEmpty || descController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please fill all fields'))
                );
                return;
              }
              Navigator.pop(context);
              _submitRequest(type, titleController.text, descController.text);
            },
            child: const Text('Submit', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(widget.isSupportOnly ? 'Support' : 'Raise a Request', 
          style: GoogleFonts.outfit(fontWeight: FontWeight.w700, color: premiumBlue)),
        elevation: 0,
        backgroundColor: Colors.white,
        leading: const BackButton(color: premiumDarkBlue),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.isSupportOnly) ...[
              _buildSectionTitle('Legal & Info'),
              const SizedBox(height: 12),
              _buildSimpleButton('About Us', Icons.info_outline, () {
                _showInfoDialog('About Us', 'PathX is your ultimate AI-powered career companion. We help you bridge the gap between where you are and where you want to be.');
              }),
              _buildSimpleButton('Privacy Policy', Icons.privacy_tip_outlined, () {
                _showInfoDialog('Privacy Policy', 'Your data is encrypted and secure. we never sell your personal information to third parties.');
              }),
              _buildSimpleButton('Terms & Conditions', Icons.gavel_outlined, () {
                _showInfoDialog('Terms & Conditions', 'By using PathX, you agree to our terms of service regarding AI-generated advice and career roadmaps.');
              }),
            ] else ...[
              _buildSectionTitle('What do you need?'),
              const SizedBox(height: 16),
              _buildRequestCard('Add a Course', 'Suggest a new course for our learning roadmaps.', Icons.library_add, Colors.blue, () => _showRequestDialog('Add Course')),
              const SizedBox(height: 16),
              _buildRequestCard('Add Careers', 'Request a new career path to be added to PathX.', Icons.work_outline, Colors.orange, () => _showRequestDialog('Add Career')),
              const SizedBox(height: 16),
              _buildRequestCard('Add Features', 'Tell us what new tools you want to see here.', Icons.auto_awesome, Colors.purple, () => _showRequestDialog('Add Feature')),
            ],
            
            if (_isSubmitting)
              const Padding(
                padding: EdgeInsets.only(top: 24),
                child: Center(child: CircularProgressIndicator(color: premiumGold)),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(title, style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: premiumDarkBlue));
  }

  Widget _buildSimpleButton(String text, IconData icon, VoidCallback onTap) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withOpacity(0.2)),
      ),
      child: ListTile(
        leading: Icon(icon, color: premiumBlue),
        title: Text(text, style: GoogleFonts.poppins(fontWeight: FontWeight.w500)),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
        onTap: onTap,
      ),
    );
  }

  Widget _buildRequestCard(String title, String subtitle, IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.2)),
          boxShadow: [
            BoxShadow(color: color.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: premiumDarkBlue)),
                  const SizedBox(height: 4),
                  Text(subtitle, style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey[600])),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showInfoDialog(String title, String content) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(title, style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        content: Text(content, style: GoogleFonts.poppins()),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
        ],
      ),
    );
  }
}
