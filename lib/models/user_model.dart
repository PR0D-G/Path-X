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

  Map<String, dynamic> toMap() {
    final map = {
      'id': uid,
      'email': email,
      'display_name': displayName,
      'avatar_url': photoURL,
      'bio': bio,
      'location': location,
      'skills': skills,
      'educationLevel': educationLevel,
      'selected_career': careerGoal,
      'hasCompletedQuestionnaire': hasCompletedQuestionnaire,
      'interests': interests,
      'created_at': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };

    // Remove null values to avoid errors if columns don't exist in Supabase
    map.removeWhere((key, value) => value == null);
    return map;
  }

  factory UserProfile.fromMap(Map<String, dynamic> map) {
    return UserProfile(
      uid: map['id']?.toString() ?? '',
      email: map['email'],
      displayName: map['display_name'],
      photoURL: map['avatar_url'],
      bio: map['bio'],
      location: map['location'],
      skills: map['skills'] != null ? List<String>.from(map['skills']) : null,
      educationLevel: map['education_level'] ?? map['educationLevel'],
      careerGoal: map['selected_career'] ?? map['careerGoal'],
      assessmentResults: map['assessmentResults'] != null
          ? Map<String, dynamic>.from(map['assessmentResults'])
          : null,
      hasCompletedQuestionnaire: map['has_completed_questionnaire'] ?? map['hasCompletedQuestionnaire'] ?? false,
      interests: map['interests'],
      createdAt: map['created_at'] != null
          ? DateTime.tryParse(map['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
      updatedAt: (map['updated_at'] ?? map['updatedAt']) != null
          ? DateTime.tryParse((map['updated_at'] ?? map['updatedAt']).toString()) ?? DateTime.now()
          : DateTime.now(),
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
    String? interests, // ✅ added here
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
      hasCompletedQuestionnaire:
          hasCompletedQuestionnaire ?? this.hasCompletedQuestionnaire,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      interests: interests ?? this.interests,
    );
  }
}

class UserProgress {
  final int? id;
  final String userId;
  final int learningPathId;
  final String status;
  final int progress;
  final DateTime? startedAt;
  final DateTime? completedAt;

  UserProgress({
    this.id,
    required this.userId,
    required this.learningPathId,
    required this.status,
    required this.progress,
    this.startedAt,
    this.completedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'user_id': userId,
      'learning_path_id': learningPathId,
      'status': status,
      'progress': progress,
      'started_at': startedAt?.toIso8601String(),
      'completed_at': completedAt?.toIso8601String(),
    };
  }

  factory UserProgress.fromMap(Map<String, dynamic> map) {
    return UserProgress(
      id: map['id'],
      userId: map['user_id'] ?? '',
      learningPathId: map['learning_path_id'] ?? 0,
      status: map['status'] ?? 'not_started',
      progress: map['progress'] ?? 0,
      startedAt: map['started_at'] != null
          ? DateTime.tryParse(map['started_at'])
          : null,
      completedAt: map['completed_at'] != null
          ? DateTime.tryParse(map['completed_at'])
          : null,
    );
  }

  UserProgress copyWith({
    int? id,
    String? userId,
    int? learningPathId,
    String? status,
    int? progress,
    DateTime? startedAt,
    DateTime? completedAt,
  }) {
    return UserProgress(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      learningPathId: learningPathId ?? this.learningPathId,
      status: status ?? this.status,
      progress: progress ?? this.progress,
      startedAt: startedAt ?? this.startedAt,
      completedAt: completedAt ?? this.completedAt,
    );
  }
}
