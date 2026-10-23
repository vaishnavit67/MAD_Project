import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:mongo_dart/mongo_dart.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import '../utils/validators.dart';

/// MongoDB service for managing user registration and authentication across
/// role-partitioned collections (tables):
/// - 'faculty'
/// - 'students'
/// - 'visitors'
///
/// Supports both REST API connection to the Node.js Express backend (`server.js`)
/// and direct MongoDB connection via `mongo_dart` with full offline fallback.
class MongoDbService {
  static final MongoDbService _instance = MongoDbService._internal();
  static MongoDbService get instance => _instance;

  MongoDbService._internal() {
    _seedLocalDefaults();
  }

  // Collection names (tables)
  static const String tableFaculty = 'faculty';
  static const String tableStudents = 'students';
  static const String tableVisitors = 'visitors';

  static const List<String> allTables = [
    tableFaculty,
    tableStudents,
    tableVisitors,
  ];

  // Default connection URI: can be overridden via Dart define --dart-define=MONGODB_URI=...
  // or set dynamically via configure(uri: ...)
  static const String _defaultUri = String.fromEnvironment(
    'MONGODB_URI',
    defaultValue: 'mongodb://127.0.0.1:27017/campus_connect',
  );

  static const String primaryLaptopIp = '10.12.252.91';
  static const List<String> candidateUrls = [
    'http://10.12.252.91:5000', // Wi-Fi Laptop LAN IP
    'http://127.0.0.1:5000',    // Physical device via adb reverse
    'http://10.0.2.2:5000',     // Android emulator
  ];

  /// Default Node.js Express backend URL
  static String get defaultBackendUrl {
    const envUrl = String.fromEnvironment('BACKEND_URL', defaultValue: '');
    if (envUrl.isNotEmpty) return envUrl;

    if (kIsWeb) return 'http://localhost:5000';
    if (defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.12.252.91:5000';
    }
    return 'http://127.0.0.1:5000';
  }

  String _connectionUri = _defaultUri;
  String _backendUrl = defaultBackendUrl;
  Db? _db;
  bool _isConnected = false;
  bool _isConnecting = false;

  /// Current connection status to MongoDB server
  bool get isConnected => _isConnected && _db != null && _db!.isConnected;

  /// Underlying mongo_dart Db instance (if connected)
  Db? get db => _db;

  /// Current configured MongoDB URI
  String get connectionUri => _connectionUri;

  /// Current configured Node.js backend URL
  String get backendUrl => _backendUrl;

  // In-memory cache synchronized with collections for high performance,
  // offline resilience, and seamless test executions
  final Map<String, List<UserModel>> _inMemoryTables = {
    tableFaculty: [],
    tableStudents: [],
    tableVisitors: [],
  };

  /// Pre-seed default domain-compliant accounts
  void _seedLocalDefaults() {
    _inMemoryTables[tableStudents] = [
      UserModel(
        id: 'seed-student-001',
        name: 'Amrita Student',
        email: 'student@cb.students.amrita.edu',
        phone: '9876543210',
        rollNumber: 'CB.EN.U4CSE21001',
        passwordHash: UserModel.hashPassword('password123'),
        role: 'Student',
        category: tableStudents,
      ),
    ];

    _inMemoryTables[tableFaculty] = [
      UserModel(
        id: 'seed-faculty-001',
        name: 'Amrita Faculty',
        email: 'faculty@cb.amrita.edu',
        phone: '9876543211',
        rollNumber: 'EMP1001',
        passwordHash: UserModel.hashPassword('password123'),
        role: 'Faculty',
        category: tableFaculty,
      ),
    ];

    _inMemoryTables[tableVisitors] = [
      UserModel(
        id: 'seed-visitor-001',
        name: 'Campus Visitor',
        email: 'user@gmail.com',
        phone: '9876543212',
        rollNumber: 'VIS001',
        passwordHash: UserModel.hashPassword('password123'),
        role: 'Visitor',
        category: tableVisitors,
      ),
    ];
  }

  /// Maps user role string to corresponding MongoDB collection (table)
  static String getCollectionNameForRole(String role) {
    switch (role.trim().toLowerCase()) {
      case 'faculty':
        return tableFaculty;
      case 'visitor':
        return tableVisitors;
      case 'student':
      default:
        return tableStudents;
    }
  }

  /// Configure MongoDB connection string
  void configure({required String uri}) {
    _connectionUri = uri.trim();
  }

  /// Configure Node.js backend URL (e.g. 'http://10.12.252.91:5000' or deployed URL)
  void configureBackend({required String url}) {
    _backendUrl = url.trim();
    _saveBackendUrl(_backendUrl);
    _lastBackendCheck = null;
  }

  Future<void> _saveBackendUrl(String url) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('backend_server_url', url);
    } catch (_) {}
  }

  /// Connect to MongoDB with timeout guard and load saved backend URL
  Future<bool> initialize({Duration timeout = const Duration(seconds: 3)}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedUrl = prefs.getString('backend_server_url');
      if (savedUrl != null && savedUrl.trim().isNotEmpty) {
        if (savedUrl.contains('10.0.2.2')) {
          _backendUrl = defaultBackendUrl;
        } else {
          _backendUrl = savedUrl.trim();
        }
        debugPrint('[MongoDbService] Restored saved backend URL: $_backendUrl');
      }
    } catch (_) {}

    // Probe live endpoints to lock onto the active server immediately
    try {
      await probeAndSelectBackendUrl(force: true).timeout(const Duration(milliseconds: 1500));
    } catch (_) {}

    if (kIsWeb) {
      debugPrint('[MongoDB] Running on Flutter Web: Using Node.js REST API backend ($backendUrl)');
      _isConnected = false;
      return true;
    }

    if (_isConnected && _db != null && _db!.isConnected) {
      return true;
    }

    if (_isConnecting) {
      return false;
    }

    _isConnecting = true;

    try {
      final dbInstance = await Db.create(_connectionUri);
      await dbInstance.open().timeout(timeout);

      _db = dbInstance;
      _isConnected = true;
      debugPrint('[MongoDB] Successfully connected to $_connectionUri');

      // Initialize collections and create unique indexes
      await _setupCollectionsAndIndexes();

      // Seed initial accounts in MongoDB collections if missing
      await _syncSeedUsersToMongoDB();

      return true;
    } catch (e) {
      _isConnected = false;
      debugPrint('[MongoDB] Could not connect directly to MongoDB server ($e). Running in hybrid/offline fallback mode.');
      return false;
    } finally {
      _isConnecting = false;
    }
  }

  /// Ensure collections and unique indexes for email and phone exist
  Future<void> _setupCollectionsAndIndexes() async {
    if (!isConnected || _db == null) return;

    for (final table in allTables) {
      try {
        final col = _db!.collection(table);
        await col.createIndex(keys: {'email': 1}, unique: true);
        await col.createIndex(keys: {'phone': 1}, unique: true);
      } catch (e) {
        debugPrint('[MongoDB] Index creation notice for $table: $e');
      }
    }
  }

  /// Synchronize pre-seeded demo accounts into live MongoDB collections
  Future<void> _syncSeedUsersToMongoDB() async {
    if (!isConnected || _db == null) return;

    for (final table in allTables) {
      final users = _inMemoryTables[table] ?? [];
      final col = _db!.collection(table);

      for (final user in users) {
        try {
          final existing = await col.findOne(where.eq('email', user.email.toLowerCase()));
          if (existing == null) {
            await col.insertOne(user.toMap());
          }
        } catch (_) {}
      }
    }
  }

  /// Close connection
  Future<void> close() async {
    try {
      if (_db != null && _db!.isConnected) {
        await _db!.close();
      }
    } catch (_) {}
    _isConnected = false;
  }

  // ==========================================
  // VALIDATION & REGISTRATION
  // ==========================================

  /// Validates all user details strictly according to role specifications
  String? validateUserDetails({
    required String name,
    required String email,
    required String phone,
    required String rollNumber,
    required String password,
    required String role,
  }) {
    final cleanRole = role.trim();
    if (!['Faculty', 'Student', 'Visitor'].contains(cleanRole)) {
      return 'Invalid role selected. Must be Faculty, Student, or Visitor.';
    }

    final nameError = FormValidators.validateName(name);
    if (nameError != null) return nameError;

    final emailError = FormValidators.validateEmailForRole(email, cleanRole);
    if (emailError != null) return emailError;

    final phoneError = FormValidators.validatePhone(phone);
    if (phoneError != null) return phoneError;

    final rollError = FormValidators.validateRollNumber(rollNumber);
    if (rollError != null) return rollError;

    final passwordError = FormValidators.validatePassword(password);
    if (passwordError != null) return passwordError;

    return null;
  }

  bool _isBackendAvailable = false;
  DateTime? _lastBackendCheck;

  /// Current backend connection availability status
  bool get isBackendAvailable => _isBackendAvailable;

  /// Test connectivity to a specific endpoint
  Future<bool> testEndpoint(String url) async {
    try {
      final clean = url.trim().replaceAll(RegExp(r'/+$'), '');
      final response = await http
          .get(Uri.parse('$clean/api/health'))
          .timeout(const Duration(milliseconds: 1000));
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  /// Explicitly probe all candidate backend URLs and lock onto the reachable one
  Future<bool> probeAndSelectBackendUrl({bool force = false}) async {
    if (!force && _isBackendAvailable && _lastBackendCheck != null) {
      if (DateTime.now().difference(_lastBackendCheck!).inSeconds < 10) {
        return true;
      }
    }

    // 1. Try current configured URL first
    if (await testEndpoint(_backendUrl)) {
      _isBackendAvailable = true;
      _lastBackendCheck = DateTime.now();
      await _saveBackendUrl(_backendUrl);
      return true;
    }

    // 2. Probe candidates (Wi-Fi, USB adb, Emulator)
    for (final altUrl in candidateUrls) {
      if (altUrl == _backendUrl) continue;
      if (await testEndpoint(altUrl)) {
        _backendUrl = altUrl;
        _isBackendAvailable = true;
        _lastBackendCheck = DateTime.now();
        await _saveBackendUrl(altUrl);
        debugPrint('[MongoDbService] Successfully locked onto backend: $altUrl');
        return true;
      }
    }

    _isBackendAvailable = false;
    _lastBackendCheck = DateTime.now();
    return false;
  }

  /// Check if the Node.js Express backend is running and responding
  Future<bool> checkBackendAvailable() async {
    final now = DateTime.now();
    if (_lastBackendCheck != null && now.difference(_lastBackendCheck!).inSeconds < 5) {
      return _isBackendAvailable;
    }

    return await probeAndSelectBackendUrl();
  }

  /// Register user into role-specific table ('faculty', 'students', 'visitors')
  /// following thorough domain and input validation.
  /// Supports communicating with the Node.js Express backend (`server.js`)
  /// with automatic fallback to direct/offline pipeline.
  Future<AuthResult> registerUser({
    required String name,
    required String email,
    required String phone,
    required String rollNumber,
    required String password,
    required String role,
  }) async {
    // 1. Strict client-side validation check
    final validationError = validateUserDetails(
      name: name,
      email: email,
      phone: phone,
      rollNumber: rollNumber,
      password: password,
      role: role,
    );
    if (validationError != null) {
      return AuthResult(success: false, message: validationError);
    }

    final cleanEmail = email.trim().toLowerCase();
    final cleanPhone = phone.replaceAll(RegExp(r'\D'), '');
    final targetTable = getCollectionNameForRole(role);

    // 2. Try Node.js Express Backend REST API first if server is running
    if (await checkBackendAvailable()) {
      try {
        final uri = Uri.parse('$_backendUrl/api/auth/signup');
        final response = await http
            .post(
              uri,
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode({
                'name': name.trim(),
                'email': cleanEmail,
                'phone': cleanPhone,
                'rollNumber': rollNumber.trim(),
                'password': password,
                'role': role,
              }),
            )
            .timeout(const Duration(milliseconds: 3000));

        final data = jsonDecode(response.body) as Map<String, dynamic>;
        if (response.statusCode == 201 && data['success'] == true) {
          UserModel? createdUser = data['user'] != null
              ? UserModel.fromMap(data['user'] as Map<String, dynamic>)
              : null;
          if (createdUser != null) {
            if (createdUser.passwordHash.isEmpty) {
              createdUser = createdUser.copyWith(
                passwordHash: UserModel.hashPassword(password),
              );
            }
            _inMemoryTables[targetTable]?.add(createdUser);
          }
          return AuthResult(
            success: true,
            message: data['message'] ?? 'Account created successfully in $targetTable table! Please log in to continue.',
            user: createdUser,
          );
        } else if (response.statusCode >= 400 && response.statusCode < 500) {
          return AuthResult(
            success: false,
            message: data['message'] ?? 'Registration failed. Please verify your details.',
          );
        }
      } catch (_) {
        // Proceed with direct MongoDB / local pipeline
      }
    }

    // 3. Check for duplicate email across all collections/tables
    final existingUserWithEmail = await findUserByEmail(cleanEmail);
    if (existingUserWithEmail != null) {
      return AuthResult(
        success: false,
        message: 'An account with this email address already exists. Please Log In.',
      );
    }

    // 4. Check for duplicate phone number across all collections/tables
    final existingUserWithPhone = await findUserByPhone(cleanPhone);
    if (existingUserWithPhone != null) {
      return AuthResult(
        success: false,
        message: 'An account with this phone number already exists. Please Log In.',
      );
    }

    // 5. Create new user model with encrypted password
    final newUser = UserModel(
      id: ObjectId().oid,
      name: name.trim(),
      email: cleanEmail,
      phone: cleanPhone,
      rollNumber: rollNumber.trim(),
      passwordHash: UserModel.hashPassword(password),
      role: role,
      category: targetTable,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    // 6. Store in live MongoDB collection if connected
    if (isConnected && _db != null) {
      try {
        final col = _db!.collection(targetTable);
        await col.insertOne(newUser.toMap());
      } catch (e) {
        debugPrint('[MongoDB] Error writing to $targetTable collection: $e');
      }
    }

    // 7. Update in-memory synchronization store
    _inMemoryTables[targetTable]?.add(newUser);

    return AuthResult(
      success: true,
      message: 'Account created successfully in $targetTable table! Please log in to continue.',
      user: newUser,
    );
  }

  // ==========================================
  // AUTHENTICATION & LOGIN
  // ==========================================

  /// Authenticate user credentials against role-specific MongoDB table
  /// Supports communicating with Node.js Express backend (`server.js`)
  /// with automatic fallback to direct/offline pipeline.
  Future<AuthResult> authenticateUser({
    required String identity,
    required String password,
    required String role,
  }) async {
    final cleanIdentity = identity.trim();

    // 1. Validate identity format for the selected role
    final identityError = FormValidators.validateLoginIdentityForRole(cleanIdentity, role);
    if (identityError != null) {
      return AuthResult(success: false, message: identityError);
    }

    final targetTable = getCollectionNameForRole(role);

    // 2. Try Node.js Express Backend REST API first if server is running
    if (await checkBackendAvailable()) {
      try {
        final uri = Uri.parse('$_backendUrl/api/auth/login');
        final response = await http
            .post(
              uri,
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode({
                'identity': cleanIdentity,
                'password': password,
                'role': role,
              }),
            )
            .timeout(const Duration(milliseconds: 3000));

        final data = jsonDecode(response.body) as Map<String, dynamic>;
        if (response.statusCode == 200 && data['success'] == true) {
          final loggedInUser = data['user'] != null
              ? UserModel.fromMap(data['user'] as Map<String, dynamic>)
              : null;
          final token = data['token'] as String?;
          return AuthResult(
            success: true,
            message: data['message'] ?? 'Logged in successfully as $role!',
            user: loggedInUser,
            token: token,
          );
        } else if (response.statusCode >= 400 && response.statusCode < 500) {
          return AuthResult(
            success: false,
            message: data['message'] ?? 'Authentication failed.',
          );
        }
      } catch (_) {
        // Backend not responding; proceed with direct pipeline
      }
    }

    // 3. Search in target table first
    UserModel? user = await _findUserInTable(targetTable, cleanIdentity);

    // 4. If not found in target table, check if user exists under a different role
    if (user == null) {
      for (final table in allTables) {
        if (table == targetTable) continue;
        final otherUser = await _findUserInTable(table, cleanIdentity);
        if (otherUser != null) {
          return AuthResult(
            success: false,
            message: 'This account is registered as ${otherUser.role}. Please select the ${otherUser.role} tab to log in.',
          );
        }
      }

      return AuthResult(
        success: false,
        message: 'No registered account found for "$cleanIdentity" under $role. Please check your details or Sign Up.',
      );
    }

    // 5. Verify password
    final isPasswordValid = UserModel.verifyPassword(password, user.passwordHash);
    if (!isPasswordValid) {
      return AuthResult(
        success: false,
        message: 'Incorrect password. Please verify and try again.',
      );
    }

    return AuthResult(
      success: true,
      message: 'Logged in successfully as $role!',
      user: user,
    );
  }

  // ==========================================
  // QUERY HELPERS
  // ==========================================

  /// Search for user by email or phone within a specific table
  Future<UserModel?> _findUserInTable(String tableName, String identity) async {
    final cleanIdentity = identity.trim().toLowerCase();
    final rawIdentity = identity.trim();
    final digitsOnly = identity.replaceAll(RegExp(r'\D'), '');
    final tenDigitPhone = digitsOnly.length >= 10 ? digitsOnly.substring(digitsOnly.length - 10) : digitsOnly;

    // Check live MongoDB if connected
    if (isConnected && _db != null) {
      try {
        final col = _db!.collection(tableName);
        Map<String, dynamic>? doc;

        if (cleanIdentity.contains('@')) {
          doc = await col.findOne(where.eq('email', cleanIdentity));
        } else if (digitsOnly.length >= 10) {
          doc = await col.findOne(where.eq('phone', tenDigitPhone));
        }
        
        // Check rollNumber / campus ID
        doc ??= await col.findOne(where.match('rollNumber', '^${RegExp.escape(rawIdentity)}\$', caseInsensitive: true));

        if (doc != null) {
          return UserModel.fromMap(doc);
        }
      } catch (e) {
        debugPrint('[MongoDB] Query error in $tableName: $e');
      }
    }

    // Check in-memory store
    final users = _inMemoryTables[tableName] ?? [];
    for (final user in users) {
      if (user.email.toLowerCase() == cleanIdentity) {
        return user;
      }
      if (digitsOnly.length >= 10 && user.phone.replaceAll(RegExp(r'\D'), '') == tenDigitPhone) {
        return user;
      }
      if (user.rollNumber.toLowerCase() == rawIdentity.toLowerCase()) {
        return user;
      }
    }

    return null;
  }

  /// Search for user by email across all tables
  Future<UserModel?> findUserByEmail(String email) async {
    final cleanEmail = email.trim().toLowerCase();

    for (final table in allTables) {
      if (isConnected && _db != null) {
        try {
          final col = _db!.collection(table);
          final doc = await col.findOne(where.eq('email', cleanEmail));
          if (doc != null) return UserModel.fromMap(doc);
        } catch (_) {}
      }

      final inMem = _inMemoryTables[table] ?? [];
      for (final u in inMem) {
        if (u.email.toLowerCase() == cleanEmail) return u;
      }
    }
    return null;
  }

  /// Search for user by phone across all tables
  Future<UserModel?> findUserByPhone(String phone) async {
    final cleanPhone = phone.replaceAll(RegExp(r'\D'), '');
    if (cleanPhone.isEmpty) return null;

    for (final table in allTables) {
      if (isConnected && _db != null) {
        try {
          final col = _db!.collection(table);
          final doc = await col.findOne(where.eq('phone', cleanPhone));
          if (doc != null) return UserModel.fromMap(doc);
        } catch (_) {}
      }

      final inMem = _inMemoryTables[table] ?? [];
      for (final u in inMem) {
        if (u.phone.replaceAll(RegExp(r'\D'), '') == cleanPhone) return u;
      }
    }
    return null;
  }

  /// Get all users in a specific table
  Future<List<UserModel>> getUsersInTable(String tableName) async {
    if (isConnected && _db != null) {
      try {
        final col = _db!.collection(tableName);
        final docs = await col.find().toList();
        return docs.map((d) => UserModel.fromMap(d)).toList();
      } catch (_) {}
    }

    return List.unmodifiable(_inMemoryTables[tableName] ?? []);
  }

  /// Count users in a specific table
  Future<int> countUsersInTable(String tableName) async {
    if (isConnected && _db != null) {
      try {
        final col = _db!.collection(tableName);
        return await col.count();
      } catch (_) {}
    }

    return _inMemoryTables[tableName]?.length ?? 0;
  }

  /// Reset all tables to default seed accounts
  Future<void> resetToSeedData() async {
    if (isConnected && _db != null) {
      for (final table in allTables) {
        try {
          final col = _db!.collection(table);
          await col.deleteMany({});
        } catch (_) {}
      }
    }

    _seedLocalDefaults();

    if (isConnected && _db != null) {
      await _syncSeedUsersToMongoDB();
    }
  }

  /// Clear all tables (for isolated testing)
  Future<void> clearAllTables() async {
    if (isConnected && _db != null) {
      for (final table in allTables) {
        try {
          final col = _db!.collection(table);
          await col.deleteMany({});
        } catch (_) {}
      }
    }

    for (final table in allTables) {
      _inMemoryTables[table]?.clear();
    }
  }
}

/// Unified authentication result returned by AuthService and MongoDbService
class AuthResult {
  final bool success;
  final String message;
  final UserModel? user;
  final String? token;

  AuthResult({
    required this.success,
    required this.message,
    this.user,
    this.token,
  });
}
