import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';
import '../services/user_service.dart';

class ProgressProvider with ChangeNotifier {
  final UserService _userService = UserService();
  
  Map<String, UserProgress> _userProgress = {};
  bool _isLoading = false;
  String? _error;

  // Getters
  Map<String, UserProgress> get userProgress => _userProgress;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Get progress for a specific job role
  UserProgress? getProgressForJob(String jobRoleId) {
    return _userProgress[jobRoleId];
  }

  // Load all user progress
  Future<void> loadUserProgress() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final progressStream = _userService.getAllUserProgress();
      await for (final progressList in progressStream) {
        _userProgress = {
          for (var progress in progressList) progress.jobRoleId: progress
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

  // Mark a lesson as completed
  Future<void> completeLesson({
    required String jobRoleId,
    required String lessonId,
    required bool isCompleted,
  }) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      await _userService.completeLesson(
        jobRoleId: jobRoleId,
        lessonId: lessonId,
        isCompleted: isCompleted,
      );

      // Reload progress after update
      await loadUserProgress();
    } catch (e) {
      _error = 'Failed to update progress: $e';
      debugPrint(_error);
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Get completion status for a specific lesson
  bool isLessonCompleted(String jobRoleId, String lessonId) {
    final progress = _userProgress[jobRoleId];
    if (progress == null) return false;
    return progress.completedLessons[lessonId] == true;
  }

  // Get completion percentage for a specific job role
  double getCompletionPercentage(String jobRoleId) {
    final progress = _userProgress[jobRoleId];
    if (progress == null) return 0.0;
    return progress.progressPercentage;
  }

  // Clear all progress (for testing or account deletion)
  Future<void> clearProgress() async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      // In a real app, you would delete the progress from Firestore here
      // For now, we'll just clear the local state
      _userProgress = {};
    } catch (e) {
      _error = 'Failed to clear progress: $e';
      debugPrint(_error);
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
