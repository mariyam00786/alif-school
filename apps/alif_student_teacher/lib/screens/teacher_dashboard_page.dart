import 'package:flutter/material.dart';
import 'package:alif_design_system/alif_design_system.dart';
import 'package:alif_student_teacher/models/badge_teacher.dart';
import 'package:alif_student_teacher/services/api_service.dart';

class TeacherDashboardPage extends StatefulWidget {
  const TeacherDashboardPage({super.key});

  @override
  State<TeacherDashboardPage> createState() => _TeacherDashboardPageState();
}

class _TeacherDashboardPageState extends State<TeacherDashboardPage> {
  bool _isLoading = true;
  String? _error;
  List<TeacherInfo> _teachers = const [];
  String? _selectedBatchId;
  List<Map<String, dynamic>> _batchStudents = const [];
  bool _loadingStudents = false;
  TeacherBatchAnalytics? _batchAnalytics;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final teachers = await ApiService.getTeacherBatches();

      if (!mounted) {
        return;
      }

      setState(() => _teachers = teachers);

      // Load students for first batch if available
      if (teachers.isNotEmpty && teachers.first.batchIds.isNotEmpty) {
        await _loadBatchStudents(teachers.first.batchIds.first);
      }
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

  Future<void> _loadBatchStudents(String batchId) async {
    try {
      setState(() {
        _loadingStudents = true;
        _selectedBatchId = batchId;
      });

      final students = await ApiService.getTeacherStudents(batchId: batchId);
      final analytics = await ApiService.getBatchAnalytics(batchId: batchId);

      if (!mounted) {
        return;
      }

      setState(() {
        _batchStudents = students;
        _batchAnalytics = analytics;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }
      setState(() => _error = e.toString());
    } finally {
      if (mounted) {
        setState(() => _loadingStudents = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Teacher Dashboard')),
      body: ListView(
        padding: const EdgeInsets.all(AlifSpacing.md),
        children: [
          if (_isLoading)
            const Center(child: CircularProgressIndicator())
          else if (_error != null)
            Text('Error: $_error', style: const TextStyle(color: Colors.red))
          else ...[
            AlifCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Assigned Batches',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: AlifSpacing.md),
                  if (_teachers.isEmpty)
                    const Text('No batches assigned yet.')
                  else
                    Wrap(
                      spacing: AlifSpacing.sm,
                      runSpacing: AlifSpacing.sm,
                      children: _teachers.expand((teacher) {
                        return teacher.batchNames.asMap().entries.map((entry) {
                          final batchId = teacher.batchIds[entry.key];
                          final batchName = entry.value;
                          final isSelected = _selectedBatchId == batchId;

                          return FilterChip(
                            label: Text(batchName),
                            selected: isSelected,
                            onSelected: (_) => _loadBatchStudents(batchId),
                          );
                        });
                      }).toList(),
                    ),
                ],
              ),
            ),
            const SizedBox(height: AlifSpacing.md),
            if (_batchAnalytics != null)
              AlifCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${_batchAnalytics!.batchName} - Analytics',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: AlifSpacing.md),
                    Row(
                      children: [
                        Expanded(
                          child: _buildStatChip(
                            label: 'Students',
                            value: '${_batchAnalytics!.totalStudents}',
                          ),
                        ),
                        const SizedBox(width: AlifSpacing.sm),
                        Expanded(
                          child: _buildStatChip(
                            label: 'Completion',
                            value: '${_batchAnalytics!.completionRate}%',
                          ),
                        ),
                        const SizedBox(width: AlifSpacing.sm),
                        Expanded(
                          child: _buildStatChip(
                            label: 'Avg Marks',
                            value: '${_batchAnalytics!.averageMarks}',
                          ),
                        ),
                      ],
                    ),
                    if (_batchAnalytics!.topPerformers.isNotEmpty) ...[
                      const SizedBox(height: AlifSpacing.md),
                      Text(
                        'Top Performers',
                        style: Theme.of(context).textTheme.labelMedium,
                      ),
                      const SizedBox(height: AlifSpacing.sm),
                      ..._batchAnalytics!.topPerformers
                          .map((name) => Text('• $name'))
                          ,
                    ],
                  ],
                ),
              ),
            const SizedBox(height: AlifSpacing.md),
            if (_loadingStudents)
              const Center(child: CircularProgressIndicator())
            else if (_batchStudents.isEmpty)
              const AlifCard(child: Text('No students in this batch.'))
            else
              ..._batchStudents.map((student) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: AlifSpacing.md),
                  child: AlifCard(
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: AlifColors.primaryContainer,
                        child: const Icon(Icons.person),
                      ),
                      title: Text(
                        '${student['father_name']} / ${student['mother_name']}',
                      ),
                      subtitle: Text(
                        'Status: ${student['status']}',
                      ),
                      trailing: const Icon(Icons.arrow_forward),
                      onTap: () {
                        // Navigate to student progress page
                      },
                    ),
                  ),
                );
              }),
          ],
        ],
      ),
    );
  }

  Widget _buildStatChip({required String label, required String value}) {
    return Container(
      padding: const EdgeInsets.all(AlifSpacing.md),
      decoration: BoxDecoration(
        color: AlifColors.primaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AlifColors.primary,
                ),
          ),
          const SizedBox(height: AlifSpacing.xs),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall,
          ),
        ],
      ),
    );
  }
}
