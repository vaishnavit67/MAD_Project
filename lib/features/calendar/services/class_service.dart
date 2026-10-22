import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import '../models/class_model.dart';

class ClassService {
  static final ClassService _instance = ClassService._internal();
  factory ClassService() => _instance;
  ClassService._internal();

  static const String _boxName = 'classes_box';
  Box<Map<dynamic, dynamic>>? _box;
  final Map<String, Map<dynamic, dynamic>> _fallbackClasses = {};

  Future<void> init() async {
    try {
      _box = await Hive.openBox<Map<dynamic, dynamic>>(_boxName);
    } catch (e) {
      debugPrint('[ClassService] Hive init notice (using memory fallback): $e');
    }
  }

  List<ClassModel> getClasses() {
    final values = _box?.values ?? _fallbackClasses.values;
    return values.map((map) => ClassModel.fromMap(map)).toList();
  }

  Future<void> addClass(ClassModel cls) async {
    _fallbackClasses[cls.id] = cls.toMap();
    try {
      await _box?.put(cls.id, cls.toMap());
    } catch (_) {}
  }

  Future<void> deleteClass(String id) async {
    _fallbackClasses.remove(id);
    try {
      await _box?.delete(id);
    } catch (_) {}
  }

  /// Returns all classes that occur on [date].
  List<ClassModel> getClassesForDate(DateTime date) {
    return getClasses().where((cls) => cls.occursOn(date)).toList();
  }
}
