import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';

class PetCountPill extends StatelessWidget {
  const PetCountPill({super.key, required this.count, required this.isDark});

  final int count;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: isDark? AppColors.primary : AppColors.primaryVariant,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        '$count ${count == 1 ? 'pet' : 'pets'}',
        style: TextStyle(
          color: isDark? AppColors.onPrimary : AppColors.primary,
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
