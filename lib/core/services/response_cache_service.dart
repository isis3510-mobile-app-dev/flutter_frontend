import 'package:shared_preferences/shared_preferences.dart';

class CachedResponseEntry {
  const CachedResponseEntry({required this.body, required this.updatedAt});

  final String body;
  final DateTime updatedAt;

  bool isFresh(Duration ttl) {
    return DateTime.now().difference(updatedAt) <= ttl;
  }
}

class ResponseCacheService {
  ResponseCacheService._();

  static final ResponseCacheService _instance = ResponseCacheService._();

  factory ResponseCacheService() => _instance;

  static final Map<String, CachedResponseEntry> _memoryCache =
      <String, CachedResponseEntry>{};
  static const String _storagePrefix = 'response_cache.';

  Future<CachedResponseEntry?> get(String key) async {
    final memoryEntry = _memoryCache[key];
    if (memoryEntry != null) {
      return memoryEntry;
    }

    final prefs = await SharedPreferences.getInstance();
    final body = prefs.getString(_bodyKey(key));
    final timestamp = prefs.getInt(_timestampKey(key));

    if (body == null || timestamp == null) {
      return null;
    }

    final entry = CachedResponseEntry(
      body: body,
      updatedAt: DateTime.fromMillisecondsSinceEpoch(timestamp),
    );

    _memoryCache[key] = entry;
    return entry;
  }

  Future<void> set(String key, String body, {DateTime? updatedAt}) async {
    final now = updatedAt ?? DateTime.now();
    final entry = CachedResponseEntry(body: body, updatedAt: now);

    _memoryCache[key] = entry;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_bodyKey(key), body);
    await prefs.setInt(_timestampKey(key), now.millisecondsSinceEpoch);
  }

  Future<void> clear(String key) async {
    _memoryCache.remove(key);

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_bodyKey(key));
    await prefs.remove(_timestampKey(key));
  }

  Future<void> clearByPrefix(String prefix) async {
    _memoryCache.removeWhere((key, _) => key.startsWith(prefix));

    final storagePrefix = _storageKey(prefix);
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys();

    final matchingKeys = keys
        .where((key) => key.startsWith(storagePrefix))
        .toList(growable: false);

    for (final key in matchingKeys) {
      await prefs.remove(key);
    }
  }

  Future<void> clearAll() async {
    _memoryCache.clear();

    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys();
    final matchingKeys = keys
        .where((key) => key.startsWith(_storagePrefix))
        .toList(growable: false);

    for (final key in matchingKeys) {
      await prefs.remove(key);
    }
  }

  String _bodyKey(String key) => '${_storageKey(key)}.body';

  String _timestampKey(String key) => '${_storageKey(key)}.timestamp';

  String _storageKey(String key) => '$_storagePrefix$key';
}
