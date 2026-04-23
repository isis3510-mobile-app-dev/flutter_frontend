import 'package:flutter/material.dart';
import 'package:flutter_frontend/core/constants/app_assets.dart';
import 'package:flutter_frontend/core/constants/app_colors.dart';
import 'package:flutter_frontend/core/constants/app_dimensions.dart';
import 'package:flutter_frontend/core/constants/app_strings.dart';
import 'package:flutter_frontend/core/models/user_profile.dart';
import 'package:flutter_frontend/core/network/api_exception.dart';
import 'package:flutter_frontend/core/services/app_preferences_service.dart';
import 'package:flutter_frontend/core/services/auth_service.dart';
import 'package:flutter_frontend/core/services/profile_photo_service.dart';
import 'package:flutter_frontend/core/services/telemetry_service.dart';
import 'package:flutter_frontend/core/services/user_service.dart';
import 'package:flutter_frontend/app/routes.dart';
import 'package:flutter_frontend/app/theme_controller.dart';
import 'package:flutter_frontend/shared/widgets/petcare_bottom_nav_bar.dart';
import 'package:flutter_frontend/shared/widgets/quick_actions_fab.dart';
import 'widgets/profile_header.dart';
import 'widgets/profile_menu_item.dart';
import 'widgets/profile_toggle_item.dart';

/// The User Profile Page displaying user information, preferences, and actions.
class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final AppPreferencesService _preferencesService = AppPreferencesService();
  final AuthService _authService = AuthService();
  final ProfilePhotoService _photoService = ProfilePhotoService();
  final UserService _userService = UserService();
  final TelemetryService _telemetryService = TelemetryService();

  // Navigation
  static const _currentIndex = 4;

  // User profile
  UserProfile? _profile;
  String? _localPhotoPath;
  bool _isLoadingProfile = false;

  // Preference states
  late bool _notificationsEnabled;

  @override
  void initState() {
    super.initState();
    _notificationsEnabled = true;
    _loadPreferences();
    _loadProfile();
  }

  Future<void> _loadPreferences() async {
    final notificationsEnabled = await _preferencesService
        .getNotificationsEnabled();
    if (!mounted) {
      return;
    }

    setState(() {
      _notificationsEnabled = notificationsEnabled;
    });
  }

  Future<void> _loadProfile() async {
    setState(() => _isLoadingProfile = true);
    try {
      final profile = await _userService.getCurrentUser();
      final photoPath = await _photoService.getLocalPhotoPath();

      if (mounted) {
        setState(() {
          _profile = profile;
          _localPhotoPath = photoPath;
        });
      }
    } on ApiException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.message)));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text(AppStrings.profileLoadError)),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoadingProfile = false);
    }
  }

  void _showUnavailableMessage() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text(AppStrings.featureUnavailable)),
    );
  }

  void _handleBottomNavTap(int index) {
    if (index == _currentIndex) {
      return;
    }

    final routeName = Routes.bottomNavRouteForIndex(index);
    if (routeName == null) {
      _showUnavailableMessage();
      return;
    }

    Navigator.of(context).pushReplacementNamed(routeName);
  }

  Future<void> _handleEditProfile() async {
    final profile = _profile;
    if (profile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(AppStrings.profileLoadError)),
      );
      return;
    }

    final shouldReload = await Navigator.of(
      context,
    ).pushNamed(Routes.profileEdit, arguments: profile);

    if (!mounted) {
      return;
    }

    if (shouldReload == true) {
      await _loadProfile();
    }
  }

  Future<void> _showThemeModePicker() async {
    final themeController = ThemeControllerScope.of(context);
    final selected = await showModalBottomSheet<AppThemePreference>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).brightness == Brightness.dark
          ? AppColors.secondaryDark
          : AppColors.secondary,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppDimensions.radiusXL),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      showDragHandle: true,
      builder: (context) {
        final currentPreference = themeController.preference;
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final textTheme = Theme.of(context).textTheme;
        final titleColor = isDark
            ? AppColors.onSurfaceDark
            : AppColors.onSurface;
        final subtitleColor = isDark ? AppColors.grey300 : AppColors.grey700;
        final selectedBackground = isDark
            ? AppColors.quickActionIconBackgroundDark
            : AppColors.primaryVariant;
        final selectedForeground = isDark
            ? AppColors.quickActionIconTintDark
            : AppColors.primary;
        final cardBackground = isDark
            ? AppColors.backgroundDark
            : AppColors.secondary;
        final dividerColor = isDark
            ? AppColors.petFilterInactiveBorderDark
            : AppColors.grey300;

        Widget option(
          AppThemePreference preference, {
          required String title,
          required String subtitle,
          IconData? icon,
          String? iconLabel,
        }) {
          assert(
            icon != null || iconLabel != null,
            'Either icon or iconLabel must be provided.',
          );
          final isSelected = preference == currentPreference;

          return Padding(
            padding: const EdgeInsets.only(bottom: AppDimensions.spaceS),
            child: Material(
              color: AppColors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(AppDimensions.radiusL),
                onTap: () => Navigator.of(context).pop(preference),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOutCubic,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppDimensions.spaceM,
                    vertical: AppDimensions.spaceM,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected ? selectedBackground : cardBackground,
                    borderRadius: BorderRadius.circular(AppDimensions.radiusL),
                    border: Border.all(
                      color: isSelected ? selectedForeground : dividerColor,
                      width: isSelected
                          ? AppDimensions.strokeMedium
                          : AppDimensions.strokeThin,
                    ),
                  ),
                  child: Row(
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 220),
                        width: AppDimensions.iconL + AppDimensions.spaceS,
                        height: AppDimensions.iconL + AppDimensions.spaceS,
                        decoration: BoxDecoration(
                          color: isSelected
                              ? selectedForeground
                              : (isDark
                                    ? AppColors.secondaryDark
                                    : AppColors.grey100),
                          shape: BoxShape.circle,
                        ),
                        child: iconLabel != null
                            ? Center(
                                child: Text(
                                  iconLabel,
                                  style: textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w800,
                                    color: isSelected
                                        ? AppColors.onPrimary
                                        : (isDark
                                              ? AppColors.onSurfaceDark
                                              : AppColors.onSurface),
                                  ),
                                ),
                              )
                            : Icon(
                                icon!,
                                size: AppDimensions.iconM,
                                color: isSelected
                                    ? AppColors.onPrimary
                                    : (isDark
                                          ? AppColors.onSurfaceDark
                                          : AppColors.onSurface),
                              ),
                      ),
                      const SizedBox(width: AppDimensions.spaceM),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              style: textTheme.titleMedium?.copyWith(
                                color: titleColor,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: AppDimensions.spaceXXS),
                            Text(
                              subtitle,
                              style: textTheme.bodySmall?.copyWith(
                                color: subtitleColor,
                                height: 1.25,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: AppDimensions.spaceS),
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 220),
                        width: AppDimensions.iconM + AppDimensions.spaceXS,
                        height: AppDimensions.iconM + AppDimensions.spaceXS,
                        decoration: BoxDecoration(
                          color: isSelected
                              ? selectedForeground
                              : AppColors.transparent,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isSelected
                                ? selectedForeground
                                : dividerColor,
                            width: AppDimensions.strokeMedium,
                          ),
                        ),
                        child: isSelected
                            ? const Icon(
                                Icons.check_rounded,
                                size: AppDimensions.iconS,
                                color: AppColors.onPrimary,
                              )
                            : null,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }

        final bottomPadding = MediaQuery.of(context).viewPadding.bottom;

        return SafeArea(
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppDimensions.spaceM,
                  ),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(AppDimensions.spaceM),
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.quickActionIconBackgroundDark
                          : AppColors.primaryVariant,
                      borderRadius: BorderRadius.circular(
                        AppDimensions.radiusL,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: AppDimensions.iconL + AppDimensions.spaceS,
                          height: AppDimensions.iconL + AppDimensions.spaceS,
                          decoration: BoxDecoration(
                            color: isDark
                                ? AppColors.primary
                                : AppColors.onPrimary,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.palette_outlined,
                            size: AppDimensions.iconM,
                            color: isDark
                                ? AppColors.onPrimary
                                : AppColors.primary,
                          ),
                        ),
                        const SizedBox(width: AppDimensions.spaceM),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                AppStrings.profileThemeModePickerTitle,
                                style: textTheme.titleMedium?.copyWith(
                                  color: titleColor,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: AppDimensions.spaceXXS),
                              Text(
                                '${AppStrings.profileThemeMode}: ${_themePreferenceLabel(themeController)}',
                                style: textTheme.bodySmall?.copyWith(
                                  color: subtitleColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AppDimensions.spaceM),
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    AppDimensions.spaceM,
                    0,
                    AppDimensions.spaceM,
                    AppDimensions.spaceM + bottomPadding,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      option(
                        AppThemePreference.light,
                        title: AppStrings.profileThemeLight,
                        subtitle: AppStrings.profileThemeLightSubtitle,
                        icon: Icons.wb_sunny_rounded,
                      ),
                      option(
                        AppThemePreference.dark,
                        title: AppStrings.profileThemeDark,
                        subtitle: AppStrings.profileThemeDarkSubtitle,
                        icon: Icons.dark_mode_rounded,
                      ),
                      option(
                        AppThemePreference.schedule,
                        title: AppStrings.profileThemeSchedule,
                        subtitle: AppStrings.profileThemeScheduleSubtitle,
                        icon: Icons.schedule_rounded,
                      ),
                      option(
                        AppThemePreference.sensor,
                        title: AppStrings.profileThemeSensor,
                        subtitle: AppStrings.profileThemeSensorSubtitle,
                        iconLabel: 'A',
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (selected == null) {
      return;
    }

    await themeController.setPreference(selected);
  }

  Future<void> _handleNotificationsToggle(bool value) async {
    setState(() {
      _notificationsEnabled = value;
    });
    await _preferencesService.setNotificationsEnabled(value);
  }

  Future<void> _handleSignOut() async {
    try {
      await _authService.signOut();

      if (!mounted) {
        return;
      }

      Navigator.of(
        context,
        rootNavigator: true,
      ).pushNamedAndRemoveUntil(Routes.authGate, (route) => false);
    } catch (_) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(AppStrings.profileSignOutError)),
      );
    }
  }

  Future<void> _goToAddPet() async {
    final result = await Navigator.pushNamed(context, Routes.addPet);
    if (!mounted || result != true) {
      return;
    }
    await _loadProfile();
    if (_profile != null) {
      await _telemetryService.logAddPetExecutionIfPending(
        endTime: DateTime.now(),
      );
    }
  }

  void _goToAddVaccine() {
    Navigator.of(context).pushNamed(Routes.addVaccine);
  }

  void _goToAddEvent() {
    _showUnavailableMessage();
  }

  String _displayValue(String? value) {
    final trimmed = value?.trim() ?? '';
    return trimmed.isEmpty ? AppStrings.valueNotAvailable : trimmed;
  }

  String _displayInitials(UserProfile? profile) {
    final rawInitials = profile?.initials.trim() ?? '';
    if (rawInitials.isNotEmpty) {
      return rawInitials;
    }

    final rawName = profile?.name.trim() ?? '';
    if (rawName.isNotEmpty) {
      return rawName.substring(0, 1).toUpperCase();
    }

    return '?';
  }

  String _themePreferenceLabel(ThemeController themeController) {
    return switch (themeController.preference) {
      AppThemePreference.light => AppStrings.profileThemeLight,
      AppThemePreference.dark => AppStrings.profileThemeDark,
      AppThemePreference.schedule => AppStrings.profileThemeSchedule,
      AppThemePreference.sensor => AppStrings.profileThemeSensor,
    };
  }

  String _themePreferenceSubtitle(ThemeController themeController) {
    return switch (themeController.preference) {
      AppThemePreference.light => AppStrings.profileThemeSummaryLight,
      AppThemePreference.dark => AppStrings.profileThemeSummaryDark,
      AppThemePreference.schedule => AppStrings.profileThemeSummaryByTime,
      AppThemePreference.sensor =>
        themeController.activeThemeSource == ThemeSource.ambientLight
            ? AppStrings.profileThemeSummaryAuto
            : AppStrings.profileThemeSummaryAutoFallback,
    };
  }

  @override
  Widget build(BuildContext context) {
    final themeController = ThemeControllerScope.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.background,
      body: SingleChildScrollView(
        child: Column(
          children: [
            if (_isLoadingProfile) const LinearProgressIndicator(),
            // Profile Header
            ProfileHeader(
              initials: _displayInitials(_profile),
              userName: _displayValue(_profile?.name),
              userEmail: _displayValue(_profile?.email),
              petCount: _profile?.petCount ?? 0,
              localPhotoPath: _localPhotoPath,
              remotePhotoUrl: _profile?.profilePhoto,
              onEditTap: _handleEditProfile,
            ),
            SizedBox(height: AppDimensions.spaceL),

            // Account Section
            Padding(
              padding: const EdgeInsets.only(
                left: AppDimensions.pageHorizontalPadding,
                right: AppDimensions.pageHorizontalPadding,
                bottom: AppDimensions.spaceS,
              ),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  AppStrings.profileSubtitleAccount.toUpperCase(),
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: isDark
                        ? AppColors.onSurfaceDark
                        : AppColors.onSurface,
                    fontWeight: FontWeight.w600,
                    letterSpacing: AppDimensions.letterSpacingSection,
                  ),
                ),
              ),
            ),
            Container(
              margin: const EdgeInsets.symmetric(
                horizontal: AppDimensions.pageHorizontalPadding,
              ),
              decoration: BoxDecoration(
                color: isDark ? AppColors.secondaryDark : AppColors.secondary,
                borderRadius: BorderRadius.circular(AppDimensions.radiusL),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ProfileMenuItem(
                    imageAssetPath: AppAssets.iconProfileUser,
                    title: AppStrings.profileEdit,
                    subtitle: _displayValue(_profile?.name),
                    onTap: _handleEditProfile,
                    isDark: isDark,
                  ),
                  Divider(
                    height: AppDimensions.strokeThin,
                    indent:
                        AppDimensions.pageHorizontalPadding +
                        AppDimensions.iconListItem +
                        AppDimensions.spaceL,
                    color: isDark ? AppColors.grey500 : AppColors.grey100,
                  ),
                  ProfileMenuItem(
                    imageAssetPath: AppAssets.iconProfileMail,
                    title: AppStrings.profileEmail,
                    subtitle: _displayValue(_profile?.email),
                    isDark: isDark,
                  ),
                  Divider(
                    height: AppDimensions.strokeThin,
                    indent:
                        AppDimensions.pageHorizontalPadding +
                        AppDimensions.iconListItem +
                        AppDimensions.spaceL,
                    color: isDark ? AppColors.grey500 : AppColors.grey100,
                  ),
                  ProfileMenuItem(
                    imageAssetPath: AppAssets.iconProfilePhone,
                    title: AppStrings.profilePhone,
                    subtitle: _displayValue(_profile?.phone),
                    isDark: isDark,
                  ),
                ],
              ),
            ),
            SizedBox(height: AppDimensions.spaceL),

            // Preferences Section
            Padding(
              padding: const EdgeInsets.only(
                left: AppDimensions.pageHorizontalPadding,
                right: AppDimensions.pageHorizontalPadding,
                bottom: AppDimensions.spaceS,
              ),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  AppStrings.profileSubtitlePreferences.toUpperCase(),
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: isDark
                        ? AppColors.onSurfaceDark
                        : AppColors.onSurface,
                    fontWeight: FontWeight.w600,
                    letterSpacing: AppDimensions.letterSpacingSection,
                  ),
                ),
              ),
            ),
            Container(
              margin: const EdgeInsets.symmetric(
                horizontal: AppDimensions.pageHorizontalPadding,
              ),
              decoration: BoxDecoration(
                color: isDark ? AppColors.secondaryDark : AppColors.secondary,
                borderRadius: BorderRadius.circular(AppDimensions.radiusL),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ProfileMenuItem(
                    imageAssetPath: AppAssets.iconProfileDarkMode,
                    title: AppStrings.profileThemeMode,
                    subtitle:
                        '${_themePreferenceLabel(themeController)} • ${_themePreferenceSubtitle(themeController)}',
                    onTap: _showThemeModePicker,
                    isDark: isDark,
                  ),
                  Divider(
                    height: AppDimensions.strokeThin,
                    indent:
                        AppDimensions.pageHorizontalPadding +
                        AppDimensions.iconListItem +
                        AppDimensions.spaceL,
                    color: isDark ? AppColors.grey500 : AppColors.grey100,
                  ),
                  ProfileToggleItem(
                    imageAssetPath: AppAssets.iconProfileNotifications,
                    title: AppStrings.profileNotifications,
                    subtitle: _notificationsEnabled
                        ? AppStrings.stateEnabled
                        : AppStrings.stateDisabled,
                    value: _notificationsEnabled,
                    onChanged: _handleNotificationsToggle,
                    isDark: isDark,
                  ),
                ],
              ),
            ),
            SizedBox(height: AppDimensions.spaceL),

            // Support Section
            Padding(
              padding: const EdgeInsets.only(
                left: AppDimensions.pageHorizontalPadding,
                right: AppDimensions.pageHorizontalPadding,
                bottom: AppDimensions.spaceS,
              ),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  AppStrings.profileSubtitleSupport.toUpperCase(),
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: isDark
                        ? AppColors.onSurfaceDark
                        : AppColors.onSurface,
                    fontWeight: FontWeight.w600,
                    letterSpacing: AppDimensions.letterSpacingSection,
                  ),
                ),
              ),
            ),
            Container(
              margin: const EdgeInsets.symmetric(
                horizontal: AppDimensions.pageHorizontalPadding,
              ),
              decoration: BoxDecoration(
                color: isDark ? AppColors.secondaryDark : AppColors.secondary,
                borderRadius: BorderRadius.circular(AppDimensions.radiusL),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ProfileMenuItem(
                    imageAssetPath: AppAssets.iconProfileSignOut,
                    title: AppStrings.profileSignOut,
                    onTap: _handleSignOut,
                    isDestructive: true,
                    isDark: isDark,
                  ),
                ],
              ),
            ),
            SizedBox(height: AppDimensions.spaceXXL),
          ],
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton: QuickActionsFab(
        onAddPet: _goToAddPet,
        onAddVaccine: _goToAddVaccine,
        onAddEvent: _goToAddEvent,
      ),
      bottomNavigationBar: PetcareBottomNavBar(
        currentIndex: _currentIndex,
        onTap: _handleBottomNavTap,
      ),
    );
  }
}
