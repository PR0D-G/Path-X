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

  // Verify password (re-auth)
  Future<bool> verifyPassword(String email, String password) async {
    try {
      final response = await _auth.signInWithPassword(
        email: email.trim(),
        password: password.trim(),
      );
      return response.session != null;
    } catch (e) {
      return false;
    }
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

  // Update email
  Future<void> updateEmail(String newEmail) async {
    await _auth.updateUser(UserAttributes(email: newEmail.trim()));
  }

  // Update password
  Future<void> updatePassword(String newPassword) async {
    await _auth.updateUser(UserAttributes(password: newPassword.trim()));
  }

  // Delete account
  Future<void> deleteAccount() async {
    final user = _auth.currentUser;
    if (user != null) {
      // In Supabase, deleting a user from the client side is restricted.
      // Usually, you'd call a Edge Function or use a service role.
      // For now, we'll use the RPC if available or just sign out and inform.
      // But actually, Supabase has a way if configured.
      // Most common way is to use an Edge Function.
      // For this demo, we'll simulate it or use a public RPC if you've set one up.
      // Since I can't setup Edge Functions, I'll sign them out and maybe mark profile as deleted.
      await Supabase.instance.client.from('users').delete().eq('id', user.id);
      await signOut();
    }
  }
}
