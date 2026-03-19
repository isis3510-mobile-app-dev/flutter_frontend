import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../pets/models/pet_ui_model.dart';

class PetSelectionDropdown extends StatelessWidget {
  const PetSelectionDropdown({
    super.key,
    required this.pets,
    required this.selectedPetId,
    required this.onChanged,
  });

  final List<PetUiModel> pets;
  final String? selectedPetId;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final iconColor = isDark ? AppColors.onSurfaceDark : AppColors.onSurface;
    final fillColor = isDark ? AppColors.secondaryDark : AppColors.surface;
    final borderColor = isDark
        ? AppColors.petFilterInactiveBorderDark
        : AppColors.petFilterInactiveBorder;
    final textColor = isDark ? AppColors.onSurfaceDark : AppColors.onSurface;

    return DropdownButtonFormField<String>(
      initialValue: selectedPetId,
      isExpanded: true,
      icon: Icon(Icons.expand_more_rounded, color: iconColor),
      dropdownColor: fillColor,
      style: TextStyle(
        color: textColor,
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),
      decoration: InputDecoration(
        filled: true,
        fillColor: fillColor,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.spaceM,
          vertical: AppDimensions.spaceS,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusM),
          borderSide: BorderSide(
            color: borderColor,
            width: AppDimensions.strokeThin,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusM),
          borderSide: BorderSide(
            color: borderColor,
            width: AppDimensions.strokeThin,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusM),
          borderSide: const BorderSide(
            color: AppColors.primary,
            width: AppDimensions.strokeRegular,
          ),
        ),
      ),
      items: pets
          .map(
            (pet) => DropdownMenuItem<String>(
              value: pet.id,
              child: Text(
                '${pet.name} (${pet.species})',
                style: TextStyle(
                  color: textColor,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          )
          .toList(),
      onChanged: onChanged,
    );
  }
}
