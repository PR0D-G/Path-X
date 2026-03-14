import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:html' as html;
import '../models/job_model.dart';
import '../services/job_service.dart';
import '../services/gemini_service.dart';

class ResumeBuilderScreen extends StatefulWidget {
  const ResumeBuilderScreen({super.key});

  @override
  State<ResumeBuilderScreen> createState() => _ResumeBuilderScreenState();
}

class _ResumeBuilderScreenState extends State<ResumeBuilderScreen> {
  // Form fields
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _summaryController = TextEditingController();
  final TextEditingController _experienceController = TextEditingController();
  final TextEditingController _skillsController = TextEditingController();

  Job? _targetJob;
  List<Job> _availableJobs = [];
  bool _isLoadingJobs = true;
  bool _isRefining = false;
  int _currentStep = 0;

  // Premium Theme Colors
  static const Color premiumGold = Color(0xFFB8860B);
  static const Color premiumDarkBlue = Color(0xFF1E293B); 
  static const Color premiumBlue = Color(0xFF1E56A0); 
  static const Color premiumBackground = Color(0xFFF8FAFC);
  static const Color premiumCardBg = Colors.white;

  @override
  void initState() {
    super.initState();
    _loadJobs();
  }

  Future<void> _loadJobs() async {
    try {
      final jobs = await JobService.getJobs();
      setState(() {
        _availableJobs = jobs;
        _isLoadingJobs = false;
      });
    } catch (e) {
      debugPrint('Error loading jobs: $e');
      setState(() => _isLoadingJobs = false);
    }
  }

  Future<void> _refineWithAI(TextEditingController controller, bool isSummary) async {
    if (_targetJob == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a target job first')),
      );
      return;
    }
    if (controller.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter some text to refine')),
      );
      return;
    }

    setState(() => _isRefining = true);

    try {
      final refined = await GeminiService.generateResumeContent(
        userInput: controller.text,
        targetRole: _targetJob!.roleTitle,
        isSummary: isSummary,
      );

      setState(() {
        controller.text = refined;
        _isRefining = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Refined with Gemini AI!'), backgroundColor: premiumBlue),
      );
    } catch (e) {
      debugPrint('Refine Error: $e');
      setState(() => _isRefining = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('AI Refinement failed. Check your API key.'), backgroundColor: Colors.orange),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: premiumBackground,
      appBar: AppBar(
        title: Text('Smart Resume Builder', style: GoogleFonts.outfit(color: premiumGold, fontWeight: FontWeight.w700, fontSize: 22, letterSpacing: 0.5)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: const BackButton(color: premiumDarkBlue),
      ),
      body: _isLoadingJobs 
        ? const Center(child: CircularProgressIndicator(color: premiumGold))
        : Theme(
            data: Theme.of(context).copyWith(
              canvasColor: premiumBackground,
              colorScheme: ColorScheme.light(primary: premiumGold, secondary: premiumGold, onSurface: premiumDarkBlue),
            ),
            child: Stack(
              children: [
                Stepper(
                  type: StepperType.vertical,
                  currentStep: _currentStep,
                  onStepContinue: () {
                    if (_currentStep < 3) {
                      setState(() => _currentStep++);
                    } else {
                      _showPreviewEditor();
                    }
                  },
                  onStepCancel: () {
                    if (_currentStep > 0) setState(() => _currentStep--);
                  },
                  controlsBuilder: (context, details) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 20),
                      child: Row(
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              color: premiumGold,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: ElevatedButton(
                              onPressed: details.onStepContinue,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                foregroundColor: Colors.white,
                                shadowColor: Colors.transparent,
                                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                              ).copyWith(
                                shape: WidgetStateProperty.all(RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                              ),
                              child: Text(_currentStep == 3 ? 'FINISH' : 'NEXT', style: const TextStyle(fontWeight: FontWeight.bold)),
                            ),
                          ),
                          if (_currentStep > 0)
                            TextButton(
                              onPressed: details.onStepCancel,
                              child: Text('BACK', style: TextStyle(color: premiumDarkBlue.withOpacity(0.5))),
                            ),
                        ],
                      ),
                    );
                  },
                  steps: [
                    Step(
                      title: Text('Target Career', style: GoogleFonts.outfit(color: premiumBlue, fontWeight: FontWeight.bold, fontSize: 16)),
                      content: _buildJobSelector(),
                      isActive: _currentStep >= 0,
                    ),
                    Step(
                      title: Text('Personal Info', style: GoogleFonts.outfit(color: premiumBlue, fontWeight: FontWeight.bold, fontSize: 16)),
                      content: Column(
                        children: [
                          _buildTextField(_nameController, 'Full Name', Icons.person),
                          const SizedBox(height: 12),
                          _buildTextField(_emailController, 'Email Address', Icons.email),
                        ],
                      ),
                      isActive: _currentStep >= 1,
                    ),
                    Step(
                      title: Text('Professional Summary', style: GoogleFonts.outfit(color: premiumBlue, fontWeight: FontWeight.bold, fontSize: 16)),
                      content: Column(
                        children: [
                          _buildTextField(_summaryController, 'Briefly describe yourself...', Icons.description, maxLines: 4),
                          const SizedBox(height: 8),
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton.icon(
                              onPressed: () => _refineWithAI(_summaryController, true),
                              icon: const Icon(Icons.auto_awesome, size: 16),
                              label: const Text('Refine with Gemini'),
                              style: TextButton.styleFrom(
                                foregroundColor: premiumGold,
                                textStyle: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                        ],
                      ),
                      isActive: _currentStep >= 2,
                    ),
                    Step(
                      title: Text('Experience', style: GoogleFonts.outfit(color: premiumBlue, fontWeight: FontWeight.bold, fontSize: 16)),
                      content: Column(
                        children: [
                          _buildTextField(_skillsController, 'List your skills (comma separated)', Icons.bolt, hint: 'e.g. Python, SQL, Project Management'),
                          const SizedBox(height: 12),
                          _buildTextField(_experienceController, 'Briefly list your work experience', Icons.work, maxLines: 5),
                          const SizedBox(height: 8),
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton.icon(
                              onPressed: () => _refineWithAI(_experienceController, false),
                              icon: const Icon(Icons.auto_awesome, size: 16),
                              label: const Text('Improve Bullets with AI'),
                              style: TextButton.styleFrom(
                                foregroundColor: premiumGold,
                                textStyle: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                        ],
                      ),
                      isActive: _currentStep >= 3,
                    ),
                  ],
                ),
                if (_isRefining)
                  Container(
                    color: Colors.white.withOpacity(0.7),
                    child: const Center(child: CircularProgressIndicator(color: premiumGold)),
                  ),
              ],
            ),
          ),
    );
  }

  Widget _buildJobSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: premiumCardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: premiumDarkBlue.withOpacity(0.05)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<Job>(
          isExpanded: true,
          dropdownColor: premiumCardBg,
          hint: Text('Select target role', style: TextStyle(color: premiumDarkBlue.withOpacity(0.3), fontSize: 14)),
          value: _targetJob,
          items: _availableJobs.map((job) {
            return DropdownMenuItem<Job>(
              value: job,
              child: Text(job.roleTitle, style: const TextStyle(color: premiumDarkBlue, fontSize: 14)),
            );
          }).toList(),
          onChanged: (val) => setState(() => _targetJob = val),
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, IconData icon, {int maxLines = 1, String? hint}) {
    return Container(
      decoration: BoxDecoration(
        color: premiumCardBg,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        style: const TextStyle(color: premiumDarkBlue, fontSize: 14),
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          hintStyle: TextStyle(color: premiumDarkBlue.withOpacity(0.3), fontSize: 14),
          labelStyle: TextStyle(color: premiumDarkBlue.withOpacity(0.5), fontSize: 14),
          prefixIcon: Icon(icon, color: premiumGold, size: 20),
          filled: true,
          fillColor: Colors.transparent,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: premiumDarkBlue.withOpacity(0.05)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: premiumDarkBlue.withOpacity(0.05)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: premiumGold, width: 1.5),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
      ),
    );
  }

  Future<void> _generateAndDownloadPDF() async {
    final PdfDocument document = PdfDocument();
    final PdfPage page = document.pages.add();
    final PdfGraphics graphics = page.graphics;
    final PdfFont font = PdfStandardFont(PdfFontFamily.helvetica, 12);
    final PdfFont titleFont = PdfStandardFont(PdfFontFamily.helvetica, 20, style: PdfFontStyle.bold);
    final PdfFont sectionFont = PdfStandardFont(PdfFontFamily.helvetica, 14, style: PdfFontStyle.bold);

    double yPos = 0;

    // Header
    graphics.drawString(_nameController.text.toUpperCase(), titleFont, bounds: const Rect.fromLTWH(0, 0, 500, 30));
    yPos += 30;
    graphics.drawString(_emailController.text, font, bounds: Rect.fromLTWH(0, yPos, 500, 20));
    yPos += 40;

    // Summary
    graphics.drawString("PROFESSIONAL SUMMARY", sectionFont, bounds: Rect.fromLTWH(0, yPos, 500, 20));
    yPos += 25;
    graphics.drawString(_summaryController.text, font, bounds: Rect.fromLTWH(0, yPos, 500, 100));
    yPos += 110;

    // Skills
    graphics.drawString("SKILLS", sectionFont, bounds: Rect.fromLTWH(0, yPos, 500, 20));
    yPos += 25;
    graphics.drawString(_skillsController.text, font, bounds: Rect.fromLTWH(0, yPos, 500, 20));
    yPos += 40;

    // Experience
    graphics.drawString("PROFESSIONAL EXPERIENCE", sectionFont, bounds: Rect.fromLTWH(0, yPos, 500, 20));
    yPos += 25;
    graphics.drawString(_experienceController.text, font, bounds: Rect.fromLTWH(0, yPos, 500, 200));

    final List<int> bytes = await document.save();
    document.dispose();

    if (kIsWeb) {
      final base64String = base64Encode(bytes);
      html.AnchorElement(href: 'data:application/octet-stream;base64,$base64String')
        ..setAttribute("download", "Optimized_Resume.pdf")
        ..click();
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Downloading Resume...'), backgroundColor: premiumBlue),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Download only supported on Web version.'), backgroundColor: Colors.orange),
      );
    }
  }

  void _showPreviewEditor() {
    showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierLabel: 'Preview',
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, _, __) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Scaffold(
              backgroundColor: const Color(0xFFE5E7EB),
              appBar: AppBar(
                backgroundColor: premiumDarkBlue,
                title: Text('Interactive Preview', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold)),
                leading: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
                actions: [
                  TextButton.icon(
                    onPressed: _generateAndDownloadPDF,
                    icon: const Icon(Icons.download, color: premiumGold),
                    label: const Text('DOWNLOAD', style: TextStyle(color: premiumGold, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(width: 10),
                ],
              ),
              body: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
                  child: Container(
                    width: 600, // A4 aspect ratio approximation for web
                    decoration: BoxDecoration(
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 20, spreadRadius: 5),
                      ],
                    ),
                    padding: const EdgeInsets.all(40),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header Section
                        _editableText(_nameController, GoogleFonts.outfit(fontSize: 28, fontWeight: FontWeight.bold, color: premiumDarkBlue), setModalState),
                        _editableText(_emailController, GoogleFonts.outfit(fontSize: 14, color: Colors.grey[600]), setModalState),
                        const SizedBox(height: 30),
                        const Divider(thickness: 1.5, color: premiumGold),
                        const SizedBox(height: 20),
                        
                        // Summary Section
                        _sectionTitle('PROFESSIONAL SUMMARY'),
                        _editableText(_summaryController, GoogleFonts.outfit(fontSize: 13, height: 1.5, color: premiumDarkBlue), setModalState, maxLines: 5),
                        const SizedBox(height: 30),

                        // Skills Section
                        _sectionTitle('TECHNICAL SKILLS'),
                        _editableText(_skillsController, GoogleFonts.outfit(fontSize: 13, height: 1.5, color: premiumDarkBlue), setModalState),
                        const SizedBox(height: 30),

                        // Experience Section
                        _sectionTitle('WORK EXPERIENCE'),
                        _editableText(_experienceController, GoogleFonts.outfit(fontSize: 13, height: 1.5, color: premiumDarkBlue), setModalState, maxLines: 10),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        title,
        style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w900, color: premiumGold, letterSpacing: 1.2),
      ),
    );
  }

  Widget _editableText(TextEditingController controller, TextStyle style, Function setState, {int maxLines = 1}) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      style: style,
      decoration: InputDecoration(
        border: InputBorder.none,
        focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: premiumGold.withOpacity(0.3))),
        contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        hoverColor: premiumGold.withOpacity(0.05),
        filled: true,
        fillColor: Colors.transparent,
      ),
      onChanged: (_) => setState(() {}),
    );
  }

  void _showFinishDialog() {
    // Deprecated in favor of _showPreviewEditor
    _showPreviewEditor();
  }
}
