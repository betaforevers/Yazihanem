import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

/// Local database service using Hive for offline caching.
///
/// Provides typed box access for each data type:
/// - Content cache
/// - Media metadata cache
/// - User profile cache
/// - Pending offline operations queue
/// - Fish / Boat / Cari / Auction caches
class LocalDbService {
  static const String _contentBoxName = 'content_cache';
  static const String _mediaBoxName = 'media_cache';
  static const String _userBoxName = 'user_cache';
  static const String _pendingOpsBoxName = 'pending_operations';
  static const String _fishBoxName = 'fish_cache';
  static const String _boatBoxName = 'boat_cache';
  static const String _cariBoxName = 'cari_cache';
  static const String _auctionBoxName = 'auction_cache';

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
      Hive.openBox<Map>(_fishBoxName),
      Hive.openBox<Map>(_boatBoxName),
      Hive.openBox<Map>(_cariBoxName),
      Hive.openBox<Map>(_auctionBoxName),
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

  // ─────────── Fish Cache ───────────
  Box<Map> get fishBox => Hive.box<Map>(_fishBoxName);

  Future<void> cacheFishList(List<Map<String, dynamic>> items) async {
    final box = fishBox;
    await box.clear();
    for (final item in items) {
      final id = item['id'] as String?;
      if (id != null) await box.put(id, {...item, '_cached_at': DateTime.now().toIso8601String()});
    }
  }

  List<Map<String, dynamic>> getCachedFishList() {
    return fishBox.values.map(_toMap).toList();
  }

  // ─────────── Boat Cache ───────────
  Box<Map> get boatBox => Hive.box<Map>(_boatBoxName);

  Future<void> cacheBoatList(List<Map<String, dynamic>> items) async {
    final box = boatBox;
    await box.clear();
    for (final item in items) {
      final id = item['id'] as String?;
      if (id != null) await box.put(id, {...item, '_cached_at': DateTime.now().toIso8601String()});
    }
  }

  List<Map<String, dynamic>> getCachedBoatList() {
    return boatBox.values.map(_toMap).toList();
  }

  // ─────────── Cari Cache ───────────
  Box<Map> get cariBox => Hive.box<Map>(_cariBoxName);

  Future<void> cacheCariList(List<Map<String, dynamic>> items) async {
    final box = cariBox;
    await box.clear();
    for (final item in items) {
      final id = item['id'] as String?;
      if (id != null) await box.put(id, {...item, '_cached_at': DateTime.now().toIso8601String()});
    }
  }

  List<Map<String, dynamic>> getCachedCariList() {
    return cariBox.values.map(_toMap).toList();
  }

  // ─────────── Auction Cache ───────────
  Box<Map> get auctionBox => Hive.box<Map>(_auctionBoxName);

  Future<void> cacheAuctionList(List<Map<String, dynamic>> items) async {
    final box = auctionBox;
    await box.clear();
    for (final item in items) {
      final id = item['id'] as String?;
      if (id != null) await box.put(id, {...item, '_cached_at': DateTime.now().toIso8601String()});
    }
  }

  List<Map<String, dynamic>> getCachedAuctionList() {
    return auctionBox.values.map(_toMap).toList();
  }

  // ─────────── Clear ───────────
  Future<void> clearAll() async {
    await contentBox.clear();
    await mediaBox.clear();
    await userBox.clear();
    await fishBox.clear();
    await boatBox.clear();
    await cariBox.clear();
    await auctionBox.clear();
    // NOTE: pending operations are NOT cleared
  }

  // ─────────── Helpers ───────────
  static Map<String, dynamic> _toMap(Map e) => Map<String, dynamic>.from(e);

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
