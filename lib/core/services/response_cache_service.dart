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

  Future<CachedResponseEntry?> get(String key) async {
    return _memoryCache[key];
  }

  Future<void> set(String key, String body, {DateTime? updatedAt}) async {
    final now = updatedAt ?? DateTime.now();
    final entry = CachedResponseEntry(body: body, updatedAt: now);

    _memoryCache[key] = entry;
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
}
