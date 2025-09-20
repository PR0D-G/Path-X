import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:mongo_dart/mongo_dart.dart';
import 'package:dotenv/dotenv.dart';

// Model class for Job
class Job {
  final String roleTitle;
  final List<String> coreSkills;
  final String education;
  final String averageSalary;
  final String jobGrowthOutlook;
  final List<LearningResource> learningResources;

  Job({
    required this.roleTitle,
    required this.coreSkills,
    required this.education,
    required this.averageSalary,
    required this.jobGrowthOutlook,
    required this.learningResources,
  });

  factory Job.fromJson(Map<String, dynamic> json) {
    return Job(
      roleTitle: json['roleTitle'] ?? '',
      coreSkills: List<String>.from(json['coreSkills'] ?? []),
      education: json['education'] ?? '',
      averageSalary: json['averageSalary'] ?? '',
      jobGrowthOutlook: json['jobGrowthOutlook'] ?? '',
      learningResources: (json['learningResources'] as List?)?.map((e) => LearningResource.fromJson(e)).toList() ?? [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'roleTitle': roleTitle,
      'coreSkills': coreSkills,
      'education': education,
      'averageSalary': averageSalary,
      'jobGrowthOutlook': jobGrowthOutlook,
      'learningResources': learningResources.map((e) => e.toJson()).toList(),
    };
  }
}

class LearningResource {
  final String platform;
  final List<String> courses;

  LearningResource({required this.platform, required this.courses});

  factory LearningResource.fromJson(Map<String, dynamic> json) {
    return LearningResource(
      platform: json['platform'] ?? '',
      courses: List<String>.from(json['courses'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'platform': platform,
      'courses': courses,
    };
  }
}

Future<void> main() async {
  try {
    // Load environment variables
    final env = DotEnv(includePlatformEnvironment: true)..load(['.env']);
    
    // Read the jobs.json file
    // Go up one directory from scripts/ to reach the project root
    final file = File(path.join('..', 'assets', 'data', 'jobs.json'));
    if (!await file.exists()) {
      print('Error: jobs.json file not found at ${file.path}');
      return;
    }

    final jsonString = await file.readAsString();
    final List<dynamic> jsonData = json.decode(jsonString);
    
    // Connect to MongoDB
    final connectionString = 'mongodb://localhost:27017/job';
    print('Connecting to MongoDB at $connectionString...');
    
    Db? db;
    try {
      db = await Db.create(connectionString);
      await db.open();
      print('Successfully connected to MongoDB!');
    } catch (e) {
      print('Error connecting to MongoDB: $e');
      print('Please ensure MongoDB is running and accessible at mongodb://localhost:27017');
      return;
    }
    
    // Get the jobs collection
    final collection = db.collection('jobs');
    
    // Clear existing data (optional)
    print('Clearing existing jobs...');
    await collection.deleteMany({});
    
    // Insert jobs
    print('Inserting ${jsonData.length} jobs...');
    for (var jobJson in jsonData) {
      try {
        final job = Job.fromJson(jobJson);
        await collection.insertOne(job.toJson());
        print('Inserted job: ${job.roleTitle}');
      } catch (e) {
        print('Error inserting job: $e');
      }
    }
    
    // Verify the data was inserted
    final count = await collection.count();
    print('Migration complete. Total jobs in database: $count');
    
    // Close the connection
    await db.close();
  } catch (e) {
    print('Error during migration: $e');
  } finally {
    exit(0);
  }
}
