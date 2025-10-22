import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/constants/supabase_config.dart';

/// Centralized Supabase service for database operations
class SupabaseService {
  static SupabaseService? _instance;
  static SupabaseClient? _client;

  SupabaseService._();

  /// Singleton instance
  static SupabaseService get instance {
    _instance ??= SupabaseService._();
    return _instance!;
  }

  /// Initialize Supabase
  static Future<void> initialize() async {
    await Supabase.initialize(
      url: SupabaseConfig.supabaseUrl,
      anonKey: SupabaseConfig.supabaseAnonKey,
    );
    _client = Supabase.instance.client;
  }

  /// Get Supabase client
  SupabaseClient get client {
    if (_client == null) {
      throw Exception(
        'Supabase not initialized. Call SupabaseService.initialize() first.',
      );
    }
    return _client!;
  }

  /// Get current user
  User? get currentUser => client.auth.currentUser;

  /// Check if user is signed in
  bool get isSignedIn => currentUser != null;

  /// Get current user ID
  String? get currentUserId => currentUser?.id;

  // ==================== Authentication ====================

  /// Sign in with email and password
  Future<AuthResponse> signInWithEmail(String email, String password) async {
    return await client.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  /// Sign up with email and password
  Future<AuthResponse> signUpWithEmail(String email, String password) async {
    return await client.auth.signUp(email: email, password: password);
  }

  /// Sign in with Google
  Future<bool> signInWithGoogle() async {
    return await client.auth.signInWithOAuth(
      OAuthProvider.google,
      redirectTo: '${SupabaseConfig.deepLinkScheme}://login-callback',
    );
  }

  /// Sign in with Facebook
  Future<bool> signInWithFacebook() async {
    return await client.auth.signInWithOAuth(
      OAuthProvider.facebook,
      redirectTo: '${SupabaseConfig.deepLinkScheme}://login-callback',
    );
  }

  /// Sign in anonymously
  Future<AuthResponse> signInAnonymously() async {
    return await client.auth.signInAnonymously();
  }

  /// Sign out
  Future<void> signOut() async {
    await client.auth.signOut();
  }

  /// Listen to auth state changes
  Stream<AuthState> get authStateChanges => client.auth.onAuthStateChange;

  // ==================== User Profile ====================

  /// Get user profile
  Future<Map<String, dynamic>?> getUserProfile(String userId) async {
    final response = await client
        .from('users')
        .select()
        .eq('id', userId)
        .maybeSingle();
    return response;
  }

  /// Create or update user profile
  Future<void> upsertUserProfile(Map<String, dynamic> profile) async {
    await client.from('users').upsert(profile);
  }

  // ==================== Emergency Contacts ====================

  /// Get all contacts for current user
  Future<List<Map<String, dynamic>>> getEmergencyContacts() async {
    if (currentUserId == null) throw Exception('User not signed in');

    final response = await client
        .from('emergency_contacts')
        .select()
        .eq('user_id', currentUserId!)
        .eq('is_active', true)
        .order('contact_type');

    return List<Map<String, dynamic>>.from(response);
  }

  /// Get AI-generated contacts (POLICE, HOSPITAL, FIRE_STATION)
  Future<List<Map<String, dynamic>>> getAiGeneratedContacts() async {
    if (currentUserId == null) throw Exception('User not signed in');

    final response = await client
        .from('emergency_contacts')
        .select()
        .eq('user_id', currentUserId!)
        .eq('is_ai_generated', true)
        .eq('is_active', true)
        .order('contact_type');

    return List<Map<String, dynamic>>.from(response);
  }

  /// Get custom user contacts
  Future<List<Map<String, dynamic>>> getCustomContacts() async {
    if (currentUserId == null) throw Exception('User not signed in');

    final response = await client
        .from('emergency_contacts')
        .select()
        .eq('user_id', currentUserId!)
        .eq('is_ai_generated', false)
        .eq('is_active', true)
        .order('created_at', ascending: false);

    return List<Map<String, dynamic>>.from(response);
  }

  /// Create emergency contact
  Future<Map<String, dynamic>> createEmergencyContact(
    Map<String, dynamic> contact,
  ) async {
    if (currentUserId == null) throw Exception('User not signed in');

    contact['user_id'] = currentUserId;
    final response = await client
        .from('emergency_contacts')
        .insert(contact)
        .select()
        .single();

    return response;
  }

  /// Update emergency contact
  Future<Map<String, dynamic>> updateEmergencyContact(
    String contactId,
    Map<String, dynamic> updates,
  ) async {
    final response = await client
        .from('emergency_contacts')
        .update(updates)
        .eq('id', contactId)
        .select()
        .single();

    return response;
  }

  /// Delete emergency contact (soft delete)
  Future<void> deleteEmergencyContact(String contactId) async {
    await client
        .from('emergency_contacts')
        .update({'is_active': false})
        .eq('id', contactId);
  }

  /// Hard delete emergency contact
  Future<void> hardDeleteEmergencyContact(String contactId) async {
    await client.from('emergency_contacts').delete().eq('id', contactId);
  }

  /// Upsert emergency contact (create or update based on contact type)
  Future<Map<String, dynamic>> upsertEmergencyContact(
    Map<String, dynamic> contact,
  ) async {
    if (currentUserId == null) throw Exception('User not signed in');

    contact['user_id'] = currentUserId;

    // Check if contact already exists for this user and contact type
    final existingContacts = await client
        .from('emergency_contacts')
        .select()
        .eq('user_id', currentUserId!)
        .eq('contact_type', contact['contact_type'])
        .eq('is_ai_generated', contact['is_ai_generated'] ?? true);

    if (existingContacts.isNotEmpty) {
      // Update existing contact
      final existingId = existingContacts.first['id'];
      final response = await client
          .from('emergency_contacts')
          .update(contact)
          .eq('id', existingId)
          .select()
          .single();
      return response;
    } else {
      // Create new contact
      final response = await client
          .from('emergency_contacts')
          .insert(contact)
          .select()
          .single();
      return response;
    }
  }

  // ==================== User Settings ====================

  /// Get user settings
  Future<Map<String, dynamic>?> getUserSettings() async {
    if (currentUserId == null) throw Exception('User not signed in');

    final response = await client
        .from('user_settings')
        .select()
        .eq('user_id', currentUserId!)
        .maybeSingle();

    return response;
  }

  /// Create or update user settings
  Future<Map<String, dynamic>> upsertUserSettings(
    Map<String, dynamic> settings,
  ) async {
    if (currentUserId == null) throw Exception('User not signed in');

    settings['user_id'] = currentUserId;
    final response = await client
        .from('user_settings')
        .upsert(settings)
        .select()
        .single();

    return response;
  }

  // ==================== Update History ====================

  /// Create update history entry
  Future<void> createUpdateHistory(Map<String, dynamic> history) async {
    if (currentUserId == null) throw Exception('User not signed in');

    history['user_id'] = currentUserId;
    await client.from('update_history').insert(history);
  }

  /// Get update history
  Future<List<Map<String, dynamic>>> getUpdateHistory({int limit = 50}) async {
    if (currentUserId == null) throw Exception('User not signed in');

    final response = await client
        .from('update_history')
        .select()
        .eq('user_id', currentUserId!)
        .order('created_at', ascending: false)
        .limit(limit);

    return List<Map<String, dynamic>>.from(response);
  }
}
