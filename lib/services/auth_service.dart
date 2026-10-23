import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:hive/hive.dart';
import '../models/user_model.dart';
import 'mongodb_service.dart';
import '../features/calendar/services/class_service.dart';
import '../features/calendar/services/event_service.dart';
import '../features/tasks/services/task_service.dart';
import '../features/notifications/services/in_app_notification_service.dart';
import '../screens/events/event_registration_service.dart';

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
/// with dual-layer persistent storage (Hive + SharedPreferences) ensuring logins remain
/// saved across app restarts until explicit sign-out.
class AuthService {
  final MongoDbService _mongoService = MongoDbService.instance;

  static const String _prefKeyUser = 'campus_connect_user_session';
  static const String _prefKeyToken = 'campus_connect_auth_token';
  static const String _prefKeyIsLoggedIn = 'campus_connect_is_logged_in';
  static const String _prefKeySavedIdentity = 'campus_connect_saved_identity';
  static const String _prefKeySavedRole = 'campus_connect_saved_role';
  static const String _prefKeyRememberMe = 'campus_connect_remember_me';
  static const String _prefKeyOnboardingCompleted = 'campus_connect_onboarding_completed';
  static const String _hiveAuthBox = 'auth_session_box';

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
  static bool get isLoggedIn => _currentUser != null;

  static String get effectiveToken {
    if (_authToken != null && _authToken!.isNotEmpty) return _authToken!;
    if (_currentUser != null) return 'dev-token-${_currentUser!.role.toLowerCase()}-${_currentUser!.id}';
    return 'dev-token-student-seed-student-001';
  }
  static String get currentRole => _currentUser?.role ?? 'Student';
  static bool get isStudent => currentRole.toLowerCase() == 'student';
  static bool get isFaculty => currentRole.toLowerCase() == 'faculty';
  static bool get isVisitor => currentRole.toLowerCase() == 'visitor';

  /// Save current user in-memory and persistently to both Hive and SharedPreferences
  static Future<void> setCurrentUser(UserModel? user, [String? token]) async {
    _currentUser = user;
    _authToken = token ?? (user != null ? 'dev-token-${user.id}' : null);
    await _persistSession(user, _authToken);
    await _notifyScopeChange();
  }

  /// Automatically switches user-isolated storage boxes and syncs role data from MongoDB
  static Future<void> _notifyScopeChange() async {
    try {
      await Future.wait([
        ClassService().switchUserScope(),
        TaskService().switchUserScope(),
        InAppNotificationService().switchUserScope(),
        EventRegistrationService().switchUserScope(),
        EventService().switchUserScope(),
      ]);
    } catch (e) {
      debugPrint('[AuthService] User scope switch notice: $e');
    }
  }

  static Future<void> _persistSession(UserModel? user, String? token) async {
    final userMap = user?.toMap();
    final userJson = userMap != null ? jsonEncode(userMap) : null;

    // 1. Persist to SharedPreferences
    try {
      final prefs = await SharedPreferences.getInstance();
      if (userJson != null) {
        await prefs.setString(_prefKeyUser, userJson);
        await prefs.setBool(_prefKeyIsLoggedIn, true);
        if (token != null) {
          await prefs.setString(_prefKeyToken, token);
        }
        if (user != null) {
          await prefs.setString(_prefKeySavedIdentity, user.email);
          await prefs.setString(_prefKeySavedRole, user.role);
        }
      } else {
        await prefs.remove(_prefKeyUser);
        await prefs.remove(_prefKeyToken);
        await prefs.setBool(_prefKeyIsLoggedIn, false);
      }
    } catch (e) {
      debugPrint('[AuthService] SharedPreferences persist notice: $e');
    }

    // 2. Persist to Hive box (robust binary on-device storage)
    try {
      final box = await Hive.openBox<dynamic>(_hiveAuthBox);
      if (userMap != null) {
        await box.put(_prefKeyUser, userMap);
        await box.put(_prefKeyIsLoggedIn, true);
        if (token != null) {
          await box.put(_prefKeyToken, token);
        }
        if (user != null) {
          await box.put(_prefKeySavedIdentity, user.email);
          await box.put(_prefKeySavedRole, user.role);
        }
      } else {
        await box.delete(_prefKeyUser);
        await box.delete(_prefKeyToken);
        await box.put(_prefKeyIsLoggedIn, false);
      }
      await box.flush();
    } catch (e) {
      debugPrint('[AuthService] Hive persist notice: $e');
    }
  }

  /// Restore user session from persistent device storage when app opens.
  /// Checks memory -> Hive -> SharedPreferences with mutual sync.
  static Future<UserModel?> restoreSession() async {
    if (_currentUser != null) {
      return _currentUser;
    }

    // 1. Try Hive first (most resilient storage across Android restarts)
    try {
      final box = await Hive.openBox<dynamic>(_hiveAuthBox);
      final rawUser = box.get(_prefKeyUser);
      final token = box.get(_prefKeyToken) as String?;

      if (rawUser != null) {
        Map<String, dynamic>? map;
        if (rawUser is Map) {
          map = Map<String, dynamic>.from(rawUser);
        } else if (rawUser is String && rawUser.isNotEmpty) {
          map = Map<String, dynamic>.from(jsonDecode(rawUser));
        }

        if (map != null && map.isNotEmpty) {
          _currentUser = UserModel.fromMap(map);
          _authToken = token ?? (_currentUser != null ? 'dev-token-${_currentUser!.id}' : null);
          debugPrint('[AuthService] Restored saved session from Hive for ${_currentUser?.email} (${_currentUser?.role})');

          // Keep SharedPreferences synced
          try {
            final prefs = await SharedPreferences.getInstance();
            await prefs.setString(_prefKeyUser, jsonEncode(map));
            await prefs.setBool(_prefKeyIsLoggedIn, true);
            if (_authToken != null) await prefs.setString(_prefKeyToken, _authToken!);
          } catch (_) {}

          await _notifyScopeChange();
          return _currentUser;
        }
      }
    } catch (e) {
      debugPrint('[AuthService] Hive session restore notice: $e');
    }

    // 2. Fallback to SharedPreferences
    try {
      final prefs = await SharedPreferences.getInstance();
      final userJson = prefs.getString(_prefKeyUser);
      final token = prefs.getString(_prefKeyToken);

      if (userJson != null && userJson.isNotEmpty) {
        final Map<String, dynamic> map = Map<String, dynamic>.from(jsonDecode(userJson));
        _currentUser = UserModel.fromMap(map);
        _authToken = token ?? (_currentUser != null ? 'dev-token-${_currentUser!.id}' : null);
        debugPrint('[AuthService] Restored saved session from SharedPreferences for ${_currentUser?.email} (${_currentUser?.role})');

        // Sync back into Hive for next startup
        try {
          final box = await Hive.openBox<dynamic>(_hiveAuthBox);
          await box.put(_prefKeyUser, map);
          await box.put(_prefKeyIsLoggedIn, true);
          if (_authToken != null) await box.put(_prefKeyToken, _authToken!);
          await box.flush();
        } catch (_) {}

        await _notifyScopeChange();
        return _currentUser;
      }
    } catch (e) {
      debugPrint('[AuthService] SharedPreferences session restore notice: $e');
    }

    return null;
  }

  /// Read saved login preferences (remembered email/phone, role, rememberMe state)
  static Future<Map<String, dynamic>> getSavedLoginPreferences() async {
    String? identity;
    String? role;
    bool rememberMe = true;

    // Check SharedPreferences first
    try {
      final prefs = await SharedPreferences.getInstance();
      identity = prefs.getString(_prefKeySavedIdentity);
      role = prefs.getString(_prefKeySavedRole);
      rememberMe = prefs.getBool(_prefKeyRememberMe) ?? true;
    } catch (_) {}

    // Fallback to Hive
    if (identity == null || identity.isEmpty) {
      try {
        final box = await Hive.openBox<dynamic>(_hiveAuthBox);
        identity ??= box.get(_prefKeySavedIdentity) as String?;
        role ??= box.get(_prefKeySavedRole) as String?;
        if (box.containsKey(_prefKeyRememberMe)) {
          rememberMe = box.get(_prefKeyRememberMe) as bool? ?? true;
        }
      } catch (_) {}
    }

    return {
      'identity': identity ?? '',
      'role': (role != null && ['Student', 'Faculty', 'Visitor'].contains(role)) ? role : 'Student',
      'rememberMe': rememberMe,
    };
  }

  /// Persist login preferences (Remember Me credentials)
  static Future<void> saveLoginPreferences({
    required String identity,
    required String role,
    required bool rememberMe,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_prefKeyRememberMe, rememberMe);
      if (rememberMe) {
        await prefs.setString(_prefKeySavedIdentity, identity.trim());
        await prefs.setString(_prefKeySavedRole, role.trim());
      } else {
        await prefs.remove(_prefKeySavedIdentity);
        await prefs.remove(_prefKeySavedRole);
      }
    } catch (_) {}

    try {
      final box = await Hive.openBox<dynamic>(_hiveAuthBox);
      await box.put(_prefKeyRememberMe, rememberMe);
      if (rememberMe) {
        await box.put(_prefKeySavedIdentity, identity.trim());
        await box.put(_prefKeySavedRole, role.trim());
      } else {
        await box.delete(_prefKeySavedIdentity);
        await box.delete(_prefKeySavedRole);
      }
      await box.flush();
    } catch (_) {}
  }

  /// Onboarding status tracking
  static Future<bool> hasCompletedOnboarding() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (prefs.getBool(_prefKeyOnboardingCompleted) == true) return true;
    } catch (_) {}
    try {
      final box = await Hive.openBox<dynamic>(_hiveAuthBox);
      if (box.get(_prefKeyOnboardingCompleted) == true) return true;
    } catch (_) {}
    return false;
  }

  static Future<void> setOnboardingCompleted() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_prefKeyOnboardingCompleted, true);
    } catch (_) {}
    try {
      final box = await Hive.openBox<dynamic>(_hiveAuthBox);
      await box.put(_prefKeyOnboardingCompleted, true);
      await box.flush();
    } catch (_) {}
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

    if (result.success && result.user != null) {
      await setCurrentUser(result.user, result.token);
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
    // Register user directly into the corresponding MongoDB table
    final result = await _mongoService.registerUser(
      name: name,
      email: email,
      phone: phone,
      rollNumber: rollNumber,
      password: password,
      role: role,
    );

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

  // Sign Out: Clears active login session but preserves saved credentials preference
  Future<void> signOut() async {
    await setCurrentUser(null);
    try {
      await _auth?.signOut();
    } catch (_) {}
  }
}
