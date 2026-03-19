import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';

class AppToggleSwitch extends StatelessWidget {
  const AppToggleSwitch({
    super.key,
    required this.value,
    required this.onChanged,
    this.enabled = true,
  });

  final bool value;
  final ValueChanged<bool>? onChanged;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final offTrackColor = isDark
        ? const Color(0xFF5D6468)
        : const Color(0xFFBCC7CA);
    final disabledTrackColor = isDark
        ? const Color(0xFF404348)
        : const Color(0xFFD9E1E3);
    final disabledThumbColor = isDark ? AppColors.grey500 : AppColors.grey700;

    return Transform.scale(
      scale: 1.08,
      child: CupertinoSwitch(
        value: value,
        onChanged: enabled ? onChanged : null,
        activeTrackColor: AppColors.primary,
        inactiveTrackColor: enabled ? offTrackColor : disabledTrackColor,
        thumbColor: enabled ? Colors.white : disabledThumbColor,
      ),
    );
  }
}
