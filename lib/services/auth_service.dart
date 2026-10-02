import 'package:firebase_auth/firebase_auth.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  static final SupabaseClient _supabase = Supabase.instance.client;
  static final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;

  static Future<bool> signUp({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      final cleanEmail = email.trim().toLowerCase();
      final cleanName = name.trim();

      // ----------------------------------------------------------
      // 1. Create Firebase account
      // ----------------------------------------------------------

      final firebaseCredential = await _firebaseAuth
          .createUserWithEmailAndPassword(
            email: cleanEmail,
            password: password,
          );

      // Save user's name in Firebase profile.
      await firebaseCredential.user?.updateDisplayName(cleanName);

      // ----------------------------------------------------------
      // 2. Create Supabase account
      // ----------------------------------------------------------

      final response = await _supabase.auth.signUp(
        email: cleanEmail,
        password: password,
        data: {'name': cleanName},
      );

      if (response.user == null) {
        // If Supabase signup failed after Firebase signup,
        // remove the newly created Firebase account.
        await firebaseCredential.user?.delete();

        throw Exception('Unable to create Supabase account.');
      }

      return true;
    } on FirebaseAuthException catch (e) {
      throw Exception(e.message ?? 'Unable to create Firebase account.');
    } on AuthException catch (e) {
      throw Exception(e.message);
    } catch (e) {
      throw Exception(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  static Future<bool> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final cleanEmail = email.trim().toLowerCase();

      // Sign in to Supabase
      await _supabase.auth.signInWithPassword(
        email: cleanEmail,
        password: password,
      );

      // Sign in to Firebase
      await _firebaseAuth.signInWithEmailAndPassword(
        email: cleanEmail,
        password: password,
      );

      return true;
    } on FirebaseAuthException catch (e) {
      // If Firebase login fails, sign out from Supabase
      await _supabase.auth.signOut();

      throw Exception(e.message ?? 'Unable to sign in to Firebase.');
    } on AuthException catch (e) {
      throw Exception(e.message);
    } catch (e) {
      throw Exception(e.toString().replaceFirst('Exception: ', ''));
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
    await _firebaseAuth.signOut();
  }
}
