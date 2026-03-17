import 'package:flutter/material.dart';
import 'package:flutter_frontend/core/constants/app_assets.dart';
import 'package:flutter_frontend/core/constants/app_colors.dart';
import 'package:flutter_frontend/core/constants/app_dimensions.dart';
import 'package:flutter_frontend/core/constants/app_strings.dart';
import 'package:flutter_frontend/core/models/user_profile.dart';
import 'package:flutter_frontend/core/network/api_exception.dart';
import 'package:flutter_frontend/core/services/auth_service.dart';
import 'package:flutter_frontend/core/services/user_service.dart';
import 'package:flutter_frontend/app/routes.dart';
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

  // Navigation
  static const _currentIndex = 4;

  // User profile
  UserProfile? _profile;
  bool _isLoadingProfile = false;

  // Preference states
  late bool _darkModeEnabled;
  late bool _notificationsEnabled;
  late bool _offlineModeEnabled;

  @override
  void initState() {
    super.initState();
    _darkModeEnabled = false;
    _notificationsEnabled = true;
    _offlineModeEnabled = false;
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() => _isLoadingProfile = true);
    try {
      final profile = await UserService().getCurrentUser();
      if (mounted) setState(() => _profile = profile);
    } on ApiException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.message)),
        );
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

  void _handleEditProfile() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text(AppStrings.featureUnavailable)),
    );
  }

  void _handleDarkModeToggle(bool value) {
    setState(() {
      _darkModeEnabled = value;
    });
    // TODO: Implement theme switching logic
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

      Navigator.of(context, rootNavigator: true).popUntil((route) => route.isFirst);
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

  @override
  Widget build(BuildContext context) {
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
                    indent: AppDimensions.pageHorizontalPadding + AppDimensions.iconListItem + AppDimensions.spaceL,
                    color: AppColors.grey100,
                  ),
                  ProfileMenuItem(
                    imageAssetPath: AppAssets.iconProfileMail,
                    title: AppStrings.profileEmail,
                    subtitle: _displayValue(_profile?.email),
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(_displayValue(_profile?.email))),
                      );
                    },
                  ),
                  Divider(
                    height: AppDimensions.strokeThin,
                    indent: AppDimensions.pageHorizontalPadding + AppDimensions.iconListItem + AppDimensions.spaceL,
                    color: AppColors.grey100,
                  ),
                  ProfileMenuItem(
                    imageAssetPath: AppAssets.iconProfilePhone,
                    title: AppStrings.profilePhone,
                    subtitle: _displayValue(_profile?.phone),
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(_displayValue(_profile?.phone))),
                      );
                    },
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
                  ProfileToggleItem(
                    imageAssetPath: AppAssets.iconProfileDarkMode,
                    title: AppStrings.profileDarkMode,
                    value: _darkModeEnabled,
                    onChanged: _handleDarkModeToggle,
                  ),
                  Divider(
                    height: AppDimensions.strokeThin,
                    indent: AppDimensions.pageHorizontalPadding + AppDimensions.iconListItem + AppDimensions.spaceL,
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
                    indent: AppDimensions.pageHorizontalPadding + AppDimensions.iconListItem + AppDimensions.spaceL,
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
