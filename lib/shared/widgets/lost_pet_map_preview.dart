import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/services/map_tile_cache_service.dart';

class LostPetMapPreview extends StatelessWidget {
  const LostPetMapPreview({
    super.key,
    this.latitude,
    this.longitude,
    this.height = 148,
    this.onPointSelected,
  });

  static const LatLng _bogotaCenter = LatLng(4.7110, -74.0721);

  final double? latitude;
  final double? longitude;
  final double height;
  final ValueChanged<LostPetMapPoint>? onPointSelected;

  bool get _hasPoint => latitude != null && longitude != null;

  @override
  Widget build(BuildContext context) {
    final point = _hasPoint ? LatLng(latitude!, longitude!) : null;
    final center = point ?? _bogotaCenter;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: SizedBox(
        height: height,
        width: double.infinity,
        child: FlutterMap(
          options: MapOptions(
            initialCenter: center,
            initialZoom: point == null ? 11 : 15,
            minZoom: 11,
            maxZoom: 18,
            backgroundColor: Colors.transparent,
            cameraConstraint: CameraConstraint.containCenter(
              bounds: MapTileCacheService.bogotaBounds,
            ),
            onTap: onPointSelected == null
                ? null
                : (_, latLng) {
                    onPointSelected!(
                      LostPetMapPoint(
                        latitude: latLng.latitude,
                        longitude: latLng.longitude,
                      ),
                    );
                  },
          ),
          children: [
            const _MapFallbackBackground(),
            TileLayer(
              urlTemplate: MapTileCacheService.osmTileUrlTemplate,
              userAgentPackageName: MapTileCacheService.userAgentPackageName,
              tileProvider: NetworkTileProvider(silenceExceptions: true),
              tileBounds: MapTileCacheService.bogotaBounds,
              maxZoom: 18,
              maxNativeZoom: 18,
              panBuffer: 1,
            ),
            if (point != null)
              MarkerLayer(
                markers: [
                  Marker(
                    point: point,
                    width: 48,
                    height: 48,
                    alignment: Alignment.topCenter,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: AppColors.onPrimary,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.18),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.location_on_rounded,
                        color: AppColors.negativeText,
                        size: 42,
                      ),
                    ),
                  ),
                ],
              ),
            Positioned(
              right: AppDimensions.spaceS,
              bottom: AppDimensions.spaceS,
              child: _MapAttribution(isDark: isDark),
            ),
            if (onPointSelected != null)
              Positioned(
                left: AppDimensions.spaceS,
                top: AppDimensions.spaceS,
                child: _MapHint(isDark: isDark),
              ),
          ],
        ),
      ),
    );
  }
}

class _MapFallbackBackground extends StatelessWidget {
  const _MapFallbackBackground();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: isDark ? AppColors.secondaryDark : AppColors.primaryVariant,
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(
              painter: _MapGridPainter(
                lineColor: (isDark ? AppColors.grey700 : AppColors.primary)
                    .withValues(alpha: 0.12),
              ),
            ),
          ),
          Center(
            child: DecoratedBox(
              decoration: BoxDecoration(
                color:
                    (isDark
                            ? AppColors.petCardBackgroundDark
                            : AppColors.petCardBackground)
                        .withValues(alpha: 0.82),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                child: Text(
                  'Online map unavailable',
                  style: TextStyle(
                    color: isDark ? AppColors.onSurfaceDark : AppColors.grey700,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MapGridPainter extends CustomPainter {
  const _MapGridPainter({required this.lineColor});

  final Color lineColor;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = lineColor
      ..strokeWidth = 1;
    const spacing = 28.0;

    for (var x = 0.0; x <= size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }

    for (var y = 0.0; y <= size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _MapGridPainter oldDelegate) {
    return oldDelegate.lineColor != lineColor;
  }
}

class LostPetMapPoint {
  const LostPetMapPoint({required this.latitude, required this.longitude});

  final double latitude;
  final double longitude;
}

class _MapAttribution extends StatelessWidget {
  const _MapAttribution({required this.isDark});

  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color:
            (isDark
                    ? AppColors.petCardBackgroundDark
                    : AppColors.petCardBackground)
                .withValues(alpha: 0.78),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
        child: Text(
          '© OSM',
          style: TextStyle(
            color: isDark ? AppColors.onSurfaceDark : AppColors.grey700,
            fontSize: 9,
            fontWeight: FontWeight.w600,
            height: 1,
          ),
        ),
      ),
    );
  }
}

class _MapHint extends StatelessWidget {
  const _MapHint({required this.isDark});

  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.petCardBackgroundDark.withValues(alpha: 0.9)
            : AppColors.petCardBackground.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: isDark ? AppColors.bottomNavTopBorderDark : AppColors.grey300,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Text(
          'Tap to set',
          style: TextStyle(
            color: isDark ? AppColors.onSurfaceDark : AppColors.onSurface,
            fontSize: 11,
            fontWeight: FontWeight.w700,
            height: 1,
          ),
        ),
      ),
    );
  }
}
