import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_model.dart';
import '../services/user_service.dart';

class ProgressProvider with ChangeNotifier {
  final UserService _userService = UserService();

  Map<int, UserProgress> _userProgress = {};
  bool _isLoading = false;
  String? _error;

  // Getters
  Map<int, UserProgress> get userProgress => _userProgress;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Get progress for a specific learning path
  UserProgress? getProgressForPath(int learningPathId) {
    return _userProgress[learningPathId];
  }

  // Load all user progress
  Future<void> loadUserProgress() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;

    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final progressStream = _userService.getAllUserProgress();
      await for (final progressList in progressStream) {
        _userProgress = {
          for (var progress in progressList) progress.learningPathId: progress
        };
        notifyListeners();
      }
    } catch (e) {
      _error = 'Failed to load user progress: $e';
      debugPrint(_error);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Update progress for a learning path
  Future<void> updateProgress({
    required int learningPathId,
    required String status,
    required int progress,
  }) async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;

    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final currentProgress = _userProgress[learningPathId];
      final updatedProgress = (currentProgress ??
              UserProgress(
                userId: userId,
                learningPathId: learningPathId,
                status: status,
                progress: progress,
                startedAt: status == 'in_progress' ? DateTime.now() : null,
              ))
          .copyWith(
        status: status,
        progress: progress,
        completedAt: status == 'completed' ? DateTime.now() : null,
      );

      await _userService.updateUserProgress(updatedProgress);

      // Local update
      _userProgress[learningPathId] = updatedProgress;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to update progress: $e';
      debugPrint(_error);
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Get completion status for a specific path
  bool isPathCompleted(int learningPathId) {
    return _userProgress[learningPathId]?.status == 'completed';
  }

  // Get completion percentage for a specific path
  double getCompletionPercentage(int learningPathId) {
    final progress = _userProgress[learningPathId];
    if (progress == null) return 0.0;
    return progress.progress.toDouble();
  }

  // Clear all progress (for testing or account deletion)
  Future<void> clearProgress() async {
    _userProgress = {};
    notifyListeners();
  }
}
