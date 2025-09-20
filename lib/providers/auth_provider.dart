import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/auth_service.dart';
import '../models/user_model.dart';

class AppAuthProvider with ChangeNotifier {
  final AuthService _auth = AuthService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  User? _user;
  UserProfile? _userProfile;
  bool _isLoading = false;
  String? _error;

  // Getters
  User? get user => _user;
  UserProfile? get userProfile => _userProfile;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _user != null;
  bool get shouldShowQuestionnaire =>
      _user != null &&
      (_userProfile == null ||
          _userProfile!.hasCompletedQuestionnaire == false);

  // Get user skills with null safety
  List<String> get userSkills => _userProfile?.skills ?? [];

  // Constructor
  AppAuthProvider() {
    _init();
  }

  // Initialize auth state listener
  void _init() {
    _auth.user.listen((user) async {
      _user = user;
      if (user != null) {
        await loadUserProfile(user.uid);
      } else {
        _userProfile = null;
      }
      notifyListeners();
    });
  }

  // Load user profile from Firestore
  Future<void> loadUserProfile(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        final data = Map<String, dynamic>.from(doc.data()!);
        data['uid'] = uid;
        _userProfile = UserProfile.fromMap(data);
      } else {
        // Create a new profile if missing
        _userProfile = UserProfile(
          uid: uid,
          email: _user?.email,
          displayName: _user?.displayName ?? _user?.email?.split('@').first,
          photoURL: _user?.photoURL,
          skills: [],
        );
        await _saveUserProfile();
      }
    } catch (e) {
      debugPrint('Error loading user profile: $e');
      _userProfile = UserProfile(
        uid: uid,
        email: _user?.email,
        displayName: _user?.displayName ?? _user?.email?.split('@').first,
        photoURL: _user?.photoURL,
        skills: [],
      );
    }
  }

  // Save user profile to Firestore
  Future<void> _saveUserProfile() async {
    if (_userProfile == null) return;
    try {
      await _firestore
          .collection('users')
          .doc(_userProfile!.uid)
          .set(_userProfile!.toMap());
    } catch (e) {
      debugPrint('Error saving user profile: $e');
      rethrow;
    }
  }

  // Update and save user profile
  Future<void> updateUserProfile(UserProfile updatedProfile) async {
    _userProfile = updatedProfile;
    await _saveUserProfile();
    notifyListeners();
  }

  // Dispose
  @override
  void dispose() {
    super.dispose();
  }

  // Sign in with email and password
  Future<User?> signInWithEmail(String email, String password) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final userCredential = await _auth.signInWithEmail(email, password);
      _user = userCredential.user;

      if (_user != null) {
        await loadUserProfile(_user!.uid);
      }

      return _user;
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'user-not-found':
          _error = 'No user found with this email.';
          break;
        case 'wrong-password':
          _error = 'Incorrect password.';
          break;
        default:
          _error = e.message ?? 'An error occurred during sign in.';
      }
      return null;
    } catch (e) {
      _error = e.toString();
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Register with email and password
  Future<User?> signUpWithEmail(String email, String password,
      {String? displayName}) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      if (email.isEmpty || password.isEmpty) {
        throw FirebaseAuthException(
          code: 'invalid-email-or-password',
          message: 'Email and password cannot be empty',
        );
      }

      final userCredential = await _auth.signUpWithEmail(email, password,
          displayName: displayName);

      if (userCredential.user == null) {
        throw FirebaseAuthException(
          code: 'user-creation-failed',
          message: 'Failed to create user account',
        );
      }

      _user = userCredential.user;

      // ✅ Ensure FirebaseAuth user has a displayName
      if (displayName != null && displayName.isNotEmpty) {
        await _user!.updateDisplayName(displayName);
        await _user!.reload();
        _user = FirebaseAuth.instance.currentUser;
      }

      // Create Firestore profile
      _userProfile = UserProfile(
        uid: _user!.uid,
        email: _user!.email,
        displayName:
            _user!.displayName ?? displayName ?? _user!.email?.split('@').first,
        photoURL: _user!.photoURL,
        skills: [],
        hasCompletedQuestionnaire: false,
      );

      await _saveUserProfile();

      await loadUserProfile(_user!.uid);

      notifyListeners();
      return _user;
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'email-already-in-use':
          _error = 'An account already exists with this email.';
          break;
        case 'invalid-email':
          _error = 'The email address is not valid.';
          break;
        case 'weak-password':
          _error = 'The password is too weak.';
          break;
        default:
          _error = e.message ?? 'An error occurred during registration.';
      }
      return null;
    } catch (e) {
      _error = e.toString();
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Sign in with Google
  Future<User?> signInWithGoogle() async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final userCredential = await _auth.signInWithGoogle();
      _user = userCredential.user;

      if (_user != null) {
        await loadUserProfile(_user!.uid);
      }

      return _user;
    } on FirebaseAuthException catch (e) {
      _error = e.message ?? 'An error occurred during Google sign in.';
      return null;
    } catch (e) {
      _error = e.toString();
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      await _auth.signOut();
      _user = null;
      _userProfile = null;
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Reset password
  Future<void> resetPassword(String email) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      await _auth.sendPasswordResetEmail(email);
    } on FirebaseAuthException catch (e) {
      _error = e.message ?? 'Failed to send password reset email.';
      rethrow;
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
