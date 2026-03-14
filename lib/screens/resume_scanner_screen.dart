import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:file_picker/file_picker.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'dart:typed_data';
import '../models/job_model.dart';
import '../services/job_service.dart';
import '../services/gemini_service.dart';

class ResumeScannerScreen extends StatefulWidget {
  const ResumeScannerScreen({super.key});

  @override
  State<ResumeScannerScreen> createState() => _ResumeScannerScreenState();
}

class _ResumeScannerScreenState extends State<ResumeScannerScreen> {
  final TextEditingController _resumeController = TextEditingController();
  Job? _targetJob;
  List<Job> _availableJobs = [];
  bool _isLoadingJobs = true;
  bool _isAnalyzing = false;
  bool _isFileLoading = false;
  String? _fileName;
  Map<String, dynamic>? _analysisResults;

  // Premium Theme Colors
  // Premium Theme Colors (Light Mode)
  static const Color premiumGold = Color(0xFFB8860B);
  static const Color premiumDarkBlue = Color(0xFF1E293B); // Used for text
  static const Color premiumBlue = Color(0xFF1E56A0); // Used for topic titles
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

  void _analyzeResume() async {
    debugPrint('UI_DEBUG: Starting Gemini Resume Analysis');
    if (_resumeController.text.isEmpty || _targetJob == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please provide your resume and select a target job')),
      );
      return;
    }

    setState(() => _isAnalyzing = true);

    try {
      final results = await GeminiService.analyzeResume(
        resumeText: _resumeController.text,
        targetRole: _targetJob!.roleTitle,
        requiredSkills: _targetJob!.coreSkills,
      );

      setState(() {
        _isAnalyzing = false;
        _analysisResults = results;
      });
      debugPrint('UI_DEBUG: Gemini Analysis Complete');
    } catch (e) {
      debugPrint('UI_DEBUG: Gemini Analysis Error: $e');
      setState(() => _isAnalyzing = false);
      
      // Fallback to basic matching if Gemini fails/No API Key
      _fallbackAnalysis();
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().contains('GEMINI_API_KEY') 
            ? 'Gemini API Key missing. Using basic analysis.' 
            : 'AI Analysis failed. Using basic matching.'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  void _fallbackAnalysis() {
    final resumeText = _resumeController.text.toLowerCase();
    final jobSkills = _targetJob!.coreSkills;
    final skillWeights = _targetJob!.skillImportances;
    
    List<String> foundSkills = [];
    List<String> missingSkills = [];
    double matchedWeightSum = 0;
    double totalWeightSum = 0;

    for (var skill in jobSkills) {
      final skillLower = skill.toLowerCase().trim();
      final weight = (skillWeights[skill] ?? 3).toDouble();
      totalWeightSum += weight;

      if (resumeText.contains(RegExp('\\b${RegExp.escape(skillLower)}\\b'))) {
        foundSkills.add(skill);
        matchedWeightSum += weight;
      } else {
        missingSkills.add(skill);
      }
    }

    final score = totalWeightSum > 0 
        ? (matchedWeightSum / totalWeightSum * 100).toInt() 
        : 0;

    setState(() {
      _analysisResults = {
        'matchScore': score,
        'foundSkills': foundSkills,
        'missingSkills': missingSkills,
        'suggestions': [
          'Add missing technical skills.',
          'Use more action verbs.',
          'Include a projects section.'
        ],
        'strengths': ['Matching job Title', 'Relevant experience']
      };
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingJobs) {
      return const Scaffold(
        backgroundColor: premiumDarkBlue,
        body: Center(child: CircularProgressIndicator(color: premiumGold)),
      );
    }
    return Scaffold(
      backgroundColor: premiumBackground,
      appBar: AppBar(
        title: Text('AI Resume Scanner', style: GoogleFonts.outfit(color: premiumGold, fontWeight: FontWeight.w700, fontSize: 22, letterSpacing: 0.5)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: const BackButton(color: premiumDarkBlue),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTargetJobSelector(),
            const SizedBox(height: 24),
            _buildFilePicker(),
            const SizedBox(height: 24),
            _buildResumeInput(),
            const SizedBox(height: 32),
            if (_isAnalyzing)
              const Center(child: CircularProgressIndicator(color: premiumGold))
            else
              _buildAnalyzeButton(),
            
            if (_analysisResults != null) ...[
              const SizedBox(height: 40),
              _buildResultsSection(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTargetJobSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Target Career',
          style: GoogleFonts.outfit(color: premiumBlue, fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: premiumCardBg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<Job>(
              isExpanded: true,
              dropdownColor: premiumCardBg,
              hint: Text('Select desired job', style: TextStyle(color: Colors.white.withOpacity(0.5))),
              value: _targetJob,
              items: _availableJobs.map((job) {
                return DropdownMenuItem<Job>(
                  value: job,
                  child: Text(job.roleTitle, style: const TextStyle(color: premiumDarkBlue)),
                );
              }).toList(),
              onChanged: (val) => setState(() => _targetJob = val),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFilePicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Upload Resume',
          style: GoogleFonts.outfit(color: premiumBlue, fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        InkWell(
          onTap: _pickFile,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
            decoration: BoxDecoration(
              color: premiumCardBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _fileName != null ? premiumGold : Colors.white.withOpacity(0.1),
                style: BorderStyle.solid,
              ),
            ),
            child: _isFileLoading 
              ? const Center(child: SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: premiumGold)))
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      _fileName != null ? Icons.check_circle : Icons.upload_file,
                      color: _fileName != null ? Colors.greenAccent : premiumGold,
                    ),
                    const SizedBox(width: 12),
                    Flexible(
                      child: Text(
                        _fileName ?? 'Select PDF, DOCX or TXT',
                        style: GoogleFonts.poppins(
                          color: _fileName != null ? premiumDarkBlue : premiumDarkBlue.withOpacity(0.5),
                          fontSize: 14,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
          ),
        ),
      ],
    );
  }

  Future<void> _pickFile() async {
    try {
      setState(() => _isFileLoading = true);
      
      debugPrint('UI_DEBUG: Opening File Picker...');
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'docx', 'txt'],
        withData: true,
      ).catchError((e) {
        debugPrint('UI_DEBUG: FilePicker Error: $e');
        if (e.toString().contains('_instance')) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Plugin not ready. Please REFRESH the browser tab (Ctrl+F5).'),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 10),
            ),
          );
        }
        return null;
      });

      if (result != null) {
        final fileBytes = result.files.first.bytes;
        final fileName = result.files.first.name;
        final extension = result.files.first.extension?.toLowerCase();

        String extractedText = '';

        if (extension == 'pdf' && fileBytes != null) {
          extractedText = await _extractTextFromPdf(fileBytes);
        } else if (extension == 'txt' && fileBytes != null) {
          extractedText = String.fromCharCodes(fileBytes);
        } else if (extension == 'docx') {
          // Note: Full DOCX parsing requires complex logic on Web.
          // For now, we inform the user to copy-paste or use PDF.
          extractedText = 'Support for DOCX text extraction is currently limited. Please export to PDF or copy-paste the text below.';
        }

        setState(() {
          _fileName = fileName;
          if (extractedText.isNotEmpty && extension != 'docx') {
            _resumeController.text = extractedText;
          }
        });
      }
    } catch (e) {
      debugPrint('Error picking file: $e');
    } finally {
      setState(() => _isFileLoading = false);
    }
  }

  Future<String> _extractTextFromPdf(Uint8List bytes) async {
    try {
      final PdfDocument document = PdfDocument(inputBytes: bytes);
      final PdfTextExtractor extractor = PdfTextExtractor(document);
      String text = extractor.extractText();
      document.dispose();
      return text;
    } catch (e) {
      debugPrint('Error extracting PDF text: $e');
      return '';
    }
  }

  Widget _buildResumeInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Paste Resume Content',
          style: GoogleFonts.outfit(color: premiumBlue, fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _resumeController,
          maxLines: 10,
          style: const TextStyle(color: premiumDarkBlue, fontSize: 14),
          decoration: InputDecoration(
            hintText: 'Paste your resume text here for AI analysis...',
            hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
            filled: true,
            fillColor: premiumCardBg,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: premiumGold),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAnalyzeButton() {
    return Container(
      width: double.infinity,
      height: 55,
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [premiumGold, Color(0xFFB8860B)]),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: premiumGold.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: ElevatedButton(
        onPressed: _analyzeResume,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        child: Text(
          'SCAN & ANALYZE',
          style: GoogleFonts.outfit(color: premiumDarkBlue, fontWeight: FontWeight.bold, fontSize: 16),
        ),
      ),
    );
  }

  Widget _buildResultsSection() {
    final isValid = _analysisResults!['isValid'] ?? true;
    
    if (!isValid) {
      final errorMsg = _analysisResults!['errorMsg'] ?? 'Please provide a valid resume';
      return Container(
        padding: const EdgeInsets.all(24),
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.red.withOpacity(0.05),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.red.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 48),
            const SizedBox(height: 16),
            Text(
              'Invalid Resume Data',
              style: GoogleFonts.outfit(color: Colors.red, fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              errorMsg,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(color: premiumDarkBlue.withOpacity(0.7), fontSize: 14),
            ),
          ],
        ),
      );
    }

    final score = (_analysisResults!['matchScore'] as num).toInt();
    final suggestions = List<String>.from(_analysisResults!['suggestions'] ?? []);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Analysis Report',
          style: GoogleFonts.outfit(color: premiumBlue, fontSize: 22, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 20),
        
        // Match Score Card
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: premiumCardBg,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: premiumGold.withOpacity(0.5)),
          ),
          child: Row(
            children: [
              Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 70,
                    height: 70,
                    child: CircularProgressIndicator(
                      value: score / 100,
                      strokeWidth: 8,
                      backgroundColor: Colors.white.withOpacity(0.1),
                      valueColor: AlwaysStoppedAnimation<Color>(score > 70 ? Colors.green : premiumGold),
                    ),
                  ),
                  Text('$score%', style: GoogleFonts.outfit(color: premiumDarkBlue, fontWeight: FontWeight.bold, fontSize: 18)),
                ],
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Job Match Score', style: GoogleFonts.outfit(color: premiumDarkBlue, fontSize: 18, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    Text(
                      score > 70 ? 'Excellent match for this role!' : 'Good start, but some gaps found.',
                      style: GoogleFonts.poppins(color: premiumDarkBlue.withOpacity(0.6), fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 24),
        
        // Detailed Skill Comparison
        Text(
          'Skill Breakdown',
          style: GoogleFonts.outfit(color: premiumBlue, fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: premiumCardBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.05)),
          ),
          child: Column(
            children: [
              _buildSkillStatusRow('Matching Skills', _analysisResults!['foundSkills'], const Color(0xFF15803D)), // Darker Green
              const Divider(color: Colors.black12, height: 24),
              _buildSkillStatusRow('Critical Gaps', _analysisResults!['missingSkills'], const Color(0xFFB91C1C)), // Darker Red
            ],
          ),
        ),

        const SizedBox(height: 24),
        
        // Improvements Section
        Text(
          'Personalized Recommendation',
          style: GoogleFonts.outfit(color: premiumBlue, fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        ...suggestions.map((s) => _buildSuggestionItem(s)).toList(),
      ],
    );
  }

  Widget _buildSkillStatusRow(String title, List<dynamic> skills, Color color) {
    final skillList = List<String>.from(skills);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(title, style: GoogleFonts.outfit(color: color, fontSize: 14, fontWeight: FontWeight.bold)),
            const Spacer(),
            Text('${skillList.length}', style: GoogleFonts.poppins(color: color.withOpacity(0.8), fontSize: 12, fontWeight: FontWeight.w600)),
          ],
        ),
        const SizedBox(height: 10),
        if (skillList.isEmpty)
          Text('None detected yet.', style: GoogleFonts.poppins(color: premiumDarkBlue.withOpacity(0.3), fontSize: 12))
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: skillList.map((s) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: color.withOpacity(0.08),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: color.withOpacity(0.15)),
              ),
              child: Text(
                s, 
                style: GoogleFonts.poppins(
                  color: color.withOpacity(0.9), 
                  fontSize: 11, 
                  fontWeight: FontWeight.w600
                )
              ),
            )).toList(),
          ),
      ],
    );
  }

  Widget _buildSuggestionItem(String suggestion) {
    // Detect if this is a critical warning (like "Not a resume" or "Wrong document")
    final isWarning = suggestion.toLowerCase().contains('not a resume') || 
                      suggestion.toLowerCase().contains('job description') ||
                      suggestion.startsWith('Note:');

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isWarning ? const Color(0xFFFFF7E6) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isWarning ? Colors.orange.withOpacity(0.3) : premiumDarkBlue.withOpacity(0.05),
          width: isWarning ? 1.5 : 1,
        ),
        boxShadow: isWarning ? [
          BoxShadow(
            color: Colors.orange.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ] : null,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            isWarning ? Icons.warning_amber_rounded : Icons.auto_awesome, 
            color: isWarning ? Colors.orange : premiumGold, 
            size: 20
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              suggestion,
              style: GoogleFonts.poppins(
                color: isWarning ? const Color(0xFF855D10) : premiumDarkBlue.withOpacity(0.8), 
                fontSize: 14,
                fontWeight: isWarning ? FontWeight.w500 : FontWeight.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
