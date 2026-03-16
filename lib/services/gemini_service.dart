import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class GeminiService {
  static final _client = Supabase.instance.client;

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
      rethrow;
    }
  }

  /// Helper to call the Supabase Edge Function
  static Future<dynamic> _callEdgeFunction(Map<String, dynamic> body) async {
    try {
      final response = await _client.functions.invoke(
        'gemini',
        body: body,
      );

      if (response.status != 200) {
        throw Exception('Edge Function Error: ${response.data}');
      }

      return response.data;
    } catch (e) {
      debugPrint('Supabase Function Error: $e');
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
      final data = await _callEdgeFunction({'prompt': prompt});
      final text = data['response'] as String?;
      if (text == null) throw Exception('Empty response from proxy');

      return _parseJson(text) as Map<String, dynamic>;
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
      final data = await _callEdgeFunction({'prompt': prompt});
      return data['response']?.trim() ?? 'Failed to generate content.';
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
      final data = await _callEdgeFunction({'prompt': prompt});
      return data['response']?.trim() ??
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
      // Use the 'contents' format for multi-part requests (text + file)
      final body = {
        'contents': [
          {
            'parts': [
              {'text': prompt},
              {
                'inline_data': {
                  'mime_type': mimeType,
                  'data': base64Encode(bytes),
                }
              }
            ]
          }
        ]
      };

      final data = await _callEdgeFunction(body);
      
      // If we used 'contents', the proxy returns the full Gemini response
      final text = data['candidates']?[0]?['content']?['parts']?[0]?['text'] as String?;
      if (text == null) throw Exception('Empty response from proxy');

      return _parseJson(text) as Map<String, dynamic>;
    } catch (e) {
      debugPrint('Gemini Error (validateCertificate): $e');
      rethrow;
    }
  }
}

