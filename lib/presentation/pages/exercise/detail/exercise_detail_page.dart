import 'package:flutter/material.dart';
import 'package:flutter_frontend/app/routes.dart';
import 'package:flutter_frontend/core/constants/app_colors.dart';
import 'package:flutter_frontend/core/constants/app_dimensions.dart';
import 'package:flutter_frontend/core/services/exercise_service.dart';
import 'package:flutter_frontend/presentation/pages/exercise/add_exercise/add_exercise_args.dart';

import 'exercise_detail_args.dart';

class ExerciseDetailPage extends StatefulWidget {
  const ExerciseDetailPage({super.key, required this.args});

  final ExerciseDetailArgs args;

  @override
  State<ExerciseDetailPage> createState() => _ExerciseDetailPageState();
}

class _ExerciseDetailPageState extends State<ExerciseDetailPage> {
  final ExerciseService _exerciseService = ExerciseService();
  bool _isDeleting = false;

  Future<void> _edit() async {
    final changed = await Navigator.of(context).pushNamed(
      Routes.addExercise,
      arguments: AddExerciseArgs(
        petId: widget.args.exercise.petId,
        petName: widget.args.petName,
        editingExercise: widget.args.exercise,
      ),
    );

    if (!mounted || changed != true) {
      return;
    }

    Navigator.of(context).pop(true);
  }

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete session'),
          content: const Text('This exercise session will be removed.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    setState(() => _isDeleting = true);
    await _exerciseService.deleteExercise(
      petId: widget.args.exercise.petId,
      exerciseId: widget.args.exercise.id,
    );
    if (!mounted) {
      return;
    }
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final exercise = widget.args.exercise;
    final title = _labelize(exercise.type);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Exercise detail'),
        actions: [
          IconButton(onPressed: _edit, icon: const Icon(Icons.edit_outlined)),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppDimensions.pageHorizontalPadding),
        children: [
          Container(
            padding: const EdgeInsets.all(AppDimensions.spaceL),
            decoration: BoxDecoration(
              color: isDark ? AppColors.secondaryDark : AppColors.secondary,
              borderRadius: BorderRadius.circular(AppDimensions.radiusL),
              border: isDark ? Border.all(color: AppColors.grey700) : null,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: AppDimensions.spaceS),
                Text(
                  widget.args.petName,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: isDark ? AppColors.grey500 : AppColors.grey700,
                  ),
                ),
                const SizedBox(height: AppDimensions.spaceL),
                _InfoRow(
                  label: 'Date',
                  value: _formatDateTime(exercise.startedAt),
                ),
                _InfoRow(
                  label: 'Duration',
                  value: '${exercise.durationMinutes} min',
                ),
                _InfoRow(
                  label: 'Intensity',
                  value: _labelize(exercise.intensity),
                ),
                _InfoRow(
                  label: 'Distance',
                  value: exercise.distanceKm == null
                      ? 'Not recorded'
                      : '${exercise.distanceKm!.toStringAsFixed(2)} km',
                ),
                _InfoRow(
                  label: 'Notes',
                  value: exercise.notes.trim().isEmpty
                      ? 'No notes'
                      : exercise.notes.trim(),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppDimensions.spaceL),
          SizedBox(
            height: AppDimensions.buttonHeightL,
            child: FilledButton.tonal(
              onPressed: _isDeleting ? null : _delete,
              style: FilledButton.styleFrom(
                foregroundColor: AppColors.error,
              ),
              child: _isDeleting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Delete session'),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppDimensions.spaceM),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: AppColors.grey700,
            ),
          ),
          const SizedBox(height: AppDimensions.spaceXS),
          Text(value, style: Theme.of(context).textTheme.titleMedium),
        ],
      ),
    );
  }
}

String _formatDateTime(DateTime value) {
  final hour = value.hour % 12 == 0 ? 12 : value.hour % 12;
  final minute = value.minute.toString().padLeft(2, '0');
  final suffix = value.hour >= 12 ? 'PM' : 'AM';
  return '${value.day}/${value.month}/${value.year} • $hour:$minute $suffix';
}

String _labelize(String value) {
  if (value.isEmpty) {
    return value;
  }
  return '${value[0].toUpperCase()}${value.substring(1)}';
}
