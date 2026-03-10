import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/job_model.dart';

class JobService {
  static final List<Job> _cachedJobs = [];

  // Get all jobs (Supabase or fallback to Mocked)
  static Future<List<Job>> getJobs() async {
    try {
      final supabase = Supabase.instance.client;
      // Reverted to 'title' as per user request
      final response =
          await supabase.from('careers').select('id, title, description');

      List<Job> fetchedJobs = [];
      for (var row in response) {
        final careerId = row['id'];

        // Fetch skills from career_skills (skill_name)
        List<String> coreSkills = [];
        try {
          final skillsResponse = await supabase
              .from('career_skills')
              .select('skill_name')
              .eq('career_id', careerId);
          coreSkills = (skillsResponse as List)
              .map((s) => s['skill_name'].toString())
              .toList();
        } catch (e) {
          debugPrint('Notice: Error fetching skills for job list: $e');
        }

        // Fetch salary/demand from career_salary_levels
        int salaryMin = 0;
        int salaryMax = 0;
        String demandLevel = 'Low';
        try {
          final salaryResponse = await supabase
              .from('career_salary_levels')
              .select('salary, demand_score')
              .eq('career_id', careerId)
              .order('salary', ascending: true);

          if (salaryResponse.isNotEmpty) {
            salaryMin = salaryResponse.first['salary'] ?? 0;
            salaryMax = salaryResponse.last['salary'] ?? 0;
            final avgDemand = salaryResponse
                    .map((s) => s['demand_score'] as int? ?? 0)
                    .reduce((a, b) => a + b) /
                salaryResponse.length;
            demandLevel =
                avgDemand >= 4 ? 'High' : (avgDemand >= 2.5 ? 'Medium' : 'Low');
          }
        } catch (e) {
          debugPrint('Notice: Error fetching salary for job list: $e');
        }

        fetchedJobs.add(Job(
          id: careerId,
          roleTitle: row['title'] ?? 'Unknown Role',
          category: '', // Category not in schema snippet
          description: row['description'] ?? '',
          demandLevel: demandLevel,
          salaryMin: salaryMin,
          salaryMax: salaryMax,
          coreSkills: coreSkills,
        ));
      }

      if (fetchedJobs.isNotEmpty) {
        return fetchedJobs;
      }
    } catch (e) {
      debugPrint('Failed to fetch from Supabase: $e');
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

      if (assessmentResponseList.isEmpty) {
        debugPrint(
            'MATCH DEBUG: No assessment results found for user: ${user.id}');
        return [];
      }

      final Map<String, dynamic> scores = assessmentResponseList.first;
      debugPrint('MATCH DEBUG: Final User Scores Map: $scores');
      debugPrint('MATCH DEBUG: USER KEYS: ${scores.keys.toList()}');

      // 2. Fetch all careers with explicit join matching the new schema
      debugPrint('MATCH DEBUG: Fetching careers with exhaustive join...');
      final List<dynamic> careersList =
          await supabase.from('careers').select('''
        id,
        title,
        description,
        career_skills (
          skill_name,
          importance
        ),
        career_weights (
          *
        ),
        career_salary_levels (
          level,
          salary,
          demand_score
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

      // --- TEMP MOCK FALLBACK FOR DEBUGGING ---
      // If the database is empty, we provide some default weights for common careers
      // so the user can verify the algorithm works.
      final Map<int, Map<String, dynamic>> mockWeights = {
        1: {'realistic': 4.0, 'investigative': 5.0, 'logic': 5.0, 'reasoning': 4.0, 'pattern': 5.0, 'math': 4.0}, // Software Engineer
        5: {'realistic': 3.0, 'investigative': 4.0, 'conventional': 5.0, 'logic': 5.0}, // DevOps
        8: {'investigative': 5.0, 'realistic': 3.0, 'logic': 5.0, 'reasoning': 5.0}, // Cybersecurity
        10: {'investigative': 5.0, 'logic': 5.0, 'pattern': 5.0, 'math': 5.0}, // ML Engineer
        21: {'enterprising': 4.0, 'conventional': 5.0, 'math': 4.0, 'logic': 4.0}, // Financial Analyst
        30: {'enterprising': 5.0, 'social': 3.0, 'conventional': 4.0, 'reasoning': 5.0}, // Business Analyst
        31: {'realistic': 5.0, 'investigative': 4.0, 'math': 5.0, 'logic': 4.0}, // Mechanical Engineer
        82: {'investigative': 4.0, 'conventional': 4.0, 'logic': 5.0, 'pattern': 5.0}, // Data Engineer
      };

      List<Job> matchedJobs = [];

      for (var row in careersList) {
        final careerId = int.tryParse(row['id'].toString());
        final String careerTitle = row['title'] ?? 'Unknown';

        // Try to get weights from the join first
        final joinedWeights = row['career_weights'] as List?;
        Map<String, dynamic>? rawW;

        if (joinedWeights != null && joinedWeights.isNotEmpty) {
          rawW = joinedWeights.first as Map<String, dynamic>;
        } else if (careerId != null &&
            weightsByCareerId.containsKey(careerId)) {
          rawW = weightsByCareerId[careerId];
          debugPrint('MATCH DEBUG: Using fallback table weights for $careerTitle');
        } else if (careerId != null && mockWeights.containsKey(careerId)) {
          rawW = mockWeights[careerId];
          debugPrint(
              'MATCH DEBUG: Using HARDCODED MOCK weights for $careerTitle (ID: $careerId) because DB is empty.');
        }

        if (rawW == null) {
          debugPrint(
              'MATCH DEBUG: Career $careerTitle (ID: $careerId) STILL HAS NO weights. Using neutral defaults.');
          rawW = {};
        }

        final Map<String, dynamic> currentWeights = rawW;
        debugPrint('MATCH DEBUG: WEIGHT KEYS for $careerTitle: ${currentWeights.keys.toList()}');

        // Auto-assign weights based on trait prefixes to handle truncated/differing column names
        double getWeight(String trait) {
          final traitLower = trait.toLowerCase();
          // Try exact match first
          if (currentWeights.containsKey(traitLower)) {
            return (currentWeights[traitLower] as num?)?.toDouble() ?? 0.0;
          }
          // Try key that starts with the trait
          final key = currentWeights.keys.firstWhere(
            (k) => k.toLowerCase().startsWith(traitLower.substring(0, 4)),
            orElse: () => '',
          );
          if (key.isNotEmpty) {
            return (currentWeights[key] as num?)?.toDouble() ?? 0.0;
          }
          return 0.0;
        }

        final Map<String, double> w = {
          'realistic': getWeight('realistic'),
          'investigative': getWeight('investigative'),
          'artistic': getWeight('artistic'),
          'social': getWeight('social'),
          'enterprising': getWeight('enterprising'),
          'conventional': getWeight('conventional'),
          'logic': getWeight('logic'),
          'reasoning': getWeight('reasoning'),
          'pattern': getWeight('pattern'),
          'math': getWeight('math'),
        };

        // 1. Normalize User Scores (0.0 to 1.0)
        // RIASEC max is 15 (3 questions * 5 stars), Aptitude max is 2 (2 questions), Math max is 3 (3 questions)
        final double normR = ((scores['riasec_realistic'] ?? 0.0) / 15.0).clamp(0.0, 1.0);
        final double normI = ((scores['riasec_investigative'] ?? 0.0) / 15.0).clamp(0.0, 1.0);
        final double normA = ((scores['riasec_artistic'] ?? 0.0) / 15.0).clamp(0.0, 1.0);
        final double normS = ((scores['riasec_social'] ?? 0.0) / 15.0).clamp(0.0, 1.0);
        final double normE = ((scores['riasec_enterprising'] ?? 0.0) / 15.0).clamp(0.0, 1.0);
        final double normC = ((scores['riasec_conventional'] ?? 0.0) / 15.0).clamp(0.0, 1.0);

        final double normLogic = ((scores['logic'] ?? 0.0) / 2.0).clamp(0.0, 1.0);
        final double normReasoning = ((scores['reasoning'] ?? 0.0) / 2.0).clamp(0.0, 1.0);
        final double normPattern = ((scores['pattern'] ?? 0.0) / 2.0).clamp(0.0, 1.0);
        final double normMath = ((scores['math'] ?? 0.0) / 3.0).clamp(0.0, 1.0);

        if (careerId == 1) {
          debugPrint('MATCH DEBUG: Calculation check for ID 1:');
          debugPrint('User Math: ${scores['math']} (Norm: $normMath) vs Weight: ${w['math']}');
          debugPrint('User Logic: ${scores['logic']} (Norm: $normLogic) vs Weight: ${w['logic']}');
        }

        // 2. Calculate RIASEC Sub-score (Weighted sum)
        double riasecScore = 0;
        riasecScore += normR * (w['realistic'] ?? 0.0);
        riasecScore += normI * (w['investigative'] ?? 0.0);
        riasecScore += normA * (w['artistic'] ?? 0.0);
        riasecScore += normS * (w['social'] ?? 0.0);
        riasecScore += normE * (w['enterprising'] ?? 0.0);
        riasecScore += normC * (w['conventional'] ?? 0.0);

        // 3. Calculate Aptitude Sub-score (Weighted sum)
        double aptitudeScore = 0;
        aptitudeScore += normLogic * (w['logic'] ?? 0.0);
        aptitudeScore += normReasoning * (w['reasoning'] ?? 0.0);
        aptitudeScore += normPattern * (w['pattern'] ?? 0.0);
        aptitudeScore += normMath * (w['math'] ?? 0.0);

        // 4. Final Weighted Match (70% Personality, 30% Aptitude)
        double finalMatch = (riasecScore * 0.7) + (aptitudeScore * 0.3);
        double matchPercentage = finalMatch * 100;

        // 5. Apply Market Demand Bonus based on career_salary_levels demand_score
        double demandBonus = 0;
        final salaryLevels = row['career_salary_levels'] as List?;
        if (salaryLevels != null && salaryLevels.isNotEmpty) {
          final maxDemand = salaryLevels
              .map((s) => (s['demand_score'] as num?)?.toDouble() ?? 0.0)
              .reduce((a, b) => a > b ? a : b);

          if (maxDemand >= 4) {
            demandBonus = 5.0; // High
          } else if (maxDemand >= 2.5) {
            demandBonus = 2.0; // Medium
          }
        }
        matchPercentage += demandBonus;

        matchPercentage = matchPercentage.clamp(0.0, 100.0);

        if (matchPercentage.isNaN || matchPercentage.isInfinite) {
          matchPercentage = 0;
        }

        debugPrint(
            'MATCH DEBUG: Results for ${row['title']}: Match=${matchPercentage.toStringAsFixed(1)}% (Base=${finalMatch * 100}, Bonus=$demandBonus)');

        // 6. Filter: match >= 40%
        if (matchPercentage >= 40) {
          List<String> skills = [];
          final joinedSkills = row['career_skills'] as List?;
          if (joinedSkills != null && joinedSkills.isNotEmpty) {
            skills =
                joinedSkills.map((s) => s['skill_name'].toString()).toList();
          }

          int salaryMin = 0;
          int salaryMax = 0;
          if (salaryLevels != null && salaryLevels.isNotEmpty) {
            final salaries = salaryLevels
                .map((s) => (s['salary'] as num?)?.toInt() ?? 0)
                .toList()
              ..sort();
            salaryMin = salaries.first;
            salaryMax = salaries.last;
          }

          matchedJobs.add(Job(
            id: row['id'],
            roleTitle: row['title'] ?? 'Unknown Role',
            category: '', // Not in provided schema
            description: row['description'] ?? '',
            demandLevel: demandBonus >= 5
                ? 'High'
                : (demandBonus >= 2 ? 'Medium' : 'Low'),
            salaryMin: salaryMin,
            salaryMax: salaryMax,
            coreSkills: skills,
            matchPercentage: matchPercentage,
          ));
        }
      }
      debugPrint('MATCH DEBUG: Final matched count: ${matchedJobs.length}');

      // 3. Sort descending by match percentage
      matchedJobs
          .sort((a, b) => b.matchPercentage.compareTo(a.matchPercentage));

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
