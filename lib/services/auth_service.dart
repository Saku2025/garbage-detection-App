import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  static final SupabaseClient _supabase = Supabase.instance.client;

  static Future<bool> signUp({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      final response = await _supabase.auth.signUp(
        email: email.trim().toLowerCase(),
        password: password,
        data: {'name': name.trim()},
      );

      return response.user != null;
    } on AuthException catch (e) {
      throw Exception(e.message);
    } catch (e) {
      throw Exception('Unable to create account.');
    }
  }

  static Future<bool> signIn({
    required String email,
    required String password,
  }) async {
    try {
      await _supabase.auth.signInWithPassword(
        email: email.trim().toLowerCase(),
        password: password,
      );

      return true;
    } on AuthException catch (e) {
      throw Exception(e.message);
    } catch (e) {
      throw Exception('Unable to sign in.');
    }
  }

  static Future<bool> isLoggedIn() async {
    return _supabase.auth.currentSession != null;
  }

  static Future<Map<String, dynamic>?> getCurrentUser() async {
    final user = _supabase.auth.currentUser;

    if (user == null) {
      return null;
    }

    return {
      'id': user.id,
      'name': user.userMetadata?['name'] ?? '',
      'email': user.email ?? '',
    };
  }

  static Future<void> signOut() async {
    await _supabase.auth.signOut();
  }
}
