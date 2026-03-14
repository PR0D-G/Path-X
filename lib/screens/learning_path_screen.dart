import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/job_model.dart';
import '../services/job_service.dart';

class LearningPathScreen extends StatefulWidget {
  const LearningPathScreen({super.key});

  @override
  State<LearningPathScreen> createState() => _LearningPathScreenState();
}

class _LearningPathScreenState extends State<LearningPathScreen> {
  Job? job;
  bool _isLoading = true;
  List<LearningPath> _steps = [];
  Map<int, List<LearningResource>> _pathResources = {};
  Map<int, String> _progressStatus = {};

  final supabase = Supabase.instance.client;

  // Premium Theme Colors (Gold and Blue)
  // Premium Theme Colors (Light Mode)
  static const Color premiumGold = Color(0xFFB8860B);
  static const Color premiumDarkBlue = Color(0xFF1E293B); 
  static const Color premiumBackground = Color(0xFFF8FAFC);
  static const Color premiumCardBg = Colors.white;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args =
          ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>?;
      if (args != null && args['job'] != null) {
        job = args['job'] as Job;
        _loadData();
      } else {
        setState(() => _isLoading = false);
      }
    });
  }

  Future<void> _loadData() async {
    if (job == null || job!.id == null) {
      debugPrint('UI_DEBUG: No job id found for loading data');
      setState(() => _isLoading = false);
      return;
    }

    try {
      debugPrint('UI_DEBUG: Loading learning paths for job ${job!.roleTitle} (ID: ${job!.id})');
      final fetchedSteps = await JobService.getLearningPaths(job!.id!);
      Map<int, List<LearningResource>> resourceMap = {};
      Map<int, String> progMap = {};

      if (fetchedSteps.isEmpty) {
        debugPrint('UI_DEBUG: No steps found in DB for career ${job!.id}');
        _steps = [];
      } else {
        debugPrint('UI_DEBUG: Found ${fetchedSteps.length} steps in DB');
        _steps = fetchedSteps;
      }

      // Sort steps by step number
      _steps.sort((a, b) => a.stepNumber.compareTo(b.stepNumber));

      for (var path in _steps) {
        debugPrint('UI_DEBUG: Fetching resources for step: ${path.title} (ID: ${path.id})');
        final resources = await JobService.getLearningResources(path.id);
        
        // If no resources for this step in DB, generate some
        if (resources.isEmpty) {
          debugPrint('UI_DEBUG: Path ${path.id} has no DB resources.');
          resourceMap[path.id] = [];
        } else {
          debugPrint('UI_DEBUG: Found ${resources.length} real resources for path ${path.id}');
          resourceMap[path.id] = resources;
        }

        final user = supabase.auth.currentUser;
        if (user != null) {
          final pResponse = await supabase
              .from('user_learning_progress')
              .select('status')
              .eq('user_id', user.id)
              .eq('learning_path_id', path.id)
              .maybeSingle();

          progMap[path.id] = pResponse != null ? pResponse['status'] as String : 'not_started';
        }
      }

      setState(() {
        _pathResources = resourceMap;
        _progressStatus = progMap;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('UI_DEBUG: Global Error in _loadData: $e');
      setState(() => _isLoading = false);
    }
  }


  Future<void> _startStep(int stepId) async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) return;

      final currentStatus = _progressStatus[stepId];
      if (currentStatus == 'in_progress' || currentStatus == 'completed') return;

      await supabase.from('user_learning_progress').upsert({
        'user_id': user.id,
        'learning_path_id': stepId,
        'status': 'in_progress',
        'progress': 20,
        'started_at': DateTime.now().toIso8601String(),
      });

      setState(() {
        _progressStatus[stepId] = 'in_progress';
      });
    } catch (e) {
      debugPrint('Error starting step: $e');
    }
  }

  Future<void> _launchURL(String url, int stepId) async {
    try {
      if (url.isEmpty) throw Exception('URL is empty');
      
      if (stepId != 0 && stepId > 0) {
        await _startStep(stepId);
      }
      
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(
          uri, 
          mode: LaunchMode.externalApplication,
        );
      } else {
        // Fallback for some platforms
        if (!await launchUrl(uri, mode: LaunchMode.platformDefault)) {
          throw Exception('Could not launch $url');
        }
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: premiumDarkBlue,
        body: const Center(child: CircularProgressIndicator(color: premiumGold)),
      );
    }

    if (job == null) {
      return Scaffold(
      backgroundColor: premiumBackground,
      body: Center(child: Text('No job selected.', style: GoogleFonts.poppins(color: premiumDarkBlue))),
    );
    }

    return Scaffold(
      backgroundColor: premiumBackground,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: premiumDarkBlue, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Learning Roadmap',
          style: GoogleFonts.outfit(color: premiumDarkBlue, fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
      ),
      body: Container(
        decoration: const BoxDecoration(
          color: premiumBackground,
        ),
        child: SafeArea(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            itemCount: _steps.length,
            itemBuilder: (context, index) {
              return _buildTimelineStep(_steps[index], index == _steps.length - 1);
            },
          ),
        ),
      ),
    );
  }

  Widget _buildTimelineStep(LearningPath step, bool isLast) {
    final resources = _pathResources[step.id] ?? [];
    
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline indicator
          Column(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: premiumGold, width: 2),
                ),
                child: Center(
                  child: Text(
                    '${step.stepNumber}',
                    style: GoogleFonts.outfit(
                      color: premiumGold,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    color: premiumGold.withOpacity(0.3),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 16),
          // Step Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        step.title,
                        style: GoogleFonts.outfit(
                          color: premiumGold,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Icon(Icons.keyboard_arrow_down, color: premiumGold.withOpacity(0.7)),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  step.description,
                  style: GoogleFonts.poppins(
                    color: premiumDarkBlue.withOpacity(0.7),
                    fontSize: 13,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 16),
                // Resources Container
                Container(
                  margin: const EdgeInsets.only(bottom: 30),
                  decoration: BoxDecoration(
                    color: premiumCardBg,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: premiumDarkBlue.withOpacity(0.1)),
                  ),
                  child: Column(
                    children: resources.map((r) => _buildResourceItem(r)).toList(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResourceItem(LearningResource r) {
    final isFree = r.free;
    
    return InkWell(
      onTap: () => _launchURL(r.url, r.learningPathId ?? 0),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: premiumDarkBlue.withOpacity(0.05)),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Platform Icon
            _getPlatformIconContainer(r.platform),
            const SizedBox(width: 12),
            // Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    r.platform,
                    style: GoogleFonts.poppins(
                      color: premiumDarkBlue.withOpacity(0.5),
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    r.title,
                    style: GoogleFonts.outfit(
                      color: premiumDarkBlue,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        r.duration,
                        style: GoogleFonts.poppins(color: premiumDarkBlue.withOpacity(0.7), fontSize: 11),
                      ),
                      const SizedBox(width: 8),
                      Icon(Icons.star, color: premiumGold, size: 12),
                      const SizedBox(width: 2),
                      Text(
                        r.rating.toStringAsFixed(1),
                        style: GoogleFonts.poppins(color: premiumDarkBlue, fontSize: 11, fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        isFree ? 'Free' : r.price,
                        style: GoogleFonts.poppins(color: premiumGold, fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                      if (r.certificate) ...[
                        const SizedBox(width: 8),
                        Icon(Icons.verified, color: Colors.blue.shade300, size: 12),
                        const SizedBox(width: 2),
                        Text(
                          'Certificate',
                          style: GoogleFonts.poppins(color: Colors.blue.shade200, fontSize: 11),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            // Action Button
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: premiumGold, width: 1.5),
              ),
              child: Text(
                _getActionLabel(r.resourceType, r.free),
                style: GoogleFonts.outfit(
                  color: premiumGold,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _getPlatformIconContainer(String platform) {
    final p = platform.toLowerCase();
    Color iconColor = Colors.white;
    IconData iconData = Icons.link;

    if (p.contains('youtube')) {
      iconColor = Colors.red;
      iconData = Icons.play_circle_filled;
    } else if (p.contains('coursera')) {
      iconColor = Colors.blue;
      iconData = Icons.school;
    } else if (p.contains('udemy')) {
      iconColor = Color(0xFFA435F0);
      iconData = Icons.video_library;
    } else if (p.contains('edx')) {
      iconColor = Colors.white;
      iconData = Icons.book;
    } else if (p.contains('freecodecamp')) {
      iconColor = Colors.green;
      iconData = Icons.terminal;
    }

    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Icon(iconData, color: iconColor, size: 24),
      ),
    );
  }

  String _getActionLabel(String type, bool free) {
    final t = type.toLowerCase();
    if (t.contains('youtube') || t.contains('video')) return 'Watch Now';
    if (t.contains('practice') || t.contains('quiz')) return 'Practice Now';
    if (t.contains('course') || t.contains('certification')) return 'Enroll Now';
    return 'Get Started';
  }
}
