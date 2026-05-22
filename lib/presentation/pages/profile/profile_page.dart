import 'package:flutter/material.dart';
import 'package:flutter_frontend/core/constants/app_assets.dart';
import 'package:flutter_frontend/core/constants/app_colors.dart';
import 'package:flutter_frontend/core/constants/app_dimensions.dart';
import 'package:flutter_frontend/core/constants/app_strings.dart';
import 'package:flutter_frontend/core/models/user_profile.dart';
import 'package:flutter_frontend/core/network/api_exception.dart';
import 'package:flutter_frontend/core/services/app_preferences_service.dart';
import 'package:flutter_frontend/core/services/auth_service.dart';
import 'package:flutter_frontend/core/services/connectivity_sync_service.dart';
import 'package:flutter_frontend/core/services/local_database_service.dart';
import 'package:flutter_frontend/core/services/profile_photo_service.dart';
import 'package:flutter_frontend/core/services/sync_retry_service.dart';
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
  final ConnectivitySyncService _connectivitySyncService =
      ConnectivitySyncService();
  final LocalDatabaseService _localDatabaseService = LocalDatabaseService();
  final ProfilePhotoService _photoService = ProfilePhotoService();
  final UserService _userService = UserService();
  final TelemetryService _telemetryService = TelemetryService();

  // Navigation
  static const _currentIndex = 4;

  // User profile
  UserProfile? _profile;
  String? _localPhotoPath;
  bool _isLoadingProfile = false;
  SyncQueueSummary? _syncQueueSummary;
  bool _isLoadingSyncQueueSummary = false;
  

  // Preference states
  late bool _notificationsEnabled;

  @override
  void initState() {
    super.initState();
    _notificationsEnabled = true;
    _loadPreferences();
    _loadProfile();
    _loadSyncQueueSummary();
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

  Future<void> _loadSyncQueueSummary() async {
    if (mounted) {
      setState(() => _isLoadingSyncQueueSummary = true);
    }

    try {
      final summary = await _localDatabaseService.getSyncQueueSummary();
      if (!mounted) {
        return;
      }

      setState(() {
        _syncQueueSummary = summary;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _syncQueueSummary = null;
      });
    } finally {
      if (mounted) {
        setState(() => _isLoadingSyncQueueSummary = false);
      }
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

  void _goToAddMedicine() {
    Navigator.of(context).pushNamed(Routes.addMedicine);
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

  String _queueSummarySubtitle() {
    if (_isLoadingSyncQueueSummary) {
      return AppStrings.profileQueueLoading;
    }

    final summary = _syncQueueSummary;
    if (summary == null) {
      return AppStrings.profileQueueLoadError;
    }

    return summary.isEmpty
        ? AppStrings.profileQueueEmpty
        : summary.overallStatus;
  }

  Future<_SyncQueueDetails> _loadSyncQueueDetails() async {
    final summary = await _localDatabaseService.getSyncQueueSummary();
    final pendingOperations = await _localDatabaseService.getPendingSyncOperations(
      limit: 20,
    );
    final failedOperations = await _localDatabaseService.getFailedSyncOperations(
      limit: 20,
    );

    return _SyncQueueDetails(
      summary: summary,
      pendingOperations: pendingOperations,
      failedOperations: failedOperations,
    );
  }

  Future<void> _retrySyncQueueAndRefresh() async {
    final hasInternet = await _connectivitySyncService.hasInternetAccess();
    if (!hasInternet) {
      throw StateError(AppStrings.profileQueueRetryNoInternet);
    }

    await SyncRetryService().retryPendingWrites();

    if (!mounted) {
      return;
    }

    await _loadSyncQueueSummary();
  }

  Future<void> _forceRetryFailedSyncQueueAndRefresh() async {
    final hasInternet = await _connectivitySyncService.hasInternetAccess();
    if (!hasInternet) {
      throw StateError(AppStrings.profileQueueRetryNoInternet);
    }

    final failedOperations = await _localDatabaseService.getFailedSyncOperations(
      limit: 20,
    );

    if (failedOperations.isEmpty) {
      throw StateError(AppStrings.profileQueueRetryFailedEmpty);
    }

    await _localDatabaseService.resetSyncOperationRetries(
      failedOperations.map((operation) => operation.id),
    );

    await SyncRetryService().retryPendingWrites();

    if (!mounted) {
      return;
    }

    await _loadSyncQueueSummary();
  }

  Future<void> _clearSyncQueueAndRefresh() async {
    await _localDatabaseService.clearSyncQueue();
    if (!mounted) {
      return;
    }

    await _loadSyncQueueSummary();
  }

  Future<void> _showSyncQueueDetails() async {
    final details = await _loadSyncQueueDetails();
    if (!mounted) {
      return;
    }

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        final isDark = Theme.of(dialogContext).brightness == Brightness.dark;
        var summary = details.summary;
        var pendingOperations = details.pendingOperations;
        var failedOperations = details.failedOperations;
        var isRetryingPending = false;
        var isRetryingFailed = false;

        Future<void> retryPendingAndRefresh(StateSetter setDialogState) async {
          if (isRetryingPending) {
            return;
          }

          setDialogState(() => isRetryingPending = true);
          try {
            await _retrySyncQueueAndRefresh();
            final refreshed = await _loadSyncQueueDetails();
            if (!mounted) {
              return;
            }

            setDialogState(() {
              summary = refreshed.summary;
              pendingOperations = refreshed.pendingOperations;
              failedOperations = refreshed.failedOperations;
            });
          } on StateError catch (error) {
            if (!mounted) {
              return;
            }

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(error.message)),
            );
          } catch (_) {
            if (!mounted) {
              return;
            }

            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(AppStrings.profileQueueRetryFailure),
              ),
            );
          } finally {
            if (mounted) {
              setDialogState(() => isRetryingPending = false);
            }
          }
        }

        Future<void> forceRetryFailedAndRefresh(StateSetter setDialogState) async {
          if (isRetryingFailed) {
            return;
          }

          setDialogState(() => isRetryingFailed = true);
          try {
            await _forceRetryFailedSyncQueueAndRefresh();
            final refreshed = await _loadSyncQueueDetails();
            if (!mounted) {
              return;
            }

            setDialogState(() {
              summary = refreshed.summary;
              pendingOperations = refreshed.pendingOperations;
              failedOperations = refreshed.failedOperations;
            });
          } on StateError catch (error) {
            if (!mounted) {
              return;
            }

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(error.message)),
            );
          } catch (_) {
            if (!mounted) {
              return;
            }

            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(AppStrings.profileQueueRetryFailure),
              ),
            );
          } finally {
            if (mounted) {
              setDialogState(() => isRetryingFailed = false);
            }
          }
        }

        Future<void> confirmClearAllAndRefresh(StateSetter setDialogState) async {
          final shouldClear = await showDialog<bool>(
            context: dialogContext,
            builder: (confirmContext) {
              return AlertDialog(
                title: const Text(AppStrings.profileQueueClearAllTitle),
                content: const Text(AppStrings.profileQueueClearAllMessage),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(confirmContext).pop(false),
                    child: const Text('Cancel'),
                  ),
                  FilledButton(
                    onPressed: () => Navigator.of(confirmContext).pop(true),
                    child: const Text(AppStrings.profileQueueClearAllConfirm),
                  ),
                ],
              );
            },
          );

          if (shouldClear != true) {
            return;
          }

          setDialogState(() => isRetryingPending = true);
          setDialogState(() => isRetryingFailed = true);
          try {
            await _clearSyncQueueAndRefresh();
            final refreshed = await _loadSyncQueueDetails();
            if (!mounted) {
              return;
            }

            setDialogState(() {
              summary = refreshed.summary;
              pendingOperations = refreshed.pendingOperations;
              failedOperations = refreshed.failedOperations;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text(AppStrings.profileQueueClearAll)),
            );
          } catch (_) {
            if (!mounted) {
              return;
            }

            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text(AppStrings.profileQueueRetryFailure)),
            );
          } finally {
            if (mounted) {
              setDialogState(() => isRetryingPending = false);
              setDialogState(() => isRetryingFailed = false);
            }
          }
        }

        Widget countChip(String label, int value) {
          return Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimensions.spaceM,
              vertical: AppDimensions.spaceS,
            ),
            decoration: BoxDecoration(
              color: isDark ? AppColors.backgroundDark : AppColors.grey100,
              borderRadius: BorderRadius.circular(AppDimensions.radiusL),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: isDark ? AppColors.grey300 : AppColors.grey700,
                  ),
                ),
                const SizedBox(height: AppDimensions.spaceXS),
                Text(
                  '$value',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: isDark ? AppColors.onSurfaceDark : AppColors.onSurface,
                  ),
                ),
              ],
            ),
          );
        }

        return StatefulBuilder(
          builder: (context, setDialogState) {
            Widget circularActionButton({
              required VoidCallback? onPressed,
              required IconData icon,
              required String tooltip,
              required Color backgroundColor,
              required Color foregroundColor,
              Widget? loadingChild,
            }) {
              final isDisabled = onPressed == null;

              return Semantics(
                button: true,
                label: tooltip,
                child: Tooltip(
                  message: tooltip,
                  child: Material(
                    color: backgroundColor,
                    shape: const CircleBorder(),
                    clipBehavior: Clip.antiAlias,
                    child: InkWell(
                      onTap: isDisabled ? null : onPressed,
                      customBorder: const CircleBorder(),
                      child: SizedBox(
                        width: 40,
                        height: 40,
                        child: Center(
                          child: loadingChild ??
                              Icon(
                                icon,
                                size: AppDimensions.iconM,
                                color: foregroundColor,
                              ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }

            return AlertDialog(
              title: Row(
                children: [
                  Expanded(
                    child: Text(
                      AppStrings.profileQueueDetailsTitle,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: isRetryingPending || isRetryingFailed
                        ? null
                        : () => Navigator.of(dialogContext).pop(),
                    icon: const Icon(Icons.close_rounded),
                    tooltip: 'Close',
                  ),
                ],
              ),
              content: SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 360),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(AppStrings.profileQueueDetailsSubtitle),
                      const SizedBox(height: AppDimensions.spaceL),
                      Wrap(
                        spacing: AppDimensions.spaceS,
                        runSpacing: AppDimensions.spaceS,
                        children: [
                            countChip(
                              AppStrings.profileQueueDetailsTotal,
                              summary.totalCount,
                            ),
                            countChip(
                              AppStrings.profileQueueDetailsPending,
                              summary.pendingCount,
                            ),
                            countChip(
                              AppStrings.profileQueueDetailsRetrying,
                              summary.retryingCount,
                            ),
                            countChip(
                              AppStrings.profileQueueDetailsFailed,
                              summary.failedCount,
                            ),
                        ],
                      ),
                      const SizedBox(height: AppDimensions.spaceL),
                      Text(
                        AppStrings.profileQueueDetailsOperations,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: AppDimensions.spaceS),
                      if (pendingOperations.isEmpty)
                        Text(AppStrings.profileQueueEmpty)
                      else
                        ...pendingOperations.map(
                          (operation) => Padding(
                            padding: const EdgeInsets.only(bottom: AppDimensions.spaceS),
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(AppDimensions.spaceM),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? AppColors.secondaryDark
                                    : AppColors.grey100,
                                borderRadius: BorderRadius.circular(AppDimensions.radiusL),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${operation.entityType} · ${operation.action}',
                                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: AppDimensions.spaceXS),
                                  Text(
                                    '${AppStrings.profileQueueDetailsEntity}: ${operation.entityId}\n'
                                    '${AppStrings.profileQueueDetailsRetries}: ${operation.retryCount}',
                                    style: Theme.of(context).textTheme.bodySmall,
                                  ),
                                  if (operation.lastError != null && operation.lastError!.trim().isNotEmpty) ...[
                                    const SizedBox(height: AppDimensions.spaceXS),
                                    Text(
                                      '${AppStrings.profileQueueDetailsLastError}: ${operation.lastError}',
                                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                        color: AppColors.error,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        ),
                      const SizedBox(height: AppDimensions.spaceM),
                      Text(
                        AppStrings.profileQueueDetailsFailedOperations,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: AppDimensions.spaceS),
                      if (failedOperations.isEmpty)
                        Text(AppStrings.profileQueueRetryFailedEmpty)
                      else
                        ...failedOperations.map(
                          (operation) => Padding(
                            padding: const EdgeInsets.only(bottom: AppDimensions.spaceS),
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(AppDimensions.spaceM),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? AppColors.secondaryDark
                                    : AppColors.grey100,
                                borderRadius: BorderRadius.circular(AppDimensions.radiusL),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${operation.entityType} · ${operation.action}',
                                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: AppDimensions.spaceXS),
                                  Text(
                                    '${AppStrings.profileQueueDetailsEntity}: ${operation.entityId}\n'
                                    '${AppStrings.profileQueueDetailsRetries}: ${operation.retryCount}',
                                    style: Theme.of(context).textTheme.bodySmall,
                                  ),
                                  if (operation.lastError != null && operation.lastError!.trim().isNotEmpty) ...[
                                    const SizedBox(height: AppDimensions.spaceXS),
                                    Text(
                                      '${AppStrings.profileQueueDetailsLastError}: ${operation.lastError}',
                                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                        color: AppColors.error,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              actions: [
                SizedBox(
                  width: double.maxFinite,
                  child: Wrap(
                    alignment: WrapAlignment.center,
                    spacing: AppDimensions.spaceS,
                    runSpacing: AppDimensions.spaceS,
                    children: [
                      circularActionButton(
                        onPressed: isRetryingPending
                            ? null
                            : () => retryPendingAndRefresh(setDialogState),
                        icon: Icons.sync_rounded,
                        tooltip: AppStrings.profileQueueRetry,
                        backgroundColor: AppColors.primary,
                        foregroundColor: AppColors.onPrimary,
                        loadingChild: isRetryingPending
                            ? const SizedBox(
                                width: AppDimensions.iconS,
                                height: AppDimensions.iconS,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : null,
                      ),
                      FilledButton.tonalIcon(
                        onPressed: isRetryingFailed
                            ? null
                            : () => forceRetryFailedAndRefresh(setDialogState),
                        icon: isRetryingFailed
                            ? const SizedBox(
                                width: AppDimensions.iconS,
                                height: AppDimensions.iconS,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.refresh_rounded),
                        label: const Text(AppStrings.profileQueueForceRetryFailed),
                      ),
                      circularActionButton(
                        onPressed: (isRetryingPending || isRetryingFailed)
                            ? null
                            : () => confirmClearAllAndRefresh(setDialogState),
                        icon: Icons.delete_outline_rounded,
                        tooltip: AppStrings.profileQueueClearAll,
                        backgroundColor: AppColors.error,
                        foregroundColor: AppColors.onPrimary,
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        );
      },
    );
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
                    icon: Icons.sync_rounded,
                    title: AppStrings.profileQueue,
                    subtitle: _queueSummarySubtitle(),
                    onTap: _showSyncQueueDetails,
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
        onAddMedicine: _goToAddMedicine,
      ),
      bottomNavigationBar: PetcareBottomNavBar(
        currentIndex: _currentIndex,
        onTap: _handleBottomNavTap,
      ),
    );
  }
}

class _SyncQueueDetails {
  const _SyncQueueDetails({
    required this.summary,
    required this.pendingOperations,
    required this.failedOperations,
  });

  final SyncQueueSummary summary;
  final List<SyncQueueOperation> pendingOperations;
  final List<SyncQueueOperation> failedOperations;
}
