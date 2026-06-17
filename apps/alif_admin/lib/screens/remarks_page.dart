import 'package:alif_design_system/alif_design_system.dart';
import 'package:flutter/material.dart';

import '../models/remark.dart';
import '../models/student.dart';
import '../models/teacher.dart';
import '../services/remark_service.dart';
import '../services/student_service.dart';
import '../services/teacher_service.dart';

class RemarksPage extends StatefulWidget {
  const RemarksPage({super.key});

  @override
  State<RemarksPage> createState() => _RemarksPageState();
}

class _RemarksPageState extends State<RemarksPage> {
  final _remarkController = TextEditingController();

  List<Teacher> _teachers = [];
  List<Student> _students = [];
  List<TeacherRemark> _remarks = [];

  String? _selectedTeacherId;
  String? _selectedStudentId;

  bool _isLoading = true;
  bool _isSubmitting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _remarkController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final teachers = await TeacherService.listTeachers(status: 'active');
      final studentsResponse = await StudentService.listStudents(limit: 200, offset: 0, status: 'active');

      _selectedTeacherId ??= teachers.isNotEmpty ? teachers.first.id : null;
      _selectedStudentId ??= studentsResponse.data.isNotEmpty ? studentsResponse.data.first.id : null;

      final remarks = await RemarkService.listRemarks(
        teacherId: _selectedTeacherId,
        studentId: _selectedStudentId,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _teachers = teachers;
        _students = studentsResponse.data;
        _remarks = remarks;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }
      setState(() => _error = e.toString());
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _applyFilter() async {
    try {
      setState(() => _isLoading = true);
      final remarks = await RemarkService.listRemarks(
        teacherId: _selectedTeacherId,
        studentId: _selectedStudentId,
      );

      if (!mounted) {
        return;
      }

      setState(() => _remarks = remarks);
    } catch (e) {
      if (!mounted) {
        return;
      }
      setState(() => _error = e.toString());
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _submit() async {
    final remarkText = _remarkController.text.trim();
    if (_selectedTeacherId == null || _selectedStudentId == null || remarkText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select teacher, student, and enter remark')),
      );
      return;
    }

    try {
      setState(() => _isSubmitting = true);

      await RemarkService.createRemark(
        teacherId: _selectedTeacherId!,
        studentId: _selectedStudentId!,
        remark: remarkText,
      );

      _remarkController.clear();
      await _applyFilter();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Remark added successfully')),
        );
      }
    } catch (e) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to add remark: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlifAppShell(
      title: 'Teacher Remarks',
      body: ListView(
        padding: const EdgeInsets.all(AlifSpacing.md),
        children: [
          AlifCard(
            child: Column(
              children: [
                DropdownButtonFormField<String>(
                  initialValue: _selectedTeacherId,
                  items: _teachers
                      .map(
                        (teacher) => DropdownMenuItem<String>(
                          value: teacher.id,
                          child: Text(teacher.fullName),
                        ),
                      )
                      .toList(),
                  onChanged: (value) => setState(() => _selectedTeacherId = value),
                  decoration: const InputDecoration(labelText: 'Teacher'),
                ),
                const SizedBox(height: AlifSpacing.md),
                DropdownButtonFormField<String>(
                  initialValue: _selectedStudentId,
                  items: _students
                      .map(
                        (student) => DropdownMenuItem<String>(
                          value: student.id,
                          child: Text('${student.fatherName} / ${student.motherName}'),
                        ),
                      )
                      .toList(),
                  onChanged: (value) => setState(() => _selectedStudentId = value),
                  decoration: const InputDecoration(labelText: 'Student'),
                ),
                const SizedBox(height: AlifSpacing.md),
                TextField(
                  controller: _remarkController,
                  minLines: 2,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: 'Remark',
                    hintText: 'Type teacher feedback...',
                  ),
                ),
                const SizedBox(height: AlifSpacing.md),
                Row(
                  children: [
                    Expanded(
                      child: FilledButton.tonalIcon(
                        onPressed: _isLoading ? null : _applyFilter,
                        icon: const Icon(Icons.filter_alt_outlined),
                        label: const Text('Apply Filter'),
                      ),
                    ),
                    const SizedBox(width: AlifSpacing.md),
                    Expanded(
                      child: AlifButton(
                        label: 'Add Remark',
                        isLoading: _isSubmitting,
                        onPressed: _isSubmitting ? null : _submit,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: AlifSpacing.md),
          if (_isLoading)
            const Center(child: CircularProgressIndicator())
          else if (_error != null)
            Text('Error: $_error', style: const TextStyle(color: Colors.red))
          else if (_remarks.isEmpty)
            const AlifCard(child: Text('No remarks found for selected filters.'))
          else
            ..._remarks.map(
              (remark) => Padding(
                padding: const EdgeInsets.only(bottom: AlifSpacing.md),
                child: AlifCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        remark.remark,
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                      const SizedBox(height: AlifSpacing.sm),
                      Text(
                        'Teacher: ${remark.teacherName ?? remark.teacherId}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      Text(
                        'Student: ${remark.studentName ?? remark.studentId}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      Text(
                        'Phone: ${remark.parentPhone ?? '-'}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      Text(
                        'Created: ${remark.createdAt.toLocal()}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
