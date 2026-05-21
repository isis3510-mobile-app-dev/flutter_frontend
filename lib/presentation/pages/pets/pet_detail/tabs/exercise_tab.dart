import 'package:flutter/material.dart';
import 'package:flutter_frontend/app/routes.dart';
import 'package:flutter_frontend/core/constants/app_colors.dart';
import 'package:flutter_frontend/core/constants/app_dimensions.dart';
import 'package:flutter_frontend/core/models/exercise_model.dart';
import 'package:flutter_frontend/core/network/api_exception.dart';
import 'package:flutter_frontend/core/services/exercise_service.dart';
import 'package:flutter_frontend/presentation/pages/exercise/add_exercise/add_exercise_args.dart';
import 'package:flutter_frontend/presentation/pages/exercise/detail/exercise_detail_args.dart';

import '../../models/pet_ui_model.dart';

class ExerciseTab extends StatefulWidget {
  const ExerciseTab({
    super.key,
    required this.pet,
    required this.onChanged,
  });

  final PetUiModel pet;
  final Future<void> Function() onChanged;

  @override
  State<ExerciseTab> createState() => _ExerciseTabState();
}

class _ExerciseTabState extends State<ExerciseTab> {
  final ExerciseService _exerciseService = ExerciseService();

  bool _isLoading = true;
  String? _errorMessage;
  List<ExerciseModel> _exercises = const [];
  ExerciseWeeklySummary _summary = const ExerciseWeeklySummary(
    totalMinutes: 0,
    sessionCount: 0,
    totalDistanceKm: 0,
  );

  @override
  void initState() {
    super.initState();
    _loadExercises();
  }

  @override
  void didUpdateWidget(covariant ExerciseTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.pet.id != widget.pet.id) {
      _loadExercises();
    }
  }

  Future<void> _loadExercises() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final exercises = await _exerciseService.getExercisesByPet(widget.pet.id);
      final summary = await _exerciseService.summarizeExercises(
        exercises,
        petId: widget.pet.id,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _exercises = exercises;
        _summary = summary;
      });
    } on ApiException catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _errorMessage = error.message;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _errorMessage = 'Unable to load exercise sessions.';
      });
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _goToLiveSession() async {
    final changed = await Navigator.of(context).pushNamed(
      Routes.liveExercise,
      arguments: AddExerciseArgs(petId: widget.pet.id, petName: widget.pet.name),
    );
    if (!mounted || changed != true) {
      return;
    }
    await _loadExercises();
    await widget.onChanged();
  }

  Future<void> _goToManualLog() async {
    final changed = await Navigator.of(context).pushNamed(
      Routes.addExercise,
      arguments: AddExerciseArgs(petId: widget.pet.id, petName: widget.pet.name),
    );
    if (!mounted || changed != true) {
      return;
    }
    await _loadExercises();
    await widget.onChanged();
  }

  Future<void> _openDetail(ExerciseModel exercise) async {
    final changed = await Navigator.of(context).pushNamed(
      Routes.exerciseDetail,
      arguments: ExerciseDetailArgs(
        exercise: exercise,
        petName: widget.pet.name,
      ),
    );
    if (!mounted || changed != true) {
      return;
    }
    await _loadExercises();
    await widget.onChanged();
  }

  String _formatStartedAt(DateTime value) {
    final hour = value.hour % 12 == 0 ? 12 : value.hour % 12;
    final minute = value.minute.toString().padLeft(2, '0');
    final suffix = value.hour >= 12 ? 'PM' : 'AM';
    return '${value.day}/${value.month}/${value.year} • $hour:$minute $suffix';
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return _ExerciseErrorState(
        message: _errorMessage!,
        onRetry: _loadExercises,
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppDimensions.pageHorizontalPadding,
        AppDimensions.spaceM,
        AppDimensions.pageHorizontalPadding,
        88,
      ),
      children: [
        _ExerciseSummaryCard(summary: _summary),
        const SizedBox(height: AppDimensions.spaceM),
        Row(
          children: [
            Expanded(
              child: FilledButton.icon(
                onPressed: _goToLiveSession,
                icon: const Icon(Icons.play_circle_fill_outlined),
                label: const Text('Start live'),
              ),
            ),
            const SizedBox(width: AppDimensions.spaceM),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _goToManualLog,
                icon: const Icon(Icons.add_task_outlined),
                label: const Text('Log manually'),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppDimensions.spaceM),
        if (_exercises.isEmpty)
          _EmptyExerciseState(
            petName: widget.pet.name,
            onStart: _goToLiveSession,
          )
        else
          ..._exercises.map(
            (exercise) => _ExerciseSessionCard(
              exercise: exercise,
              subtitle: _formatStartedAt(exercise.startedAt),
              onTap: () => _openDetail(exercise),
            ),
          ),
      ],
    );
  }
}

class _ExerciseSummaryCard extends StatelessWidget {
  const _ExerciseSummaryCard({required this.summary});

  final ExerciseWeeklySummary summary;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(AppDimensions.spaceL),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? const [Color(0xFF173B37), Color(0xFF0D2A26)]
              : const [Color(0xFFE2F6F3), Color(0xFFF4FFFD)],
        ),
        borderRadius: BorderRadius.circular(AppDimensions.radiusXL),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'This week',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: isDark ? AppColors.grey500 : AppColors.grey700,
            ),
          ),
          const SizedBox(height: AppDimensions.spaceS),
          Text(
            '${summary.totalMinutes} active min',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: AppDimensions.spaceS),
          
          Row(
            children: [
              _MetricPill(
                label: 'Sessions',
                value: '${summary.sessionCount}',
                accent: AppColors.primary,
              ),
              const SizedBox(width: AppDimensions.spaceS),
              _MetricPill(
                label: 'Distance',
                value: '${summary.totalDistanceKm.toStringAsFixed(1)} km',
                accent: AppColors.primary,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MetricPill extends StatelessWidget {
  const _MetricPill({
    required this.label,
    required this.value,
    required this.accent,
  });

  final String label;
  final String value;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(AppDimensions.spaceM),
        decoration: BoxDecoration(
          color: accent.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(AppDimensions.radiusL),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: AppDimensions.spaceXS),
            Text(
              value,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ExerciseSessionCard extends StatelessWidget {
  const _ExerciseSessionCard({
    required this.exercise,
    required this.subtitle,
    required this.onTap,
  });

  final ExerciseModel exercise;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: AppDimensions.spaceM),
        padding: const EdgeInsets.all(AppDimensions.spaceL),
        decoration: BoxDecoration(
          color: isDark ? AppColors.secondaryDark : AppColors.secondary,
          borderRadius: BorderRadius.circular(AppDimensions.radiusL),
          border: isDark ? Border.all(color: AppColors.grey700) : null,
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(AppDimensions.radiusL),
              ),
              child: const Icon(Icons.directions_walk, color: AppColors.primary),
            ),
            const SizedBox(width: AppDimensions.spaceM),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _labelize(exercise.type),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: AppDimensions.spaceXS),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: isDark ? AppColors.grey500 : AppColors.grey700,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppDimensions.spaceS),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${exercise.durationMinutes} min',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: AppDimensions.spaceXS),
                Text(
                  exercise.distanceKm == null
                      ? _labelize(exercise.intensity)
                      : '${exercise.distanceKm!.toStringAsFixed(1)} km',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: isDark ? AppColors.grey500 : AppColors.grey700,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyExerciseState extends StatelessWidget {
  const _EmptyExerciseState({
    required this.petName,
    required this.onStart,
  });

  final String petName;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.spaceXL),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? AppColors.secondaryDark
            : AppColors.secondary,
        borderRadius: BorderRadius.circular(AppDimensions.radiusL),
      ),
      child: Column(
        children: [
          const Icon(Icons.fitness_center_outlined, size: 54),
          const SizedBox(height: AppDimensions.spaceM),
          Text(
            'No exercise sessions yet.',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppDimensions.spaceS),
          Text(
            'Start the first session for $petName to begin tracking walks, play and training.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: AppDimensions.spaceL),
          FilledButton.icon(
            onPressed: onStart,
            icon: const Icon(Icons.play_arrow_rounded),
            label: const Text('Start first session'),
          ),
        ],
      ),
    );
  }
}

class _ExerciseErrorState extends StatelessWidget {
  const _ExerciseErrorState({
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.spaceXL),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.cloud_off_rounded,
              size: 56,
              color: AppColors.grey300,
            ),
            const SizedBox(height: AppDimensions.spaceM),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppColors.grey500,
              ),
            ),
            const SizedBox(height: AppDimensions.spaceM),
            OutlinedButton(
              onPressed: onRetry,
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

String _labelize(String value) {
  if (value.isEmpty) {
    return value;
  }
  return '${value[0].toUpperCase()}${value.substring(1)}';
}
