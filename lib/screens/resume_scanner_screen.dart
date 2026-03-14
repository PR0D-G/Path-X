import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:file_picker/file_picker.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'dart:typed_data';
import '../models/job_model.dart';
import '../services/job_service.dart';

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
    debugPrint('UI_DEBUG: Starting Resume Analysis');
    if (_resumeController.text.isEmpty || _targetJob == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please provide your resume and select a target job')),
      );
      return;
    }

    setState(() => _isAnalyzing = true);

    // Simulate AI analysis delay
    await Future.delayed(const Duration(seconds: 2));

    final resumeText = _resumeController.text.toLowerCase();
    final jobSkills = _targetJob!.coreSkills;
    final skillWeights = _targetJob!.skillImportances;
    
    debugPrint('UI_DEBUG: Matching against Job: ${_targetJob!.roleTitle}');
    debugPrint('UI_DEBUG: Required Skills: $jobSkills');
    
    List<String> foundSkills = [];
    List<String> missingSkills = [];
    double matchedWeightSum = 0;
    double totalWeightSum = 0;

    if (jobSkills.isEmpty) {
      debugPrint('UI_DEBUG: WARNING - targetJob has 0 skills in database');
      setState(() {
        _isAnalyzing = false;
        _analysisResults = {
          'matchScore': 0,
          'foundSkills': [],
          'missingSkills': [],
          'suggestions': ['We don\'t have skill data for this specific role yet. Please try another role.'],
        };
      });
      return;
    }

    // Synonym map for common industry terms
    final Map<String, List<String>> synonyms = {
      'lesson planning': ['lesson plans', 'curriculum', 'teaching across subject areas'],
      'classroom management': ['disciplined', 'productive environment', 'classroom of', 'managing students'],
      'communication': ['interpersonal', 'presentation', 'explaining', 'notes', 'summaries'],
      'assessment': ['grading', 'evaluation', 'feedback', 'monitoring'],
      'technology': ['digital', 'software', 'pos', 'processing'],
    };

    for (var skill in jobSkills) {
      final skillLower = skill.toLowerCase().trim();
      final weight = (skillWeights[skill] ?? 3).toDouble();
      totalWeightSum += weight;

      bool isMatch = false;

      // Tier 1: Exact Match
      if (resumeText.contains(RegExp('\\b${RegExp.escape(skillLower)}\\b'))) {
        isMatch = true;
      } 
      
      // Tier 2: Synonym/Semantic Match
      if (!isMatch) {
        for (var entry in synonyms.entries) {
          if (skillLower.contains(entry.key) || entry.key.contains(skillLower)) {
            if (entry.value.any((syn) => resumeText.contains(syn.toLowerCase()))) {
              isMatch = true;
              debugPrint('UI_DEBUG: Synonym Match! $skill matched via known teaching term');
              break;
            }
          }
        }
      }

      // Tier 3: Keyword Threshold Matching
      if (!isMatch && skillLower.contains(' ')) {
        final tokens = skillLower.split(RegExp(r'[\s/&,]+')).where((t) => t.length > 2).toList();
        if (tokens.isNotEmpty) {
          int matchCount = 0;
          for (var token in tokens) {
            final tokenClean = token.toLowerCase();
            final hasToken = resumeText.contains(RegExp('\\b${RegExp.escape(tokenClean)}\\b'));
            if (hasToken) {
              matchCount++;
              debugPrint('UI_DEBUG:   - Keyword Match: "$token"');
            }
          }
          final matchRatio = matchCount / tokens.length;
          if (matchRatio >= 0.5) {
            isMatch = true;
          }
        }
      }

      if (isMatch) {
        foundSkills.add(skill);
        matchedWeightSum += weight;
        debugPrint('UI_DEBUG: MATCH! $skill (Weight: $weight)');
      } else {
        missingSkills.add(skill);
      }
    }

    final score = totalWeightSum > 0 
        ? (matchedWeightSum / totalWeightSum * 100).toInt() 
        : 0;
    
    debugPrint('UI_DEBUG: Raw Weights: $matchedWeightSum / $totalWeightSum');
    debugPrint('UI_DEBUG: Calculated Score: $score%');

    // Logic for "Suggest what to add"
    List<String> suggestions = [];
    if (missingSkills.isNotEmpty) {
      suggestions.add('Add these missing technical skills: ${missingSkills.take(3).join(", ")}');
    }
    
    if (!resumeText.contains('project') && !resumeText.contains('experience')) {
      suggestions.add('Consider adding a "Projects" or "Work Experience" section to showcase practical application.');
    }

    if (!resumeText.contains('achieved') && !resumeText.contains('increased') && !resumeText.contains('managed')) {
      suggestions.add('Use more action verbs like "Achieved", "Increased", or "Led" to describe your impact.');
    }

    setState(() {
      _isAnalyzing = false;
      _analysisResults = {
        'matchScore': score,
        'foundSkills': foundSkills,
        'missingSkills': missingSkills,
        'suggestions': suggestions,
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
    final score = _analysisResults!['matchScore'] as int;
    final suggestions = _analysisResults!['suggestions'] as List<String>;
    
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
              _buildSkillStatusRow('Matching Skills', _analysisResults!['foundSkills'], Colors.greenAccent),
              const Divider(color: Colors.white10, height: 24),
              _buildSkillStatusRow('Critical Gaps', _analysisResults!['missingSkills'], Colors.redAccent),
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
            Text('${skillList.length}', style: TextStyle(color: color.withOpacity(0.7))),
          ],
        ),
        const SizedBox(height: 8),
        if (skillList.isEmpty)
          Text('None detected yet.', style: GoogleFonts.poppins(color: Colors.white30, fontSize: 12))
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: skillList.map((s) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: color.withOpacity(0.2)),
              ),
              child: Text(s, style: GoogleFonts.poppins(color: Colors.white.withOpacity(0.8), fontSize: 11)),
            )).toList(),
          ),
      ],
    );
  }

  Widget _buildSuggestionItem(String suggestion) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: premiumDarkBlue.withOpacity(0.05)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.auto_awesome, color: premiumGold, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              suggestion,
              style: GoogleFonts.poppins(color: premiumDarkBlue.withOpacity(0.8), fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}
