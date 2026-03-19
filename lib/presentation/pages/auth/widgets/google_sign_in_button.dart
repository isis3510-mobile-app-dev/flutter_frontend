import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_frontend/core/constants/app_assets.dart';
import 'package:flutter_frontend/core/constants/app_colors.dart';
import 'package:flutter_frontend/core/constants/app_dimensions.dart';
import 'package:flutter_frontend/core/utils/context_extensions.dart';

class GoogleSignInButton extends StatelessWidget {
  const GoogleSignInButton({
    super.key,
    required this.text,
    required this.onPressed,
  });

  final String text;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor = isDark ? AppColors.grey700 : AppColors.grey300;
    final backgroundColor = isDark
        ? AppColors.secondaryDark
        : AppColors.secondary;
    final textColor = isDark ? AppColors.onSurfaceDark : AppColors.onSurface;

    return SizedBox(
      width: double.infinity,
      height: AppDimensions.buttonHeightL,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          backgroundColor: backgroundColor,
          side: BorderSide(color: borderColor, width: AppDimensions.strokeThin),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimensions.radiusCircle),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SvgPicture.asset(
              AppAssets.iconGoogle,
              width: AppDimensions.iconM,
              height: AppDimensions.iconM,
            ),
            const SizedBox(width: AppDimensions.spaceS),
            Text(
              text,
              style: context.textTheme.labelLarge?.copyWith(color: textColor),
            ),
          ],
        ),
      ),
    );
  }
}
