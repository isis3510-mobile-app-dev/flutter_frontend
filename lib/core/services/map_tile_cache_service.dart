import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class MapTileCacheService {
  MapTileCacheService._();

  static const String userAgentPackageName = 'com.example.petcare';
  static const String osmTileUrlTemplate =
      'https://tile.openstreetmap.org/{z}/{x}/{y}.png';

  static final LatLngBounds bogotaBounds = LatLngBounds(
    const LatLng(4.45, -74.24),
    const LatLng(4.84, -73.98),
  );
}
