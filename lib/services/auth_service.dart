import 'package:firebase_auth/firebase_auth.dart' as fb;
import '../models/user_model.dart';
import 'mongodb_service.dart';

// Re-export AuthResult and UserModel for callers of AuthService
export 'mongodb_service.dart' show AuthResult;
export '../models/user_model.dart' show UserModel;

/// Backward compatibility class for any legacy references
class LocalUser {
  final String name;
  final String email;
  final String phone;
  final String rollNumber;
  final String password;
  final String role;

  LocalUser({
    required this.name,
    required this.email,
    required this.phone,
    required this.rollNumber,
    required this.password,
    required this.role,
  });

  UserModel toUserModel() {
    return UserModel(
      name: name,
      email: email,
      phone: phone,
      rollNumber: rollNumber,
      passwordHash: UserModel.hashPassword(password),
      role: role,
    );
  }
}

/// Authentication service backed by MongoDB collections ('faculty', 'students', 'visitors')
/// instead of Firestore.
class AuthService {
  final MongoDbService _mongoService = MongoDbService.instance;

  fb.FirebaseAuth? get _auth {
    try {
      return fb.FirebaseAuth.instance;
    } catch (_) {
      return null;
    }
  }

  // Stream of auth status
  Stream<fb.User?> get authStateChanges {
    final auth = _auth;
    if (auth != null) {
      return auth.authStateChanges();
    }
    return Stream.value(null);
  }

  static UserModel? _currentUser;
  static String? _authToken;

  static UserModel? get currentUser => _currentUser;
  static String? get authToken => _authToken;
  static String get effectiveToken {
    if (_authToken != null && _authToken!.isNotEmpty) return _authToken!;
    if (_currentUser != null) return 'dev-token-${_currentUser!.id}';
    return 'dev-token-seed-student-001';
  }
  static String get currentRole => _currentUser?.role ?? 'Student';
  static bool get isStudent => currentRole.toLowerCase() == 'student';
  static bool get isFaculty => currentRole.toLowerCase() == 'faculty';
  static bool get isVisitor => currentRole.toLowerCase() == 'visitor';

  static void setCurrentUser(UserModel? user, [String? token]) {
    _currentUser = user;
    _authToken = token ?? (user != null ? 'dev-token-${user.id}' : null);
  }

  fb.User? get firebaseUser {
    try {
      return _auth?.currentUser;
    } catch (_) {
      return null;
    }
  }

  /// Sign In with Email or Phone Number and verify role-specific credentials against MongoDB.
  /// Enforces role domain validation:
  /// - Visitor -> @gmail.com (searches in 'visitors' table)
  /// - Student -> @cb.students.amrita.edu (searches in 'students' table)
  /// - Faculty -> @cb.amrita.edu (searches in 'faculty' table)
  Future<AuthResult> signInUser({
    required String identity,
    required String password,
    required String role,
  }) async {
    // Authenticate through MongoDB service with strict role-partitioned table validation
    final result = await _mongoService.authenticateUser(
      identity: identity,
      password: password,
      role: role,
    );

    // If MongoDB authentication succeeds, synchronize Firebase Auth session if active
    if (result.success && identity.contains('@')) {
      final auth = _auth;
      if (auth != null) {
        try {
          await auth.signInWithEmailAndPassword(
            email: identity.trim().toLowerCase(),
            password: password,
          );
        } catch (_) {
          // Firebase Auth sync is optional; MongoDB is primary authority
        }
      }
    }

    if (result.success && result.user != null) {
      setCurrentUser(result.user, result.token);
    }

    return result;
  }

  /// Sign Up user with Name, Email, Phone, Roll Number, Password, Role.
  /// Following domain and input validation, categorizes users into role-specific
  /// MongoDB tables:
  /// - 'faculty'
  /// - 'students'
  /// - 'visitors'
  Future<AuthResult> signUpUser({
    required String name,
    required String email,
    required String phone,
    required String rollNumber,
    required String password,
    required String role,
  }) async {
    // 1. Register user directly into the corresponding MongoDB table
    final result = await _mongoService.registerUser(
      name: name,
      email: email,
      phone: phone,
      rollNumber: rollNumber,
      password: password,
      role: role,
    );

    if (!result.success) {
      return result;
    }

    // 2. Optionally sync with Firebase Auth if configured
    final auth = _auth;
    if (auth != null) {
      try {
        await auth.createUserWithEmailAndPassword(
          email: email.trim().toLowerCase(),
          password: password,
        );
        // Sign out immediately so user logs in on LoginScreen
        await auth.signOut();
      } catch (_) {
        // Firebase Auth sync is secondary; MongoDB is primary
      }
    }

    return result;
  }

  // Legacy Sign In method
  Future<fb.UserCredential?> signInWithEmail({
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

  // Legacy Sign Up method
  Future<fb.UserCredential?> signUpWithEmail({
    required String name,
    required String email,
    required String rollNumber,
    required String password,
  }) async {
    final result = await signUpUser(
      name: name,
      email: email,
      phone: '9876543210',
      rollNumber: rollNumber,
      password: password,
      role: 'Student',
    );
    if (!result.success) {
      throw fb.FirebaseAuthException(
        code: 'signup-failed',
        message: result.message,
      );
    }
    return null;
  }

  // Sign Out
  Future<void> signOut() async {
    setCurrentUser(null);
    try {
      await _auth?.signOut();
    } catch (_) {}
  }
}
