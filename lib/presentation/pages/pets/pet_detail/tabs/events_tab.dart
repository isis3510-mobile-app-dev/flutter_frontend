import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_dimensions.dart';
import '../../models/pet_ui_model.dart';

class _MedicalEvent {
  const _MedicalEvent({
    required this.title,
    required this.iconAsset,
    required this.vet,
    required this.clinic,
    required this.date,
    required this.notes,
    this.cost,
    this.followUp,
  });

  final String title;
  final String iconAsset;
  final String vet;
  final String clinic;
  final String date;
  final String notes;
  final double? cost;
  final String? followUp;
}

const _mockEvents = [
  _MedicalEvent(
    title: 'Checkup',
    iconAsset: 'assets/icons/eventsIcons/vetCheck.svg',
    vet: 'Dr. Smith',
    clinic: 'Happy Paws Clinic',
    date: 'Nov 19, 2024',
    notes: 'Annual wellness exam. All vitals normal. Weight stable at 28.5kg.',
    cost: 120,
    followUp: 'Nov 19, 2025',
  ),
  _MedicalEvent(
    title: 'Dental',
    iconAsset: 'assets/icons/eventsIcons/dentalCheck.svg',
    vet: 'Dr. Johnson',
    clinic: 'City Vet Center',
    date: 'Jun 4, 2024',
    notes: 'Routine dental cleaning. No extractions needed.',
    cost: 280,
  ),
  _MedicalEvent(
    title: 'Emergency',
    iconAsset: 'assets/icons/eventsIcons/emergency.svg',
    vet: 'Dr. Patel',
    clinic: '24/7 Emergency Vet',
    date: 'Jan 8, 2025',
    notes: 'Mild allergic reaction treated quickly. Observed and discharged.',
    cost: 340,
    followUp: 'Jan 15, 2025',
  ),
];

class EventsTab extends StatelessWidget {
  const EventsTab({super.key, required this.pet});

  final PetUiModel pet;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(
        AppDimensions.pageHorizontalPadding,
        AppDimensions.spaceM,
        AppDimensions.pageHorizontalPadding,
        88, // room for FAB
      ),
      // +1 for the "Add Medical Event" button at the bottom
      itemCount: _mockEvents.length + 1,
      separatorBuilder: (_, _) => const SizedBox(height: AppDimensions.spaceS),
      itemBuilder: (context, index) {
        if (index == _mockEvents.length) {
          return _AddEventButton(isDark: isDark);
        }
        return _EventCard(event: _mockEvents[index], isDark: isDark);
      },
    );
  }
}

class _EventCard extends StatelessWidget {
  const _EventCard({required this.event, required this.isDark});

  final _MedicalEvent event;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final cardColor = isDark ? AppColors.petCardBackgroundDark : Colors.white;
    final metaColor = isDark
        ? AppColors.onSurfaceDark.withValues(alpha: 0.55)
        : AppColors.grey500;
    final bodyColor = isDark ? AppColors.onSurfaceDark : AppColors.grey700;
    final titleColor = isDark ? AppColors.onSurfaceDark : AppColors.grey900;

    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(AppDimensions.radiusXL),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.12 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      padding: const EdgeInsets.all(AppDimensions.pageHorizontalPadding),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SvgPicture.asset(event.iconAsset, width: 44, height: 44),
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
                        event.title,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: titleColor,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    if (event.cost != null) ...[
                      const SizedBox(width: 8),
                      Text(
                        '\$${event.cost!.toStringAsFixed(0)}',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: titleColor,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  '${event.vet} · ${event.clinic}',
                  style: TextStyle(color: metaColor, fontSize: 12),
                ),
                const SizedBox(height: 1),
                Text(
                  event.date,
                  style: TextStyle(color: metaColor, fontSize: 12),
                ),
                const SizedBox(height: 7),
                Text(
                  event.notes,
                  style: TextStyle(color: bodyColor, fontSize: 13, height: 1.4),
                ),
                if (event.followUp != null) ...[
                  const SizedBox(height: 8),
                  _FollowUpChip(date: event.followUp!),
                ],
              ],
            ),
          ),
        ],
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.addPetPhotoBackground,
        borderRadius: BorderRadius.circular(AppDimensions.radiusCircle),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.schedule_outlined,
            size: 14,
            color: AppColors.bottomNavActive,
          ),
          const SizedBox(width: 4),
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

class _AddEventButton extends StatelessWidget {
  const _AddEventButton({required this.isDark});

  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.bottomNavActive,
        side: const BorderSide(color: AppColors.bottomNavActive),
        minimumSize: const Size.fromHeight(AppDimensions.buttonHeight),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusCircle),
        ),
      ),
      onPressed: () {},
      child: const Text('+ Add Medical Event'),
    );
  }
}
