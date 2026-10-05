import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  FirebaseAuth? get _auth {
    try {
      return FirebaseAuth.instance;
    } catch (_) {
      return null;
    }
  }

  FirebaseFirestore? get _firestore {
    try {
      return FirebaseFirestore.instance;
    } catch (_) {
      return null;
    }
  }

  // Stream of auth status
  Stream<User?> get authStateChanges {
    final auth = _auth;
    if (auth != null) {
      return auth.authStateChanges();
    }
    return Stream.value(null);
  }

  // Get current user
  User? get currentUser {
    try {
      return _auth?.currentUser;
    } catch (_) {
      return null;
    }
  }

  // Sign In with Email
  Future<UserCredential?> signInWithEmail({
    required String email,
    required String password,
  }) async {
    final auth = _auth;
    if (auth != null) {
      return await auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    }
    return null;
  }

  // Sign Up with Email and save User Profile to Firestore
  Future<UserCredential?> signUpWithEmail({
    required String name,
    required String email,
    required String rollNumber,
    required String password,
  }) async {
    final auth = _auth;
    if (auth != null) {
      final UserCredential credential = await auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final User? user = credential.user;
      final firestore = _firestore;
      if (user != null && firestore != null) {
        try {
          await firestore.collection('users').doc(user.uid).set({
            'uid': user.uid,
            'name': name,
            'email': email,
            'rollNumber': rollNumber,
            'createdAt': FieldValue.serverTimestamp(),
          });
        } catch (_) {}
      }

      return credential;
    }
    return null;
  }

  // Sign Out
  Future<void> signOut() async {
    try {
      await _auth?.signOut();
    } catch (_) {}
  }
}
