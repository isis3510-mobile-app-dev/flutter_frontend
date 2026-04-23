import 'package:flutter_cache_manager/flutter_cache_manager.dart';

/// Shared image cache configuration used by CachedNetworkImage widgets/providers.
class AppImageCacheManager {
  AppImageCacheManager._();

  static const String _cacheKey = 'petcare_image_cache';
  static const Duration _stalePeriod = Duration(days: 7);
  static const int _maxNrOfCacheObjects = 200;

  static final CacheManager instance = CacheManager(
    Config(
      _cacheKey,
      stalePeriod: _stalePeriod,
      maxNrOfCacheObjects: _maxNrOfCacheObjects,
    ),
  );
}
