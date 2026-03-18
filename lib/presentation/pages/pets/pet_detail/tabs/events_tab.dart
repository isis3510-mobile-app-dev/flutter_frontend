import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../../../core/constants/app_assets.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_dimensions.dart';
import '../../../../../core/constants/app_strings.dart';
import '../../../../../core/models/event_model.dart';
import '../../models/pet_ui_model.dart';

class EventsTab extends StatelessWidget {
  const EventsTab({
    super.key,
    required this.pet,
    required this.events,
    required this.isLoading,
    required this.onRetry,
    required this.onAddEvent,
    required this.onOpenEvent,
    this.errorMessage,
  });

  final PetUiModel pet;
  final List<EventModel> events;
  final bool isLoading;
  final String? errorMessage;
  final VoidCallback onRetry;
  final VoidCallback onAddEvent;
  final ValueChanged<EventModel> onOpenEvent;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final petName = pet.name;

    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(
        AppDimensions.pageHorizontalPadding,
        AppDimensions.spaceM,
        AppDimensions.pageHorizontalPadding,
        88,
      ),
      itemCount: (events.isEmpty ? 2 : events.length + 1) + (errorMessage == null ? 0 : 1),
      separatorBuilder: (_, _) => const SizedBox(height: AppDimensions.spaceS),
      itemBuilder: (context, index) {
        if (errorMessage != null && index == 0) {
          return _EventsErrorCard(
            message: errorMessage!,
            onRetry: onRetry,
          );
        }

        final eventIndex = errorMessage == null ? index : index - 1;
        if (events.isEmpty && eventIndex == 0) {
          return _EmptyEventsCard(
            petName: petName,
            isDark: isDark,
          );
        }

        if ((events.isEmpty && eventIndex == 1) ||
            (events.isNotEmpty && eventIndex == events.length)) {
          return _AddEventButton(
            petName: petName,
            onTap: onAddEvent,
          );
        }

        return _EventCard(
          event: events[eventIndex],
          isDark: isDark,
          onTap: () => onOpenEvent(events[eventIndex]),
        );
      },
    );
  }
}

class _EventCard extends StatelessWidget {
  const _EventCard({
    required this.event,
    required this.isDark,
    required this.onTap,
  });

  final EventModel event;
  final bool isDark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cardColor = isDark ? AppColors.petCardBackgroundDark : Colors.white;
    final metaColor = isDark
        ? AppColors.onSurfaceDark.withValues(alpha: 0.75)
        : AppColors.grey700;
    final bodyColor = isDark ? AppColors.onSurfaceDark : AppColors.grey900;
    final titleColor = isDark ? AppColors.onSurfaceDark : AppColors.grey900;

    final title = event.title.trim().isNotEmpty
        ? event.title.trim()
        : AppStrings.valueNotAvailable;
    final provider = event.provider.trim().isNotEmpty
        ? event.provider.trim()
        : AppStrings.valueNotAvailable;
    final clinic = event.clinic.trim().isNotEmpty
        ? event.clinic.trim()
        : AppStrings.valueNotAvailable;
    final notes = event.description.trim().isNotEmpty
        ? event.description.trim()
        : AppStrings.valueNotAvailable;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppDimensions.radiusXL),
        onTap: onTap,
        child: Ink(
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(AppDimensions.radiusXL),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.16 : 0.05),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          padding: const EdgeInsets.all(AppDimensions.pageHorizontalPadding),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SvgPicture.asset(
                _eventIconAsset(event),
                width: 46,
                height: 46,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: titleColor,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        if (event.price != null) ...[
                          const SizedBox(width: 8),
                          Text(
                            '\$${event.price!.toStringAsFixed(0)}',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: titleColor,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$provider · $clinic',
                      style: TextStyle(
                        color: metaColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      _formatDate(event.date),
                      style: TextStyle(
                        color: metaColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      notes,
                      style: TextStyle(
                        color: bodyColor,
                        fontSize: 13,
                        height: 1.4,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (event.followUpDate != null) ...[
                      const SizedBox(height: AppDimensions.spaceS),
                      _FollowUpChip(date: _formatDate(event.followUpDate!)),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FollowUpChip extends StatelessWidget {
  const _FollowUpChip({required this.date});

  final String date;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: AppColors.addPetPhotoBackground,
        borderRadius: BorderRadius.circular(AppDimensions.radiusCircle),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.schedule_outlined,
            size: 15,
            color: AppColors.bottomNavActive,
          ),
          const SizedBox(width: 6),
          Text(
            'Follow-up: $date',
            style: const TextStyle(
              color: AppColors.bottomNavActive,
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyEventsCard extends StatelessWidget {
  const _EmptyEventsCard({
    required this.petName,
    required this.isDark,
  });

  final String petName;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final cardColor = isDark ? AppColors.petCardBackgroundDark : Colors.white;
    final textColor = isDark ? AppColors.onSurfaceDark : AppColors.grey900;
    final subtextColor = isDark
        ? AppColors.onSurfaceDark.withValues(alpha: 0.75)
        : AppColors.grey700;

    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(AppDimensions.radiusXL),
      ),
      padding: const EdgeInsets.all(AppDimensions.pageHorizontalPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'No medical events yet',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: textColor,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Add the first event for $petName to start building a real medical history.',
            style: TextStyle(
              color: subtextColor,
              fontSize: 13,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

class _EventsErrorCard extends StatelessWidget {
  const _EventsErrorCard({
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppDimensions.radiusXL),
        border: Border.all(
          color: AppColors.error.withValues(alpha: 0.24),
        ),
      ),
      padding: const EdgeInsets.all(AppDimensions.pageHorizontalPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Could not load events',
            style: TextStyle(
              color: AppColors.error,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            message,
            style: const TextStyle(
              color: AppColors.grey700,
              fontSize: 13,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 10),
          TextButton(
            onPressed: onRetry,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}

String _eventIconAsset(EventModel event) {
  final normalized = '${event.eventType} ${event.title}'.toLowerCase();
  if (normalized.contains('emergency') || normalized.contains('urgent')) {
    return AppAssets.iconEmergencyCheck;
  }
  if (normalized.contains('dental')) {
    return AppAssets.iconDentalCheck;
  }
  return AppAssets.iconVetCheck;
}

String _formatDate(DateTime date) {
  if (date.year < 2) {
    return AppStrings.valueNotAvailable;
  }

  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  return '${months[date.month - 1]} ${date.day}, ${date.year}';
}

class _AddEventButton extends StatelessWidget {
  const _AddEventButton({
    required this.petName,
    required this.onTap,
  });

  final String petName;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.bottomNavActive,
        side: const BorderSide(color: AppColors.bottomNavActive, width: 2),
        minimumSize: const Size.fromHeight(AppDimensions.buttonHeightL),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusCircle),
        ),
      ),
      onPressed: onTap,
      child: Text(
        '+ Add Medical Event',
        semanticsLabel: 'Add medical event for $petName',
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
    );
  }
}
