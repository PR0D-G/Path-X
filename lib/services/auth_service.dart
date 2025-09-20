import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  // Auth state changes stream
  Stream<User?> get user => _auth.authStateChanges();

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Email & Password Sign In
  Future<UserCredential> signInWithEmail(String email, String password) async {
    return await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password.trim(),
    );
  }

  // Email & Password Sign Up
  Future<UserCredential> signUpWithEmail(String email, String password,
      {String? displayName}) async {
    try {
      // Create the user
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );

      // Ensure displayName is set
      if (displayName != null &&
          displayName.isNotEmpty &&
          userCredential.user != null) {
        await userCredential.user!.updateDisplayName(displayName);
        await userCredential.user!.reload();
      }

      return userCredential;
    } on FirebaseAuthException catch (e) {
      print('Firebase Auth Error (${e.code}): ${e.message}');
      rethrow;
    } catch (e, stackTrace) {
      print('Unexpected error during signup: $e');
      print('Stack trace: $stackTrace');
      rethrow;
    }
  }

  // Google Sign In
  Future<UserCredential> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        throw FirebaseAuthException(
          code: 'google-sign-in-cancelled',
          message: 'Google sign in was cancelled',
        );
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await _auth.signInWithCredential(credential);

      // ✅ Ensure displayName is never null
      if (userCredential.user != null &&
          (userCredential.user!.displayName == null ||
              userCredential.user!.displayName!.isEmpty)) {
        await userCredential.user!.updateDisplayName(googleUser.displayName ??
            userCredential.user!.email?.split('@').first);
        await userCredential.user!.reload();
      }

      return userCredential;
    } on FirebaseAuthException catch (e) {
      print('Google Sign In Error (${e.code}): ${e.message}');
      rethrow;
    } catch (e, stackTrace) {
      print('Unexpected error during Google sign in: $e');
      print('Stack trace: $stackTrace');
      rethrow;
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
    } catch (_) {
      // Ignore if already signed out
    }
    await _auth.signOut();
  }

  // Password reset
  Future<void> sendPasswordResetEmail(String email) async {
    await _auth.sendPasswordResetEmail(email: email.trim());
  }
}
