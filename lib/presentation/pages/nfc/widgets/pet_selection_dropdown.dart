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
    return DropdownButtonFormField<String>(
      initialValue: selectedPetId,
      isExpanded: true,
      icon: const Icon(
        Icons.expand_more_rounded,
        color: AppColors.onSurface,
      ),
      decoration: InputDecoration(
        filled: true,
        fillColor: AppColors.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.spaceM,
          vertical: AppDimensions.spaceS,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusM),
          borderSide: const BorderSide(
            color: AppColors.petFilterInactiveBorder,
            width: AppDimensions.strokeThin,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusM),
          borderSide: const BorderSide(
            color: AppColors.petFilterInactiveBorder,
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
                style: const TextStyle(
                  color: AppColors.onSurface,
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