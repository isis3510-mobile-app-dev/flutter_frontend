import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../../core/constants/app_assets.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';

enum NfcHeaderGraphicState { idle, scanning, success }

class NfcHeaderGraphic extends StatelessWidget {
  const NfcHeaderGraphic({
    super.key,
    required this.state,
  });

  final NfcHeaderGraphicState state;

  @override
  Widget build(BuildContext context) {
    return switch (state) {
      NfcHeaderGraphicState.idle => _IdleGraphic(),
      NfcHeaderGraphicState.scanning => _ScanningGraphic(),
      NfcHeaderGraphicState.success => _SuccessGraphic(),
    };
  }
}

class _IdleGraphic extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final size = AppDimensions.iconXXXL * 1.5;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.primaryVariant.withValues(alpha: 0.3),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: SvgPicture.asset(
          AppAssets.iconNfc,
          width: AppDimensions.iconXXL,
          height: AppDimensions.iconXXL,
        ),
      ),
    );
  }
}

class _ScanningGraphic extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final size = AppDimensions.iconXXXL * 1.5;

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          _Ring(size: size, opacity: 0.55),
          _Ring(size: size * 0.76, opacity: 0.7),
          Container(
            width: size * 0.58,
            height: size * 0.58,
            decoration: BoxDecoration(
              color: AppColors.primaryVariant.withValues(alpha: 0.8),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: SvgPicture.asset(
                AppAssets.iconNfc,
                width: AppDimensions.iconXL,
                height: AppDimensions.iconXL,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Ring extends StatelessWidget {
  const _Ring({
    required this.size,
    required this.opacity,
  });

  final double size;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: AppColors.grey300.withValues(alpha: opacity),
          width: AppDimensions.strokeThin,
        ),
      ),
    );
  }
}

class _SuccessGraphic extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final size = AppDimensions.iconXXL + AppDimensions.spaceS;

    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        color: AppColors.petStatusHealthyBg,
        shape: BoxShape.circle,
      ),
      child: const Icon(
        Icons.check_rounded,
        color: AppColors.success,
        size: AppDimensions.iconL,
      ),
    );
  }
}