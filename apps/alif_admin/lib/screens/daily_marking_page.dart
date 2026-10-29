import 'package:alif_design_system/alif_design_system.dart';
import 'package:flutter/material.dart';

import '../models/activity.dart';
import '../models/rating.dart';
import '../models/student.dart';
import '../services/activity_log_service.dart';
import '../services/activity_service.dart';
import '../services/rating_service.dart';
import '../services/student_service.dart';

class DailyMarkingPage extends StatefulWidget {
  const DailyMarkingPage({super.key});

  @override
  State<DailyMarkingPage> createState() => _DailyMarkingPageState();
}

class _DailyMarkingPageState extends State<DailyMarkingPage> {
  final Map<String, List<RatingOption>> _ratingsByActivity = {};
  final Map<String, String?> _selectedRatingIdByActivity = {};
  final Map<String, TextEditingController> _quantityControllers = {};

  List<Student> _students = [];
  List<ActivityItem> _activities = [];
  bool _usedAllActivitiesFallback = false;
  bool _isLoading = true;
  String? _error;
  String? _selectedStudentId;
  DateTime _selectedDate = DateTime.now();
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadBaseData();
  }

  @override
  void dispose() {
    for (final controller in _quantityControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  String get _logDate {
    final month = _selectedDate.month.toString().padLeft(2, '0');
    final day = _selectedDate.day.toString().padLeft(2, '0');
    return '${_selectedDate.year}-$month-$day';
  }

  Future<void> _loadBaseData() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final studentsResponse = await StudentService.listStudents(
        limit: 200,
        offset: 0,
      );
      var activities = await ActivityService.listActivities(status: 'active');
      var usedAllActivitiesFallback = false;

      if (activities.isEmpty) {
        activities = await ActivityService.listActivities();
        usedAllActivitiesFallback = activities.isNotEmpty;
      }

      final ratingsByActivity = <String, List<RatingOption>>{};
      for (final activity in activities) {
        ratingsByActivity[activity.id] = await RatingService.listRatings(
          activityId: activity.id,
        );
      }

      if (!mounted) {
        return;
      }

      setState(() {
        _students = studentsResponse.data;
        _activities = activities;
        _ratingsByActivity
          ..clear()
          ..addAll(ratingsByActivity);
        _usedAllActivitiesFallback = usedAllActivitiesFallback;
        _selectedStudentId = _students.isNotEmpty ? _students.first.id : null;
      });

      if (_selectedStudentId != null) {
        await _loadExistingLogs();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _error = e.toString());
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _loadExistingLogs() async {
    final studentId = _selectedStudentId;
    if (studentId == null) {
      return;
    }

    final logs = await ActivityLogService.listLogs(
      studentId: studentId,
      logDate: _logDate,
    );

    if (!mounted) {
      return;
    }

    final selected = <String, String?>{};
    final quantities = <String, String>{};
    for (final log in logs) {
      selected[log.activityId] = log.ratingId;
      if (log.quantity != null) {
        quantities[log.activityId] = log.quantity.toString();
      }
    }

    setState(() {
      _selectedRatingIdByActivity
        ..clear()
        ..addAll(selected);
      for (final activity in _activities) {
        final controller = _quantityControllers.putIfAbsent(
          activity.id,
          () => TextEditingController(),
        );
        controller.text = quantities[activity.id] ?? '';
      }
    });
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );

    if (!mounted || picked == null) {
      return;
    }

    setState(() => _selectedDate = picked);
    await _loadExistingLogs();
  }

  Future<void> _saveActivityMark(ActivityItem activity) async {
    final studentId = _selectedStudentId;
    final ratingId = _selectedRatingIdByActivity[activity.id];
    if (studentId == null || ratingId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select student and rating first')),
      );
      return;
    }

    final quantityText = _quantityControllers[activity.id]?.text.trim() ?? '';
    final quantity = quantityText.isEmpty ? null : int.tryParse(quantityText);

    try {
      setState(() => _isSaving = true);
      await ActivityLogService.upsertLog(
        studentId: studentId,
        activityId: activity.id,
        ratingId: ratingId,
        logDate: _logDate,
        quantity: quantity,
      );

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Saved ${activity.name}')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Save failed: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlifAppShell(
      title: 'Daily Marking',
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(
              child: Text(
                'Error: $_error',
                style: const TextStyle(color: Colors.red),
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(AlifSpacing.md),
              children: [
                AlifCard(
                  child: Column(
                    children: [
                      DropdownButtonFormField<String>(
                        initialValue: _selectedStudentId,
                        items: _students
                            .map(
                              (student) => DropdownMenuItem<String>(
                                value: student.id,
                                child: Text(
                                  '${student.fatherName} / ${student.motherName} (${student.parentPhone})',
                                ),
                              ),
                            )
                            .toList(),
                        onChanged: (value) async {
                          if (value == null) {
                            return;
                          }

                          setState(() => _selectedStudentId = value);
                          await _loadExistingLogs();
                        },
                        decoration: InputDecoration(
                          labelText: 'Student',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                      const SizedBox(height: AlifSpacing.md),
                      Row(
                        children: [
                          Expanded(child: Text('Date: $_logDate')),
                          FilledButton.tonal(
                            onPressed: _pickDate,
                            child: const Text('Change Date'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AlifSpacing.md),
                if (_students.isEmpty)
                  const Padding(
                    padding: EdgeInsets.only(bottom: AlifSpacing.md),
                    child: AlifCard(
                      child: Text(
                        'No students found. Add a student first from Student Management.',
                      ),
                    ),
                  ),
                if (_activities.isEmpty)
                  const Padding(
                    padding: EdgeInsets.only(bottom: AlifSpacing.md),
                    child: AlifCard(
                      child: Text(
                        'No activities found. Add activities in Configuration to start daily marking.',
                      ),
                    ),
                  ),
                if (_usedAllActivitiesFallback)
                  const Padding(
                    padding: EdgeInsets.only(bottom: AlifSpacing.md),
                    child: AlifCard(
                      child: Text(
                        'No active activities found. Showing all activities including inactive ones.',
                      ),
                    ),
                  ),
                ..._activities.map((activity) {
                  final ratings =
                      _ratingsByActivity[activity.id] ?? const <RatingOption>[];
                  final quantityController = _quantityControllers.putIfAbsent(
                    activity.id,
                    () => TextEditingController(),
                  );

                  return Padding(
                    padding: const EdgeInsets.only(bottom: AlifSpacing.md),
                    child: AlifCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            activity.name,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          if ((activity.nameMl ?? '').isNotEmpty)
                            Text(
                              activity.nameMl!,
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          const SizedBox(height: AlifSpacing.md),
                          DropdownButtonFormField<String>(
                            initialValue:
                                _selectedRatingIdByActivity[activity.id],
                            items: ratings
                                .map(
                                  (rating) => DropdownMenuItem<String>(
                                    value: rating.id,
                                    child: Text(
                                      '${rating.ratingName} (${rating.marks})',
                                    ),
                                  ),
                                )
                                .toList(),
                            onChanged: (value) {
                              setState(() {
                                _selectedRatingIdByActivity[activity.id] =
                                    value;
                              });
                            },
                            decoration: InputDecoration(
                              labelText: 'Rating',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                          if (activity.hasQuantity) ...[
                            const SizedBox(height: AlifSpacing.md),
                            TextField(
                              controller: quantityController,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                labelText: 'Quantity',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ],
                          const SizedBox(height: AlifSpacing.md),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              FilledButton(
                                onPressed: _isSaving
                                    ? null
                                    : () => _saveActivityMark(activity),
                                child: const Text('Save Mark'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ],
            ),
    );
  }
}
