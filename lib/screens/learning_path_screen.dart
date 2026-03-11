import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/job_model.dart';
import '../providers/auth_provider.dart';
import '../services/job_service.dart';

class LearningPathScreen extends StatefulWidget {
  const LearningPathScreen({super.key});

  @override
  State<LearningPathScreen> createState() => _LearningPathScreenState();
}

class _LearningPathScreenState extends State<LearningPathScreen> {
  Job? job;
  bool _isLoading = true;
  List<LearningPath> _paths = [];
  Map<int, List<LearningResource>> _resourcesMap = {};
  Map<int, String> _progressStatus = {};

  final supabase = Supabase.instance.client;

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
      setState(() => _isLoading = false);
      return;
    }

    try {
      final paths = await JobService.getLearningPaths(job!.id!);
      Map<int, List<LearningResource>> resMap = {};
      Map<int, String> progMap = {};

      for (var path in paths) {
        final resources = await JobService.getLearningResources(path.id);
        resMap[path.id] = resources;

        // Fetch progress
        final user = supabase.auth.currentUser;
        if (user != null) {
          final pResponse = await supabase
              .from('user_learning_progress')
              .select('status')
              .eq('user_id', user.id)
              .eq('learning_path_id', path.id)
              .maybeSingle();

          if (pResponse != null) {
            progMap[path.id] = pResponse['status'] as String;
          } else {
            progMap[path.id] = 'not_started';
          }
        }
      }

      setState(() {
        _paths = paths;
        _resourcesMap = resMap;
        _progressStatus = progMap;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading learning paths: \$e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _startStep(int stepId) async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) return;

      final currentStatus = _progressStatus[stepId];
      if (currentStatus == 'in_progress' || currentStatus == 'completed')
        return;

      await supabase.from('user_learning_progress').insert({
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
      debugPrint('Error starting step: \$e');
    }
  }

  Future<void> _completeStep(int stepId) async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) return;

      await supabase
          .from('user_learning_progress')
          .update({
            'status': 'completed',
            'progress': 100,
            'completed_at': DateTime.now().toIso8601String(),
          })
          .eq('learning_path_id', stepId)
          .eq('user_id', user.id);

      setState(() {
        _progressStatus[stepId] = 'completed';
      });
    } catch (e) {
      debugPrint('Error completing step: \$e');
    }
  }

  Future<void> _launchURL(String url, int stepId) async {
    try {
      await _startStep(stepId); // Mark as in progress when clicking a resource
      final uri = Uri.parse(url);
      if (!await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
        webOnlyWindowName: '_blank',
      )) {
        throw Exception('Could not launch \$url');
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not launch URL: \$e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Learning Path')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (job == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Learning Path')),
        body: const Center(
          child: Text('No job selected.'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Path: \${job!.roleTitle}'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: _paths.map((path) {
            final resources = _resourcesMap[path.id] ?? [];
            final status = _progressStatus[path.id] ?? 'not_started';

            return Card(
              margin: const EdgeInsets.only(bottom: 20),
              elevation: 2,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              child: ExpansionTile(
                initiallyExpanded: status == 'in_progress',
                leading: CircleAvatar(
                  backgroundColor: status == 'completed'
                      ? const Color(0xFF43A047)
                      : (status == 'in_progress' ? const Color(0xFF004B8D) : Colors.grey),
                  child: Icon(status == 'completed' ? Icons.check : Icons.book,
                      color: status == 'in_progress' ? const Color(0xFFFFD700) : Colors.white),
                ),
                title: Text(
                  'Step \${path.stepNumber}: \${path.title}',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(path.description),
                children: [
                  ...resources.map((r) => ListTile(
                        leading: const Icon(Icons.link, color: Color(0xFF004B8D)),
                        title: Text(r.title),
                        subtitle: Text('\${r.platform} • \${r.duration}'),
                        trailing: TextButton(
                          onPressed: () => _launchURL(r.url, path.id),
                          child: const Text('View', style: TextStyle(color: Color(0xFF004B8D), fontWeight: FontWeight.bold)),
                        ),
                      )),
                  if (status == 'in_progress')
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF004B8D),
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                        onPressed: () => _completeStep(path.id),
                        child: Text('Mark as Completed',
                            style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600)),
                      ),
                    ),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}
