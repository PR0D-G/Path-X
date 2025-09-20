import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:mongo_dart/mongo_dart.dart';
import 'package:dotenv/dotenv.dart';

// Model classes
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

Future<void> main() async {
  try {
    print('🚀 Starting job migration...');
    
    // Load environment variables
    final env = DotEnv()..load(['.env']);
    
    // Read the jobs.json file
    final file = File(path.join('assets', 'data', 'jobs.json'));
    if (!await file.exists()) {
      print('❌ Error: jobs.json file not found at ${file.path}');
      print('Make sure to run this script from the project root directory');
      return;
    }

    print('📄 Reading jobs data...');
    final jsonString = await file.readAsString();
    final List<dynamic> jsonData = json.decode(jsonString);
    
    // Connect to MongoDB
    final connectionString = env['MONGODB_URI'] ?? 'mongodb://localhost:27017/career_guide';
    
    print('🔌 Connecting to MongoDB at $connectionString...');
    final db = await Db.create(connectionString);
    await db.open();
    
    // Get the jobs collection
    final collection = db.collection('jobs');
    
    // Clear existing data
    print('🧹 Clearing existing jobs...');
    await collection.deleteMany({});
    
    // Insert jobs
    print('📤 Inserting ${jsonData.length} jobs...');
    int successCount = 0;
    for (var jobJson in jsonData) {
      try {
        final job = Job.fromJson(jobJson);
        await collection.insertOne(job.toJson());
        print('  ✅ Inserted job: ${job.roleTitle}');
        successCount++;
      } catch (e) {
        print('  ❌ Error inserting job: $e');
      }
    }
    
    // Verify the data was inserted
    final count = await collection.count();
    print('\n🎉 Migration complete!');
    print('   Total jobs in database: $count');
    print('   Successfully inserted: $successCount/${jsonData.length}');
    
    // Close the connection
    await db.close();
  } catch (e) {
    print('\n❌ Error during migration:');
    print(e);
  } finally {
    exit(0);
  }
}
