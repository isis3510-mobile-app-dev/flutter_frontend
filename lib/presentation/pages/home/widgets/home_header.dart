import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../../core/constants/app_assets.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';

/// Header section of the home page with user name and action buttons.
class HomeHeader extends StatelessWidget {
  const HomeHeader({
    super.key,
    required this.userName,
    this.hasNotification = false,
    this.onNotificationTap,
    this.onNfcTap,
  });

  final String userName;
  final bool hasNotification;
  final VoidCallback? onNotificationTap;
  final VoidCallback? onNfcTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark
        ? AppColors.onBackgroundDark
        : AppColors.onBackground;
    final nfcBackground = isDark
        ? AppColors.quickActionIconBackgroundDark
        : AppColors.primaryVariant;
    final nfcIconColor = isDark
        ? AppColors.primaryVariant
        : AppColors.quickActionIconTint;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.pageHorizontalPadding,
        vertical: AppDimensions.spaceM,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                userName,
                style: TextStyle(
                  color: textColor,
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: onNfcTap,
                  customBorder: const CircleBorder(),
                  child: SizedBox(
                    width: 44,
                    height: 44,
                    child: Center(
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: nfcBackground,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: SvgPicture.asset(
                            AppAssets.iconNfc,
                            width: 18,
                            height: 18,
                            colorFilter: ColorFilter.mode(
                              nfcIconColor,
                              BlendMode.srcIn,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              _NotificationButton(
                hasNotification: hasNotification,
                onTap: onNotificationTap,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _NotificationButton extends StatelessWidget {
  const _NotificationButton({required this.hasNotification, this.onTap});

  final bool hasNotification;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark
        ? AppColors.secondaryDark
        : AppColors.secondary;
    final borderColor = isDark ? AppColors.grey700 : AppColors.grey300;
    final iconColor = isDark ? AppColors.onBackgroundDark : AppColors.onSurface;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: 44,
          height: 44,
          child: Center(
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: backgroundColor,
                shape: BoxShape.circle,
                border: Border.all(color: borderColor),
              ),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Center(
                    child: Icon(
                      Icons.notifications_none_rounded,
                      size: 20,
                      color: iconColor,
                    ),
                  ),
                  if (hasNotification)
                    const Positioned(
                      top: 8,
                      right: 8,
                      child: _NotificationDot(),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NotificationDot extends StatelessWidget {
  const _NotificationDot();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(
        color: AppColors.error,
        shape: BoxShape.circle,
        border: Border.all(
          color: Theme.of(context).brightness == Brightness.dark
              ? AppColors.secondaryDark
              : AppColors.secondary,
          width: 1.5,
        ),
      ),
    );
  }
}
