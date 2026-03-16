import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/auth_service.dart';
import '../models/user_model.dart';

class AppAuthProvider with ChangeNotifier {
  final AuthService _auth = AuthService();
  final SupabaseClient _supabase = Supabase.instance.client;

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
        await loadUserProfile(user.id);
      } else {
        _userProfile = null;
      }
      notifyListeners();
    });
  }

  // Load user profile from Supabase Database
  Future<void> loadUserProfile(String uid) async {
    try {
      debugPrint('Attempting to load profile for UID: $uid');
      final data =
          await _supabase.from('users').select().eq('id', uid).maybeSingle();

      if (data != null) {
        debugPrint('Profile data found: $data');
        _userProfile = UserProfile.fromMap(data);

        // Fetch assessment results from separate table
        try {
          final assessmentData = await _supabase
              .from('assessment_results')
              .select()
              .eq('user_id', uid)
              .maybeSingle();

          if (assessmentData != null) {
            _userProfile = _userProfile!.copyWith(
              assessmentResults: assessmentData,
            );
          }
        } catch (ae) {
          debugPrint('Notice: Could not load assessment results: $ae');
          // Non-critical, continue with profile only
        }
      } else {
        debugPrint('No profile found for UID: $uid. Creating default.');
        // Create a new profile if missing
        _userProfile = UserProfile(
          uid: uid,
          email: _user?.email,
          displayName: _user?.userMetadata?['display_name'] ??
              _user?.userMetadata?['full_name'] ?? '',
          photoURL: _user?.userMetadata?['avatar_url'],
          skills: [],
        );
        await _saveUserProfile();
      }
    } catch (e) {
      debugPrint('CRITICAL: Error loading user profile: $e');
      // If we hit a network error, we still need a fallback profile for the UI to render
      // but we should probably mark it as "loading failed"
      _userProfile = UserProfile(
        uid: uid,
        email: _user?.email,
        displayName: _user?.userMetadata?['display_name'] ?? '',
        skills: [],
      );
    } finally {
      notifyListeners();
    }
  }

  // Save user profile to Supabase Database
  Future<void> _saveUserProfile() async {
    if (_userProfile == null) return;
    try {
      final map = _userProfile!.toMap();
      // UserProfile.toMap() now matches the Supabase schema (uses 'id', snake_case)
      await _supabase.from('users').upsert(map);
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

  // Select Career Goal
  Future<void> selectCareer(String careerTitle) async {
    if (_userProfile == null) return;
    _userProfile = _userProfile!.copyWith(careerGoal: careerTitle);
    await _saveUserProfile();
    notifyListeners();
  }

  // Clear Career Goal
  Future<void> clearCareerGoal() async {
    if (_userProfile == null) return;
    _userProfile = _userProfile!.copyWith(careerGoal: '');
    await _saveUserProfile();
    notifyListeners();
  }

  // Add skills to profile
  Future<void> addSkills(List<String> newSkills) async {
    if (_userProfile == null) return;
    
    final currentSkills = _userProfile!.skills != null 
        ? List<String>.from(_userProfile!.skills!) 
        : <String>[];
        
    for (var skill in newSkills) {
      if (!currentSkills.contains(skill)) {
        currentSkills.add(skill);
      }
    }
    
    _userProfile = _userProfile!.copyWith(skills: currentSkills);
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

      final authResponse = await _auth.signInWithEmail(email, password);
      _user = authResponse.user;

      if (_user != null) {
        await loadUserProfile(_user!.id);
      }

      return _user;
    } on AuthException catch (e) {
      _error = e.message;
      rethrow;
    } catch (e) {
      _error = e.toString();
      rethrow;
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
        throw AuthException('Email and password cannot be empty');
      }

      final authResponse = await _auth.signUpWithEmail(email, password,
          displayName: displayName);

      if (authResponse.user == null) {
        throw AuthException('Failed to create user account');
      }

      _user = authResponse.user;

      // Only create Supabase profile and fetch if they are immediately signed in
      if (authResponse.session != null) {
        _userProfile = UserProfile(
          uid: _user!.id,
          email: _user!.email,
          displayName: displayName ??
              _user?.userMetadata?['display_name'] ?? '',
          photoURL: _user?.userMetadata?['avatar_url'],
          skills: [],
          hasCompletedQuestionnaire: false,
        );

        await _saveUserProfile();
        await loadUserProfile(_user!.id);
      }

      notifyListeners();
      return _user;
    } on AuthException catch (e) {
      _error = e.message;
      rethrow;
    } catch (e) {
      _error = e.toString();
      rethrow;
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

      await _auth.signInWithGoogle();
      // On web this redirects, so we don't get a user immediately back here.
      // The onAuthStateChange stream handles subsequent logic.
      return _user;
    } on AuthException catch (e) {
      _error = e.message;
      return null;
    } catch (e) {
      _error = e.toString();
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Sign in with LinkedIn
  Future<User?> signInWithLinkedIn() async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      await _auth.signInWithLinkedIn();

      return _user;
    } on AuthException catch (e) {
      _error = e.message;
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
    } on AuthException catch (e) {
      _error = e.message;
      rethrow;
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Update Email
  Future<void> updateEmail(String newEmail) async {
    try {
      _isLoading = true;
      notifyListeners();
      await _auth.updateEmail(newEmail);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Update Password
  Future<void> updatePassword(String newPassword) async {
    try {
      _isLoading = true;
      notifyListeners();
      await _auth.updatePassword(newPassword);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Delete Account
  Future<void> deleteAccount() async {
    try {
      _isLoading = true;
      notifyListeners();
      await _auth.deleteAccount();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Verify Password
  Future<bool> verifyPassword(String password) async {
    if (_user?.email == null) return false;
    return await _auth.verifyPassword(_user!.email!, password);
  }
}
