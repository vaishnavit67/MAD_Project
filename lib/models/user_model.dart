import 'dart:convert';
import 'package:crypto/crypto.dart';

/// User model representing a verified campus member stored in MongoDB.
/// Mapped to role-specific collections (tables):
/// - 'faculty'
/// - 'students'
/// - 'visitors'
class UserModel {
  final String? id;
  final String name;
  final String email;
  final String phone;
  final String rollNumber; // Roll Number / Employee ID / Visitor ID
  final String passwordHash;
  final String role; // 'Faculty', 'Student', 'Visitor'
  final String category; // 'faculty', 'students', 'visitors'
  final DateTime createdAt;
  final DateTime updatedAt;

  UserModel({
    this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.rollNumber,
    required this.passwordHash,
    required this.role,
    String? category,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : category = category ?? _roleToCategory(role),
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  static String _roleToCategory(String role) {
    switch (role.trim().toLowerCase()) {
      case 'faculty':
        return 'faculty';
      case 'visitor':
        return 'visitors';
      case 'student':
      default:
        return 'students';
    }
  }

  /// Hashes a password using SHA-256 with an application-level salt.
  static String hashPassword(String password, {String salt = 'CampusConnect_Salt_2026'}) {
    final bytes = utf8.encode('$salt:$password');
    return sha256.convert(bytes).toString();
  }

  /// Verifies a plain text password against a stored hash or plaintext seed.
  static bool verifyPassword(
    String inputPassword,
    String storedHash, {
    String salt = 'CampusConnect_Salt_2026',
  }) {
    if (storedHash == inputPassword) return true; // Plaintext support for demo seed accounts
    return hashPassword(inputPassword, salt: salt) == storedHash;
  }

  /// Convert to MongoDB document format (BSON Map)
  Map<String, dynamic> toMap() {
    return {
      if (id != null) '_id': id,
      'name': name.trim(),
      'email': email.trim().toLowerCase(),
      'phone': phone.replaceAll(RegExp(r'\D'), ''),
      'rollNumber': rollNumber.trim(),
      'passwordHash': passwordHash,
      'role': role,
      'category': category.toLowerCase(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  /// Create UserModel from MongoDB document Map
  factory UserModel.fromMap(Map<String, dynamic> map) {
    DateTime parseDate(dynamic val) {
      if (val is DateTime) return val;
      if (val is String) {
        return DateTime.tryParse(val) ?? DateTime.now();
      }
      return DateTime.now();
    }

    final rawId = map['_id'];
    String? idStr;
    if (rawId != null) {
      idStr = rawId.toString();
    }

    final role = map['role'] ?? 'Student';
    return UserModel(
      id: idStr,
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      phone: map['phone'] ?? '',
      rollNumber: map['rollNumber'] ?? map['campusId'] ?? '',
      passwordHash: map['passwordHash'] ?? map['password'] ?? '',
      role: role,
      category: map['category'] ?? _roleToCategory(role),
      createdAt: parseDate(map['createdAt']),
      updatedAt: parseDate(map['updatedAt']),
    );
  }

  UserModel copyWith({
    String? id,
    String? name,
    String? email,
    String? phone,
    String? rollNumber,
    String? passwordHash,
    String? role,
    String? category,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      rollNumber: rollNumber ?? this.rollNumber,
      passwordHash: passwordHash ?? this.passwordHash,
      role: role ?? this.role,
      category: category ?? this.category,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
