import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final supabase = Supabase.instance.client;

class QuestionService {
  static Future<List<Map<String, dynamic>>> fetchQuizQuestions() async {
    List<Map<String, dynamic>> questions = [];

    try {
      debugPrint('Fetching quiz questions in strict order...');
      String tableName = 'questions';

      // Verify table name exists or try fallback
      try {
        await supabase.from(tableName).select().limit(1);
      } catch (e) {
        debugPrint(
            'Notice: "questions" table not found, trying "assessment_questions"...');
        tableName = 'assessment_questions';
      }

      // 1. RIASEC (18 questions total: 3 per category)
      final riasecCategories = [
        'Realistic',
        'Investigative',
        'Artistic',
        'Social',
        'Enterprising',
        'Conventional'
      ];

      try {
        final res = await supabase
            .from(tableName)
            .select()
            .filter('category', 'in', '(${riasecCategories.join(",")})');

        final allRiasec = List<Map<String, dynamic>>.from(res as List);
        for (var category in riasecCategories) {
          final categoryQuestions = allRiasec
              .where((q) => q['category'] == category)
              .toList()
            ..shuffle();
          if (categoryQuestions.isNotEmpty) {
            questions.addAll(categoryQuestions.take(3));
          }
        }
      } catch (e) {
        debugPrint('Notice: Error fetching RIASEC questions: $e');
      }

      // 2. Aptitude (6 questions total: 2 per category)
      final aptitudeCategories = ['Logic', 'Reasoning', 'Pattern'];

      try {
        final res = await supabase
            .from(tableName)
            .select()
            .filter('category', 'in', '(${aptitudeCategories.join(",")})');

        final allAptitude = List<Map<String, dynamic>>.from(res as List);
        for (var cat in aptitudeCategories) {
          final catQuestions = allAptitude
              .where((q) => q['category'] == cat)
              .toList()
            ..shuffle();
          if (catQuestions.isNotEmpty) {
            questions.addAll(catQuestions.take(2));
          }
        }
      } catch (e) {
        debugPrint('Notice: Error fetching Aptitude questions: $e');
      }

      // 3. Quick math (3 questions total)
      try {
        final math = await supabase.from('quick_math').select();
        final mathList = List<Map<String, dynamic>>.from(math as List)
          ..shuffle();
        final selectedMath = mathList.take(3).map((m) {
          m['isMath'] = true;
          return m;
        }).toList();
        questions.addAll(selectedMath);
      } catch (e) {
        debugPrint('Notice: Error for quick_math: $e');
      }

      debugPrint('Order check: RIASEC block first, then Aptitude, then Math.');
      debugPrint('Final count: ${questions.length} / 27');

      if (questions.isEmpty) {
        throw Exception('No questions found. Check your database tables.');
      }

      return questions;
    } catch (e) {
      debugPrint('FATAL: fetchQuizQuestions failed: $e');
      rethrow;
    }
  }
}
