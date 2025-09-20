import 'package:mongo_dart/mongo_dart.dart';
import '../models/job_model.dart';
import 'mongo_db_service.dart';

class JobService {
  static final MongoDBService _mongoDBService = MongoDBService();
  static bool _isInitialized = false;
  static final List<Job> _cachedJobs = [];

  // Initialize the service and connect to MongoDB
  static Future<void> _initialize() async {
    if (!_isInitialized) {
      await _mongoDBService.connect();
      _isInitialized = true;
    }
  }

  // Get all jobs from MongoDB
  static Future<List<Job>> getJobs() async {
    if (_cachedJobs.isNotEmpty) {
      return _cachedJobs;
    }

    try {
      await _initialize();
      final collection = _mongoDBService.collection('jobs');
      
      final jobsData = await collection.find().toList();
      
      _cachedJobs.clear();
      for (var jobData in jobsData) {
        try {
          _cachedJobs.add(Job.fromJson(jobData));
        } catch (e) {
          print('Error parsing job data: $e');
        }
      }
      
      return _cachedJobs;
    } catch (e) {
      print('Error loading jobs from MongoDB: $e');
      return [];
    }
  }

  /// Get a specific job by its title (case-insensitive)
  /// Returns null if no job is found
  static Future<Job?> getJobByTitle(String title) async {
    try {
      await _initialize();
      final collection = _mongoDBService.collection('jobs');
      
      final jobData = await collection.findOne({
        'roleTitle': {'\$regex': '^${title.trim()}\\b', 'options': 'i'}
      });
      
      return jobData != null ? Job.fromJson(jobData) : null;
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

  // Add a new job to the database
  static Future<bool> addJob(Job job) async {
    try {
      await _initialize();
      final collection = _mongoDBService.collection('jobs');
      
      await collection.insertOne(job.toJson());
      _cachedJobs.add(job); // Update cache
      
      return true;
    } catch (e) {
      print('Error adding job: $e');
      return false;
    }
  }

  // Update an existing job
  static Future<bool> updateJob(String title, Job updatedJob) async {
    try {
      await _initialize();
      final collection = _mongoDBService.collection('jobs');
      
      final result = await collection.updateOne(
        where.eq('roleTitle', title),
        {
          '\$set': updatedJob.toJson(),
        },
      );
      
      // Update cache if needed
      if (result.isSuccess && _cachedJobs.isNotEmpty) {
        final index = _cachedJobs.indexWhere((j) => j.roleTitle == title);
        if (index != -1) {
          _cachedJobs[index] = updatedJob;
        }
      }
      
      return result.isSuccess;
    } catch (e) {
      print('Error updating job: $e');
      return false;
    }
  }

  // Delete a job by title
  static Future<bool> deleteJob(String title) async {
    try {
      await _initialize();
      final collection = _mongoDBService.collection('jobs');
      
      final result = await collection.deleteOne(where.eq('roleTitle', title));
      
      // Update cache if needed
      if (result.isSuccess && _cachedJobs.isNotEmpty) {
        _cachedJobs.removeWhere((j) => j.roleTitle == title);
      }
      
      return result.isSuccess;
    } catch (e) {
      print('Error deleting job: $e');
      return false;
    }
  }
}
