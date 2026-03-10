import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_model.dart';

class UserService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Collection references
  final String _usersCollection = 'users';
  final String _userProgressCollection = 'user_learning_progress';

  // Get user profile
  Stream<UserProfile> getUserProfile(String userId) {
    return _supabase
        .from(_usersCollection)
        .stream(primaryKey: ['id'])
        .eq('id', userId)
        .map((docs) {
          if (docs.isEmpty) throw Exception('User profile not found');
          final data = Map<String, dynamic>.from(docs.first);
          return UserProfile.fromMap(data);
        });
  }

  // Create or update user profile
  Future<void> updateUserProfile(UserProfile userProfile) async {
    final data = userProfile.toMap();
    await _supabase.from(_usersCollection).upsert(data);
  }

  // Get user progress for a specific learning path
  Stream<UserProgress> getUserProgress(String userId, int learningPathId) {
    return _supabase
        .from(_userProgressCollection)
        .stream(primaryKey: ['id']).map((docs) {
      final filteredDocs = docs
          .where((doc) =>
              doc['user_id'] == userId &&
              doc['learning_path_id'] == learningPathId)
          .toList();

      if (filteredDocs.isEmpty) {
        return UserProgress(
          userId: userId,
          learningPathId: learningPathId,
          status: 'not_started',
          progress: 0,
        );
      }

      final doc = filteredDocs.first;
      return UserProgress.fromMap(doc);
    });
  }

  // Update user progress
  Future<void> updateUserProgress(UserProgress progress) async {
    final data = progress.toMap();

    if (progress.id == null) {
      await _supabase.from(_userProgressCollection).insert(data);
    } else {
      await _supabase
          .from(_userProgressCollection)
          .update(data)
          .eq('id', progress.id!);
    }
  }

  // Get all user progress for the current user
  Stream<List<UserProgress>> getAllUserProgress() {
    final user = _supabase.auth.currentUser;
    final userId = user?.id;
    if (userId == null) return Stream.value([]);

    return _supabase
        .from(_userProgressCollection)
        .stream(primaryKey: ['id']).map((docs) {
      return docs
          .where((doc) => doc['user_id'] == userId)
          .map((doc) => UserProgress.fromMap(doc))
          .toList();
    });
  }

  // Get progress summary for a career
  Future<Map<String, dynamic>> getCareerProgressSummary(int careerId) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return {'completed': 0, 'total': 0, 'percentage': 0.0};

    try {
      // Get all learning paths for this career
      final paths = await _supabase
          .from('learning_paths')
          .select('id')
          .eq('career_id', careerId);
      final pathIds = (paths as List).map((p) => p['id'] as int).toList();

      if (pathIds.isEmpty)
        return {'completed': 0, 'total': 0, 'percentage': 0.0};

      // Get user progress for these paths
      final progressResponse = await _supabase
          .from(_userProgressCollection)
          .select()
          .eq('user_id', user.id)
          .filter('learning_path_id', 'in', '(${pathIds.join(",")})');

      final progresses = (progressResponse as List)
          .map((p) => UserProgress.fromMap(p))
          .toList();
      final completedCount =
          progresses.where((p) => p.status == 'completed').length;

      return {
        'completed': completedCount,
        'total': pathIds.length,
        'percentage': (completedCount / pathIds.length) * 100,
      };
    } catch (e) {
      debugPrint('Error getting career progress summary: $e');
      return {'completed': 0, 'total': 0, 'percentage': 0.0};
    }
  }
}
