import 'package:flutter/material.dart';
import 'package:flutter_frontend/core/constants/app_assets.dart';
import 'package:flutter_frontend/core/constants/app_colors.dart';
import 'package:flutter_frontend/core/constants/app_dimensions.dart';
import 'package:flutter_frontend/core/constants/app_strings.dart';
import 'package:flutter_frontend/core/models/user_profile.dart';
import 'package:flutter_frontend/core/network/api_exception.dart';
import 'package:flutter_frontend/core/services/auth_service.dart';
import 'package:flutter_frontend/core/services/profile_photo_service.dart';
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
  final AuthService _authService = AuthService();
  final ProfilePhotoService _photoService = ProfilePhotoService();
  final UserService _userService = UserService();

  // Navigation
  static const _currentIndex = 4;

  // User profile
  UserProfile? _profile;
  String? _localPhotoPath;
  bool _isLoadingProfile = false;

  // Preference states
  late bool _notificationsEnabled;
  late bool _offlineModeEnabled;

  @override
  void initState() {
    super.initState();
    _notificationsEnabled = true;
    _offlineModeEnabled = false;
    _loadProfile();
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
      showDragHandle: true,
      builder: (context) {
        final currentPreference = themeController.preference;

        Widget option(
          AppThemePreference preference, {
          required String title,
          String? subtitle,
        }) {
          return ListTile(
            title: Text(title),
            subtitle: subtitle == null ? null : Text(subtitle),
            trailing: preference == currentPreference
                ? const Icon(Icons.check, color: AppColors.primary)
                : null,
            onTap: () => Navigator.of(context).pop(preference),
          );
        }

        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: Text(
                  AppStrings.profileThemeModePickerTitle,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
              option(
                AppThemePreference.light,
                title: AppStrings.profileThemeLight,
                subtitle: AppStrings.profileThemeLightSubtitle,
              ),
              option(
                AppThemePreference.dark,
                title: AppStrings.profileThemeDark,
                subtitle: AppStrings.profileThemeDarkSubtitle,
              ),
              option(
                AppThemePreference.schedule,
                title: AppStrings.profileThemeSchedule,
                subtitle: AppStrings.profileThemeScheduleSubtitle,
              ),
              option(
                AppThemePreference.sensor,
                title: AppStrings.profileThemeSensor,
                subtitle: AppStrings.profileThemeSensorSubtitle,
              ),
            ],
          ),
        );
      },
    );

    if (selected == null) {
      return;
    }

    await themeController.setPreference(selected);
  }

  void _handleNotificationsToggle(bool value) {
    setState(() {
      _notificationsEnabled = value;
    });
    // TODO: Implement notifications preference storage
  }

  void _handleOfflineModeToggle(bool value) {
    setState(() {
      _offlineModeEnabled = value;
    });
    // TODO: Implement offline mode logic
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

  void _goToAddPet() {
    Navigator.pushNamed(context, Routes.addPet);
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

  String? _emailValidator(String? value) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) {
      return AppStrings.validationRequired;
    }

    final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    if (!emailRegex.hasMatch(trimmed)) {
      return AppStrings.authErrorInvalidEmail;
    }

    return null;
  }

  String? _phoneValidator(String? value) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) {
      return AppStrings.validationRequired;
    }
    return null;
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

  Future<String?> _showSingleFieldEditor({
    required String title,
    required String initialValue,
    required TextInputType keyboardType,
    required String? Function(String?) validator,
  }) async {
    final controller = TextEditingController(text: initialValue);
    String? errorText;

    final result = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (_, setDialogState) {
            void saveIfValid() {
              final value = controller.text.trim();
              final validationError = validator(value);
              if (validationError != null) {
                setDialogState(() => errorText = validationError);
                return;
              }

              Navigator.of(dialogContext).pop(value);
            }

            return AlertDialog(
              title: Text(title),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextField(
                    controller: controller,
                    keyboardType: keyboardType,
                    autofocus: true,
                    onChanged: (_) {
                      if (errorText != null) {
                        setDialogState(() => errorText = null);
                      }
                    },
                    decoration: InputDecoration(
                      hintText: title,
                      errorText: errorText,
                      filled: true,
                      fillColor: AppColors.secondary,
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: AppDimensions.spaceM),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: saveIfValid,
                      child: const Text(AppStrings.semanticSaveButton),
                    ),
                  ),
                  Center(
                    child: TextButton(
                      onPressed: () => Navigator.of(dialogContext).pop(),
                      child: const Text(AppStrings.nfcCancel),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.dispose();
    });
    return result;
  }

  Future<void> _updateContactData({String? email, String? phone}) async {
    final currentProfile = _profile;
    if (currentProfile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(AppStrings.profileLoadError)),
      );
      return;
    }

    setState(() => _isLoadingProfile = true);
    try {
      final updated = await _userService.updateCurrentUser(
        name: currentProfile.name,
        email: email ?? currentProfile.email,
        phone: phone ?? currentProfile.phone,
        address: currentProfile.address,
        profilePhoto: currentProfile.profilePhoto,
      );

      if (!mounted) {
        return;
      }

      setState(() => _profile = updated);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(AppStrings.profileSaveSuccess)),
      );
    } on ApiException catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
    } catch (_) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(AppStrings.profileSaveError)),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoadingProfile = false);
      }
    }
  }

  Future<void> _handleQuickEditEmail() async {
    final currentProfile = _profile;
    if (currentProfile == null) {
      return;
    }

    final updatedEmail = await _showSingleFieldEditor(
      title: AppStrings.profileEmail,
      initialValue: currentProfile.email,
      keyboardType: TextInputType.emailAddress,
      validator: _emailValidator,
    );

    if (updatedEmail == null || updatedEmail == currentProfile.email.trim()) {
      return;
    }

    await _updateContactData(email: updatedEmail);
  }

  Future<void> _handleQuickEditPhone() async {
    final currentProfile = _profile;
    if (currentProfile == null) {
      return;
    }

    final updatedPhone = await _showSingleFieldEditor(
      title: AppStrings.profilePhone,
      initialValue: currentProfile.phone,
      keyboardType: TextInputType.phone,
      validator: _phoneValidator,
    );

    if (updatedPhone == null || updatedPhone == currentProfile.phone.trim()) {
      return;
    }

    await _updateContactData(phone: updatedPhone);
  }

  @override
  Widget build(BuildContext context) {
    final themeController = ThemeControllerScope.of(context);

    return Scaffold(
      backgroundColor: AppColors.background,
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
                    color: AppColors.onSurface,
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
                color: AppColors.secondary,
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
                  ),
                  Divider(
                    height: AppDimensions.strokeThin,
                    indent:
                        AppDimensions.pageHorizontalPadding +
                        AppDimensions.iconListItem +
                        AppDimensions.spaceL,
                    color: AppColors.grey100,
                  ),
                  ProfileMenuItem(
                    imageAssetPath: AppAssets.iconProfileMail,
                    title: AppStrings.profileEmail,
                    subtitle: _displayValue(_profile?.email),
                    onTap: _handleQuickEditEmail,
                  ),
                  Divider(
                    height: AppDimensions.strokeThin,
                    indent:
                        AppDimensions.pageHorizontalPadding +
                        AppDimensions.iconListItem +
                        AppDimensions.spaceL,
                    color: AppColors.grey100,
                  ),
                  ProfileMenuItem(
                    imageAssetPath: AppAssets.iconProfilePhone,
                    title: AppStrings.profilePhone,
                    subtitle: _displayValue(_profile?.phone),
                    onTap: _handleQuickEditPhone,
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
                    color: AppColors.onSurface,
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
                color: AppColors.secondary,
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
                  ),
                  Divider(
                    height: AppDimensions.strokeThin,
                    indent:
                        AppDimensions.pageHorizontalPadding +
                        AppDimensions.iconListItem +
                        AppDimensions.spaceL,
                    color: AppColors.grey100,
                  ),
                  ProfileToggleItem(
                    imageAssetPath: AppAssets.iconProfileNotifications,
                    title: AppStrings.profileNotifications,
                    subtitle: _notificationsEnabled
                        ? AppStrings.stateEnabled
                        : AppStrings.stateDisabled,
                    value: _notificationsEnabled,
                    onChanged: _handleNotificationsToggle,
                  ),
                  Divider(
                    height: AppDimensions.strokeThin,
                    indent:
                        AppDimensions.pageHorizontalPadding +
                        AppDimensions.iconListItem +
                        AppDimensions.spaceL,
                    color: AppColors.grey100,
                  ),
                  ProfileToggleItem(
                    imageAssetPath: AppAssets.iconProfileOffline,
                    title: AppStrings.profileOffline,
                    value: _offlineModeEnabled,
                    onChanged: _handleOfflineModeToggle,
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
                    color: AppColors.onSurface,
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
                color: AppColors.secondary,
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
