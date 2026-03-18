import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_dimensions.dart';
import '../../../../../core/constants/app_strings.dart';
import '../../../../../core/models/pet_model.dart';
import '../../../../../core/network/api_exception.dart';
import '../../../../../core/services/pet_service.dart';
import '../../../../../core/services/vaccine_service.dart';
import '../../models/pet_ui_model.dart';

enum VaccineStatusType { completed, upcoming, overdue }

class VaccineUiModel {
  VaccineUiModel({
    required this.vaccinationId,
    required this.vaccineId,
    required this.vaccineName,
    required this.dateGiven,
    required this.nextDueDate,
    required this.lotNumber,
    required this.status,
    required this.administeredBy,
    required this.clinicName,
  });

  final String vaccinationId;
  final String vaccineId;
  final String vaccineName;
  final DateTime dateGiven;
  final DateTime nextDueDate;
  final String lotNumber;
  final VaccineStatusType status;
  final String administeredBy;
  final String clinicName;

  String get uniqueKey => '${vaccineId}_${dateGiven.millisecondsSinceEpoch}';

  String get statusLabel {
    return switch (status) {
      VaccineStatusType.completed => 'completed',
      VaccineStatusType.upcoming => 'upcoming',
      VaccineStatusType.overdue => 'overdue',
    };
  }

  String get doctorClinic {
    final doctor = administeredBy.trim().isEmpty ? null : administeredBy.trim();
    final clinic = clinicName.trim().isEmpty ? null : clinicName.trim();

    if (doctor != null && clinic != null) {
      return '$doctor + $clinic';
    }

    if (doctor != null) {
      return doctor;
    }

    if (clinic != null) {
      return clinic;
    }

    return AppStrings.valueNotAvailable;
  }
}

class VaccinesTab extends StatefulWidget {
  const VaccinesTab({
    super.key,
    required this.pet,
    required this.vaccinations,
    required this.onAddVaccine,
  });

  final PetUiModel pet;
  final List<PetVaccinationModel> vaccinations;
  final VoidCallback onAddVaccine;

  @override
  State<VaccinesTab> createState() => _VaccinesTabState();
}

class _VaccinesTabState extends State<VaccinesTab> {
  final VaccineService _vaccineService = VaccineService();
  final PetService _petService = PetService();
  Map<String, String> _vaccineNames = const <String, String>{};
  final Map<String, VaccineStatusType> _statusOverrides = <String, VaccineStatusType>{};
  final Set<String> _updatingStatuses = <String>{};

  @override
  void initState() {
    super.initState();
    _loadVaccineNames();
  }

  @override
  void didUpdateWidget(covariant VaccinesTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.vaccinations != widget.vaccinations) {
      _loadVaccineNames();
    }
  }

  Future<void> _loadVaccineNames() async {
    final vaccineIds = widget.vaccinations
        .map((item) => item.vaccineId.trim())
        .where((id) => id.isNotEmpty)
        .toSet();

    if (vaccineIds.isEmpty) {
      if (!mounted) {
        return;
      }
      setState(() {
        _vaccineNames = const <String, String>{};
      });
      return;
    }

    try {
      final vaccines = await _vaccineService.getVaccines();
      final catalogById = <String, String>{};
      for (final vaccine in vaccines) {
        final id = vaccine.id.trim();
        final name = vaccine.name.trim();
        if (id.isNotEmpty && name.isNotEmpty) {
          catalogById[id] = name;
        }
      }

      final unresolvedIds = vaccineIds.where((id) => !catalogById.containsKey(id));
      for (final id in unresolvedIds) {
        try {
          final vaccineDetail = await _vaccineService.getVaccineById(id);
          final detailName = vaccineDetail.name.trim();
          if (detailName.isNotEmpty) {
            catalogById[id] = detailName;
          }
        } catch (_) {
          // Keep id as fallback when an individual lookup fails.
        }
      }

      if (!mounted) {
        return;
      }

      setState(() {
        _vaccineNames = {
          for (final id in vaccineIds) id: catalogById[id] ?? id,
        };
      });
    } catch (_) {
      // Keep fallback to vaccine id when the catalog cannot be loaded.
    }
  }

  VaccineStatusType _mapStatus(PetVaccinationModel model) {
    final sourceStatus = model.status.trim().toLowerCase();
    final now = DateTime.now();

    if (sourceStatus == 'completed' || sourceStatus == 'done' || sourceStatus == 'applied') {
      return VaccineStatusType.completed;
    }

    if (sourceStatus == 'overdue' || sourceStatus == 'late' || sourceStatus == 'expired') {
      return VaccineStatusType.overdue;
    }

    if (sourceStatus == 'upcoming' || sourceStatus == 'pending' || sourceStatus == 'scheduled') {
      return VaccineStatusType.upcoming;
    }

    if (model.nextDueDate.isBefore(now)) {
      return VaccineStatusType.overdue;
    }

    if (model.dateGiven.isAfter(now)) {
      return VaccineStatusType.upcoming;
    }

    return VaccineStatusType.completed;
  }

  String _formatDateForApi(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }

  String _statusToApiValue(VaccineStatusType status) {
    return switch (status) {
      VaccineStatusType.completed => 'completed',
      VaccineStatusType.upcoming => 'upcoming',
      VaccineStatusType.overdue => 'overdue',
    };
  }

  String _statusLabel(VaccineStatusType status) {
    return switch (status) {
      VaccineStatusType.completed => 'Completed',
      VaccineStatusType.upcoming => 'Upcoming',
      VaccineStatusType.overdue => 'Overdue',
    };
  }

  Future<void> _showStatusPicker(VaccineUiModel vaccine) async {
    final key = vaccine.uniqueKey;
    if (_updatingStatuses.contains(key)) {
      return;
    }

    final selected = await showModalBottomSheet<VaccineStatusType>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: Text(
                  vaccine.vaccineName,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                subtitle: const Text('Select new status'),
              ),
              for (final status in VaccineStatusType.values)
                ListTile(
                  title: Text(_statusLabel(status)),
                  trailing: status == vaccine.status
                      ? const Icon(Icons.check, color: AppColors.primary)
                      : null,
                  onTap: () => Navigator.of(context).pop(status),
                ),
            ],
          ),
        );
      },
    );

    if (selected == null || selected == vaccine.status) {
      return;
    }

    await _updateVaccineStatus(vaccine, selected);
  }

  Future<void> _updateVaccineStatus(
    VaccineUiModel vaccine,
    VaccineStatusType newStatus,
  ) async {
    final key = vaccine.uniqueKey;
    if (_updatingStatuses.contains(key)) {
      return;
    }

    setState(() {
      _updatingStatuses.add(key);
    });

    try {
      final payload = <String, dynamic>{
        'vaccineId': vaccine.vaccineId,
        'dateGiven': _formatDateForApi(vaccine.dateGiven),
        'status': _statusToApiValue(newStatus),
      };
      if (vaccine.nextDueDate.year > 1) {
        payload['nextDueDate'] = _formatDateForApi(vaccine.nextDueDate);
      }
      final administeredBy = vaccine.administeredBy.trim();
      if (administeredBy.isNotEmpty) {
        payload['administeredBy'] = administeredBy;
      }
      final lotNumber = vaccine.lotNumber.trim();
      if (lotNumber.isNotEmpty) {
        payload['lotNumber'] = lotNumber;
      }

      await _petService.updateVaccination(
        petId: widget.pet.id,
        vaccinationId: vaccine.vaccinationId,
        data: payload,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _statusOverrides[key] = newStatus;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Vaccine status updated to ${_statusLabel(newStatus).toLowerCase()}.')),
      );
    } on ApiException catch (error) {
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
        const SnackBar(content: Text(AppStrings.errorGeneric)),
      );
    } finally {
      if (mounted) {
        setState(() {
          _updatingStatuses.remove(key);
        });
      }
    }
  }

  String _formatDate(DateTime date) {
    if (date.year < 2) {
      return AppStrings.valueNotAvailable;
    }
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  List<VaccineUiModel> _mapVaccines(List<PetVaccinationModel> raw) {
    final mapped = raw.map((item) {
      final candidate = item.vaccineId.trim();
      final name = _vaccineNames[candidate]?.trim();
      final resolvedName =
          name != null && name.isNotEmpty ? name : candidate;
      final vaccine = VaccineUiModel(
        vaccinationId: item.id,
        vaccineId: item.vaccineId,
        vaccineName:
            resolvedName.isEmpty ? AppStrings.valueNotAvailable : resolvedName,
        dateGiven: item.dateGiven,
        nextDueDate: item.nextDueDate,
        lotNumber: item.lotNumber,
        status: _mapStatus(item),
        administeredBy: item.administeredBy,
        clinicName: item.clinicName,
      );

      final override = _statusOverrides[vaccine.uniqueKey];
      if (override == null) {
        return vaccine;
      }

      return VaccineUiModel(
        vaccinationId: vaccine.vaccinationId,
        vaccineId: vaccine.vaccineId,
        vaccineName: vaccine.vaccineName,
        dateGiven: vaccine.dateGiven,
        nextDueDate: vaccine.nextDueDate,
        lotNumber: vaccine.lotNumber,
        status: override,
        administeredBy: vaccine.administeredBy,
        clinicName: vaccine.clinicName,
      );
    }).toList(growable: false);

    mapped.sort((a, b) => b.dateGiven.compareTo(a.dateGiven));
    return mapped;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final uiVaccines = _mapVaccines(widget.vaccinations);
    final completed = uiVaccines.where((i) => i.status == VaccineStatusType.completed).length;
    final upcoming = uiVaccines.where((i) => i.status == VaccineStatusType.upcoming).length;
    final overdue = uiVaccines.where((i) => i.status == VaccineStatusType.overdue).length;

    if (uiVaccines.isEmpty) {
      return Column(
        children: [
          Expanded(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(AppDimensions.spaceXL),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.vaccines_outlined,
                      size: 44,
                      color: isDark ? AppColors.onSurfaceDark : AppColors.grey500,
                    ),
                    const SizedBox(height: AppDimensions.spaceM),
                    Text(
                      'No vaccine records yet for ${widget.pet.name}.',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: isDark ? AppColors.onSurfaceDark : AppColors.grey700,
                            fontWeight: FontWeight.w600,
                          ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppDimensions.spaceS),
                    Text(
                      'Add your first vaccine in records to track your pet health.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.grey500,
                          ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppDimensions.pageHorizontalPadding,
              0,
              AppDimensions.pageHorizontalPadding,
              AppDimensions.spaceM,
            ),
            child: _AddVaccineButton(
              petName: widget.pet.name,
              onTap: widget.onAddVaccine,
            ),
          ),
        ],
      );
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppDimensions.pageHorizontalPadding,
            AppDimensions.spaceM,
            AppDimensions.pageHorizontalPadding,
            0,
          ),
          child: VaccinesStatusSummary(
            completedCount: completed,
            upcomingCount: upcoming,
            overdueCount: overdue,
          ),
        ),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(
              AppDimensions.pageHorizontalPadding,
              AppDimensions.spaceM,
              AppDimensions.pageHorizontalPadding,
              AppDimensions.spaceXL,
            ),
            itemCount: uiVaccines.length + 1,
            separatorBuilder: (context, index) => const SizedBox(height: AppDimensions.spaceS),
            itemBuilder: (context, index) {
              if (index == uiVaccines.length) {
                return _AddVaccineButton(
                  petName: widget.pet.name,
                  onTap: widget.onAddVaccine,
                );
              }

              final item = uiVaccines[index];
              return VaccineTimelineItem(
                vaccine: item,
                isFirst: index == 0,
                isLast: index == uiVaccines.length - 1,
                dateFormatter: _formatDate,
                isUpdatingStatus: _updatingStatuses.contains(item.uniqueKey),
                onTap: () => _showStatusPicker(item),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _AddVaccineButton extends StatelessWidget {
  const _AddVaccineButton({
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
        '+ Add Vaccine',
        semanticsLabel: 'Add vaccine for $petName',
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
    );
  }
}

class VaccinesStatusSummary extends StatelessWidget {
  const VaccinesStatusSummary({
    super.key,
    required this.completedCount,
    required this.upcomingCount,
    required this.overdueCount,
  });

  final int completedCount;
  final int upcomingCount;
  final int overdueCount;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _StatusChip(
            label: 'Completed',
            count: completedCount,
            textColor: AppColors.vaccineStatusCompletedText,
            backgroundColor: AppColors.vaccineStatusCompletedBg,
          ),
        ),
        const SizedBox(width: AppDimensions.spaceS),
        Expanded(
          child: _StatusChip(
            label: 'Upcoming',
            count: upcomingCount,
            textColor: AppColors.vaccineStatusUpcomingText,
            backgroundColor: AppColors.vaccineStatusUpcomingBg,
          ),
        ),
        const SizedBox(width: AppDimensions.spaceS),
        Expanded(
          child: _StatusChip(
            label: 'Overdue',
            count: overdueCount,
            textColor: AppColors.vaccineStatusOverdueText,
            backgroundColor: AppColors.vaccineStatusOverdueBg,
          ),
        ),
      ],
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({
    required this.label,
    required this.count,
    required this.textColor,
    required this.backgroundColor,
  });

  final String label;
  final int count;
  final Color textColor;
  final Color backgroundColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        vertical: AppDimensions.spaceXS,
        horizontal: AppDimensions.spaceS,
      ),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(AppDimensions.radiusXL),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '$count',
            style: TextStyle(
              color: textColor,
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: textColor,
              fontWeight: FontWeight.w600,
              fontSize: 12.5,
            ),
          ),
        ],
      ),
    );
  }
}

class VaccineTimelineItem extends StatelessWidget {
  const VaccineTimelineItem({
    super.key,
    required this.vaccine,
    required this.isFirst,
    required this.isLast,
    required this.dateFormatter,
    required this.onTap,
    this.isUpdatingStatus = false,
  });

  final VaccineUiModel vaccine;
  final bool isFirst;
  final bool isLast;
  final String Function(DateTime) dateFormatter;
  final VoidCallback onTap;
  final bool isUpdatingStatus;

  @override
  Widget build(BuildContext context) {
    final lineColor = Theme.of(context).brightness == Brightness.dark
        ? AppColors.grey700
        : AppColors.grey300;
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Expanded(
                child: Container(
                  width: 2,
                  margin: const EdgeInsets.only(top: 1, bottom: 2),
                  color: isFirst ? Colors.transparent : lineColor,
                ),
              ),
              TimelineIndicator(status: vaccine.status),
              Expanded(
                child: Container(
                  width: 2,
                  margin: const EdgeInsets.only(top: 2),
                  color: isLast ? Colors.transparent : lineColor,
                ),
              ),
            ],
          ),
          const SizedBox(width: AppDimensions.spaceS),
          Expanded(
            child: Align(
              alignment: Alignment.centerRight,
              child: FractionallySizedBox(
                widthFactor: 0.94,
                alignment: Alignment.centerRight,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 560),
                  child: VaccineCard(
                    vaccine: vaccine,
                    dateFormatter: dateFormatter,
                    onTap: onTap,
                    isUpdatingStatus: isUpdatingStatus,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class TimelineIndicator extends StatelessWidget {
  const TimelineIndicator({
    super.key,
    required this.status,
  });

  final VaccineStatusType status;

  String get _iconPath {
    return switch (status) {
      VaccineStatusType.completed => 'assets/icons/status/successPrimary.svg',
      VaccineStatusType.upcoming => 'assets/icons/status/pendingPrimary.svg',
      VaccineStatusType.overdue => 'assets/icons/status/warningPrimary.svg',
    };
  }

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      _iconPath,
      width: 24,
      height: 24,
    );
  }
}

class VaccineCard extends StatelessWidget {
  const VaccineCard({
    super.key,
    required this.vaccine,
    required this.dateFormatter,
    required this.onTap,
    this.isUpdatingStatus = false,
  });

  final VaccineUiModel vaccine;
  final String Function(DateTime) dateFormatter;
  final VoidCallback onTap;
  final bool isUpdatingStatus;

  Color get _badgeColor {
    return switch (vaccine.status) {
      VaccineStatusType.completed => AppColors.vaccineStatusCompletedBg,
      VaccineStatusType.upcoming => AppColors.vaccineStatusUpcomingBg,
      VaccineStatusType.overdue => AppColors.vaccineStatusOverdueBg,
    };
  }

  Color get _badgeTextColor {
    return switch (vaccine.status) {
      VaccineStatusType.completed => AppColors.vaccineStatusCompletedText,
      VaccineStatusType.upcoming => AppColors.vaccineStatusUpcomingText,
      VaccineStatusType.overdue => AppColors.vaccineStatusOverdueText,
    };
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? AppColors.surfaceDark : Colors.white;
    final shadow = [
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.05),
        blurRadius: 8,
        offset: const Offset(0, 2),
      ),
    ];

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppDimensions.radiusL),
        onTap: isUpdatingStatus ? null : onTap,
        child: Container(
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(AppDimensions.radiusL),
            boxShadow: shadow,
            border: Border.all(
              color: isDark ? AppColors.grey700 : AppColors.grey300,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppDimensions.spaceM),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        vaccine.vaccineName,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.onSurface,
                        ),
                      ),
                    ),
                    if (isUpdatingStatus)
                      const Padding(
                        padding: EdgeInsets.only(right: 8),
                        child: SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppDimensions.spaceXS,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _badgeColor,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        vaccine.statusLabel,
                        style: TextStyle(
                          color: _badgeTextColor,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppDimensions.spaceXS),
                Text(
                  vaccine.doctorClinic,
                  style: TextStyle(
                    color: isDark ? AppColors.onSurfaceDark : AppColors.grey700,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: AppDimensions.spaceS),
                Row(
                  children: [
                    _MetaDataColumn(
                      label: 'Date given',
                      value: vaccine.dateGiven.year > 1
                          ? dateFormatter(vaccine.dateGiven)
                          : AppStrings.valueNotAvailable,
                    ),
                    const SizedBox(width: AppDimensions.spaceS),
                    _MetaDataColumn(
                      label: 'Next due',
                      value: vaccine.nextDueDate.year > 1
                          ? dateFormatter(vaccine.nextDueDate)
                          : AppStrings.valueNotAvailable,
                    ),
                    if (vaccine.lotNumber.trim().isNotEmpty) ...[
                      const SizedBox(width: AppDimensions.spaceS),
                      _MetaDataColumn(
                        label: 'Lot #',
                        value: vaccine.lotNumber,
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MetaDataColumn extends StatelessWidget {
  const _MetaDataColumn({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              color: AppColors.grey500,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: AppDimensions.spaceXS),
          Text(
            value,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.onSurface,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
