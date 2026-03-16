import 'package:flutter/material.dart';
import 'package:flutter_frontend/core/constants/app_colors.dart';
import 'package:flutter_frontend/core/constants/app_dimensions.dart';
import 'package:flutter_frontend/core/constants/app_strings.dart';
import 'package:flutter_frontend/core/services/auth_service.dart';
import 'package:flutter_frontend/app/routes.dart';
import 'package:flutter_frontend/shared/widgets/petcare_bottom_nav_bar.dart';
import 'package:flutter_frontend/shared/widgets/quick_actions_fab.dart';
import 'widgets/profile_header.dart';
import 'widgets/profile_menu_item.dart';
import 'widgets/profile_toggle_item.dart';

/// The User Profile Page displaying user information, preferences, and actions.
class ProfilePage extends StatefulWidget {
  const ProfilePage({Key? key}) : super(key: key);

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final AuthService _authService = AuthService();

  // Navigation
  static const _currentIndex = 4;

  // Mock user data
  final String _userName = 'Sarah Johnson';
  final String _userEmail = 'sarah.johnson@email.com';
  final String _userPhone = '+1 (555) 012-3456';
  final int _petCount = 3;

  // Preference states
  late bool _darkModeEnabled;
  late bool _notificationsEnabled;
  late bool _offlineModeEnabled;

  @override
  void initState() {
    super.initState();
    // Initialize preferences with default values
    _darkModeEnabled = false;
    _notificationsEnabled = true;
    _offlineModeEnabled = false;
  }

  void _showUnavailableMessage() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('This section is not available yet.')),
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
      const SnackBar(content: Text('Navigate to Edit Profile page')),
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
        const SnackBar(content: Text('Could not sign out. Please try again.')),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Profile Header
            ProfileHeader(
              initials: 'SJ',
              userName: _userName,
              userEmail: _userEmail,
              petCount: _petCount,
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
                        letterSpacing: 0.5,
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
                    imageAssetPath: 'assets/icons/profile/profile.png',
                    title: AppStrings.profileEdit,
                    subtitle: _userName,
                    onTap: _handleEditProfile,
                  ),
                  Divider(
                    height: 1,
                    indent: AppDimensions.pageHorizontalPadding + AppDimensions.iconL + 8 + AppDimensions.spaceL,
                    color: AppColors.grey100,
                  ),
                  ProfileMenuItem(
                    imageAssetPath: 'assets/icons/profile/mail.png',
                    title: AppStrings.profileEmail,
                    subtitle: _userEmail,
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Email: sarah.johnson@email.com')),
                      );
                    },
                  ),
                  Divider(
                    height: 1,
                    indent: AppDimensions.pageHorizontalPadding + AppDimensions.iconL + 8 + AppDimensions.spaceL,
                    color: AppColors.grey100,
                  ),
                  ProfileMenuItem(
                    imageAssetPath: 'assets/icons/profile/phone.png',
                    title: AppStrings.profilePhone,
                    subtitle: _userPhone,
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Phone: +1 (555) 012-3456')),
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
                        letterSpacing: 0.5,
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
                    imageAssetPath: 'assets/icons/profile/darkMode.png',
                    title: AppStrings.profileDarkMode,
                    value: _darkModeEnabled,
                    onChanged: _handleDarkModeToggle,
                  ),
                  Divider(
                    height: 1,
                    indent: AppDimensions.pageHorizontalPadding + AppDimensions.iconL + 8 + AppDimensions.spaceL,
                    color: AppColors.grey100,
                  ),
                  ProfileToggleItem(
                    imageAssetPath: 'assets/icons/profile/notifications.png',
                    title: AppStrings.profileNotifications,
                    subtitle: _notificationsEnabled ? AppStrings.profileNotificationsenabled : AppStrings.profileNotificationdisabled,
                    value: _notificationsEnabled,
                    onChanged: _handleNotificationsToggle,
                  ),
                  Divider(
                    height: 1,
                    indent: AppDimensions.pageHorizontalPadding + AppDimensions.iconL + 8 + AppDimensions.spaceL,
                    color: AppColors.grey100,
                  ),
                  ProfileToggleItem(
                    imageAssetPath: 'assets/icons/profile/offline.png',
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
                        letterSpacing: 0.5,
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
                    imageAssetPath: 'assets/icons/profile/signOut.png',
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
