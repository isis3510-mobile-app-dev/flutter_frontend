import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../core/constants/app_colors.dart';

class QuickActionsFab extends StatefulWidget {
  const QuickActionsFab({
    super.key,
    required this.onAddPet,
    required this.onAddVaccine,
    required this.onAddEvent,
  });

  final VoidCallback onAddPet;
  final VoidCallback onAddVaccine;
  final VoidCallback onAddEvent;

  @override
  State<QuickActionsFab> createState() => _QuickActionsFabState();
}

class _QuickActionsFabState extends State<QuickActionsFab>
    with SingleTickerProviderStateMixin {
  static const _actionSpacing = 8.0;
  static const _fabGap = 12.0;

  late final AnimationController _controller;
  bool _isOpen = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() {
      _isOpen = !_isOpen;
      if (_isOpen) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    });
  }

  void _close() {
    if (!_isOpen) {
      return;
    }
    setState(() {
      _isOpen = false;
      _controller.reverse();
    });
  }

  void _onActionTap(VoidCallback action) {
    _close();
    action();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fabBackground = isDark
        ? AppColors.quickFabBackgroundDark
        : AppColors.quickFabBackground;
    final pillBackground = isDark
        ? AppColors.quickActionPillBackgroundDark
        : AppColors.quickActionPillBackground;
    final textColor = isDark
        ? AppColors.quickActionTextDark
        : AppColors.quickActionText;
    final iconBackground = isDark
        ? AppColors.quickActionIconBackgroundDark
        : AppColors.quickActionIconBackground;
    final iconTint = isDark
        ? AppColors.quickActionIconTintDark
        : AppColors.quickActionIconTint;

    return TapRegion(
      onTapOutside: (_) => _close(),
      child: SizedBox(
        width: 236,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            IgnorePointer(
              ignoring: !_isOpen,
              child: _ActionItem(
                label: 'Add Pet',
                iconAssetPath: 'assets/icons/featureIcons/pets.svg',
                onTap: () => _onActionTap(widget.onAddPet),
                backgroundColor: pillBackground,
                textColor: textColor,
                iconBackground: iconBackground,
                iconTint: iconTint,
                animation: _buildItemAnimation(0.0, 0.4),
              ),
            ),
            const SizedBox(height: _actionSpacing),
            IgnorePointer(
              ignoring: !_isOpen,
              child: _ActionItem(
                label: 'Add Vaccine',
                iconAssetPath: 'assets/icons/featureIcons/vaccines.svg',
                onTap: () => _onActionTap(widget.onAddVaccine),
                backgroundColor: pillBackground,
                textColor: textColor,
                iconBackground: iconBackground,
                iconTint: iconTint,
                animation: _buildItemAnimation(0.2, 0.6),
              ),
            ),
            const SizedBox(height: _actionSpacing),
            IgnorePointer(
              ignoring: !_isOpen,
              child: _ActionItem(
                label: 'Add Event',
                iconAssetPath: 'assets/icons/featureIcons/calendar.svg',
                onTap: () => _onActionTap(widget.onAddEvent),
                backgroundColor: pillBackground,
                textColor: textColor,
                iconBackground: iconBackground,
                iconTint: iconTint,
                animation: _buildItemAnimation(0.4, 0.8),
              ),
            ),
            const SizedBox(height: _fabGap),
            _MainFabButton(
              isOpen: _isOpen,
              onTap: _toggle,
              backgroundColor: fabBackground,
            ),
          ],
        ),
      ),
    );
  }

  Animation<double> _buildItemAnimation(double start, double end) {
    return CurvedAnimation(
      parent: _controller,
      curve: Interval(start, end, curve: Curves.easeOut),
    );
  }
}

class _MainFabButton extends StatelessWidget {
  const _MainFabButton({
    required this.isOpen,
    required this.onTap,
    required this.backgroundColor,
  });

  final bool isOpen;
  final VoidCallback onTap;
  final Color backgroundColor;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 56,
        height: 56,
        child: TweenAnimationBuilder<double>(
          tween: Tween<double>(begin: 0, end: isOpen ? 1 : 0),
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
          builder: (context, value, _) {
            final rotation = value * (math.pi / 4);

            return Stack(
              alignment: Alignment.center,
              children: [
                Transform.rotate(
                  angle: rotation,
                  child: Container(
                    decoration: BoxDecoration(
                      color: backgroundColor,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: const [
                        BoxShadow(
                          color: AppColors.quickActionShadow,
                          blurRadius: 8,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                  ),
                ),
                Transform.rotate(
                  angle: -rotation,
                  child: const Icon(
                    Icons.add,
                    color: AppColors.quickFabIcon,
                    size: 28,
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _ActionItem extends StatelessWidget {
  const _ActionItem({
    required this.label,
    required this.iconAssetPath,
    required this.onTap,
    required this.backgroundColor,
    required this.textColor,
    required this.iconBackground,
    required this.iconTint,
    required this.animation,
  });

  final String label;
  final String iconAssetPath;
  final VoidCallback onTap;
  final Color backgroundColor;
  final Color textColor;
  final Color iconBackground;
  final Color iconTint;
  final Animation<double> animation;

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: animation,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.12),
          end: Offset.zero,
        ).animate(animation),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(999),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 13,
                  ),
                  decoration: BoxDecoration(
                    color: backgroundColor,
                    borderRadius: BorderRadius.circular(999),
                    boxShadow: const [
                      BoxShadow(
                        color: AppColors.quickActionShadow,
                        blurRadius: 8,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Text(
                    label,
                    style: TextStyle(
                      color: textColor,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: iconBackground,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: SvgPicture.asset(
                      iconAssetPath,
                      width: 20,
                      height: 20,
                      colorFilter: ColorFilter.mode(iconTint, BlendMode.srcIn),
                      placeholderBuilder: (_) =>
                          Icon(Icons.circle, size: 18, color: iconTint),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
