import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_frontend/app/routes.dart';
import 'package:flutter_frontend/core/constants/app_colors.dart';
import 'package:flutter_frontend/core/constants/app_dimensions.dart';
import 'package:flutter_frontend/presentation/pages/exercise/add_exercise/add_exercise_args.dart';

class LiveSessionPage extends StatefulWidget {
  const LiveSessionPage({super.key, this.args});

  final AddExerciseArgs? args;

  @override
  State<LiveSessionPage> createState() => _LiveSessionPageState();
}

class _LiveSessionPageState extends State<LiveSessionPage> {
  final Stopwatch _stopwatch = Stopwatch();

  Timer? _ticker;
  String _selectedType = 'walk';
  DateTime? _startedAt;

  static const List<String> _exerciseTypes = [
    'walk',
    'run',
    'play',
    'training',
    'other',
  ];

  @override
  void initState() {
    super.initState();
    _selectedType = widget.args?.prefilledType ?? 'walk';
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _stopwatch.stop();
    super.dispose();
  }

  void _toggleSession() {
    setState(() {
      if (_stopwatch.isRunning) {
        _stopwatch.stop();
        _ticker?.cancel();
        _ticker = null;
      } else {
        _startedAt ??= DateTime.now();
        _stopwatch.start();
        _ticker ??= Timer.periodic(const Duration(seconds: 1), (_) {
          if (mounted) {
            setState(() {});
          }
        });
      }
    });
  }

  Future<void> _finishSession() async {
    final elapsedMinutes = (_stopwatch.elapsed.inSeconds / 60).ceil();
    final petId = widget.args?.petId.trim() ?? '';
    if (elapsedMinutes <= 0 || _startedAt == null) {
      _showMessage('Run the session for at least a few seconds first.');
      return;
    }
    if (petId.isEmpty) {
      _showMessage('Choose a pet before finishing this session.');
      return;
    }

    _ticker?.cancel();
    _ticker = null;
    _stopwatch.stop();

    if (!mounted) {
      return;
    }

    final changed = await Navigator.of(context).pushNamed(
      Routes.addExercise,
      arguments: AddExerciseArgs(
        petId: petId,
        petName: widget.args?.petName ?? 'Pet session',
        prefilledType: _selectedType,
        prefilledStartedAt: _startedAt,
        prefilledDurationMinutes: elapsedMinutes,
      ),
    );
    if (!mounted) {
      return;
    }
    Navigator.of(context).pop(changed == true);
  }

  String get _durationText {
    final elapsed = _stopwatch.elapsed;
    final hours = elapsed.inHours.toString().padLeft(2, '0');
    final minutes = (elapsed.inMinutes % 60).toString().padLeft(2, '0');
    final seconds = (elapsed.inSeconds % 60).toString().padLeft(2, '0');
    return '$hours:$minutes:$seconds';
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('Live session')),
      body: Padding(
              padding: const EdgeInsets.all(AppDimensions.pageHorizontalPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    padding: const EdgeInsets.all(AppDimensions.spaceL),
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.secondaryDark
                          : AppColors.secondary,
                      borderRadius: BorderRadius.circular(AppDimensions.radiusL),
                      border: isDark ? Border.all(color: AppColors.grey700) : null,
                    ),
                    child: Column(
                      children: [
                        Text(
                          'Track a session in real time',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: AppDimensions.spaceL),
                        Text(
                          widget.args?.petName ?? 'Pet session',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: isDark ? AppColors.grey500 : AppColors.grey700,
                          ),
                        ),
                        const SizedBox(height: AppDimensions.spaceM),
                        DropdownButtonFormField<String>(
                          value: _selectedType,
                          decoration: const InputDecoration(
                            labelText: 'Exercise type',
                            border: OutlineInputBorder(),
                          ),
                          items: _exerciseTypes
                              .map(
                                (type) => DropdownMenuItem<String>(
                                  value: type,
                                  child: Text(_labelize(type)),
                                ),
                              )
                              .toList(growable: false),
                          onChanged: _stopwatch.isRunning
                              ? null
                              : (value) {
                                  if (value != null) {
                                    setState(() => _selectedType = value);
                                  }
                                },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppDimensions.spaceL),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(AppDimensions.spaceXL),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: isDark
                              ? const [Color(0xFF173B37), Color(0xFF0F2C28)]
                              : const [Color(0xFFE2F6F3), Color(0xFFCDEFE8)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(AppDimensions.radiusXL),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.directions_walk, size: 48),
                          const SizedBox(height: AppDimensions.spaceL),
                          Text(
                            _durationText,
                            style: Theme.of(context).textTheme.displaySmall?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: AppDimensions.spaceS),
                          Text(
                            _stopwatch.isRunning
                                ? 'Session is running'
                                : _startedAt == null
                                    ? 'Ready when you are'
                                    : 'Session paused',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: AppDimensions.spaceXL),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: () => Navigator.of(context).pop(),
                                  child: const Text('Cancel'),
                                ),
                              ),
                              const SizedBox(width: AppDimensions.spaceM),
                              Expanded(
                                child: FilledButton(
                                  onPressed: _toggleSession,
                                  child: Text(
                                    _stopwatch.isRunning
                                        ? 'Pause'
                                        : _startedAt == null
                                            ? 'Start'
                                            : 'Resume',
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppDimensions.spaceM),
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton.tonal(
                              onPressed: _finishSession,
                              child: const Text('Finish and save'),
                            ),
                          ),
                        ],
                      ),
                    ),
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
