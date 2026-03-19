import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

/// Local database service using Hive for offline caching.
///
/// Provides typed box access for each data type:
/// - Content cache
/// - Media metadata cache
/// - User profile cache
/// - Pending offline operations queue
class LocalDbService {
  static const String _contentBoxName = 'content_cache';
  static const String _mediaBoxName = 'media_cache';
  static const String _userBoxName = 'user_cache';
  static const String _pendingOpsBoxName = 'pending_operations';

  bool _initialized = false;

  /// Initialize Hive and open all boxes.
  Future<void> init() async {
    if (_initialized) return;
    await Hive.initFlutter();
    await Future.wait([
      Hive.openBox<Map>(_contentBoxName),
      Hive.openBox<Map>(_mediaBoxName),
      Hive.openBox<Map>(_userBoxName),
      Hive.openBox<Map>(_pendingOpsBoxName),
    ]);
    _initialized = true;
  }

  // ─────────── Content Cache ───────────
  Box<Map> get contentBox => Hive.box<Map>(_contentBoxName);

  Future<void> cacheContent(String id, Map<String, dynamic> data) async {
    data['_cached_at'] = DateTime.now().toIso8601String();
    await contentBox.put(id, data);
  }

  Map<String, dynamic>? getCachedContent(String id, {Duration? maxAge}) {
    final data = contentBox.get(id);
    if (data == null) return null;

    if (maxAge != null) {
      final cachedAt = DateTime.tryParse(data['_cached_at'] as String? ?? '');
      if (cachedAt != null && DateTime.now().difference(cachedAt) > maxAge) {
        return null; // Cache expired
      }
    }
    return Map<String, dynamic>.from(data);
  }

  Future<void> cacheContentList(List<Map<String, dynamic>> items) async {
    for (final item in items) {
      final id = item['id'] as String?;
      if (id != null) await cacheContent(id, item);
    }
  }

  // ─────────── Media Cache ───────────
  Box<Map> get mediaBox => Hive.box<Map>(_mediaBoxName);

  Future<void> cacheMedia(String id, Map<String, dynamic> data) async {
    data['_cached_at'] = DateTime.now().toIso8601String();
    await mediaBox.put(id, data);
  }

  // ─────────── User Cache ───────────
  Box<Map> get userBox => Hive.box<Map>(_userBoxName);

  Future<void> cacheUser(Map<String, dynamic> data) async {
    data['_cached_at'] = DateTime.now().toIso8601String();
    await userBox.put('current_user', data);
  }

  Map<String, dynamic>? getCachedUser({Duration? maxAge}) {
    return _getWithTTL(userBox, 'current_user', maxAge);
  }

  // ─────────── Pending Operations (Offline Queue) ───────────
  Box<Map> get pendingOpsBox => Hive.box<Map>(_pendingOpsBoxName);

  Future<void> addPendingOperation(Map<String, dynamic> operation) async {
    final key = DateTime.now().millisecondsSinceEpoch.toString();
    await pendingOpsBox.put(key, operation);
  }

  List<MapEntry<String, Map<String, dynamic>>> getPendingOperations() {
    return pendingOpsBox.toMap().entries.map((e) {
      return MapEntry(e.key.toString(), Map<String, dynamic>.from(e.value));
    }).toList();
  }

  Future<void> removePendingOperation(String key) async {
    await pendingOpsBox.delete(key);
  }

  // ─────────── Clear ───────────
  Future<void> clearAll() async {
    await contentBox.clear();
    await mediaBox.clear();
    await userBox.clear();
    // NOTE: pending operations are NOT cleared
  }

  // ─────────── Helper ───────────
  Map<String, dynamic>? _getWithTTL(Box<Map> box, String key, Duration? maxAge) {
    final data = box.get(key);
    if (data == null) return null;

    if (maxAge != null) {
      final cachedAt = DateTime.tryParse(data['_cached_at'] as String? ?? '');
      if (cachedAt != null && DateTime.now().difference(cachedAt) > maxAge) {
        return null;
      }
    }
    return Map<String, dynamic>.from(data);
  }
}

/// Riverpod provider for [LocalDbService].
final localDbProvider = Provider<LocalDbService>((ref) {
  return LocalDbService();
});
