import 'package:flutter/foundation.dart';

/// Represents a learning resource with platform, courses, title, and URL
@immutable
class LearningResource {
  final String platform;
  final List<String>? courses;
  final String? title;
  final String? url;

  const LearningResource({
    required this.platform,
    this.courses,
    this.title,
    this.url,
  });

  /// Creates a LearningResource from JSON data
  factory LearningResource.fromJson(Map<String, dynamic> json) {
    return LearningResource(
      platform: json['Platform']?.toString() ?? '',
      courses: json['Courses'] is List
          ? List<String>.from(
              (json['Courses'] as List).map((x) => x.toString()))
          : null,
      title: json['Title']?.toString(),
      url: json['URL']?.toString(),
    );
  }

  /// Converts the LearningResource to a JSON map
  Map<String, dynamic> toJson() => {
        'Platform': platform,
        if (courses != null) 'Courses': courses,
        if (title != null) 'Title': title,
        if (url != null) 'URL': url,
      };

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is LearningResource &&
        other.platform == platform &&
        listEquals(other.courses, courses) &&
        other.title == title &&
        other.url == url;
  }

  @override
  int get hashCode =>
      platform.hashCode ^
      (courses?.fold(0, (hash, e) => hash! ^ e.hashCode) ?? 0) ^
      title.hashCode ^
      url.hashCode;
}

/// Represents a job role with its details and learning resources
@immutable
class Job {
  final String roleTitle;
  final List<String> coreSkills;
  final String education;
  final String averageSalary;
  final String jobGrowthOutlook;
  final List<LearningResource> learningResources;

  const Job({
    required this.roleTitle,
    required this.coreSkills,
    required this.education,
    required this.averageSalary,
    required this.jobGrowthOutlook,
    required this.learningResources,
  });

  /// Creates a Job from JSON data
  factory Job.fromJson(Map<String, dynamic> json) {
    return Job(
      roleTitle: (json['Role Title'] as String?) ?? '',
      coreSkills: json['Core Skills'] is List
          ? List<String>.from(json['Core Skills'])
          : const [],
      education: (json['Education'] as String?) ?? '',
      averageSalary: (json['Average Salary Range (LPA)'] as String?) ?? '',
      jobGrowthOutlook:
          (json['Job Growth Outlook (%) (2024)'] as String?) ?? '',
      learningResources: json['Learning Resources'] is List
          ? List<LearningResource>.from((json['Learning Resources'] as List)
              .map((x) => LearningResource.fromJson(x as Map<String, dynamic>)))
          : const [],
    );
  }

  /// Converts the Job to a JSON map
  Map<String, dynamic> toJson() => {
        'Role Title': roleTitle,
        'Core Skills': coreSkills,
        'Education': education,
        'Average Salary Range (LPA)': averageSalary,
        'Job Growth Outlook (%) (2024)': jobGrowthOutlook,
        'Learning Resources': learningResources.map((x) => x.toJson()).toList(),
      };

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Job &&
        other.roleTitle == roleTitle &&
        listEquals(other.coreSkills, coreSkills) &&
        other.education == education &&
        other.averageSalary == averageSalary &&
        other.jobGrowthOutlook == jobGrowthOutlook &&
        listEquals(other.learningResources, learningResources);
  }

  @override
  int get hashCode =>
      roleTitle.hashCode ^
      coreSkills.fold(0, (hash, e) => hash ^ e.hashCode) ^
      education.hashCode ^
      averageSalary.hashCode ^
      jobGrowthOutlook.hashCode ^
      learningResources.fold(0, (hash, e) => hash ^ e.hashCode);
}
