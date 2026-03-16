import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class GeminiService {
  static GenerativeModel? _model;

  static GenerativeModel get model {
    if (_model == null) {
      final apiKey = dotenv.env['GEMINI_API_KEY'];
      if (apiKey == null ||
          apiKey.isEmpty ||
          apiKey == 'YOUR_GEMINI_API_KEY_HERE') {
        throw Exception(
            'GEMINI_API_KEY is missing or invalid in .env file. Please add your real key from Google AI Studio.');
      }
      _model = GenerativeModel(
        model: 'gemini-1.5-flash-latest',
        apiKey: apiKey,
      );
    }
    return _model!;
  }

  /// Robustly extracts JSON even if the AI includes extra text
  static dynamic _parseJson(String text) {
    try {
      String cleanText = text.trim();
      if (cleanText.contains('```json')) {
        cleanText = cleanText.split('```json')[1].split('```')[0].trim();
      } else if (cleanText.contains('```')) {
        cleanText = cleanText.split('```')[1].split('```')[0].trim();
      }
      return json.decode(cleanText);
    } catch (e) {
      debugPrint('JSON Syntax Error: $e\nOriginal Text: $text');
      // Clean up common AI weirdness like trailing commas
      rethrow;
    }
  }

  /// Analyzes a resume against a job description or target role
  static Future<Map<String, dynamic>> analyzeResume({
    required String resumeText,
    required String targetRole,
    required List<String> requiredSkills,
  }) async {
    final prompt = '''
    Context: You are an expert career advisor and technical recruiter.
    Task: Analyze the following resume against the target role: "$targetRole".
    Required Skills for this role: ${requiredSkills.join(', ')}

    Resume Text:
    $resumeText

    Please provided the analysis in the following JSON format:
    {
      "isValid": (boolean, false if the text is garbage, empty, random words, or clearly not a resume),
      "errorMsg": (string, only if isValid is false, e.g., "Please provide a valid resume"),
      "matchScore": (integer 0-100),
      "foundSkills": [(list of strings)],
      "missingSkills": [(list of strings)],
      "suggestions": [(list of 3-5 strings)],
      "strengths": [(list of 2-3 strings)]
    }
    If isValid is false, the other fields can be empty/zero.
    Return ONLY the JSON.
    ''';

    try {
      final content = [Content.text(prompt)];
      final response = await model.generateContent(content);

      final text = response.text;
      if (text == null) throw Exception('Empty response from Gemini');

      return _parseJson(text) as Map<String, dynamic>;
    } catch (e) {
      debugPrint('Gemini Error (analyzeResume): $e');
      if (e.toString().contains('not found')) {
        debugPrint('TIP: "gemini-1.5-flash" not found. This usually means the API key is not connected to a project with this model enabled.');
      }
      rethrow;
    }
  }

  /// Generates a professional resume summary or bullet points
  static Future<String> generateResumeContent({
    required String userInput,
    required String targetRole,
    bool isSummary = true,
  }) async {
    final type =
        isSummary ? 'professional summary' : 'work experience bullet points';
    final prompt = '''
    Task: Generate a $type for a resume.
    Target Role: $targetRole
    User's Input/Experience: $userInput

    Instructions:
    - Use professional, action-oriented language.
    - Focus on achievements and impact.
    - Keep it concise and tailored to the target role.
    - If it's bullet points, provide 3-4 impactful bullets.
    - If it's a summary, provide a 3-4 sentence paragraph.
    
    Return ONLY the generated content.
    ''';

    try {
      final content = [Content.text(prompt)];
      final response = await model.generateContent(content);
      return response.text?.trim() ?? 'Failed to generate content.';
    } catch (e) {
      debugPrint('Gemini Error (generateResumeContent): $e');
      return 'Error generating content with AI.';
    }
  }

  /// Provides personalized insights for a career recommendation
  static Future<String> getRecommendationInsights({
    required String roleTitle,
    required Map<String, dynamic> userScores,
  }) async {
    final prompt = '''
    Task: Explain why the role "$roleTitle" is a good match for the user based on their assessment results.
    
    User Assessment Results (normalized 0-1):
    $userScores

    Instructions:
    - Be encouraging and insightful.
    - Explain the connection between their strengths and the role's requirements.
    - Keep it to 2-3 concise sentences.
    
    Return ONLY the explanation.
    ''';

    try {
      final content = [Content.text(prompt)];
      final response = await model.generateContent(content);
      return response.text?.trim() ??
          'Great fit for your background and skill set.';
    } catch (e) {
      debugPrint('Gemini Error (getRecommendationInsights): $e');
      return 'Great fit for your background and skill set.';
    }
  }

  /// Validates a certificate against a user's name and extracts skills
  static Future<Map<String, dynamic>> validateCertificate({
    required String userName,
    required Uint8List bytes,
    required String mimeType,
  }) async {
    final prompt = '''
    Context: You are a verification assistant for a career platform.
    Task: Validate the following certificate.
    
    Expected Recipient Name: "$userName"
    
    Please analyze the attached file and provide results in this JSON format:
    {
      "isAuthentic": (boolean, true if it looks like a real certificate and the name matches exactly or very closely),
      "nameOnCertificate": (string, the name you found on the certificate),
      "extractedSkills": [(list of strings, technical or soft skills mentioned in the certificate)],
      "issuingOrganization": (string, name of the institution that issued it),
      "errorMsg": (string, explain why it failed if isAuthentic is false)
    }
    
    Validation Rules:
    1. The name on the certificate MUST match "$userName". Slight variations/middle names are okay.
    2. If the file is not a certificate, isAuthentic should be false.
    
    Return ONLY the JSON.
    ''';

    try {
      final content = [
        Content.multi([
          TextPart(prompt),
          DataPart(mimeType, bytes),
        ])
      ];

      final response = await model.generateContent(content);
      final text = response.text;
      if (text == null) throw Exception('Empty response from Gemini');

      return _parseJson(text) as Map<String, dynamic>;
    } catch (e) {
      debugPrint('Gemini Error (validateCertificate): $e');
      if (e.toString().contains('not found')) {
        debugPrint('TIP: "gemini-1.5-flash-latest" not found. Please ensure:');
        debugPrint('1. Your API key in .env matches the project in your screenshot.');
        debugPrint('2. You are not using a restricted key that blocks this API.');
        debugPrint('3. Try visiting https://aistudio.google.com/ to get a direct API key if GCP settings persist with errors.');
      }
      rethrow;
    }
  }
}
