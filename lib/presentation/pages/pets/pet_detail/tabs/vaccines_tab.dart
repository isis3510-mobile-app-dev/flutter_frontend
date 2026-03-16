import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_dimensions.dart';
import '../../models/pet_ui_model.dart';

class _VaccineRecord {
  const _VaccineRecord({
    required this.name,
    required this.status,
    required this.vet,
    required this.clinic,
    required this.dateGiven,
    required this.nextDue,
    this.lotNumber,
  });

  final String name;

  /// 'completed' | 'upcoming' | 'overdue'
  final String status;
  final String vet;
  final String clinic;
  final String dateGiven;
  final String nextDue;
  final String? lotNumber;
}

const _mockVaccines = [
  _VaccineRecord(
    name: 'Bordetella',
    status: 'completed',
    vet: 'Dr. Smith',
    clinic: 'Happy Paws Clinic',
    dateGiven: 'Sep 19, 2024',
    nextDue: 'Sep 19, 2025',
  ),
  _VaccineRecord(
    name: 'DHPP (Core)',
    status: 'completed',
    vet: 'Dr. Smith',
    clinic: 'Happy Paws Clinic',
    dateGiven: 'Jun 9, 2024',
    nextDue: 'Jun 9, 2025',
    lotNumber: 'DH2024-0610',
  ),
  _VaccineRecord(
    name: 'Rabies',
    status: 'upcoming',
    vet: 'Dr. Smith',
    clinic: 'Happy Paws Clinic',
    dateGiven: 'Mar 14, 2024',
    nextDue: 'Mar 14, 2025',
    lotNumber: 'LP2024-0315',
  ),
  _VaccineRecord(
    name: 'Leptospirosis',
    status: 'overdue',
    vet: 'Dr. Johnson',
    clinic: 'City Vet Center',
    dateGiven: 'Jan 5, 2024',
    nextDue: 'Jan 5, 2025',
  ),
];

class VaccinesTab extends StatefulWidget {
  const VaccinesTab({super.key, required this.pet});

  final PetUiModel pet;

  @override
  State<VaccinesTab> createState() => _VaccinesTabState();
}

class _VaccinesTabState extends State<VaccinesTab> {
  /// null = show all
  String? _activeFilter;

  List<_VaccineRecord> get _filtered => _activeFilter == null
      ? _mockVaccines
      : _mockVaccines.where((v) => v.status == _activeFilter).toList();

  int _count(String status) =>
      _mockVaccines.where((v) => v.status == status).length;

  void _toggleFilter(String status) =>
      setState(() => _activeFilter = _activeFilter == status ? null : status);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppDimensions.pageHorizontalPadding,
            AppDimensions.spaceM,
            AppDimensions.pageHorizontalPadding,
            0,
          ),
          child: Row(
            children: [
              _FilterChip(
                label: '${_count('completed')} Completed',
                color: AppColors.petStatusHealthyText,
                bgColor: AppColors.petStatusHealthyBg,
                isActive: _activeFilter == 'completed',
                onTap: () => _toggleFilter('completed'),
              ),
              const SizedBox(width: AppDimensions.spaceS),
              _FilterChip(
                label: '${_count('upcoming')} Upcoming',
                color: const Color(0xFF1565C0),
                bgColor: const Color(0xFFE3F2FD),
                isActive: _activeFilter == 'upcoming',
                onTap: () => _toggleFilter('upcoming'),
              ),
              const SizedBox(width: AppDimensions.spaceS),
              _FilterChip(
                label: '${_count('overdue')} Overdue',
                color: AppColors.error,
                bgColor: const Color(0xFFFDECEC),
                isActive: _activeFilter == 'overdue',
                onTap: () => _toggleFilter('overdue'),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppDimensions.spaceS),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(
              AppDimensions.pageHorizontalPadding,
              AppDimensions.spaceXS,
              AppDimensions.pageHorizontalPadding,
              88, // room for FAB
            ),
            itemCount: _filtered.length,
            separatorBuilder: (_, _) =>
                const SizedBox(height: AppDimensions.spaceS),
            itemBuilder: (_, i) =>
                _VaccineCard(vaccine: _filtered[i], isDark: isDark),
          ),
        ),
      ],
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.color,
    required this.bgColor,
    required this.isActive,
    required this.onTap,
  });

  final String label;
  final Color color;
  final Color bgColor;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isActive ? color.withValues(alpha: 0.14) : bgColor,
          borderRadius: BorderRadius.circular(AppDimensions.radiusCircle),
          border: isActive ? Border.all(color: color, width: 1.5) : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _VaccineCard extends StatelessWidget {
  const _VaccineCard({required this.vaccine, required this.isDark});

  final _VaccineRecord vaccine;
  final bool isDark;

  static Color _statusColor(String status) {
    if (status == 'completed') return AppColors.petStatusHealthyText;
    if (status == 'upcoming') return const Color(0xFF1565C0);
    return AppColors.error;
  }

  static Color _statusBg(String status) {
    if (status == 'completed') return AppColors.petStatusHealthyBg;
    if (status == 'upcoming') return const Color(0xFFE3F2FD);
    return const Color(0xFFFDECEC);
  }

  static String _statusIconPath(String status) {
    if (status == 'completed') return 'assets/icons/status/successPrimary.svg';
    if (status == 'upcoming') return 'assets/icons/status/pendingPrimary.svg';
    return 'assets/icons/status/warningPrimary.svg';
  }

  @override
  Widget build(BuildContext context) {
    final cardColor = isDark ? AppColors.petCardBackgroundDark : Colors.white;
    final metaColor = isDark
        ? AppColors.onSurfaceDark.withValues(alpha: 0.55)
        : AppColors.grey500;
    final valueColor = isDark ? AppColors.onSurfaceDark : AppColors.grey700;
    final titleColor = isDark ? AppColors.onSurfaceDark : AppColors.grey900;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Container(
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
                SvgPicture.asset(
                  _statusIconPath(vaccine.status),
                  width: 20,
                  height: 20,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              vaccine.name,
                              style: Theme.of(context).textTheme.titleSmall
                                  ?.copyWith(
                                    color: titleColor,
                                    fontWeight: FontWeight.w700,
                                  ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 9,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: _statusBg(vaccine.status),
                              borderRadius: BorderRadius.circular(
                                AppDimensions.radiusCircle,
                              ),
                            ),
                            child: Text(
                              vaccine.status,
                              style: TextStyle(
                                color: _statusColor(vaccine.status),
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${vaccine.vet} · ${vaccine.clinic}',
                        style: TextStyle(color: metaColor, fontSize: 12),
                      ),
                      const SizedBox(height: 8),
                      _DateRow(
                        vaccine: vaccine,
                        metaColor: metaColor,
                        valueColor: valueColor,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _DateRow extends StatelessWidget {
  const _DateRow({
    required this.vaccine,
    required this.metaColor,
    required this.valueColor,
  });

  final _VaccineRecord vaccine;
  final Color metaColor;
  final Color valueColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _DateField(
            label: 'Date given',
            value: vaccine.dateGiven,
            metaColor: metaColor,
            valueColor: valueColor,
          ),
        ),
        Expanded(
          child: _DateField(
            label: 'Next due',
            value: vaccine.nextDue,
            metaColor: metaColor,
            valueColor: valueColor,
          ),
        ),
        if (vaccine.lotNumber != null)
          Expanded(
            child: _DateField(
              label: 'Lot #',
              value: vaccine.lotNumber!,
              metaColor: metaColor,
              valueColor: valueColor,
            ),
          ),
      ],
    );
  }
}

class _DateField extends StatelessWidget {
  const _DateField({
    required this.label,
    required this.value,
    required this.metaColor,
    required this.valueColor,
  });

  final String label;
  final String value;
  final Color metaColor;
  final Color valueColor;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: metaColor,
            fontSize: 10.5,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            color: valueColor,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
