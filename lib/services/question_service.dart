import 'package:supabase_flutter/supabase_flutter.dart';

final supabase = Supabase.instance.client;

class QuestionService {
  static Future<List<Map<String, dynamic>>> fetchQuizQuestions() async {
    List<Map<String, dynamic>> questions = [];

    try {
      print("--- STARTING QUESTION FETCH ---");
      // 1. Connection check
      final test = await supabase.from('questions').select().limit(1);
      print("Supabase connection check successful. First question: $test");

      // RIASEC categories
      final riasecCategories = [
        'Realistic',
        'Investigative',
        'Artistic',
        'Social',
        'Enterprising',
        'Conventional'
      ];

      List<Map<String, dynamic>> riasecQuestions = [];
      for (var category in riasecCategories) {
        final res = await supabase
            .from('questions')
            .select()
            .eq('category', category); // Fetch all to shuffle manually

        final list = List<Map<String, dynamic>>.from(res);
        list.shuffle();
        riasecQuestions.addAll(list.take(3));
      }

      // Shuffle the RIASEC block so categories are mixed
      riasecQuestions.shuffle();
      questions.addAll(riasecQuestions);
      print("Loaded ${riasecQuestions.length} RIASEC questions.");

      // Aptitude (Logic, Reasoning, Pattern)
      List<Map<String, dynamic>> aptitudeQuestions = [];

      // Logic
      final logic =
          await supabase.from('questions').select().eq('category', 'Logic');
      final logicList = List<Map<String, dynamic>>.from(logic)..shuffle();
      aptitudeQuestions.addAll(logicList.take(2));

      // Reasoning
      final reasoning =
          await supabase.from('questions').select().eq('category', 'Reasoning');
      final reasoningList = List<Map<String, dynamic>>.from(reasoning)
        ..shuffle();
      aptitudeQuestions.addAll(reasoningList.take(2));

      // Pattern
      final pattern =
          await supabase.from('questions').select().eq('category', 'Pattern');
      final patternList = List<Map<String, dynamic>>.from(pattern)..shuffle();
      aptitudeQuestions.addAll(patternList.take(2));

      // Shuffle the aptitude block together
      aptitudeQuestions.shuffle();
      questions.addAll(aptitudeQuestions);
      print("Loaded ${aptitudeQuestions.length} Aptitude questions.");

      // Quick math (Appended at the end of the test)
      final math = await supabase.from('quick_math').select();
      final mathList = List<Map<String, dynamic>>.from(math)..shuffle();
      final selectedMath = mathList.take(3).map((m) {
        m['isMath'] = true;
        return m;
      }).toList();

      questions.addAll(selectedMath);
      print("Loaded ${selectedMath.length} Math questions.");

      print("--- TOTAL QUESTIONS LOADED: ${questions.length} ---");
      // The final array consists of Shuffled RIASEC -> Shuffled Aptitude -> Math questions at the very end.
      return questions;
    } catch (e) {
      print("!!! ERROR FETCHING QUESTIONS: $e !!!");
      // Return whatever we have so far, or empty list
      return questions;
    }
  }
}
