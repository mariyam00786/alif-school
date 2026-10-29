import 'package:flutter/material.dart';
import 'package:alif_design_system/alif_design_system.dart';
import 'package:alif_student_teacher/models/student.dart';
import 'package:alif_student_teacher/models/leaderboard.dart';
import 'package:alif_student_teacher/models/teacher_remark.dart';
import 'package:alif_student_teacher/services/api_service.dart';
import 'package:alif_student_teacher/services/auth_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ParentInsightsPage extends StatefulWidget {
  const ParentInsightsPage({super.key});

  @override
  State<ParentInsightsPage> createState() => _ParentInsightsPageState();
}

class _ParentInsightsPageState extends State<ParentInsightsPage> {
  bool _isLoading = true;
  String? _error;
  List<LinkedStudent> _linkedStudents = const [];
  String? _selectedStudentId;
  ProgressResult? _weeklyProgress;
  List<TeacherRemark> _teacherRemarks = const [];
  DateTime? _remarksSeenAt;
  int _unreadRemarksCount = 0;
  bool _loadingProgress = false;

  String _remarksSeenKey(String studentId) => 'remarks_seen_at_$studentId';

  DateTime? _tryParseDate(String? value) {
    if (value == null || value.isEmpty) {
      return null;
    }
    return DateTime.tryParse(value)?.toUtc();
  }

  int _countUnreadRemarks(List<TeacherRemark> remarks, DateTime? seenAt) {
    if (seenAt == null) {
      return remarks.length;
    }

    return remarks.where((item) {
      final created = _tryParseDate(item.createdAt);
      if (created == null) {
        return false;
      }
      return created.isAfter(seenAt);
    }).length;
  }

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

      final session = AuthService.currentSession;
      final parentPhone = session?.user.phone ?? '9999999999';
      final students = await ApiService.getLinkedStudents(parentPhone: parentPhone);

      if (!mounted) {
        return;
      }

      setState(() => _linkedStudents = students);

      if (students.isNotEmpty) {
        await _loadStudentProgress(students.first.id);
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

  Future<void> _loadStudentProgress(String studentId) async {
    try {
      setState(() {
        _loadingProgress = true;
        _selectedStudentId = studentId;
      });

      final progress = await ApiService.getWeeklyProgress(studentId: studentId);
      final remarks = await ApiService.getTeacherRemarks(studentId: studentId, limit: 5);
      final prefs = await SharedPreferences.getInstance();
      final seenRaw = prefs.getString(_remarksSeenKey(studentId));
      final seenAt = _tryParseDate(seenRaw);
      final unreadCount = _countUnreadRemarks(remarks, seenAt);

      if (!mounted) {
        return;
      }

      setState(() {
        _weeklyProgress = progress;
        _teacherRemarks = remarks;
        _remarksSeenAt = seenAt;
        _unreadRemarksCount = unreadCount;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }
      setState(() => _error = e.toString());
    } finally {
      if (mounted) {
        setState(() => _loadingProgress = false);
      }
    }
  }

  Future<void> _markRemarksAsRead() async {
    final studentId = _selectedStudentId;
    if (studentId == null) {
      return;
    }

    final newestCreatedAt = _teacherRemarks.isNotEmpty
        ? _tryParseDate(_teacherRemarks.first.createdAt)
        : DateTime.now().toUtc();
    final markAt = newestCreatedAt ?? DateTime.now().toUtc();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_remarksSeenKey(studentId), markAt.toIso8601String());

    if (!mounted) {
      return;
    }

    setState(() {
      _remarksSeenAt = markAt;
      _unreadRemarksCount = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Parent Insights')),
      body: ListView(
        padding: const EdgeInsets.all(AlifSpacing.md),
        children: [
          if (_isLoading)
            const Center(child: CircularProgressIndicator())
          else if (_error != null)
            Text('Error: $_error', style: const TextStyle(color: Colors.red))
          else ...[
            if (_linkedStudents.isEmpty)
              const AlifCard(child: Text('No linked children found.'))
            else ...[
              AlifCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Select Child',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: AlifSpacing.md),
                    Wrap(
                      spacing: AlifSpacing.sm,
                      runSpacing: AlifSpacing.sm,
                      children: _linkedStudents.map((student) {
                        final isSelected = _selectedStudentId == student.id;
                        return FilterChip(
                          label: Text(student.name),
                          selected: isSelected,
                          onSelected: (_) => _loadStudentProgress(student.id),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AlifSpacing.md),
              if (_loadingProgress)
                const Center(child: CircularProgressIndicator())
              else if (_weeklyProgress != null) ...[
                AlifCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'This Week\'s Progress',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: AlifSpacing.md),
                      Row(
                        children: [
                          Expanded(
                            child: _buildProgressStat(
                              label: 'Total Marks',
                              value: '${_weeklyProgress!.summary.totalMarks}',
                            ),
                          ),
                          const SizedBox(width: AlifSpacing.md),
                          Expanded(
                            child: _buildProgressStat(
                              label: 'Activities',
                              value: '${_weeklyProgress!.summary.totalActivities}',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AlifSpacing.md),
                      Text(
                        'Daily Breakdown',
                        style: Theme.of(context).textTheme.labelMedium,
                      ),
                      const SizedBox(height: AlifSpacing.sm),
                      ..._weeklyProgress!.rows.map((row) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: AlifSpacing.sm),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(row.logDate),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: AlifSpacing.md,
                                  vertical: AlifSpacing.sm,
                                ),
                                decoration: BoxDecoration(
                                  color: AlifColors.primaryContainer,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  '${row.marksEarned} pts',
                                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                                        color: AlifColors.primary,
                                      ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
                  ),
                ),
                const SizedBox(height: AlifSpacing.md),
                AlifCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'Recent Teacher Remarks',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(width: AlifSpacing.sm),
                          if (_unreadRemarksCount > 0)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AlifSpacing.sm,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: AlifColors.error,
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                '$_unreadRemarksCount new',
                                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                      color: Colors.white,
                                    ),
                              ),
                            ),
                          const Spacer(),
                          if (_unreadRemarksCount > 0)
                            TextButton(
                              onPressed: _markRemarksAsRead,
                              child: const Text('Mark all as read'),
                            ),
                        ],
                      ),
                      const SizedBox(height: AlifSpacing.md),
                      if (_teacherRemarks.isEmpty)
                        const Text('No teacher remarks yet for this child.')
                      else
                        ..._teacherRemarks.map(
                          (item) {
                            final created = _tryParseDate(item.createdAt);
                            final isUnread = _remarksSeenAt == null
                                ? true
                                : (created?.isAfter(_remarksSeenAt!) ?? false);

                            return Padding(
                              padding: const EdgeInsets.only(bottom: AlifSpacing.md),
                              child: Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(AlifSpacing.md),
                                decoration: BoxDecoration(
                                  color: isUnread
                                      ? AlifColors.primaryContainer
                                      : AlifColors.surface,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(child: Text(item.remark)),
                                        if (isUnread)
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: AlifSpacing.sm,
                                              vertical: 2,
                                            ),
                                            decoration: BoxDecoration(
                                              color: AlifColors.primary,
                                              borderRadius: BorderRadius.circular(999),
                                            ),
                                            child: Text(
                                              'NEW',
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .labelSmall
                                                  ?.copyWith(color: Colors.white),
                                            ),
                                          ),
                                      ],
                                    ),
                                    const SizedBox(height: AlifSpacing.xs),
                                    Text(
                                      '${item.teacherName ?? 'Teacher'} • ${item.createdAt.split('T').first}',
                                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                            color: AlifColors.textSecondary,
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: AlifSpacing.md),
                AlifCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Parent Tips',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: AlifSpacing.md),
                      const Text('• Encourage consistency in daily activities'),
                      const SizedBox(height: AlifSpacing.sm),
                      const Text('• Celebrate small victories and progress'),
                      const SizedBox(height: AlifSpacing.sm),
                      const Text('• Review progress together weekly'),
                      const SizedBox(height: AlifSpacing.sm),
                      const Text('• Use badges as motivation milestones'),
                    ],
                  ),
                ),
              ]
            ]
          ],
        ],
      ),
    );
  }

  Widget _buildProgressStat({required String label, required String value}) {
    return Container(
      padding: const EdgeInsets.all(AlifSpacing.md),
      decoration: BoxDecoration(
        color: AlifColors.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: Theme.of(context).textTheme.titleLarge,
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
