import 'package:flutter/material.dart';
import 'package:flutter_frontend/core/constants/app_strings.dart';
import 'package:flutter_frontend/presentation/pages/add_flow/utils/date_input.dart';
import 'package:flutter_frontend/presentation/pages/add_flow/widgets/add_flow_scaffold.dart';
import 'package:flutter_frontend/presentation/pages/add_event/widgets/add_event_step_basic.dart';
import 'package:flutter_frontend/presentation/pages/add_event/widgets/add_event_step_details.dart';
import 'package:flutter_frontend/presentation/pages/add_event/widgets/add_event_step_overview.dart';

class AddEventPage extends StatefulWidget {
  const AddEventPage({super.key});

  @override
  State<AddEventPage> createState() => _AddEventPageState();
}

class _AddEventPageState extends State<AddEventPage> {
  final _formKey = GlobalKey<FormState>();
  final _dateController = TextEditingController();
  final _eventController = TextEditingController();
  final _timeController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _petNameController = TextEditingController();
  int _step = 0;

  @override
  void dispose() {
    _dateController.dispose();
    _eventController.dispose();
    _timeController.dispose();
    _descriptionController.dispose();
    _petNameController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (pickedDate == null) {
      return;
    }

    _dateController.text = formatDateForInput(pickedDate);
  }

  void _continue() {
    final isValid = _formKey.currentState?.validate() ?? false;
    if (!isValid) {
      return;
    }

    setState(() {
      if (_step < 2) {
        _step++;
      }
    });
  }

  Future<void> _pickTime() async {
    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );

    if (pickedTime == null) {
      return;
    }

    final hour = pickedTime.hour.toString().padLeft(2, '0');
    final minute = pickedTime.minute.toString().padLeft(2, '0');
    _timeController.text = '$hour:$minute';
  }

  void _back() {
    setState(() {
      if (_step > 0) {
        _step--;
      }
    });
  }

  void _submit() {
    if (_formKey.currentState?.validate() ?? false) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sample vaccine form submitted')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AddFlowScaffold(
      title: AppStrings.addEventTitle,
      formKey: _formKey,
      steps: const [
        AppStrings.stepBasicInfo,
        AppStrings.stepDetails,
        AppStrings.stepOverview,
      ],
      currentStep: _step,
      stepContent: _buildStepContent(),
      primaryButtonText: _step == 2
          ? AppStrings.semanticAddEventButton
          : AppStrings.semanticContinueButton,
      onPrimaryPressed: _step == 2 ? _submit : _continue,
      onBackPressed: _back,
      backButtonText: AppStrings.semanticBackButton,
    );
  }

  List<Widget> _buildStepContent() {
    switch (_step) {
      case 0:
        return [
          AddEventStepBasic(
            eventController: _eventController,
            dateController: _dateController,
            timeController: _timeController,
            petNameController: _petNameController,
            onPickDate: _pickDate,
            onPickTime: _pickTime,
          ),
        ];
      case 1:
        return [
          AddEventStepDetails(
            descriptionController: _descriptionController,
          ),
        ];
      case 2:
      default:
        return [
          AddEventStepOverview(
            eventController: _eventController,
            dateController: _dateController,
            timeController: _timeController,
            petNameController: _petNameController,
            descriptionController: _descriptionController,
          ),
        ];
    }
  }
}
