import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/material.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load();
  
  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
  );
  
  final supabase = Supabase.instance.client;
  
  try {
    print('--- Checking "careers" table columns ---');
    final careers = await supabase.from('careers').select().limit(1);
    if (careers.isNotEmpty) {
      print('First career data: ${careers.first}');
      print('Keys: ${careers.first.keys.toList()}');
    } else {
      print('No careers found!');
    }
  } catch (e) {
    print('Error: $e');
  }
}
