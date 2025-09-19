import 'package:cloud_firestore/cloud_firestore.dart';

class UserProfile {
  final String uid;
  final String? email;
  final String? displayName;
  final String? photoURL;
  final String? bio;
  final String? location;
  final List<String>? skills;
  final String? educationLevel;
  final String? careerGoal;
  final Map<String, dynamic>? assessmentResults;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool hasCompletedQuestionnaire;
  final String? interests;

  UserProfile({
    required this.uid,
    this.email,
    this.displayName,
    this.photoURL,
    this.bio,
    this.location,
    this.skills,
    this.educationLevel,
    this.careerGoal,
    this.assessmentResults,
    this.hasCompletedQuestionnaire = false,
    this.interests,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  // Convert UserProfile to a Map
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'displayName': displayName,
      'photoURL': photoURL,
      'bio': bio,
      'location': location,
      'skills': skills,
      'educationLevel': educationLevel,
      'careerGoal': careerGoal,
      'assessmentResults': assessmentResults,
      'hasCompletedQuestionnaire': hasCompletedQuestionnaire,
      'interests': interests,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  // Create UserProfile from a Map
  factory UserProfile.fromMap(Map<String, dynamic> map) {
    return UserProfile(
      uid: map['uid'] ?? '',
      email: map['email'],
      displayName: map['displayName'],
      photoURL: map['photoURL'],
      bio: map['bio'],
      location: map['location'],
      skills: map['skills'] != null ? List<String>.from(map['skills']) : null,
      educationLevel: map['educationLevel'],
      careerGoal: map['careerGoal'],
      assessmentResults: map['assessmentResults'] != null 
          ? Map<String, dynamic>.from(map['assessmentResults'])
          : null,
      hasCompletedQuestionnaire: map['hasCompletedQuestionnaire'] ?? false,
      interests: map['interests'],
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  UserProfile copyWith({
    String? uid,
    String? email,
    String? displayName,
    String? photoURL,
    String? bio,
    String? location,
    List<String>? skills,
    String? educationLevel,
    String? careerGoal,
    Map<String, dynamic>? assessmentResults,
    bool? hasCompletedQuestionnaire,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserProfile(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      photoURL: photoURL ?? this.photoURL,
      bio: bio ?? this.bio,
      location: location ?? this.location,
      skills: skills ?? this.skills,
      educationLevel: educationLevel ?? this.educationLevel,
      careerGoal: careerGoal ?? this.careerGoal,
      assessmentResults: assessmentResults ?? this.assessmentResults,
      hasCompletedQuestionnaire: hasCompletedQuestionnaire ?? this.hasCompletedQuestionnaire,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class UserProgress {
  final String id;
  final String userId;
  final String jobRoleId;
  final Map<String, dynamic> completedLessons; // Map of lessonId to completion status
  final double progressPercentage;
  final DateTime lastAccessed;
  final DateTime createdAt;
  final DateTime updatedAt;

  UserProgress({
    required this.id,
    required this.userId,
    required this.jobRoleId,
    required this.completedLessons,
    required this.progressPercentage,
    DateTime? lastAccessed,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : lastAccessed = lastAccessed ?? DateTime.now(),
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  // Convert UserProgress to a Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'jobRoleId': jobRoleId,
      'completedLessons': completedLessons,
      'progressPercentage': progressPercentage,
      'lastAccessed': Timestamp.fromDate(lastAccessed),
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  // Create UserProgress from a Map
  factory UserProgress.fromMap(Map<String, dynamic> map) {
    return UserProgress(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      jobRoleId: map['jobRoleId'] ?? '',
      completedLessons: Map<String, dynamic>.from(map['completedLessons'] ?? {}),
      progressPercentage: (map['progressPercentage'] ?? 0.0).toDouble(),
      lastAccessed: (map['lastAccessed'] as Timestamp?)?.toDate(),
      createdAt: (map['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  // Create a new UserProgress with updated fields
  UserProgress copyWith({
    String? id,
    String? userId,
    String? jobRoleId,
    Map<String, dynamic>? completedLessons,
    double? progressPercentage,
    DateTime? lastAccessed,
  }) {
    return UserProgress(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      jobRoleId: jobRoleId ?? this.jobRoleId,
      completedLessons: completedLessons ?? this.completedLessons,
      progressPercentage: progressPercentage ?? this.progressPercentage,
      lastAccessed: lastAccessed ?? this.lastAccessed,
      createdAt: this.createdAt,
      updatedAt: DateTime.now(),
    );
  }
}
