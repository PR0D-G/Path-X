import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class GeminiService {
  static GenerativeModel? _model;

  static GenerativeModel get model {
    if (_model == null) {
      final apiKey = dotenv.env['GEMINI_API_KEY'];
      if (apiKey == null || apiKey.isEmpty || apiKey == 'YOUR_GEMINI_API_KEY_HERE') {
        throw Exception('GEMINI_API_KEY is missing or invalid in .env file. Please add your real key from Google AI Studio.');
      }
      _model = GenerativeModel(
        model: 'gemini-2.5-flash',
        apiKey: apiKey,
      );
    }
    return _model!;
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
      
      // Extract JSON if there's markdown formatting
      final jsonString = text.contains('```json') 
          ? text.split('```json')[1].split('```')[0].trim()
          : text.trim();
          
      return json.decode(jsonString) as Map<String, dynamic>;
    } catch (e) {
      debugPrint('Gemini Error (analyzeResume): $e');
      rethrow;
    }
  }

  /// Generates a professional resume summary or bullet points
  static Future<String> generateResumeContent({
    required String userInput,
    required String targetRole,
    bool isSummary = true,
  }) async {
    final type = isSummary ? 'professional summary' : 'work experience bullet points';
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
      return response.text?.trim() ?? 'Matches your unique profile and career goals.';
    } catch (e) {
      debugPrint('Gemini Error (getRecommendationInsights): $e');
      return 'Great fit for your background and skill set.';
    }
  }
}
