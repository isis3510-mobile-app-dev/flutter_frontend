import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';

class PetCountPill extends StatelessWidget {
  const PetCountPill({super.key, required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.quickActionIconBackground,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        '$count ${count == 1 ? 'pet' : 'pets'}',
        style: const TextStyle(
          color: AppColors.bottomNavActive,
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
