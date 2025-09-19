import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/job_model.dart';

class JobService {
  static const String _jobsAssetPath = 'assets/data/jobs.json';
  static List<Job> _cachedJobs = [];

  static Future<List<Job>> getJobs() async {
    if (_cachedJobs.isNotEmpty) {
      return _cachedJobs;
    }

    try {
      // Load jobs from local JSON file
      final String response = await rootBundle.loadString(_jobsAssetPath);
      final List<dynamic> data = json.decode(response);
      
      // Convert JSON data to Job objects
      _cachedJobs = data.map((json) => Job.fromJson(json)).toList();
      return _cachedJobs;
    } catch (e) {
      print('Error loading jobs from JSON: $e');
      // Fallback to sample data if there's an error
      return _getSampleJobs();
    }
  }

  /// Get a specific job by its title (case-insensitive)
  /// Returns null if no job is found
  static Future<Job?> getJobByTitle(String title) async {
    try {
      final jobs = await getJobs();
      return jobs.firstWhere(
        (job) => job.roleTitle.toLowerCase() == title.trim().toLowerCase(),
      );
    } on StateError {
      // No job found with the given title
      return null;
    } catch (e) {
      print('Error finding job "$title": $e');
      return null;
    }
  }

  /// Get learning resources for a specific job
  /// Returns empty list if job is not found or has no resources
  static Future<List<LearningResource>> getLearningResources(String jobTitle) async {
    try {
      final job = await getJobByTitle(jobTitle);
      return job?.learningResources ?? [];
    } catch (e) {
      print('Error getting learning resources for "$jobTitle": $e');
      return [];
    }
  }

  // Fallback sample data in case JSON loading fails
  static List<Job> _getSampleJobs() {
    return [
      Job(
        roleTitle: 'System Engineer',
        coreSkills: ['Linux/UNIX', 'Networking', 'Scripting (Python)', 'Cloud (AWS)'],
        education: "Bachelor's",
        averageSalary: '4 - 25+ LPA',
        jobGrowthOutlook: '15%',
        learningResources: [
          LearningResource(
            platform: 'Coursera',
            courses: [
              'AWS Cloud Technical Essentials',
              'AWS Cloud Solutions Architect',
            ],
          ),
        ],
      ),
      Job(
        roleTitle: 'Cloud Engineer',
        coreSkills: ['AWS/Azure/GCP', 'Kubernetes', 'Docker', 'Terraform'],
        education: "Bachelor's",
        averageSalary: '6 - 40+ LPA',
        jobGrowthOutlook: '11.30%',
        learningResources: [
          LearningResource(
            platform: 'Coursera',
            courses: [
              'AWS Cloud Technology Consultant',
              'Getting Started with Data Analytics on AWS',
            ],
          ),
        ],
      ),
    ];
  }
}
