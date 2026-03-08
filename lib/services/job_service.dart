import '../models/job_model.dart';

class JobService {
  static final List<Job> _cachedJobs = [
    Job(
      roleTitle: 'Software Engineer',
      averageSalary: '\$100,000 - \$150,000',
      education: 'Bachelor\'s in Computer Science or related field',
      jobGrowthOutlook: 'Very High (22% over 10 years)',
      coreSkills: ['Flutter', 'Dart', 'Firebase', 'Git', 'Agile'],
      learningResources: [
        LearningResource(
          title: 'Flutter Official Documentation',
          platform: 'Documentation',
          url: 'https://flutter.dev/docs',
          courses: ['The official guides and API references for Flutter.'],
        ),
      ],
    ),
    Job(
      roleTitle: 'Data Scientist',
      averageSalary: '\$120,000 - \$160,000',
      education: 'Master\'s or Ph.D in Statistics, Math, or Computer Science',
      jobGrowthOutlook: 'High (15% over 10 years)',
      coreSkills: ['Python', 'SQL', 'Machine Learning', 'Data Analysis'],
      learningResources: [
        LearningResource(
          title: 'Intro to Machine Learning',
          platform: 'Course',
          url: 'https://coursera.org',
          courses: ['A comprehensive beginner course to ML.'],
        ),
      ],
    ),
    Job(
      roleTitle: 'UX/UI Designer',
      averageSalary: '\$80,000 - \$130,000',
      education: 'Bachelor\'s in Design, HCI or equivalent bootcamp experience',
      jobGrowthOutlook: 'Good (10% over 10 years)',
      coreSkills: ['Figma', 'Prototyping', 'User Research', 'Wireframing'],
      learningResources: [
        LearningResource(
          title: 'Google UX Design Certificate',
          platform: 'Course',
          url: 'https://coursera.org',
          courses: ['Learn the fundamentals of UX design.'],
        ),
      ],
    ),
  ];

  // Get all jobs (Mocked)
  static Future<List<Job>> getJobs() async {
    return _cachedJobs;
  }

  /// Get a specific job by its title (case-insensitive)
  static Future<Job?> getJobByTitle(String title) async {
    try {
      return _cachedJobs.firstWhere(
        (job) =>
            job.roleTitle.toLowerCase().contains(title.toLowerCase().trim()),
      );
    } catch (e) {
      return null; // Equivalent to orElse returning null
    }
  }

  /// Get learning resources for a specific job
  static Future<List<LearningResource>> getLearningResources(
      String jobTitle) async {
    final job = await getJobByTitle(jobTitle);
    return job?.learningResources ?? [];
  }

  // Add a new job (Mocked)
  static Future<bool> addJob(Job job) async {
    _cachedJobs.add(job);
    return true;
  }

  // Update an existing job (Mocked)
  static Future<bool> updateJob(String title, Job updatedJob) async {
    final index = _cachedJobs.indexWhere((j) => j.roleTitle == title);
    if (index != -1) {
      _cachedJobs[index] = updatedJob;
      return true;
    }
    return false;
  }

  // Delete a job by title (Mocked)
  static Future<bool> deleteJob(String title) async {
    final originalLength = _cachedJobs.length;
    _cachedJobs.removeWhere((j) => j.roleTitle == title);
    return _cachedJobs.length < originalLength;
  }
}
