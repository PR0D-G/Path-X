import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  final GoTrueClient _auth = Supabase.instance.client.auth;

  // Auth state changes stream
  Stream<User?> get user =>
      _auth.onAuthStateChange.map((event) => event.session?.user);

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Email & Password Sign In
  Future<AuthResponse> signInWithEmail(String email, String password) async {
    return await _auth.signInWithPassword(
      email: email.trim(),
      password: password.trim(),
    );
  }

  // Email & Password Sign Up
  Future<AuthResponse> signUpWithEmail(String email, String password,
      {String? displayName}) async {
    try {
      final Map<String, dynamic> data = {};
      if (displayName != null && displayName.isNotEmpty) {
        data['full_name'] = displayName;
        data['display_name'] = displayName;
      }

      final response = await _auth.signUp(
        email: email.trim(),
        password: password.trim(),
        data: data.isEmpty ? null : data,
      );

      return response;
    } on AuthException catch (e) {
      print('Supabase Auth Error: ${e.message}');
      rethrow;
    } catch (e, stackTrace) {
      print('Unexpected error during signup: $e');
      print('Stack trace: $stackTrace');
      rethrow;
    }
  }

  // Google Sign In
  Future<bool> signInWithGoogle() async {
    try {
      return await _auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo:
            'http://localhost:8080', // Replace with your production redirect
      );
    } catch (e) {
      print('Unexpected error during Google sign in: $e');
      rethrow;
    }
  }

  // LinkedIn Sign In
  Future<bool> signInWithLinkedIn() async {
    try {
      return await _auth.signInWithOAuth(
        OAuthProvider.linkedinOidc,
        redirectTo:
            'http://localhost:8080', // Replace with your production redirect
      );
    } catch (e) {
      print('Unexpected error during LinkedIn sign in: $e');
      rethrow;
    }
  }

  // Sign out
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // Password reset
  Future<void> sendPasswordResetEmail(String email) async {
    await _auth.resetPasswordForEmail(email.trim());
  }
}
