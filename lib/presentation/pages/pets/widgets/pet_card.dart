import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../../core/constants/app_colors.dart';
import '../models/pet_ui_model.dart';

class PetCard extends StatelessWidget {
  const PetCard({
    super.key,
    required this.pet,
    required this.onTap,
    required this.onVaccinesTap,
    required this.onLostModeTap,
    required this.onNfcTap,
  });

  final PetUiModel pet;
  final VoidCallback onTap;
  final VoidCallback onVaccinesTap;
  final VoidCallback onLostModeTap;
  final VoidCallback onNfcTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor =
        isDark ? AppColors.petCardBackgroundDark : AppColors.petCardBackground;
    final dividerColor = isDark
        ? AppColors.bottomNavTopBorderDark
        : AppColors.bottomNavTopBorder;

    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.18 : 0.06),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            InkWell(
              onTap: onTap,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
                child: _PetCardTopSection(
                  pet: pet,
                  isDark: isDark,
                  onTap: onTap,
                ),
              ),
            ),
            DecoratedBox(
              decoration: BoxDecoration(
                color: cardColor,
                border: Border(top: BorderSide(color: dividerColor)),
              ),
              child: _PetCardBottomActions(
                isDark: isDark,
                onVaccinesTap: onVaccinesTap,
                onLostModeTap: onLostModeTap,
                onNfcTap: onNfcTap,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PetCardTopSection extends StatelessWidget {
  const _PetCardTopSection({
    required this.pet,
    required this.isDark,
    required this.onTap,
  });

  final PetUiModel pet;
  final bool isDark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _PetCardPhoto(
          photoUrl: pet.photoUrl,
          species: pet.species,
          isDark: isDark,
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      pet.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: isDark
                                ? AppColors.onSurfaceDark
                                : AppColors.grey900,
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            height: 1.1,
                          ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  _PetCardStatusBadge(status: pet.status),
                ],
              ),
              const SizedBox(height: 9),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: _PetCardBreedLine(
                      breed: pet.breed,
                      species: pet.species,
                      isDark: isDark,
                    ),
                  ),
                  const SizedBox(width: 8),
                  InkWell(
                    onTap: onTap,
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.all(2),
                      child: Icon(
                        Icons.chevron_right_rounded,
                        size: 22,
                        color: isDark
                            ? AppColors.onSurfaceDark
                            : AppColors.grey700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 11),
              _PetCardMetaRow(
                age: pet.ageLabel,
                weight: pet.weightLabel,
                gender: pet.gender,
                isDark: isDark,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PetCardPhoto extends StatelessWidget {
  const _PetCardPhoto({
    required this.photoUrl,
    required this.species,
    required this.isDark,
  });

  final String? photoUrl;
  final String species;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 96,
      height: 96,
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.petCardQuickActionBgDark
            : AppColors.petCardQuickActionBg,
        borderRadius: BorderRadius.circular(20),
      ),
      clipBehavior: Clip.antiAlias,
      child: photoUrl != null
          ? Image.network(
              photoUrl!,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _PetCardPhotoPlaceholder(
                isDark: isDark,
              ),
            )
          : _PetCardPhotoPlaceholder(isDark: isDark),
    );
  }
}

class _PetCardPhotoPlaceholder extends StatelessWidget {
  const _PetCardPhotoPlaceholder({required this.isDark});

  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SvgPicture.asset(
        _PetCardAssets.pets,
        width: 34,
        height: 34,
        colorFilter: ColorFilter.mode(
          isDark
              ? AppColors.quickActionIconTintDark
              : AppColors.quickActionIconTint,
          BlendMode.srcIn,
        ),
      ),
    );
  }
}

class _PetCardStatusBadge extends StatelessWidget {
  const _PetCardStatusBadge({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final isHealthy = status == 'healthy';
    final backgroundColor = isHealthy
        ? AppColors.petStatusHealthyBg
        : AppColors.petStatusAttentionBg;
    final textColor = isHealthy
        ? AppColors.petStatusHealthyText
        : AppColors.petStatusAttentionText;
    final label = isHealthy ? 'Healthy' : 'Needs Attention';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.fade,
        softWrap: false,
        style: TextStyle(
          color: textColor,
          fontSize: 12,
          fontWeight: FontWeight.w600,
          height: 1,
        ),
      ),
    );
  }
}

class _PetCardBreedLine extends StatelessWidget {
  const _PetCardBreedLine({
    required this.breed,
    required this.species,
    required this.isDark,
  });

  final String breed;
  final String species;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Image.asset(
          _PetCardAssets.speciesIcon(species: species, isDark: isDark),
          width: 16,
          height: 16,
          errorBuilder: (_, __, ___) => SvgPicture.asset(
            _PetCardAssets.pets,
            width: 16,
            height: 16,
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            breed,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: isDark
                      ? AppColors.onSurfaceDark.withOpacity(0.84)
                      : AppColors.grey700,
                  fontSize: 15,
                  fontWeight: FontWeight.w400,
                  height: 1.1,
                ),
          ),
        ),
      ],
    );
  }
}

class _PetCardMetaRow extends StatelessWidget {
  const _PetCardMetaRow({
    required this.age,
    required this.weight,
    required this.gender,
    required this.isDark,
  });

  final String age;
  final String weight;
  final String gender;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return FittedBox(
      alignment: Alignment.centerLeft,
      fit: BoxFit.scaleDown,
      child: Row(
        children: [
          _PetCardMetaItem(
            iconPath: _PetCardAssets.age,
            label: age,
            iconColor: AppColors.petAgeIcon,
            textColor: isDark ? AppColors.onSurfaceDark : AppColors.grey700,
          ),
          const SizedBox(width: 14),
          _PetCardMetaItem(
            iconPath: _PetCardAssets.weight,
            label: weight,
            iconColor: isDark ? AppColors.onSurfaceDark : AppColors.grey700,
            textColor: isDark ? AppColors.onSurfaceDark : AppColors.grey700,
          ),
          const SizedBox(width: 14),
          _PetCardMetaItem(
            iconPath: _PetCardAssets.gender(gender),
            label: gender,
            iconColor: isDark ? AppColors.onSurfaceDark : AppColors.grey700,
            textColor: isDark ? AppColors.onSurfaceDark : AppColors.grey700,
          ),
        ],
      ),
    );
  }
}

class _PetCardMetaItem extends StatelessWidget {
  const _PetCardMetaItem({
    required this.iconPath,
    required this.label,
    required this.iconColor,
    required this.textColor,
  });

  final String iconPath;
  final String label;
  final Color iconColor;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SvgPicture.asset(
          iconPath,
          width: 15,
          height: 15,
          colorFilter: ColorFilter.mode(iconColor, BlendMode.srcIn),
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: textColor,
                fontSize: 12.5,
                fontWeight: FontWeight.w500,
                height: 1,
              ),
        ),
      ],
    );
  }
}

class _PetCardBottomActions extends StatelessWidget {
  const _PetCardBottomActions({
    required this.isDark,
    required this.onVaccinesTap,
    required this.onLostModeTap,
    required this.onNfcTap,
  });

  final bool isDark;
  final VoidCallback onVaccinesTap;
  final VoidCallback onLostModeTap;
  final VoidCallback onNfcTap;

  @override
  Widget build(BuildContext context) {
    final dividerColor = isDark
        ? AppColors.bottomNavTopBorderDark
        : AppColors.bottomNavTopBorder;

    return SizedBox(
      height: 54,
      child: Row(
        children: [
          Expanded(
            child: _PetCardActionItem(
              label: 'Vaccines',
              assetPath: _PetCardAssets.vaccines,
              color: AppColors.bottomNavActive,
              onTap: onVaccinesTap,
            ),
          ),
          Container(width: 1, color: dividerColor),
          Expanded(
            child: _PetCardActionItem(
              label: 'Lost Mode',
              assetPath: _PetCardAssets.lostMode,
              color: isDark ? AppColors.onSurfaceDark : AppColors.grey700,
              onTap: onLostModeTap,
            ),
          ),
          Container(width: 1, color: dividerColor),
          Expanded(
            child: _PetCardActionItem(
              label: 'NFC',
              assetPath: _PetCardAssets.nfc,
              color: AppColors.petQuickActionNfc,
              onTap: onNfcTap,
            ),
          ),
        ],
      ),
    );
  }
}

class _PetCardActionItem extends StatelessWidget {
  const _PetCardActionItem({
    required this.label,
    required this.assetPath,
    required this.color,
    required this.onTap,
  });

  final String label;
  final String assetPath;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Center(
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SvgPicture.asset(
                assetPath,
                width: 15,
                height: 15,
                colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  height: 1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PetCardAssets {
  static const String _metaBase = 'assets/icons/petRelated';

  static const String age = '$_metaBase/age.svg';
  static const String weight = '$_metaBase/weight.svg';
  static const String male = '$_metaBase/male.svg';
  static const String female = '$_metaBase/female.svg';

  static const String vaccines = 'assets/icons/featureIcons/vaccines.svg';
  static const String lostMode = 'assets/icons/featureIcons/location.svg';
  static const String nfc = 'assets/icons/featureIcons/nfc.svg';
  static const String pets = 'assets/icons/featureIcons/pets.svg';

  static String speciesIcon({required String species, required bool isDark}) {
    if (species.toLowerCase() == 'cat') {
      return isDark
          ? 'assets/images/catSecondary.png'
          : 'assets/images/catPrimary.png';
    }
    return isDark
        ? 'assets/images/dogSecondary.png'
        : 'assets/images/dogPrimary.png';
  }

  static String gender(String value) {
    return value.toLowerCase() == 'male' ? male : female;
  }
}
