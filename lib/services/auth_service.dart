import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/user_profile.dart';
import '../models/user_settings.dart';
import 'supabase_service.dart';

/// Authentication service with user profile management
class AuthService {
  final SupabaseService _supabase = SupabaseService.instance;

  /// Get current user
  User? get currentUser => _supabase.currentUser;

  /// Check if user is signed in
  bool get isSignedIn => _supabase.isSignedIn;

  /// Get current user ID
  String? get currentUserId => _supabase.currentUserId;

  /// Listen to auth state changes
  Stream<AuthState> get authStateChanges => _supabase.authStateChanges;

  // ==================== Sign In Methods ====================

  /// Sign in with email and password
  Future<AuthResult> signInWithEmail(String email, String password) async {
    try {
      final response = await _supabase.signInWithEmail(email, password);

      if (response.user != null) {
        await _ensureUserProfileExists(response.user!);
        return AuthResult.success(response.user!);
      }

      return AuthResult.error('Sign in failed');
    } catch (e) {
      return AuthResult.error(e.toString());
    }
  }

  /// Sign up with email and password
  Future<AuthResult> signUpWithEmail(String email, String password) async {
    try {
      final response = await _supabase.signUpWithEmail(email, password);

      if (response.user != null) {
        await _createUserProfile(response.user!);
        await _createDefaultSettings(response.user!.id);
        return AuthResult.success(response.user!);
      }

      return AuthResult.error('Sign up failed');
    } catch (e) {
      return AuthResult.error(e.toString());
    }
  }

  /// Sign in with Google
  Future<AuthResult> signInWithGoogle() async {
    try {
      final success = await _supabase.signInWithGoogle();

      if (success) {
        // Wait for auth state change to get user
        await Future.delayed(const Duration(seconds: 2));
        final user = _supabase.currentUser;

        if (user != null) {
          await _ensureUserProfileExists(user);
          return AuthResult.success(user);
        }
      }

      return AuthResult.error('Google sign in failed');
    } catch (e) {
      return AuthResult.error(e.toString());
    }
  }

  /// Sign in with Facebook
  Future<AuthResult> signInWithFacebook() async {
    try {
      final success = await _supabase.signInWithFacebook();

      if (success) {
        // Wait for auth state change to get user
        await Future.delayed(const Duration(seconds: 2));
        final user = _supabase.currentUser;

        if (user != null) {
          await _ensureUserProfileExists(user);
          return AuthResult.success(user);
        }
      }

      return AuthResult.error('Facebook sign in failed');
    } catch (e) {
      return AuthResult.error(e.toString());
    }
  }

  /// Sign in anonymously
  Future<AuthResult> signInAnonymously() async {
    try {
      final response = await _supabase.signInAnonymously();

      if (response.user != null) {
        await _createUserProfile(response.user!, isAnonymous: true);
        await _createDefaultSettings(response.user!.id);
        return AuthResult.success(response.user!);
      }

      return AuthResult.error('Anonymous sign in failed');
    } catch (e) {
      return AuthResult.error(e.toString());
    }
  }

  /// Sign out
  Future<void> signOut() async {
    await _supabase.signOut();
  }

  // ==================== User Profile Management ====================

  /// Get user profile
  Future<UserProfile?> getUserProfile() async {
    if (currentUserId == null) return null;

    try {
      final data = await _supabase.getUserProfile(currentUserId!);
      if (data != null) {
        return UserProfile.fromJson(data);
      }
      return null;
    } catch (e) {
      print('Error fetching user profile: $e');
      return null;
    }
  }

  /// Update user profile
  Future<bool> updateUserProfile({String? displayName, String? email}) async {
    if (currentUserId == null) return false;

    try {
      final updates = {
        'id': currentUserId!,
        if (displayName != null) 'display_name': displayName,
        if (email != null) 'email': email,
      };

      await _supabase.upsertUserProfile(updates);
      return true;
    } catch (e) {
      print('Error updating user profile: $e');
      return false;
    }
  }

  /// Create user profile if it doesn't exist
  Future<void> _ensureUserProfileExists(User user) async {
    try {
      final existing = await _supabase.getUserProfile(user.id);

      if (existing == null) {
        await _createUserProfile(user);
        await _createDefaultSettings(user.id);
      }
    } catch (e) {
      print('Error ensuring user profile exists: $e');
    }
  }

  /// Create new user profile
  Future<void> _createUserProfile(User user, {bool isAnonymous = false}) async {
    try {
      final profile = {
        'id': user.id,
        'email': isAnonymous ? null : user.email,
        'display_name': isAnonymous
            ? 'Anonymous User'
            : user.userMetadata?['full_name'] ?? user.email?.split('@')[0],
      };

      await _supabase.upsertUserProfile(profile);
    } catch (e) {
      print('Error creating user profile: $e');
    }
  }

  /// Create default user settings
  Future<void> _createDefaultSettings(String userId) async {
    try {
      final settings = UserSettings(
        userId: userId,
        updateIntervalMinutes: 60, // 1 hour
        autoUpdateEnabled: true,
        locationRadiusKm: 10.0, // 10km
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await _supabase.upsertUserSettings(settings.toInsertJson());
    } catch (e) {
      print('Error creating default settings: $e');
    }
  }

  /// Delete user account
  Future<bool> deleteAccount() async {
    if (currentUserId == null) return false;

    try {
      // Note: This only signs out. Full account deletion requires admin API
      // or you can implement a deletion request system
      await signOut();
      return true;
    } catch (e) {
      print('Error deleting account: $e');
      return false;
    }
  }
}

/// Authentication result wrapper
class AuthResult {
  final bool success;
  final User? user;
  final String? error;

  AuthResult._({required this.success, this.user, this.error});

  factory AuthResult.success(User user) {
    return AuthResult._(success: true, user: user);
  }

  factory AuthResult.error(String message) {
    return AuthResult._(success: false, error: message);
  }
}
