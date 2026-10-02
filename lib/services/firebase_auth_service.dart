import 'package:firebase_auth/firebase_auth.dart';

class FirebaseAuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  // ------------------------------------------------------------
  // CREATE ACCOUNT
  // ------------------------------------------------------------

  static Future<UserCredential> signUp({
    required String name,
    required String email,
    required String password,
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email.trim().toLowerCase(),
      password: password,
    );

    // Save user's name in Firebase Auth profile.
    await credential.user?.updateDisplayName(name.trim());

    return credential;
  }

  // ------------------------------------------------------------
  // SIGN IN
  // ------------------------------------------------------------

  static Future<UserCredential> signIn({
    required String email,
    required String password,
  }) async {
    return await _auth.signInWithEmailAndPassword(
      email: email.trim().toLowerCase(),
      password: password,
    );
  }

  // ------------------------------------------------------------
  // CURRENT USER
  // ------------------------------------------------------------

  static User? get currentUser => _auth.currentUser;

  // ------------------------------------------------------------
  // SIGN OUT
  // ------------------------------------------------------------

  static Future<void> signOut() async {
    await _auth.signOut();
  }
}
