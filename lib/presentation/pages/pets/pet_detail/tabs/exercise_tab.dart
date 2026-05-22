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
  const ExerciseTab({super.key, required this.pet, required this.onChanged});

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
      if (!mounted) {
        return;
      }
      setState(() {
        _exercises = exercises;
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
      arguments: AddExerciseArgs(
        petId: widget.pet.id,
        petName: widget.pet.name,
      ),
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
      arguments: AddExerciseArgs(
        petId: widget.pet.id,
        petName: widget.pet.name,
      ),
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
        _ExerciseSummaryCard(exercises: _exercises),
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
  const _ExerciseSummaryCard({required this.exercises});

  final List<ExerciseModel> exercises;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dailyTotals = _buildDailyTotals(exercises);
    final recentExercises = _filterRecentExercises(exercises, dailyTotals);
    final totalMinutes = dailyTotals.fold<int>(
      0,
      (sum, day) => sum + day.minutes,
    );
    final averageMinutes = dailyTotals.isEmpty
        ? 0.0
        : totalMinutes / dailyTotals.length;
    final todayMinutes = dailyTotals.isEmpty ? 0 : dailyTotals.last.minutes;
    final todayDelta = todayMinutes - averageMinutes;
    final comparisonText = _formatAverageComparison(todayDelta);
    final totalDistanceKm = recentExercises.fold<double>(
      0,
      (sum, exercise) => sum + (exercise.distanceKm ?? 0),
    );

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
            'Last 7 days',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: isDark ? AppColors.grey500 : AppColors.grey700,
            ),
          ),
          const SizedBox(height: AppDimensions.spaceS),
          Text(
            '$totalMinutes active min',
            style: Theme.of(
              context,
            ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: AppDimensions.spaceS),
          Text(
            'Daily average: ${averageMinutes.round()} min',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: isDark ? AppColors.grey500 : AppColors.grey700,
            ),
          ),
          const SizedBox(height: AppDimensions.spaceM),
          _WeeklyActivityChart(
            days: dailyTotals,
            averageMinutes: averageMinutes,
            isDark: isDark,
          ),
          const SizedBox(height: AppDimensions.spaceM),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimensions.spaceM,
              vertical: AppDimensions.spaceS,
            ),
            decoration: BoxDecoration(
              color: (todayDelta >= 0 ? AppColors.success : AppColors.warning)
                  .withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppDimensions.radiusM),
            ),
            child: Text(
              comparisonText,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: todayDelta >= 0 ? AppColors.success : AppColors.warning,
              ),
            ),
          ),
          const SizedBox(height: AppDimensions.spaceM),
          Row(
            children: [
              _MetricPill(
                label: 'Sessions',
                value: '${recentExercises.length}',
                accent: AppColors.primary,
              ),
              const SizedBox(width: AppDimensions.spaceS),
              _MetricPill(
                label: 'Distance',
                value: '${totalDistanceKm.toStringAsFixed(1)} km',
                accent: AppColors.primary,
              ),
            ],
          ),
        ],
      ),
    );
  }

  List<_DailyExerciseTotal> _buildDailyTotals(List<ExerciseModel> exercises) {
    final today = DateTime.now();
    final todayOnly = DateTime(today.year, today.month, today.day);
    final startDate = todayOnly.subtract(const Duration(days: 6));
    final totals = <DateTime, int>{
      for (var index = 0; index < 7; index++)
        startDate.add(Duration(days: index)): 0,
    };

    for (final exercise in exercises) {
      final date = DateTime(
        exercise.startedAt.year,
        exercise.startedAt.month,
        exercise.startedAt.day,
      );
      if (totals.containsKey(date)) {
        totals[date] = totals[date]! + exercise.durationMinutes;
      }
    }

    return totals.entries
        .map(
          (entry) => _DailyExerciseTotal(date: entry.key, minutes: entry.value),
        )
        .toList(growable: false);
  }

  List<ExerciseModel> _filterRecentExercises(
    List<ExerciseModel> exercises,
    List<_DailyExerciseTotal> dailyTotals,
  ) {
    if (dailyTotals.isEmpty) {
      return const [];
    }

    final startDate = dailyTotals.first.date;
    final endDate = dailyTotals.last.date.add(const Duration(days: 1));
    return exercises
        .where((exercise) {
          final date = DateTime(
            exercise.startedAt.year,
            exercise.startedAt.month,
            exercise.startedAt.day,
          );
          return !date.isBefore(startDate) && date.isBefore(endDate);
        })
        .toList(growable: false);
  }

  String _formatAverageComparison(double delta) {
    final roundedDelta = delta.abs().round();
    if (roundedDelta == 0) {
      return 'Today is on pace with the weekly average';
    }

    final direction = delta > 0 ? 'above' : 'below';
    return 'Today is $roundedDelta min $direction average';
  }
}

class _DailyExerciseTotal {
  const _DailyExerciseTotal({required this.date, required this.minutes});

  final DateTime date;
  final int minutes;

  String get dayLabel {
    const labels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return labels[date.weekday - 1];
  }
}

class _WeeklyActivityChart extends StatelessWidget {
  const _WeeklyActivityChart({
    required this.days,
    required this.averageMinutes,
    required this.isDark,
  });

  final List<_DailyExerciseTotal> days;
  final double averageMinutes;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 156,
      child: CustomPaint(
        painter: _WeeklyActivityChartPainter(
          days: days,
          averageMinutes: averageMinutes,
          textStyle:
              Theme.of(context).textTheme.labelSmall?.copyWith(
                color: isDark ? AppColors.grey500 : AppColors.grey700,
                fontWeight: FontWeight.w600,
              ) ??
              TextStyle(
                color: isDark ? AppColors.grey500 : AppColors.grey700,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
          primaryColor: AppColors.primary,
          aboveAverageColor: AppColors.success,
          belowAverageColor: AppColors.warning,
          trackColor: isDark
              ? Colors.white.withValues(alpha: 0.12)
              : Colors.black.withValues(alpha: 0.08),
          averageColor: isDark ? AppColors.primaryVariant : AppColors.primary,
        ),
        child: const SizedBox.expand(),
      ),
    );
  }
}

class _WeeklyActivityChartPainter extends CustomPainter {
  _WeeklyActivityChartPainter({
    required this.days,
    required this.averageMinutes,
    required this.textStyle,
    required this.primaryColor,
    required this.aboveAverageColor,
    required this.belowAverageColor,
    required this.trackColor,
    required this.averageColor,
  });

  final List<_DailyExerciseTotal> days;
  final double averageMinutes;
  final TextStyle textStyle;
  final Color primaryColor;
  final Color aboveAverageColor;
  final Color belowAverageColor;
  final Color trackColor;
  final Color averageColor;

  @override
  void paint(Canvas canvas, Size size) {
    if (days.isEmpty) {
      return;
    }

    const topPadding = 18.0;
    const labelHeight = 24.0;
    const valueHeight = 18.0;
    final chartHeight = size.height - topPadding - labelHeight - valueHeight;
    final chartTop = topPadding;
    final chartBottom = chartTop + chartHeight;
    final maxMinutes = days.fold<double>(
      averageMinutes,
      (maxValue, day) =>
          day.minutes > maxValue ? day.minutes.toDouble() : maxValue,
    );
    final scaleMax = maxMinutes <= 0 ? 30.0 : maxMinutes * 1.18;
    final slotWidth = size.width / days.length;
    final barWidth = slotWidth.clamp(28.0, 42.0).toDouble() * 0.48;
    final radius = Radius.circular(barWidth / 2);

    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.fill;

    for (var index = 0; index < days.length; index++) {
      final day = days[index];
      final centerX = slotWidth * index + slotWidth / 2;
      final left = centerX - barWidth / 2;
      final right = centerX + barWidth / 2;
      final trackRect = RRect.fromRectAndRadius(
        Rect.fromLTRB(left, chartTop, right, chartBottom),
        radius,
      );
      canvas.drawRRect(trackRect, trackPaint);

      final barHeight = day.minutes <= 0
          ? 0.0
          : (day.minutes / scaleMax * chartHeight)
                .clamp(4.0, chartHeight)
                .toDouble();
      final barColor = day.minutes == 0
          ? primaryColor.withValues(alpha: 0.18)
          : day.minutes >= averageMinutes
          ? aboveAverageColor
          : belowAverageColor;
      final barPaint = Paint()
        ..color = barColor
        ..style = PaintingStyle.fill;
      final barRect = RRect.fromRectAndRadius(
        Rect.fromLTRB(left, chartBottom - barHeight, right, chartBottom),
        radius,
      );
      canvas.drawRRect(barRect, barPaint);

      _drawCenteredText(
        canvas,
        text: '${day.minutes}',
        x: centerX,
        y: chartBottom - barHeight - valueHeight,
        maxWidth: slotWidth,
        style: textStyle,
      );
      _drawCenteredText(
        canvas,
        text: day.dayLabel,
        x: centerX,
        y: chartBottom + AppDimensions.spaceS,
        maxWidth: slotWidth,
        style: textStyle,
      );
    }

    if (averageMinutes > 0) {
      final averageY = chartBottom - (averageMinutes / scaleMax * chartHeight);
      final averagePaint = Paint()
        ..color = averageColor
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke;
      canvas.drawLine(
        Offset(0, averageY),
        Offset(size.width, averageY),
        averagePaint,
      );
      _drawLabelBubble(
        canvas,
        text: 'avg ${averageMinutes.round()}',
        x: size.width,
        y: averageY,
      );
    }
  }

  void _drawCenteredText(
    Canvas canvas, {
    required String text,
    required double x,
    required double y,
    required double maxWidth,
    required TextStyle style,
  }) {
    final painter = TextPainter(
      text: TextSpan(text: text, style: style),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
      maxLines: 1,
    )..layout(maxWidth: maxWidth);
    painter.paint(canvas, Offset(x - painter.width / 2, y));
  }

  void _drawLabelBubble(
    Canvas canvas, {
    required String text,
    required double x,
    required double y,
  }) {
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: textStyle.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w800,
        ),
      ),
      textDirection: TextDirection.ltr,
      maxLines: 1,
    )..layout();
    const horizontalPadding = 7.0;
    const verticalPadding = 4.0;
    final width = painter.width + horizontalPadding * 2;
    final height = painter.height + verticalPadding * 2;
    final left = (x - width).clamp(0.0, x).toDouble();
    final top = (y - height - AppDimensions.spaceXS).clamp(0.0, y).toDouble();
    final rect = RRect.fromRectAndRadius(
      Rect.fromLTWH(left, top, width, height),
      const Radius.circular(AppDimensions.radiusS),
    );
    final paint = Paint()
      ..color = averageColor
      ..style = PaintingStyle.fill;
    canvas.drawRRect(rect, paint);
    painter.paint(
      canvas,
      Offset(left + horizontalPadding, top + verticalPadding),
    );
  }

  @override
  bool shouldRepaint(covariant _WeeklyActivityChartPainter oldDelegate) {
    return oldDelegate.days != days ||
        oldDelegate.averageMinutes != averageMinutes ||
        oldDelegate.textStyle != textStyle ||
        oldDelegate.trackColor != trackColor;
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
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
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
              child: const Icon(
                Icons.directions_walk,
                color: AppColors.primary,
              ),
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
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
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
  const _EmptyExerciseState({required this.petName, required this.onStart});

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
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
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
  const _ExerciseErrorState({required this.message, required this.onRetry});

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
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(color: AppColors.grey500),
            ),
            const SizedBox(height: AppDimensions.spaceM),
            OutlinedButton(onPressed: onRetry, child: const Text('Retry')),
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
