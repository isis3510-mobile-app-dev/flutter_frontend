import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_frontend/core/constants/app_colors.dart';
import 'package:flutter_frontend/core/constants/app_dimensions.dart';
import 'package:flutter_frontend/core/services/exercise_service.dart';

import 'add_exercise_args.dart';

class AddExercisePage extends StatefulWidget {
  const AddExercisePage({super.key, this.args});

  final AddExerciseArgs? args;

  @override
  State<AddExercisePage> createState() => _AddExercisePageState();
}

class _AddExercisePageState extends State<AddExercisePage> {
  final ExerciseService _exerciseService = ExerciseService();
  final TextEditingController _durationController = TextEditingController();
  final TextEditingController _distanceController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  bool _isSaving = false;
  String _selectedType = 'walk';
  String _selectedIntensity = 'medium';
  late DateTime _selectedDateTime;

  bool get _isEditing => widget.args?.editingExercise != null;

  static const List<String> _exerciseTypes = [
    'walk',
    'run',
    'play',
    'training',
    'other',
  ];

  static const List<String> _intensityLevels = ['low', 'medium', 'high'];

  @override
  void initState() {
    super.initState();
    _seedForm();
  }

  void _seedForm() {
    final editing = widget.args?.editingExercise;
    if (editing != null) {
      _selectedType = editing.type;
      _selectedIntensity = editing.intensity;
      _selectedDateTime = editing.startedAt;
      _durationController.text = editing.durationMinutes.toString();
      if (editing.distanceKm != null) {
        _distanceController.text = editing.distanceKm!.toStringAsFixed(2);
      }
      _notesController.text = editing.notes;
      return;
    }

    _selectedType = widget.args?.prefilledType ?? 'walk';
    _selectedDateTime = widget.args?.prefilledStartedAt ?? DateTime.now();
    final prefilledDuration = widget.args?.prefilledDurationMinutes;
    if (prefilledDuration != null && prefilledDuration > 0) {
      _durationController.text = prefilledDuration.toString();
    }
  }

  @override
  void dispose() {
    _durationController.dispose();
    _distanceController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDateTime,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked == null) {
      return;
    }

    setState(() {
      _selectedDateTime = DateTime(
        picked.year,
        picked.month,
        picked.day,
        _selectedDateTime.hour,
        _selectedDateTime.minute,
      );
    });
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_selectedDateTime),
    );
    if (picked == null) {
      return;
    }

    setState(() {
      _selectedDateTime = DateTime(
        _selectedDateTime.year,
        _selectedDateTime.month,
        _selectedDateTime.day,
        picked.hour,
        picked.minute,
      );
    });
  }

  Future<void> _save() async {
    final petId = widget.args?.petId.trim() ?? '';
    final duration = int.tryParse(_durationController.text.trim());
    final distanceText = _distanceController.text.trim();
    final distance = distanceText.isEmpty ? null : double.tryParse(distanceText);

    if (petId.isEmpty) {
      _showMessage('Choose a pet before saving this session.');
      return;
    }
    if (duration == null || duration <= 0) {
      _showMessage('Enter a valid duration in minutes.');
      return;
    }
    if (distanceText.isNotEmpty && distance == null) {
      _showMessage('Distance must be a valid number.');
      return;
    }

    setState(() => _isSaving = true);

    final payload = <String, dynamic>{
      'petId': petId,
      'type': _selectedType,
      'startedAt': _selectedDateTime.toIso8601String(),
      'durationMinutes': duration,
      'intensity': _selectedIntensity,
      'distanceKm': distance,
      'notes': _notesController.text.trim(),
    };

    try {
      if (_isEditing) {
        await _exerciseService.updateExercise(
          petId: petId,
          exerciseId: widget.args!.editingExercise!.id,
          data: payload,
        );
      } else {
        await _exerciseService.createExercise(petId: petId, data: payload);
      }

      if (!mounted) {
        return;
      }
      Navigator.of(context).pop(true);
    } catch (_) {
      if (!mounted) {
        return;
      }
      _showMessage('Unable to save exercise right now.');
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  String _formatDate(DateTime value) {
    return '${value.day}/${value.month}/${value.year}';
  }

  String _formatTime(DateTime value) {
    final hour = value.hour % 12 == 0 ? 12 : value.hour % 12;
    final minute = value.minute.toString().padLeft(2, '0');
    final suffix = value.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $suffix';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit exercise' : 'Log exercise'),
      ),
      body: ListView(
              padding: const EdgeInsets.all(AppDimensions.pageHorizontalPadding),
              children: [
                _SectionCard(
                  isDark: isDark,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Session details',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: AppDimensions.spaceM),
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
                        onChanged: (value) {
                          if (value != null) {
                            setState(() => _selectedType = value);
                          }
                        },
                      ),
                      const SizedBox(height: AppDimensions.spaceM),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _pickDate,
                              icon: const Icon(Icons.calendar_today_outlined),
                              label: Text(_formatDate(_selectedDateTime)),
                            ),
                          ),
                          const SizedBox(width: AppDimensions.spaceS),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _pickTime,
                              icon: const Icon(Icons.schedule_outlined),
                              label: Text(_formatTime(_selectedDateTime)),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppDimensions.spaceM),
                      TextField(
                        controller: _durationController,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          TextInputFormatter.withFunction((oldValue, newValue) {
                            if (newValue.text.isEmpty) return newValue;
                            final number = int.tryParse(newValue.text);
                            if (number == null || number > 360) return oldValue;
                            return newValue;
                          }),
                        ],
                        decoration: const InputDecoration(
                          labelText: 'Duration (minutes)',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: AppDimensions.spaceM),
                      DropdownButtonFormField<String>(
                        value: _selectedIntensity,
                        decoration: const InputDecoration(
                          labelText: 'Intensity',
                          border: OutlineInputBorder(),
                        ),
                        items: _intensityLevels
                            .map(
                              (level) => DropdownMenuItem<String>(
                                value: level,
                                child: Text(_labelize(level)),
                              ),
                            )
                            .toList(growable: false),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() => _selectedIntensity = value);
                          }
                        },
                      ),
                      const SizedBox(height: AppDimensions.spaceM),
                      TextField(
                        controller: _distanceController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d*')),
                          TextInputFormatter.withFunction((oldValue, newValue) {
                            if (newValue.text.isEmpty) return newValue;
                            if (newValue.text.length > 5) return oldValue; // Limit to 3 digits before decimal
                            final number = double.tryParse(newValue.text);
                            if (number == null || number > 21) return oldValue;
                            return newValue;
                          }),
                        ],
                        decoration: const InputDecoration(
                          labelText: 'Distance (km, optional)',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: AppDimensions.spaceM),
                      TextField(
                        controller: _notesController,
                        maxLines: 4,
                        decoration: const InputDecoration(
                          labelText: 'Notes',
                          border: OutlineInputBorder(),
                        ),
                        inputFormatters: [
                          LengthLimitingTextInputFormatter(500),
                          FilteringTextInputFormatter.allow(RegExp(r'^[a-zA-Z0-9\s.,!?()\-]*$')),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppDimensions.spaceL),
                SizedBox(
                  height: AppDimensions.buttonHeightL,
                  child: FilledButton(
                    onPressed: _isSaving ? null : _save,
                    child: _isSaving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(_isEditing ? 'Save changes' : 'Save exercise'),
                  ),
                ),
              ],
            ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.child, required this.isDark});

  final Widget child;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.spaceL),
      decoration: BoxDecoration(
        color: isDark ? AppColors.secondaryDark : AppColors.secondary,
        borderRadius: BorderRadius.circular(AppDimensions.radiusL),
        border: isDark ? Border.all(color: AppColors.grey700) : null,
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.16)
                : AppColors.shadowSoft,
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }
}

String _labelize(String value) {
  if (value.isEmpty) {
    return value;
  }
  return '${value[0].toUpperCase()}${value.substring(1)}';
}
