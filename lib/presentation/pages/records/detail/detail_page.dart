import 'package:flutter/material.dart';
import 'package:flutter_frontend/app/routes.dart';
import 'package:flutter_frontend/core/constants/app_colors.dart';
import 'package:flutter_frontend/core/constants/app_strings.dart';
import 'package:flutter_frontend/core/utils/context_extensions.dart';
import 'package:flutter_frontend/shared/widgets/full_width_button.dart';

class DetailPage extends StatelessWidget {
  const DetailPage({super.key, required this.type});

  final String type;

  void navigateToEditPage(BuildContext context) {
    if (type == 'vaccine') {
      Navigator.of(context).pushNamed(Routes.addVaccine);
    } else if (type == 'event') {
      Navigator.of(context).pushNamed(Routes.addEvent);
    }
  }

  @override
  Widget build(BuildContext context) {
    final (appbarIcon, appbarTitle, lastCardTitle, lastCardEmpty) = switch (type) {
      'vaccine' => (
          Icons.vaccines_outlined,
          AppStrings.vaccineDetailsTitle,
          AppStrings.vaccineAttachedDocumentTitle,
          AppStrings.vaccineNoDocuments
        ),
      'event' => (
          Icons.event_note_outlined,
          AppStrings.eventDetailsTitle,
          AppStrings.eventNotesTitle,
          AppStrings.eventNoNotes
        ),
      _ => (
          Icons.info_outline,
          '',
          '',
          ''
        ),
    };
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.onPrimary,
        toolbarHeight: 80.0,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Icon(appbarIcon),
                SizedBox(width: 8),
                Text(appbarTitle),
              ]
            ),
            const SizedBox(height: 2),
            Text(
              AppStrings.detailsSubtitle,
              style: TextStyle(
                fontSize: 12,
                color: AppColors.grey100,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 140),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _InfoCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Bordetella",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: AppColors.onSurface,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.positiveBackground,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.check,
                            size: 16,
                            color: AppColors.positiveText,
                          ),
                          SizedBox(width: 6),
                          Text(
                            AppStrings.vaccineStatusCompleted,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.success,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _InfoCard(
                title: AppStrings.vaccineTimelineTitle,
                child: Column(
                  children: const [
                    _InfoRow(
                      icon: Icons.calendar_today_outlined,
                      label: AppStrings.vaccineDateGivenLabel,
                      value: AppStrings.vaccineDateGivenValue,
                    ),
                    Divider(height: 24),
                    _InfoRow(
                      icon: Icons.calendar_month_outlined,
                      label: AppStrings.vaccineNextDueLabel,
                      value: AppStrings.vaccineNextDueValue,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _InfoCard(
                title: AppStrings.providerInfoTitle,
                child: Column(
                  children: const [
                    _InfoRow(
                      icon: Icons.person_outline,
                      label: AppStrings.veterinarianLabel,
                      value: AppStrings.vaccineVeterinarianValue,
                    ),
                    Divider(height: 24),
                    _InfoRow(
                      icon: Icons.location_on_outlined,
                      label: AppStrings.clinicLabel,
                      value: AppStrings.vaccineClinicValue,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _InfoCard(
                title: lastCardTitle,
                child: Text(
                  lastCardEmpty,
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.grey700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Container(
        color: AppColors.secondary,
        child: SafeArea(
          minimum: const EdgeInsets.fromLTRB(16, 18, 16, 16),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12.0),
            child: Row(
              children: [
                Expanded(
                  child: FullWidthButton(
                    text: AppStrings.actionDelete,
                    onPressed: () {},
                    backgroundColor: Colors.transparent,
                    borderColor: AppColors.error,
                    textColor: AppColors.error,
                    splashColor: AppColors.negativeText,
                    icon: Icons.delete_outline,
                    height: 52,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FullWidthButton(
                    text: AppStrings.actionEdit,
                    onPressed: () => navigateToEditPage(context),
                    icon: Icons.edit_outlined,
                    height: 52,
                  ),
                ),
              ],
            ),
          ),
        )
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  // ignore: unused_element_parameter
  const _InfoCard({this.title, required this.child, this.backgroundColor = AppColors.secondary});

  final String? title;
  final Widget child;
  final Color backgroundColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.grey100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null) ...[
            Text(
              title!.toUpperCase(),
              style: context.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
          ],
          child,
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.grey700),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: context.textTheme.bodySmall?.copyWith(color: AppColors.grey700),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: context.textTheme.bodyMedium?.copyWith(color: AppColors.onSecondary),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
