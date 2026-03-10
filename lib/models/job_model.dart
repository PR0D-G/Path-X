import 'package:flutter/foundation.dart';

@immutable
class LearningResource {
  final int? id;
  final int? learningPathId;
  final String resourceType;
  final String platform;
  final String title;
  final String url;
  final String duration;
  final double rating;
  final bool free;
  final bool certificate;

  // For backward compatibility
  List<String> get courses => [];

  const LearningResource({
    this.id,
    this.learningPathId,
    required this.resourceType,
    required this.platform,
    required this.title,
    required this.url,
    required this.duration,
    required this.rating,
    required this.free,
    required this.certificate,
  });

  factory LearningResource.fromJson(Map<String, dynamic> json) {
    return LearningResource(
      id: json['id'],
      learningPathId: json['learning_path_id'],
      resourceType: json['resource_type']?.toString() ?? '',
      platform: json['platform']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      url: json['url']?.toString() ?? '',
      duration: json['duration']?.toString() ?? '',
      rating: double.tryParse(json['rating']?.toString() ?? '0') ?? 0.0,
      free: json['free'] == true,
      certificate: json['certificate'] == true,
    );
  }
}

@immutable
class LearningPath {
  final int id;
  final int careerId;
  final int stepNumber;
  final String title;
  final String description;

  const LearningPath({
    required this.id,
    required this.careerId,
    required this.stepNumber,
    required this.title,
    required this.description,
  });

  factory LearningPath.fromJson(Map<String, dynamic> json) {
    return LearningPath(
      id: json['id'],
      careerId: json['career_id'],
      stepNumber: json['step_number'] ?? 0,
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
    );
  }
}

@immutable
class Job {
  final int? id;
  final String roleTitle; // Maps to title
  final String category;
  final String description;
  final String demandLevel;
  final int salaryMin;
  final int salaryMax;
  final bool remotePossible;
  final bool fresherFriendly;

  // Existing UI mapped fields
  final List<String> coreSkills;
  final List<LearningResource> learningResources;
  final double matchPercentage;
  final String education;

  String get averageSalary =>
      '₹${(salaryMin ~/ 100000)}L - ₹${(salaryMax ~/ 100000)}L';
  String get jobGrowthOutlook => demandLevel;

  const Job({
    this.id,
    required this.roleTitle,
    this.category = '',
    this.description = '',
    this.demandLevel = '',
    this.salaryMin = 0,
    this.salaryMax = 0,
    this.remotePossible = false,
    this.fresherFriendly = false,
    required this.coreSkills,
    this.learningResources = const [],
    this.education = '',
    this.matchPercentage = 0.0,
  });

  factory Job.fromJson(Map<String, dynamic> json) {
    final rawSkills = json['core_skills'];
    List<String> skills = [];
    if (rawSkills != null) {
      if (rawSkills is List) {
        skills = List<String>.from(rawSkills);
      } else if (rawSkills is String) {
        skills = rawSkills.split(',').map((s) => s.trim()).toList();
      }
    }

    return Job(
      id: json['id'],
      roleTitle: json['title']?.toString() ?? '',
      category: json['category']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      demandLevel: json['demand_level']?.toString() ?? '',
      salaryMin: json['salary_min'] ?? 0,
      salaryMax: json['salary_max'] ?? 0,
      remotePossible: json['remote_possible'] == true,
      fresherFriendly: json['fresher_friendly'] == true,
      coreSkills: skills,
      education:
          (json['education_level'] ?? json['education'])?.toString() ?? '',
      matchPercentage:
          double.tryParse(json['match_percentage']?.toString() ?? '0') ?? 0.0,
    );
  }
}
