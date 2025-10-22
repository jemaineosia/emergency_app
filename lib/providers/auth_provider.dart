import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/user_profile.dart';
import '../services/auth_service.dart';

/// Provider for authentication state management
class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();

  User? _currentUser;
  UserProfile? _userProfile;
  bool _isLoading = false;
  String? _error;

  User? get currentUser => _currentUser;
  UserProfile? get userProfile => _userProfile;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isSignedIn => _currentUser != null;
  String? get userId => _currentUser?.id;

  AuthProvider() {
    _init();
  }

  /// Initialize auth provider
  void _init() {
    _currentUser = _authService.currentUser;

    // Listen to auth state changes
    _authService.authStateChanges.listen((AuthState state) {
      _currentUser = state.session?.user;

      if (_currentUser != null) {
        _loadUserProfile();
      } else {
        _userProfile = null;
      }

      notifyListeners();
    });

    // Load initial profile if signed in
    if (_currentUser != null) {
      _loadUserProfile();
    }
  }

  /// Load user profile
  Future<void> _loadUserProfile() async {
    try {
      _userProfile = await _authService.getUserProfile();
      notifyListeners();
    } catch (e) {
      print('Error loading user profile: $e');
    }
  }

  /// Sign in with email and password
  Future<bool> signInWithEmail(String email, String password) async {
    _setLoading(true);
    _clearError();

    final result = await _authService.signInWithEmail(email, password);

    _setLoading(false);

    if (result.success) {
      _currentUser = result.user;
      await _loadUserProfile();
      return true;
    } else {
      _setError(result.error ?? 'Sign in failed');
      return false;
    }
  }

  /// Sign up with email and password
  Future<bool> signUpWithEmail(String email, String password) async {
    _setLoading(true);
    _clearError();

    final result = await _authService.signUpWithEmail(email, password);

    _setLoading(false);

    if (result.success) {
      _currentUser = result.user;
      await _loadUserProfile();
      return true;
    } else {
      _setError(result.error ?? 'Sign up failed');
      return false;
    }
  }

  /// Sign in with Google
  Future<bool> signInWithGoogle() async {
    _setLoading(true);
    _clearError();

    final result = await _authService.signInWithGoogle();

    _setLoading(false);

    if (result.success) {
      _currentUser = result.user;
      await _loadUserProfile();
      return true;
    } else {
      _setError(result.error ?? 'Google sign in failed');
      return false;
    }
  }

  /// Sign in with Facebook
  Future<bool> signInWithFacebook() async {
    _setLoading(true);
    _clearError();

    final result = await _authService.signInWithFacebook();

    _setLoading(false);

    if (result.success) {
      _currentUser = result.user;
      await _loadUserProfile();
      return true;
    } else {
      _setError(result.error ?? 'Facebook sign in failed');
      return false;
    }
  }

  /// Sign in anonymously
  Future<bool> signInAnonymously() async {
    _setLoading(true);
    _clearError();

    final result = await _authService.signInAnonymously();

    _setLoading(false);

    if (result.success) {
      _currentUser = result.user;
      await _loadUserProfile();
      return true;
    } else {
      _setError(result.error ?? 'Anonymous sign in failed');
      return false;
    }
  }

  /// Sign out
  Future<void> signOut() async {
    _setLoading(true);

    await _authService.signOut();
    _currentUser = null;
    _userProfile = null;

    _setLoading(false);
  }

  /// Update user profile
  Future<bool> updateProfile({String? displayName, String? email}) async {
    _setLoading(true);
    _clearError();

    final success = await _authService.updateUserProfile(
      displayName: displayName,
      email: email,
    );

    if (success) {
      await _loadUserProfile();
    } else {
      _setError('Failed to update profile');
    }

    _setLoading(false);
    return success;
  }

  /// Delete account
  Future<bool> deleteAccount() async {
    _setLoading(true);
    _clearError();

    final success = await _authService.deleteAccount();

    if (success) {
      _currentUser = null;
      _userProfile = null;
    } else {
      _setError('Failed to delete account');
    }

    _setLoading(false);
    return success;
  }

  /// Reload user profile
  Future<void> reloadProfile() async {
    await _loadUserProfile();
  }

  // Helper methods
  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setError(String message) {
    _error = message;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
    notifyListeners();
  }
}
