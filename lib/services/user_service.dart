import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_model.dart';

class UserService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Collection references
  final String _usersCollection = 'users';
  final String _userProgressCollection = 'user_progress';

  // Get user profile
  Stream<UserProfile> getUserProfile(String userId) {
    return _supabase
        .from(_usersCollection)
        .stream(primaryKey: ['id'])
        .eq('id', userId)
        .map((docs) {
          if (docs.isEmpty) throw Exception('User profile not found');
          final data = Map<String, dynamic>.from(docs.first);
          data['uid'] = data['id'];
          return UserProfile.fromMap(data);
        });
  }

  // Create or update user profile
  Future<void> updateUserProfile(UserProfile userProfile) async {
    final data = userProfile.toMap();
    data['id'] = data['uid'];
    data.remove('uid');

    await _supabase.from(_usersCollection).upsert(data);
  }

  // Get user progress for a specific job role
  Stream<UserProgress> getUserProgress(String userId, String jobRoleId) {
    return _supabase
        .from(_userProgressCollection)
        .stream(primaryKey: ['id']).map((docs) {
      final filteredDocs = docs
          .where((doc) =>
              doc['user_id'] == userId && doc['job_role_id'] == jobRoleId)
          .toList();

      if (filteredDocs.isEmpty) {
        // Return a new progress object if none exists
        return UserProgress(
          id: '',
          userId: userId,
          jobRoleId: jobRoleId,
          completedLessons: {},
          progressPercentage: 0.0,
        );
      }

      final doc = filteredDocs.first;
      return UserProgress(
        id: doc['id'].toString(),
        userId: doc['user_id'] as String,
        jobRoleId: doc['job_role_id'] as String,
        completedLessons:
            doc['completed_lessons'] as Map<String, dynamic>? ?? {},
        progressPercentage:
            (doc['progress_percentage'] as num?)?.toDouble() ?? 0.0,
      );
    });
  }

  // Update user progress
  Future<void> updateUserProgress(UserProgress progress) async {
    final progressData = {
      'user_id': progress.userId,
      'job_role_id': progress.jobRoleId,
      'completed_lessons': progress.completedLessons,
      'progress_percentage': progress.progressPercentage,
    };

    if (progress.id.isEmpty) {
      // Create new progress document
      await _supabase.from(_userProgressCollection).insert(progressData);
    } else {
      // Update existing progress document
      await _supabase
          .from(_userProgressCollection)
          .update(progressData)
          .eq('id', progress.id);
    }
  }

  // Mark a lesson as completed
  Future<void> completeLesson({
    required String jobRoleId,
    required String lessonId,
    required bool isCompleted,
  }) async {
    final user = _supabase.auth.currentUser;
    final userId = user?.id;
    if (userId == null) return;

    // Get the current progress
    final docs = await _supabase
        .from(_userProgressCollection)
        .select()
        .eq('user_id', userId)
        .eq('job_role_id', jobRoleId)
        .limit(1);

    UserProgress progress;
    if (docs.isEmpty) {
      // Create new progress if it doesn't exist
      progress = UserProgress(
        id: '',
        userId: userId,
        jobRoleId: jobRoleId,
        completedLessons: {lessonId: isCompleted},
        progressPercentage: isCompleted ? 1.0 : 0.0, // This will be updated
      );
    } else {
      // Update existing progress
      final data = docs.first;
      final completedLessons =
          Map<String, dynamic>.from(data['completed_lessons'] ?? {});
      completedLessons[lessonId] = isCompleted;

      // Calculate progress percentage (simplified example)
      final totalLessons =
          10; // You'll need to get the actual total number of lessons
      final completedCount =
          completedLessons.values.where((v) => v == true).length;
      final progressPercentage =
          totalLessons > 0 ? completedCount / totalLessons : 0.0;

      progress = UserProgress(
        id: data['id'].toString(),
        userId: userId,
        jobRoleId: jobRoleId,
        completedLessons: completedLessons,
        progressPercentage: progressPercentage,
      );
    }

    await updateUserProgress(progress);
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
          .where((doc) => doc['user_id'] == userId) // Client-side filtering
          .map((doc) => UserProgress(
                id: doc['id'].toString(),
                userId: doc['user_id'] as String,
                jobRoleId: doc['job_role_id'] as String,
                completedLessons:
                    doc['completed_lessons'] as Map<String, dynamic>? ?? {},
                progressPercentage:
                    (doc['progress_percentage'] as num?)?.toDouble() ?? 0.0,
              ))
          .toList();
    });
  }
}
