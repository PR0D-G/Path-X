import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'package:file_picker/file_picker.dart';
import '../providers/auth_provider.dart';
import '../services/gemini_service.dart';

class CertificateValidationScreen extends StatefulWidget {
  const CertificateValidationScreen({super.key});

  @override
  State<CertificateValidationScreen> createState() => _CertificateValidationScreenState();
}

class _CertificateValidationScreenState extends State<CertificateValidationScreen> {
  final _urlController = TextEditingController();
  bool _isValidating = false;
  Map<String, dynamic>? _result;
  String? _error;
  PlatformFile? _selectedFile;

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
        withData: true,
      );

      if (result != null && result.files.single.bytes != null) {
        setState(() {
          _selectedFile = result.files.single;
          _urlController.clear(); // Clear URL if file is picked
          _error = null;
        });
      }
    } catch (e) {
      setState(() => _error = 'Error picking file: $e');
    }
  }

  Future<void> _validateCertificate() async {
    final url = _urlController.text.trim();
    if (url.isEmpty && _selectedFile == null) {
      setState(() => _error = 'Please enter a URL or upload a certificate');
      return;
    }

    setState(() {
      _isValidating = true;
      _error = null;
      _result = null;
    });

    try {
      final authProvider = Provider.of<AppAuthProvider>(context, listen: false);
      final userName = authProvider.userProfile?.displayName ?? 'User';

      Uint8List bytes;
      String mimeType;

      if (_selectedFile != null) {
        // Handle local file
        bytes = _selectedFile!.bytes!;
        final ext = _selectedFile!.extension?.toLowerCase();
        mimeType = ext == 'pdf' ? 'application/pdf' : 'image/${ext ?? 'jpeg'}';
      } else {
        // Handle URL
        final response = await http.get(Uri.parse(url));
        if (response.statusCode != 200) {
          throw Exception('Failed to download certificate. Status: ${response.statusCode}');
        }
        bytes = response.bodyBytes;
        mimeType = response.headers['content-type'] ?? 'application/pdf';
        if (mimeType.contains(';')) {
          mimeType = mimeType.split(';')[0].trim();
        }
      }

      // 2. Validate with Gemini
      final result = await GeminiService.validateCertificate(
        userName: userName,
        bytes: bytes,
        mimeType: mimeType,
      );

      setState(() {
        _result = result;
        _isValidating = false;
      });

      // 3. If valid, add skills to profile
      if (result['isAuthentic'] == true) {
        final List<String> skills = List<String>.from(result['extractedSkills'] ?? []);
        if (skills.isNotEmpty) {
          await authProvider.addSkills(skills);
        }
      }
    } catch (e) {
      setState(() {
        _error = 'Error: ${e.toString()}';
        _isValidating = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    const premiumBlue = Color(0xFF004B8D);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text('Verify Certificate', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildInfoCard(),
            const SizedBox(height: 24),
            Text(
              'Option 1: Paste URL',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600, color: premiumBlue),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _urlController,
              onChanged: (val) {
                if (val.isNotEmpty) setState(() => _selectedFile = null);
              },
              decoration: InputDecoration(
                hintText: 'https://example.com/certificate.pdf',
                prefixIcon: const Icon(Icons.link, color: premiumBlue),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade200),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                const Expanded(child: Divider()),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text('OR', style: GoogleFonts.poppins(color: Colors.grey, fontWeight: FontWeight.bold)),
                ),
                const Expanded(child: Divider()),
              ],
            ),
            const SizedBox(height: 24),
            Text(
              'Option 2: Upload File',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600, color: premiumBlue),
            ),
            const SizedBox(height: 8),
            InkWell(
              onTap: _pickFile,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _selectedFile != null ? premiumBlue : Colors.grey.shade200),
                ),
                child: Row(
                  children: [
                    Icon(
                      _selectedFile != null ? Icons.file_present : Icons.cloud_upload_outlined,
                      color: premiumBlue,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _selectedFile?.name ?? 'Select PDF or Certificate Image',
                        style: GoogleFonts.poppins(
                          color: _selectedFile != null ? premiumBlue : Colors.grey.shade600,
                          fontWeight: _selectedFile != null ? FontWeight.w500 : FontWeight.normal,
                        ),
                      ),
                    ),
                    if (_selectedFile != null)
                      IconButton(
                        icon: const Icon(Icons.close, size: 20),
                        onPressed: () => setState(() => _selectedFile = null),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _isValidating ? null : _validateCertificate,
              style: ElevatedButton.styleFrom(
                backgroundColor: premiumBlue,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: _isValidating
                  ? const CircularProgressIndicator(color: Colors.white)
                  : Text('Validate with AI', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
            if (_error != null) _buildErrorSection(),
            if (_result != null) _buildResultSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade100),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, color: Color(0xFF004B8D)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Enter the public URL of your certificate (PDF or Image). Gemini will verify the name and extract skills automatically.',
              style: GoogleFonts.poppins(fontSize: 13, color: Colors.blue.shade900),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorSection() {
    return Padding(
      padding: const EdgeInsets.only(top: 24),
      child: Text(
        _error!,
        style: GoogleFonts.poppins(color: Colors.red, fontSize: 13),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildResultSection() {
    final isAuthentic = _result!['isAuthentic'] == true;
    final skills = List<String>.from(_result!['extractedSkills'] ?? []);

    return Padding(
      padding: const EdgeInsets.only(top: 32),
      child: Column(
        children: [
          Icon(
            isAuthentic ? Icons.verified : Icons.error_outline,
            size: 64,
            color: isAuthentic ? Colors.green : Colors.orange,
          ),
          const SizedBox(height: 16),
          Text(
            isAuthentic ? 'Verification Successful!' : 'Verification Failed',
            style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          if (!isAuthentic)
            Text(
              _result!['errorMsg'] ?? 'The name on the certificate does not match your profile.',
              style: GoogleFonts.poppins(color: Colors.grey.shade600),
              textAlign: TextAlign.center,
            ),
          if (isAuthentic) ...[
            Text(
              'Found on Certificate: ${_result!['nameOnCertificate']}',
              style: GoogleFonts.poppins(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 24),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Extracted Skills:',
                style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: skills.map((skill) => Chip(
                label: Text(skill, style: const TextStyle(fontSize: 12)),
                backgroundColor: Colors.white,
                side: const BorderSide(color: Color(0xFF004B8D)),
              )).toList(),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.green, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'These skills have been added to your profile!',
                      style: GoogleFonts.poppins(fontSize: 12, color: Colors.green.shade900),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
