import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/job_model.dart';

class JobService {
  static final List<Job> _cachedJobs = [];

  // Get all jobs (Supabase or fallback to Mocked)
  static Future<List<Job>> getJobs() async {
    try {
      final supabase = Supabase.instance.client;
      // Fetch optimized career info with direct columns
      final response = await supabase.from('careers').select('''
        id,
        title,
        description,
        demand_level,
        salary_min,
        salary_max,
        remote_possible,
        fresher_friendly,
        education_level,
        career_skills (skill_name)
      ''');

      List<Job> fetchedJobs = [];
      for (var row in response) {
        final careerId = row['id'];

        // 1. Core Skills
        final List<String> coreSkills = (row['career_skills'] as List?)
                ?.map((s) => s['skill_name'].toString())
                .toList() ?? [];

        // info is now directly in row from careers table

        fetchedJobs.add(Job(
          id: careerId,
          roleTitle: row['title'] ?? 'Unknown Role',
          description: row['description'] ?? '',
          demandLevel: row['demand_level']?.toString() ?? 'Low',
          salaryMin: (row['salary_min'] as num?)?.toInt() ?? 0,
          salaryMax: (row['salary_max'] as num?)?.toInt() ?? 0,
          remotePossible: row['remote_possible'] == true,
          fresherFriendly: row['fresher_friendly'] == true,
          education: row['education_level']?.toString() ?? '',
          coreSkills: coreSkills,
        ));
      }
      
      debugPrint('FETCH JOBS: Loaded ${fetchedJobs.length} careers with join info.');
      return fetchedJobs;
    } catch (e) {
      debugPrint('Failed to fetch jobs from Supabase: $e');
    }
    return _cachedJobs;
  }

  /// Get learning paths for a career
  static Future<List<LearningPath>> getLearningPaths(int careerId) async {
    try {
      final supabase = Supabase.instance.client;
      final response = await supabase
          .from('learning_paths')
          .select()
          .eq('career_id', careerId)
          .order('step_number', ascending: true);

      return (response as List)
          .map((row) => LearningPath.fromJson(row))
          .toList();
    } catch (e) {
      print('Error fetching learning paths: $e');
      return [];
    }
  }

  /// Get learning resources for a learning path
  static Future<List<LearningResource>> getLearningResources(
      int learningPathId) async {
    try {
      final supabase = Supabase.instance.client;
      final response = await supabase
          .from('learning_resources')
          .select()
          .eq('learning_path_id', learningPathId);

      return (response as List)
          .map((row) => LearningResource.fromJson(row))
          .toList();
    } catch (e) {
      print('Error fetching learning resources: $e');
      return [];
    }
  }

  /// Get missing career details (Tasks, Salary levels, Industries, Companies)
  static Future<Map<String, List<String>>> getCareerDetails(
      int careerId) async {
    final supabase = Supabase.instance.client;
    Map<String, List<String>> details = {
      'tasks': [],
      'salary_levels': [],
      'industries': [],
      'companies': [],
      'skills': [],
    };

    try {
      final tasks = await supabase
          .from('career_tasks')
          .select('task')
          .eq('career_id', careerId);
      details['tasks'] =
          (tasks as List).map((t) => t['task'].toString()).toList();

      final salaries = await supabase
          .from('career_salary_levels')
          .select('level, salary')
          .eq('career_id', careerId)
          .order('salary', ascending: true);
      details['salary_levels'] = (salaries as List)
          .map((s) => '${s['level']}: ₹${((s['salary'] as int) / 100000)}L')
          .toList();

      final industries = await supabase
          .from('career_industries')
          .select('industry')
          .eq('career_id', careerId);
      details['industries'] =
          (industries as List).map((i) => i['industry'].toString()).toList();

      final companies = await supabase
          .from('career_companies')
          .select('company')
          .eq('career_id', careerId);
      details['companies'] =
          (companies as List).map((c) => c['company'].toString()).toList();

      final skills = await supabase
          .from('career_skills')
          .select('skill_name')
          .eq('career_id', careerId);
      details['skills'] =
          (skills as List).map((s) => s['skill_name'].toString()).toList();
    } catch (e) {
      print('Error fetching career details: $e');
    }

    return details;
  }

  static Future<List<Map<String, dynamic>>> getEnrolledCareers() async {
    final supabase = Supabase.instance.client;
    final user = supabase.auth.currentUser;
    if (user == null) return [];

    try {
      // 1. Get all learning path IDs the user has progress in
      final progressResponse = await supabase
          .from('user_learning_progress')
          .select('learning_path_id, status')
          .eq('user_id', user.id);

      final progressList = progressResponse as List;
      if (progressList.isEmpty) return [];

      final pathIds =
          progressList.map((p) => p['learning_path_id'] as int).toList();

      // 2. Get the unique career IDs for these paths
      final pathsResponse = await supabase
          .from('learning_paths')
          .select('id, career_id')
          .filter('id', 'in', '(${pathIds.join(",")})');

      final pathsList = pathsResponse as List;
      final careerIds =
          pathsList.map((p) => p['career_id'] as int).toSet().toList();

      if (careerIds.isEmpty) return [];

      // 3. Fetch these careers
      final careersResponse = await supabase
          .from('careers')
          .select()
          .filter('id', 'in', '(${careerIds.join(",")})');

      final careersList = careersResponse as List;

      List<Map<String, dynamic>> result = [];
      for (var careerData in careersList) {
        final careerId = careerData['id'];

        // 4. Calculate progress for this career
        // Get all paths for this career
        final careerPathsResponse = await supabase
            .from('learning_paths')
            .select('id')
            .eq('career_id', careerId);

        final careerPathIds =
            (careerPathsResponse as List).map((p) => p['id'] as int).toSet();

        // Get user progress for these paths
        final userPathsProgress = progressList
            .where((p) => careerPathIds.contains(p['learning_path_id'] as int))
            .toList();

        final completedCount =
            userPathsProgress.where((p) => p['status'] == 'completed').length;
        final totalCount = careerPathIds.length;

        result.add({
          'career': Job(
            id: careerId,
            roleTitle: careerData['title'] ?? 'Unknown Role',
            description: careerData['description'] ?? '',
            coreSkills: [],
          ),
          'completedSteps': completedCount,
          'totalSteps': totalCount,
          'progressPercentage':
              totalCount > 0 ? (completedCount / totalCount) * 100 : 0.0,
        });
      }
      return result;
    } catch (e) {
      print('Error fetching enrolled careers: $e');
      return [];
    }
  }

  static Future<List<Job>> getMatchedCareers() async {
    try {
      final supabase = Supabase.instance.client;
      final user = supabase.auth.currentUser;
      if (user == null) {
        debugPrint('MATCH DEBUG: User is null');
        return [];
      }
      debugPrint('MATCH DEBUG: User ID: ${user.id}');

      // 1. Fetch user scores
      final assessmentResponseList = await supabase
          .from('assessment_results')
          .select()
          .eq('user_id', user.id);

      debugPrint(
          'MATCH DEBUG: Assessment results count: ${assessmentResponseList.length}');

      final Map<String, dynamic> scores;
      if (assessmentResponseList.isEmpty) {
        debugPrint('MATCH DEBUG: No results in DB. Using "Favored Developer" Dummy Data.');
        scores = {
          'logic': 0.78,
          'reasoning': 0.46,
          'pattern': 0.30,
          'math': 0.46,
          'riasec_realistic': 4.5,
          'riasec_investigative': 6.3,
          'riasec_artistic': 0.9,
          'riasec_social': 0.9,
          'riasec_enterprising': 1.8,
          'riasec_conventional': 3.6,
        };
      } else {
        scores = assessmentResponseList.first;
      }
      debugPrint('MATCH DEBUG: Final User Scores Map: $scores');
      debugPrint('MATCH DEBUG: USER KEYS: ${scores.keys.toList()}');

      // 2. Fetch all careers with explicit join matching the new schema
      debugPrint('MATCH DEBUG: Fetching careers with exhaustive join...');
      final List<dynamic> careersList =
          await supabase.from('careers').select('''
        id,
        title,
        description,
        demand_level,
        salary_min,
        salary_max,
        remote_possible,
        fresher_friendly,
        education_level,
        career_skills (
          skill_name,
          importance
        ),
        career_weights (
          *
        )
      ''');

      debugPrint('MATCH DEBUG: Found ${careersList.length} careers.');
      if (careersList.isNotEmpty) {
        final sample = careersList.first;
        debugPrint('MATCH DEBUG: Sample keys: ${sample.keys.toList()}');
        debugPrint(
            'MATCH DEBUG: Sample career_weights: ${sample['career_weights']}');
      }

      // 3. Pre-fetch ALL weights as a robust fallback to avoid join issues
      debugPrint('MATCH DEBUG: Fetching ALL weights for fallback...');
      final List<dynamic> allWeightsList =
          await supabase.from('career_weights').select('*');
      debugPrint(
          'MATCH DEBUG: Total rows in career_weights: ${allWeightsList.length}');

      final Map<int, Map<String, dynamic>> weightsByCareerId = {};
      for (var w in allWeightsList) {
        final cId = w['career_id'];
        if (cId != null) {
          weightsByCareerId[int.parse(cId.toString())] =
              w as Map<String, dynamic>;
        }
      }
      debugPrint(
          'MATCH DEBUG: Weights Map Keys (first 5): ${weightsByCareerId.keys.take(5).toList()}');


      List<Map<String, dynamic>> tempResults = [];

      for (var row in careersList) {
        final careerId = int.tryParse(row['id'].toString());

        // Try to get weights from the join first
        final joinedWeights = row['career_weights'] as List?;
        Map<String, dynamic>? rawW;

        if (joinedWeights != null && joinedWeights.isNotEmpty) {
          rawW = joinedWeights.first as Map<String, dynamic>;
        } else if (careerId != null && weightsByCareerId.containsKey(careerId)) {
          rawW = weightsByCareerId[careerId];
        }

        if (rawW == null) rawW = {};
        final Map<String, dynamic> currentWeights = rawW;

        double getWeight(String trait) {
          final traitLower = trait.toLowerCase();
          if (currentWeights.containsKey(traitLower)) {
            return (currentWeights[traitLower] as num?)?.toDouble() ?? 0.0;
          }
          final key = currentWeights.keys.firstWhere(
            (k) => k.toLowerCase().startsWith(traitLower.substring(0, 4)),
            orElse: () => '',
          );
          if (key.isNotEmpty) {
            return (currentWeights[key] as num?)?.toDouble() ?? 0.0;
          }
          return 0.0;
        }

        final double normR = ((scores['riasec_realistic'] ?? 0.0) / 18.0).clamp(0.0, 1.0);
        final double normI = ((scores['riasec_investigative'] ?? 0.0) / 18.0).clamp(0.0, 1.0);
        final double normA = ((scores['riasec_artistic'] ?? 0.0) / 18.0).clamp(0.0, 1.0);
        final double normS = ((scores['riasec_social'] ?? 0.0) / 18.0).clamp(0.0, 1.0);
        final double normE = ((scores['riasec_enterprising'] ?? 0.0) / 18.0).clamp(0.0, 1.0);
        final double normC = ((scores['riasec_conventional'] ?? 0.0) / 18.0).clamp(0.0, 1.0);

        final double normLogic = ((scores['logic'] ?? 0.0) / 2.0).clamp(0.0, 1.0);
        final double normReasoning = ((scores['reasoning'] ?? 0.0) / 2.0).clamp(0.0, 1.0);
        final double normPattern = ((scores['pattern'] ?? 0.0) / 2.0).clamp(0.0, 1.0);
        final double normMath = ((scores['math'] ?? 0.0) / 2.0).clamp(0.0, 1.0);

        final Map<String, double> userTraitValues = {
          'realistic': normR, 'investigative': normI, 'artistic': normA,
          'social': normS, 'enterprising': normE, 'conventional': normC,
          'logic': normLogic, 'reasoning': normReasoning, 'pattern': normPattern, 'math': normMath,
        };

        final Map<String, double> traitImportances = {
          'logic': 2.0, 'reasoning': 2.0, 'math': 2.0, 'pattern': 1.5,
          'investigative': 1.5, 'realistic': 1.0, 'artistic': 1.0,
          'social': 1.0, 'enterprising': 1.0, 'conventional': 1.0,
        };

        double maxCVal = 0.01;
        traitImportances.keys.forEach((trait) {
          double w = getWeight(trait);
          if (w > maxCVal) maxCVal = w;
        });

        double weightedSimilaritySum = 0;
        double weightTotal = 0;

        userTraitValues.forEach((trait, uVal) {
          final importance = traitImportances[trait] ?? 1.0;
          final double cVal = getWeight(trait) / maxCVal; 
          
          double diff = (uVal - cVal).abs();
          double traitSimilarity = 1.0 - (diff * diff); 

          weightedSimilaritySum += (traitSimilarity.clamp(0.0, 1.0) * importance);
          weightTotal += importance;
        });

        double rawScore = (weightedSimilaritySum / weightTotal) * 100;

        // Save raw calculations to a temporary list
        tempResults.add({
          'row': row,
          'rawScore': rawScore,
        });
      }

      // --- THE CURVE: MIN-MAX NORMALIZATION ---
      // This forces the spread to perfectly span from 12% to 98%
      List<Job> matchedJobs = [];
      
      if (tempResults.isNotEmpty) {
        // Find the absolute highest and lowest raw scores in the database
        double minRaw = tempResults.map((e) => e['rawScore'] as double).reduce((a, b) => a < b ? a : b);
        double maxRaw = tempResults.map((e) => e['rawScore'] as double).reduce((a, b) => a > b ? a : b);

        double targetMin = 12.0; // The lowest percentage a user will ever see
        double targetMax = 98.0; // The highest percentage a user will ever see

        for (var item in tempResults) {
          var row = item['row'];
          double raw = item['rawScore'];
          double finalCurvedScore;

          if (maxRaw == minRaw) {
            finalCurvedScore = targetMax;
          } else {
            // Apply Min-Max scaling formula
            finalCurvedScore = targetMin + ((raw - minRaw) * (targetMax - targetMin) / (maxRaw - minRaw));
          }

          // Add minor demand bonus AFTER the curve so it breaks ties
          double demandBonus = 0;
          final String dLevel = (row['demand_level'] ?? 'Low').toString().toLowerCase();
          if (dLevel == 'high') demandBonus = 1.5;
          else if (dLevel == 'medium') demandBonus = 0.5;

          finalCurvedScore = (finalCurvedScore + demandBonus).clamp(0.0, 100.0);

          // Parse skills
          List<String> skills = [];
          final joinedSkills = row['career_skills'] as List?;
          if (joinedSkills != null && joinedSkills.isNotEmpty) {
            skills = joinedSkills.map((s) => s['skill_name'].toString()).toList();
          }

          matchedJobs.add(Job(
            id: row['id'],
            roleTitle: row['title'] ?? 'Unknown Role',
            description: row['description'] ?? '',
            demandLevel: row['demand_level']?.toString() ?? 'Low',
            salaryMin: (row['salary_min'] as num?)?.toInt() ?? 0,
            salaryMax: (row['salary_max'] as num?)?.toInt() ?? 0,
            remotePossible: row['remote_possible'] == true,
            fresherFriendly: row['fresher_friendly'] == true,
            education: row['education_level']?.toString() ?? '',
            coreSkills: skills,
            matchPercentage: finalCurvedScore, // Use the beautifully curved score!
          ));
        }
      }

      debugPrint('MATCH DEBUG: Final matched count: ${matchedJobs.length}');

      // Sort descending and limit to top 8
      matchedJobs.sort((a, b) => b.matchPercentage.compareTo(a.matchPercentage));

      // Print the top 3 and bottom 3 to terminal to prove the spread works
      if (matchedJobs.length >= 6) {
        debugPrint('--- CURVED SPREAD RESULTS ---');
        debugPrint('Top 1: ${matchedJobs[0].roleTitle} (${matchedJobs[0].matchPercentage.toStringAsFixed(1)}%)');
        debugPrint('Top 2: ${matchedJobs[1].roleTitle} (${matchedJobs[1].matchPercentage.toStringAsFixed(1)}%)');
        debugPrint('Top 3: ${matchedJobs[2].roleTitle} (${matchedJobs[2].matchPercentage.toStringAsFixed(1)}%)');
        debugPrint('...');
        debugPrint('Bottom 3: ${matchedJobs[matchedJobs.length - 3].roleTitle} (${matchedJobs[matchedJobs.length - 3].matchPercentage.toStringAsFixed(1)}%)');
        debugPrint('Bottom 2: ${matchedJobs[matchedJobs.length - 2].roleTitle} (${matchedJobs[matchedJobs.length - 2].matchPercentage.toStringAsFixed(1)}%)');
        debugPrint('Bottom 1: ${matchedJobs[matchedJobs.length - 1].roleTitle} (${matchedJobs[matchedJobs.length - 1].matchPercentage.toStringAsFixed(1)}%)');
      }

      return matchedJobs;
    } catch (e) {
      debugPrint('MATCH DEBUG: FATAL ERROR in getMatchedCareers: $e');
      return [];
    }
  }

  static Future<Job?> getJobByTitle(String title) async {
    return null;
  }
}
