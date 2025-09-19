import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';

class UserService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Collection references
  final String _usersCollection = 'users';
  final String _userProgressCollection = 'user_progress';

  // Get user profile
  Stream<UserProfile> getUserProfile(String userId) {
    return _firestore
        .collection(_usersCollection)
        .doc(userId)
        .snapshots()
        .map((doc) => UserProfile.fromMap(
            {'uid': doc.id, ...?doc.data() as Map<String, dynamic>}));
  }

  // Create or update user profile
  Future<void> updateUserProfile(UserProfile userProfile) async {
    await _firestore
        .collection(_usersCollection)
        .doc(userProfile.uid)
        .set(userProfile.toMap(), SetOptions(merge: true));
  }

  // Get user progress for a specific job role
  Stream<UserProgress> getUserProgress(String userId, String jobRoleId) {
    return _firestore
        .collection(_userProgressCollection)
        .where('userId', isEqualTo: userId)
        .where('jobRoleId', isEqualTo: jobRoleId)
        .limit(1)
        .snapshots()
        .map((snapshot) {
      if (snapshot.docs.isEmpty) {
        // Return a new progress object if none exists
        return UserProgress(
          id: '',
          userId: userId,
          jobRoleId: jobRoleId,
          completedLessons: {},
          progressPercentage: 0.0,
        );
      }
      return UserProgress.fromMap({
        'id': snapshot.docs.first.id,
        ...snapshot.docs.first.data(),
      });
    });
  }

  // Update user progress
  Future<void> updateUserProgress(UserProgress progress) async {
    final progressMap = progress.toMap();
    // Remove the id from the map as it's the document ID
    final progressData = Map<String, dynamic>.from(progressMap);
    progressData.remove('id');

    if (progress.id.isEmpty) {
      // Create new progress document
      final docRef = await _firestore.collection(_userProgressCollection).add(progressData);
      // Update the progress with the new document ID
      await _firestore
          .collection(_userProgressCollection)
          .doc(docRef.id)
          .update({'id': docRef.id});
    } else {
      // Update existing progress document
      await _firestore
          .collection(_userProgressCollection)
          .doc(progress.id)
          .update(progressData);
    }
  }

  // Mark a lesson as completed
  Future<void> completeLesson({
    required String jobRoleId,
    required String lessonId,
    required bool isCompleted,
  }) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;

    // Get the current progress
    final progressSnapshot = await _firestore
        .collection(_userProgressCollection)
        .where('userId', isEqualTo: userId)
        .where('jobRoleId', isEqualTo: jobRoleId)
        .limit(1)
        .get();

    UserProgress progress;
    if (progressSnapshot.docs.isEmpty) {
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
      final data = progressSnapshot.docs.first.data();
      final completedLessons = Map<String, dynamic>.from(data['completedLessons'] ?? {});
      completedLessons[lessonId] = isCompleted;
      
      // Calculate progress percentage (simplified example)
      final totalLessons = 10; // You'll need to get the actual total number of lessons
      final completedCount = completedLessons.values.where((v) => v == true).length;
      final progressPercentage = totalLessons > 0 ? completedCount / totalLessons : 0.0;
      
      progress = UserProgress(
        id: progressSnapshot.docs.first.id,
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
    final userId = _auth.currentUser?.uid;
    if (userId == null) return Stream.value([]);
    
    return _firestore
        .collection(_userProgressCollection)
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => UserProgress.fromMap({
                  'id': doc.id,
                  ...doc.data(),
                }))
            .toList());
  }
}
