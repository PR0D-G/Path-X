import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/auth_service.dart';
import '../models/user_model.dart';
import '../services/user_service.dart';

class AppAuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();
  final UserService _userService = UserService();

  User? _user;
  UserProfile? _userProfile;
  bool _isLoading = false;
  String? _error;
  StreamSubscription<UserProfile>? _profileSubscription;

  // Getters
  User? get user => _user;
  UserProfile? get userProfile => _userProfile;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _user != null;

  // 👇 Used to decide navigation
  bool get shouldShowQuestionnaire =>
      isAuthenticated &&
      _userProfile != null &&
      !_userProfile!.hasCompletedQuestionnaire;

  // Constructor
  AppAuthProvider() {
    _init();
  }

  // Listen to auth state
  void _init() {
    _authService.user.listen((firebaseUser) async {
      _user = firebaseUser;
      if (firebaseUser != null) {
        await _loadUserProfile(firebaseUser.uid);
      } else {
        _userProfile = null;
      }
      notifyListeners();
    });
  }

  // Dispose subscription properly
  @override
  void dispose() {
    _profileSubscription?.cancel();
    super.dispose();
  }

  // Load Firestore profile with real-time updates
  Future<void> _loadUserProfile(String userId) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      // Cancel previous subscription if exists
      await _profileSubscription?.cancel();

      _profileSubscription = _userService.getUserProfile(userId).listen(
        (UserProfile profile) {
          _userProfile = profile;
          _isLoading = false;
          _error = null;
          notifyListeners();
        },
        onError: (Object error) {
          _error = 'Failed to load user profile: $error';
          _isLoading = false;
          _userProfile = null;
          notifyListeners();
        },
      );
    } catch (e) {
      _error = 'Error setting up profile listener: $e';
      _isLoading = false;
      _userProfile = null;
      notifyListeners();
    }
  }

  // Create profile only if it doesn't exist
  Future<void> _updateProfileAfterSignIn(UserCredential userCredential) async {
    final user = userCredential.user;
    if (user == null) return;

    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();
    if (doc.exists) return; // ✅ Don’t overwrite

    final userProfile = UserProfile(
      uid: user.uid,
      email: user.email,
      displayName: user.displayName,
      photoURL: user.photoURL,
      hasCompletedQuestionnaire: false,
    );
    await _userService.updateUserProfile(userProfile);
  }

  // Mark questionnaire complete
  Future<void> completeQuestionnaire() async {
    if (_user == null || _userProfile == null) return;

    try {
      _isLoading = true;
      notifyListeners();

      final updated = _userProfile!.copyWith(hasCompletedQuestionnaire: true);
      await _userService.updateUserProfile(updated);
      _userProfile = updated;
    } catch (e) {
      _error = 'Failed to complete questionnaire: $e';
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // 🔹 Email/Password login
  Future<User?> signInWithEmailAndPassword(
      String email, String password) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final credential =
          await _authService.signInWithEmailAndPassword(email, password);

      if (credential != null) {
        await _updateProfileAfterSignIn(credential);
      }
      return credential?.user;
    } catch (e) {
      _error = e.toString();
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // 🔹 Email/Password register
  Future<User?> registerWithEmailAndPassword(
      String email, String password, String displayName) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final credential =
          await _authService.registerWithEmailAndPassword(email, password);

      if (credential?.user != null) {
        final user = credential!.user!;
        await user.updateDisplayName(displayName);
        await user.reload(); // ✅ Refresh user profile
        await _updateProfileAfterSignIn(credential);
      }
      return credential?.user;
    } catch (e) {
      _error = e.toString();
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // 🔹 Google Sign-In
  Future<User?> signInWithGoogle() async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final credential = await _authService.signInWithGoogle();
      if (credential != null) {
        await _updateProfileAfterSignIn(credential);
      }
      return credential?.user;
    } catch (e) {
      _error = e.toString();
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // 🔹 Sign out
  Future<void> signOut() async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      await _authService.signOut();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // 🔹 Reset password
  Future<void> resetPassword(String email) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      await _authService.resetPassword(email);
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // 🔹 Update profile
  Future<void> updateUserProfile(UserProfile updatedProfile) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      await _userService.updateUserProfile(updatedProfile);
      _userProfile = updatedProfile;
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
