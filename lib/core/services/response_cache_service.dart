import 'dart:collection';

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
  static const int _maxEntries = 100;

  factory ResponseCacheService() => _instance;

  static final LinkedHashMap<String, CachedResponseEntry> _memoryCache =
      LinkedHashMap<String, CachedResponseEntry>();

  Future<CachedResponseEntry?> get(String key) async {
    final entry = _memoryCache.remove(key);
    if (entry == null) {
      return null;
    }

    _memoryCache[key] = entry;
    return entry;
  }

  Future<void> set(String key, String body, {DateTime? updatedAt}) async {
    final now = updatedAt ?? DateTime.now();
    final entry = CachedResponseEntry(body: body, updatedAt: now);

    _memoryCache.remove(key);
    _memoryCache[key] = entry;
    _evictIfNeeded();
  }

  Future<void> clear(String key) async {
    _memoryCache.remove(key);
  }

  Future<void> clearByPrefix(String prefix) async {
    _memoryCache.removeWhere((key, _) => key.startsWith(prefix));
  }

  Future<void> clearAll() async {
    _memoryCache.clear();
  }

  void _evictIfNeeded() {
    while (_memoryCache.length > _maxEntries) {
      final oldestKey = _memoryCache.keys.first;
      _memoryCache.remove(oldestKey);
    }
  }
}
