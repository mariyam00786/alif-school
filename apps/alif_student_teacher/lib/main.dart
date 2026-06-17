import 'package:flutter/material.dart';
import 'package:alif_design_system/alif_design_system.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() {
  runApp(const StudentTeacherApp());
}

class StudentTeacherApp extends StatelessWidget {
  const StudentTeacherApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Alif Student & Teacher',
      debugShowCheckedModeBanner: false,
      theme: AlifTheme.light(),
      home: const StudentTeacherHomePage(),
    );
  }
}

class StudentTeacherHomePage extends StatelessWidget {
  const StudentTeacherHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AlifColors.bg,
      appBar: AppBar(title: const Text('Student & Teacher')),
      body: Stack(
        children: [
          const _LearningAtmosphereBackground(),
          SafeArea(
            child: ListView(
              padding: const EdgeInsets.all(AlifSpacing.lg),
              children: [
                Container(
                  padding: const EdgeInsets.all(AlifSpacing.xl),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AlifColors.primary.withValues(alpha: 0.95),
                        AlifColors.accent.withValues(alpha: 0.92),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Ihthisab at a glance',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              color: Colors.white,
                            ),
                      ),
                      const SizedBox(height: AlifSpacing.sm),
                      Text(
                        'Track daily amal with clarity and keep your momentum strong.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.white.withValues(alpha: 0.92),
                            ),
                      ),
                      const SizedBox(height: AlifSpacing.md),
                      const Wrap(
                        spacing: AlifSpacing.sm,
                        runSpacing: AlifSpacing.sm,
                        children: [
                          _HeroStatChip(label: 'Weekly Streak', value: '4 days'),
                          _HeroStatChip(label: 'Completion', value: '82%'),
                        ],
                      ),
                      const SizedBox(height: AlifSpacing.lg),
                      AlifButton(
                        label: 'Mark Today\'s Activities',
                        leading: const Icon(Icons.check_circle_outline, color: Colors.white),
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => const DailyActivityMarkingPage(),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AlifSpacing.lg),
                AlifCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Quick Guidance',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: AlifSpacing.sm),
                      Text(
                        'Open daily marker, choose a rating for each activity, and save once to log today.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AlifColors.textSecondary,
                            ),
                      ),
                      const SizedBox(height: AlifSpacing.md),
                      Wrap(
                        spacing: AlifSpacing.sm,
                        runSpacing: AlifSpacing.sm,
                        children: [
                          FilledButton.tonalIcon(
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute<void>(
                                  builder: (_) => const LeaderboardPage(),
                                ),
                              );
                            },
                            icon: const Icon(Icons.leaderboard_rounded),
                            label: const Text('Leaderboard'),
                          ),
                          FilledButton.tonalIcon(
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute<void>(
                                  builder: (_) => const ProgressPage(),
                                ),
                              );
                            },
                            icon: const Icon(Icons.insights_rounded),
                            label: const Text('Progress'),
                          ),
                          FilledButton.tonalIcon(
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute<void>(
                                  builder: (_) => const StudentBadgesPage(),
                                ),
                              );
                            },
                            icon: const Icon(Icons.workspace_premium_rounded),
                            label: const Text('Badges'),
                          ),
                          FilledButton.tonalIcon(
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute<void>(
                                  builder: (_) => const StudentProfilePage(),
                                ),
                              );
                            },
                            icon: const Icon(Icons.person_outline_rounded),
                            label: const Text('Profile'),
                          ),
                          FilledButton.tonalIcon(
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute<void>(
                                  builder: (_) => const TeacherDashboardPage(),
                                ),
                              );
                            },
                            icon: const Icon(Icons.school_rounded),
                            label: const Text('Teacher Dashboard'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LearningAtmosphereBackground extends StatelessWidget {
  const _LearningAtmosphereBackground();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AlifColors.bg,
            AlifColors.primaryContainer.withValues(alpha: 0.75),
          ],
        ),
      ),
      child: Stack(
        children: [
          Align(
            alignment: const Alignment(-1.2, -1),
            child: _SoftCircle(
              size: 220,
              color: AlifColors.secondaryContainer.withValues(alpha: 0.65),
            ),
          ),
          Align(
            alignment: const Alignment(1.1, -0.7),
            child: _SoftCircle(
              size: 260,
              color: AlifColors.primaryContainer.withValues(alpha: 0.9),
            ),
          ),
        ],
      ),
    );
  }
}

class _SoftCircle extends StatelessWidget {
  const _SoftCircle({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
    );
  }
}

class _HeroStatChip extends StatelessWidget {
  const _HeroStatChip({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AlifSpacing.md,
        vertical: AlifSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        '$label: $value',
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }
}

class DailyActivityMarkingPage extends StatefulWidget {
  const DailyActivityMarkingPage({super.key});

  @override
  State<DailyActivityMarkingPage> createState() =>
      _DailyActivityMarkingPageState();
}

class _DailyActivityMarkingPageState extends State<DailyActivityMarkingPage> {
  bool _loading = true;
  bool _saving = false;
  String? _error;
  String? _studentId;
  bool _parentMode = false;
  bool _parentApproved = false;
  String _parentPhone = '9999999999';
  List<LinkedStudent> _linkedStudents = const [];
  List<ActivityCategory> _categories = const [];
  List<ActivityItem> _activities = const [];
  List<RatingOption> _ratings = const [];

  final Map<String, String> _selectedRatings = <String, String>{};
  final Map<String, TextEditingController> _quantityControllers =
      <String, TextEditingController>{};

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    for (final controller in _quantityControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _load() async {
    try {
      setState(() {
        _loading = true;
        _error = null;
      });

      final linkedStudents = await ApiService.getLinkedStudents(
        parentPhone: _parentPhone,
      );
      final fallbackStudentId = await ApiService.getFirstStudentId();
      final studentId = linkedStudents.isNotEmpty
          ? linkedStudents.first.id
          : fallbackStudentId;
      final categories = await ApiService.listCategories();
      final activities = await ApiService.listActivities();
      final ratings = await ApiService.listRatings();

      if (!mounted) {
        return;
      }

      setState(() {
        _linkedStudents = linkedStudents;
        _studentId = studentId;
        _categories = categories;
        _activities = activities;
        _ratings = ratings;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  List<RatingOption> _ratingsForActivity(String activityId) {
    final filtered = _ratings
        .where((item) => item.activityId == activityId)
        .toList(growable: false);
    filtered.sort(
      (left, right) => left.displayOrder.compareTo(right.displayOrder),
    );
    return filtered;
  }

  Future<void> _saveToday() async {
    if (_studentId == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('No active student found.')));
      return;
    }

    if (_selectedRatings.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select at least one activity rating.')),
      );
      return;
    }

    final today = DateTime.now().toIso8601String().split('T')[0];

    try {
      setState(() => _saving = true);

      for (final entry in _selectedRatings.entries) {
        final activityId = entry.key;
        final ratingId = entry.value;
        final quantityText = _quantityControllers[activityId]?.text.trim();
        final quantity = (quantityText == null || quantityText.isEmpty)
            ? null
            : int.tryParse(quantityText);

        await ApiService.upsertActivityLog(
          studentId: _studentId!,
          activityId: activityId,
          ratingId: ratingId,
          logDate: today,
          quantity: quantity,
          parentApproved: _parentMode ? _parentApproved : null,
        );
      }

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Today\'s activity marks saved successfully.'),
        ),
      );
    } catch (e) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to save marks: $e')));
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Daily Activity Marking')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(AlifSpacing.lg),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Error loading data: $_error',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AlifSpacing.md),
                FilledButton.icon(
                  onPressed: _load,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Daily Activity Marking')),
      body: ListView(
        padding: const EdgeInsets.all(AlifSpacing.md),
        children: [
          AlifCard(
            child: Column(
              children: [
                Row(
                  children: [
                    const Icon(Icons.today_rounded, color: AlifColors.primary),
                    const SizedBox(width: AlifSpacing.sm),
                    Expanded(
                      child: Text(
                        'Select rating for each activity and save once for today.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AlifColors.textSecondary,
                            ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AlifSpacing.md),
                SwitchListTile(
                  value: _parentMode,
                  onChanged: (value) {
                    setState(() => _parentMode = value);
                  },
                  title: const Text('Parent Mode (Child Switch + Approval)'),
                  contentPadding: EdgeInsets.zero,
                ),
                if (_parentMode) ...[
                  const SizedBox(height: AlifSpacing.sm),
                  DropdownButtonFormField<String>(
                    initialValue: _linkedStudents.any((item) => item.id == _studentId)
                        ? _studentId
                        : null,
                    items: _linkedStudents
                        .map(
                          (item) => DropdownMenuItem<String>(
                            value: item.id,
                            child: Text(item.displayName),
                          ),
                        )
                        .toList(growable: false),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _studentId = value);
                      }
                    },
                    decoration: const InputDecoration(
                      labelText: 'Select Child',
                    ),
                  ),
                  const SizedBox(height: AlifSpacing.sm),
                  CheckboxListTile(
                    value: _parentApproved,
                    onChanged: (value) {
                      setState(() => _parentApproved = value ?? false);
                    },
                    title: const Text('Parent approval confirmed'),
                    contentPadding: EdgeInsets.zero,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: AlifSpacing.md),
          for (final category in _categories)
            AlifCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    category.name,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  if ((category.nameMl ?? '').isNotEmpty)
                    Text(
                      category.nameMl!,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  const SizedBox(height: AlifSpacing.md),
                  ..._activities
                      .where((item) => item.categoryId == category.id)
                      .map((activity) {
                        final options = _ratingsForActivity(activity.id);
                        final current = _selectedRatings[activity.id];
                        final qtyController = _quantityControllers.putIfAbsent(
                          activity.id,
                          TextEditingController.new,
                        );

                        return Padding(
                          padding: const EdgeInsets.only(
                            bottom: AlifSpacing.lg,
                          ),
                          child: Container(
                            padding: const EdgeInsets.all(AlifSpacing.md),
                            decoration: BoxDecoration(
                              color: AlifColors.bg,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: AlifColors.border),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  activity.name,
                                  style: Theme.of(context).textTheme.titleSmall,
                                ),
                                if ((activity.nameMl ?? '').isNotEmpty)
                                  Text(
                                    activity.nameMl!,
                                    style: Theme.of(context).textTheme.bodySmall,
                                  ),
                                const SizedBox(height: AlifSpacing.sm),
                                Wrap(
                                  spacing: AlifSpacing.sm,
                                  runSpacing: AlifSpacing.sm,
                                  children: options
                                      .map(
                                        (option) => ChoiceChip(
                                          label: Text(
                                            '${option.ratingName} (${option.marks})',
                                          ),
                                          selected: current == option.id,
                                          onSelected: (_) {
                                            setState(() {
                                              _selectedRatings[activity.id] = option.id;
                                            });
                                          },
                                        ),
                                      )
                                      .toList(growable: false),
                                ),
                                if (activity.hasQuantity) ...[
                                  const SizedBox(height: AlifSpacing.sm),
                                  TextField(
                                    controller: qtyController,
                                    keyboardType: TextInputType.number,
                                    decoration: const InputDecoration(
                                      labelText: 'Quantity',
                                      hintText: 'Enter quantity (e.g., pages)',
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        );
                      }),
                ],
              ),
            ),
          const SizedBox(height: AlifSpacing.md),
          AlifButton(
            label: _saving ? 'Saving...' : 'Save Today\'s Marks',
            isLoading: _saving,
            onPressed: _saving ? null : _saveToday,
          ),
        ],
      ),
    );
  }
}

class LeaderboardPage extends StatefulWidget {
  const LeaderboardPage({super.key});

  @override
  State<LeaderboardPage> createState() => _LeaderboardPageState();
}

class _LeaderboardPageState extends State<LeaderboardPage> {
  String _period = 'weekly';
  bool _isLoading = true;
  String? _error;
  List<LeaderboardRow> _rows = const [];

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

      final rows = await ApiService.getLeaderboard(period: _period);
      if (!mounted) {
        return;
      }

      setState(() => _rows = rows);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Leaderboard')),
      body: ListView(
        padding: const EdgeInsets.all(AlifSpacing.md),
        children: [
          AlifCard(
            child: DropdownButtonFormField<String>(
              initialValue: _period,
              items: const [
                DropdownMenuItem(value: 'daily', child: Text('Daily')),
                DropdownMenuItem(value: 'weekly', child: Text('Weekly')),
                DropdownMenuItem(value: 'monthly', child: Text('Monthly')),
                DropdownMenuItem(value: 'all_time', child: Text('All Time')),
              ],
              onChanged: (value) async {
                if (value == null) {
                  return;
                }

                setState(() => _period = value);
                await _load();
              },
              decoration: const InputDecoration(labelText: 'Period'),
            ),
          ),
          const SizedBox(height: AlifSpacing.md),
          if (_isLoading)
            const Center(child: CircularProgressIndicator())
          else if (_error != null)
            Text('Error: $_error', style: const TextStyle(color: Colors.red))
          else if (_rows.isEmpty)
            const AlifCard(child: Text('No leaderboard data found.'))
          else
            ..._rows.map(
              (row) => Padding(
                padding: const EdgeInsets.only(bottom: AlifSpacing.md),
                child: AlifCard(
                  child: Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: AlifColors.primaryContainer,
                        child: Text('${row.rank}'),
                      ),
                      const SizedBox(width: AlifSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              row.studentName,
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            Text(
                              'Batch: ${row.batchName ?? '-'}',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '${row.totalMarks} pts',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          Text(
                            '${row.activitiesCompleted} activities',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
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

class ProgressPage extends StatefulWidget {
  const ProgressPage({super.key});

  @override
  State<ProgressPage> createState() => _ProgressPageState();
}

class _ProgressPageState extends State<ProgressPage> {
  String _period = 'weekly';
  bool _isLoading = true;
  String? _error;
  ProgressSummary? _summary;
  List<ProgressLogRow> _rows = const [];

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

      final studentId = await ApiService.getFirstStudentId();
      final result = _period == 'weekly'
          ? await ApiService.getWeeklyProgress(studentId: studentId)
          : await ApiService.getMonthlyProgress(studentId: studentId);

      if (!mounted) {
        return;
      }

      setState(() {
        _summary = result.summary;
        _rows = result.rows;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Progress')),
      body: ListView(
        padding: const EdgeInsets.all(AlifSpacing.md),
        children: [
          AlifCard(
            child: Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: _period,
                    items: const [
                      DropdownMenuItem(value: 'weekly', child: Text('Weekly')),
                      DropdownMenuItem(value: 'monthly', child: Text('Monthly')),
                    ],
                    onChanged: (value) async {
                      if (value == null) {
                        return;
                      }

                      setState(() => _period = value);
                      await _load();
                    },
                    decoration: const InputDecoration(labelText: 'Period'),
                  ),
                ),
                const SizedBox(width: AlifSpacing.sm),
                FilledButton.tonalIcon(
                  onPressed: _load,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Refresh'),
                ),
              ],
            ),
          ),
          const SizedBox(height: AlifSpacing.md),
          if (_isLoading)
            const Center(child: CircularProgressIndicator())
          else if (_error != null)
            Text('Error: $_error', style: const TextStyle(color: Colors.red))
          else ...[
            if (_summary != null)
              AlifCard(
                child: Wrap(
                  spacing: AlifSpacing.md,
                  runSpacing: AlifSpacing.sm,
                  children: [
                    Text('Total Marks: ${_summary!.totalMarks}'),
                    Text('Activities: ${_summary!.totalActivities}'),
                  ],
                ),
              ),
            const SizedBox(height: AlifSpacing.md),
            if (_rows.isEmpty)
              const AlifCard(child: Text('No progress rows found.'))
            else
              ..._rows.map(
                (item) => Padding(
                  padding: const EdgeInsets.only(bottom: AlifSpacing.sm),
                  child: AlifCard(
                    child: Row(
                      children: [
                        Expanded(child: Text(item.logDate)),
                        Text('${item.marksEarned} pts'),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }
}

class StudentBadgesPage extends StatefulWidget {
  const StudentBadgesPage({super.key});

  @override
  State<StudentBadgesPage> createState() => _StudentBadgesPageState();
}

class _StudentBadgesPageState extends State<StudentBadgesPage> {
  bool _isLoading = true;
  String? _error;
  List<StudentBadgeItem> _badges = const [];

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
      final studentId = await ApiService.getFirstStudentId();
      final items = await ApiService.getStudentBadges(studentId: studentId);
      if (!mounted) {
        return;
      }
      setState(() => _badges = items);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Badges & Achievements')),
      body: ListView(
        padding: const EdgeInsets.all(AlifSpacing.md),
        children: [
          if (_isLoading)
            const Center(child: CircularProgressIndicator())
          else if (_error != null)
            Text('Error: $_error', style: const TextStyle(color: Colors.red))
          else if (_badges.isEmpty)
            const AlifCard(child: Text('No badges earned yet.'))
          else
            ..._badges.map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: AlifSpacing.md),
                child: AlifCard(
                  child: Row(
                    children: [
                      const Icon(
                        Icons.workspace_premium_rounded,
                        color: AlifColors.secondary,
                      ),
                      const SizedBox(width: AlifSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.name,
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            if ((item.description ?? '').isNotEmpty)
                              Text(
                                item.description!,
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            Text(
                              'Bonus: ${item.bonusPoints} | Earned: ${item.earnedAt}',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
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

class StudentProfilePage extends StatefulWidget {
  const StudentProfilePage({super.key});

  @override
  State<StudentProfilePage> createState() => _StudentProfilePageState();
}

class _StudentProfilePageState extends State<StudentProfilePage> {
  bool _isLoading = true;
  bool _isSaving = false;
  String? _error;
  StudentProfileData? _profile;
  final TextEditingController _addressController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });
      final studentId = await ApiService.getFirstStudentId();
      final profile = await ApiService.getStudentProfile(studentId: studentId);
      if (!mounted) {
        return;
      }
      _addressController.text = profile.address ?? '';
      setState(() => _profile = profile);
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

  Future<void> _save() async {
    final profile = _profile;
    if (profile == null) {
      return;
    }

    try {
      setState(() => _isSaving = true);
      final updated = await ApiService.updateStudentProfile(
        studentId: profile.id,
        address: _addressController.text.trim(),
      );
      if (!mounted) {
        return;
      }
      setState(() => _profile = updated);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Profile updated')));
    } catch (e) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Update failed: $e')));
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: ListView(
        padding: const EdgeInsets.all(AlifSpacing.md),
        children: [
          if (_isLoading)
            const Center(child: CircularProgressIndicator())
          else if (_error != null)
            Text('Error: $_error', style: const TextStyle(color: Colors.red))
          else if (_profile == null)
            const AlifCard(child: Text('Profile not found.'))
          else ...[
            AlifCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Father: ${_profile!.fatherName}'),
                  Text('Mother: ${_profile!.motherName}'),
                  Text('Phone: ${_profile!.parentPhone}'),
                  Text('Gender: ${_profile!.gender}'),
                  Text('Batch: ${_profile!.batchName ?? '-'}'),
                  Text('Class: ${_profile!.className ?? '-'}'),
                ],
              ),
            ),
            const SizedBox(height: AlifSpacing.md),
            AlifCard(
              child: Column(
                children: [
                  TextField(
                    controller: _addressController,
                    decoration: const InputDecoration(labelText: 'Address'),
                  ),
                  const SizedBox(height: AlifSpacing.md),
                  AlifButton(
                    label: 'Save Profile',
                    isLoading: _isSaving,
                    onPressed: _isSaving ? null : _save,
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class TeacherDashboardPage extends StatefulWidget {
  const TeacherDashboardPage({super.key});

  @override
  State<TeacherDashboardPage> createState() => _TeacherDashboardPageState();
}

class _TeacherDashboardPageState extends State<TeacherDashboardPage> {
  bool _isLoading = true;
  String? _error;
  List<TeacherBatchItem> _batches = const [];
  String? _selectedBatchId;
  TeacherBatchAnalytics? _analytics;
  List<TeacherStudentItem> _students = const [];

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

      final batches = await ApiService.getTeacherBatches();
      final selected = _selectedBatchId ?? (batches.isNotEmpty ? batches.first.id : null);
      final analytics = selected == null
          ? null
          : await ApiService.getTeacherBatchAnalytics(batchId: selected);
      final students = await ApiService.getTeacherStudents(batchId: selected);

      if (!mounted) {
        return;
      }

      setState(() {
        _batches = batches;
        _selectedBatchId = selected;
        _analytics = analytics;
        _students = students;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Teacher Dashboard')),
      body: ListView(
        padding: const EdgeInsets.all(AlifSpacing.md),
        children: [
          AlifCard(
            child: Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: _selectedBatchId,
                    items: _batches
                        .map(
                          (batch) => DropdownMenuItem(
                            value: batch.id,
                            child: Text(batch.name),
                          ),
                        )
                        .toList(growable: false),
                    onChanged: (value) async {
                      if (value == null) {
                        return;
                      }
                      setState(() => _selectedBatchId = value);
                      await _load();
                    },
                    decoration: const InputDecoration(labelText: 'Batch'),
                  ),
                ),
                const SizedBox(width: AlifSpacing.sm),
                FilledButton.tonalIcon(
                  onPressed: _load,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Refresh'),
                ),
              ],
            ),
          ),
          const SizedBox(height: AlifSpacing.md),
          if (_isLoading)
            const Center(child: CircularProgressIndicator())
          else if (_error != null)
            Text('Error: $_error', style: const TextStyle(color: Colors.red))
          else ...[
            if (_analytics != null)
              AlifCard(
                child: Wrap(
                  spacing: AlifSpacing.md,
                  runSpacing: AlifSpacing.sm,
                  children: [
                    Text('Students: ${_analytics!.students}'),
                    Text('Marks: ${_analytics!.totalMarks}'),
                    Text('Activities: ${_analytics!.totalActivities}'),
                    Text('Completion: ${_analytics!.completionRate}'),
                  ],
                ),
              ),
            const SizedBox(height: AlifSpacing.md),
            if (_students.isEmpty)
              const AlifCard(child: Text('No students found in this batch.'))
            else
              ..._students.map(
                (student) => Padding(
                  padding: const EdgeInsets.only(bottom: AlifSpacing.sm),
                  child: AlifCard(
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                student.displayName,
                                style: Theme.of(context).textTheme.titleSmall,
                              ),
                              Text(
                                student.parentPhone,
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }
}

class AppConfig {
  AppConfig._();

  static const String _apiBaseUrl = String.fromEnvironment(
    'ALIF_API_BASE_URL',
    defaultValue: 'http://localhost:4000/api',
  );

  static Uri apiUri(String path, {Map<String, String>? queryParameters}) {
    final normalizedBase = _apiBaseUrl.endsWith('/')
        ? _apiBaseUrl.substring(0, _apiBaseUrl.length - 1)
        : _apiBaseUrl;
    final normalizedPath = path.startsWith('/') ? path : '/$path';

    return Uri.parse('$normalizedBase$normalizedPath').replace(
      queryParameters: queryParameters == null || queryParameters.isEmpty
          ? null
          : queryParameters,
    );
  }
}

class ApiService {
  static Future<String> getFirstStudentId() async {
    final response = await http.get(
      AppConfig.apiUri(
        '/students',
        queryParameters: {'limit': '1', 'offset': '0', 'status': 'active'},
      ),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to load students: ${response.statusCode}');
    }

    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    final list = (decoded['data'] as List<dynamic>? ?? const []);
    if (list.isEmpty) {
      throw Exception('No active students available');
    }

    return (list.first as Map<String, dynamic>)['id'] as String;
  }

  static Future<List<ActivityCategory>> listCategories() async {
    final response = await http.get(
      AppConfig.apiUri('/categories', queryParameters: {'status': 'active'}),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to load categories: ${response.statusCode}');
    }

    final decoded = jsonDecode(response.body) as List<dynamic>;
    return decoded
        .map((item) => ActivityCategory.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  static Future<List<ActivityItem>> listActivities() async {
    final response = await http.get(
      AppConfig.apiUri('/activities', queryParameters: {'status': 'active'}),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to load activities: ${response.statusCode}');
    }

    final decoded = jsonDecode(response.body) as List<dynamic>;
    return decoded
        .map((item) => ActivityItem.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  static Future<List<RatingOption>> listRatings() async {
    final response = await http.get(AppConfig.apiUri('/ratings'));
    if (response.statusCode != 200) {
      throw Exception('Failed to load ratings: ${response.statusCode}');
    }

    final decoded = jsonDecode(response.body) as List<dynamic>;
    return decoded
        .map((item) => RatingOption.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  static Future<void> upsertActivityLog({
    required String studentId,
    required String activityId,
    required String ratingId,
    required String logDate,
    int? quantity,
    bool? parentApproved,
  }) async {
    final response = await http.post(
      AppConfig.apiUri('/activity-logs'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'student_id': studentId,
        'activity_id': activityId,
        'rating_id': ratingId,
        'log_date': logDate,
        'quantity': quantity,
        'parent_approved': parentApproved,
      }),
    );

    if (response.statusCode != 201) {
      throw Exception('Failed to save activity log: ${response.body}');
    }
  }

  static Future<List<LeaderboardRow>> getLeaderboard({
    required String period,
  }) async {
    final response = await http.get(
      AppConfig.apiUri('/student/leaderboard', queryParameters: {'period': period}),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to load leaderboard: ${response.statusCode}');
    }

    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    final list = decoded['data'] as List<dynamic>? ?? const [];
    return list
        .map((item) => LeaderboardRow.fromJson(item as Map<String, dynamic>))
        .toList(growable: false);
  }

  static Future<ProgressResult> getWeeklyProgress({
    required String studentId,
  }) async {
    final response = await http.get(
      AppConfig.apiUri(
        '/student/progress/weekly',
        queryParameters: {'student_id': studentId},
      ),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to load weekly progress: ${response.statusCode}');
    }

    return ProgressResult.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  static Future<ProgressResult> getMonthlyProgress({
    required String studentId,
  }) async {
    final response = await http.get(
      AppConfig.apiUri(
        '/student/progress/monthly',
        queryParameters: {'student_id': studentId},
      ),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to load monthly progress: ${response.statusCode}');
    }

    return ProgressResult.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  static Future<List<StudentBadgeItem>> getStudentBadges({
    required String studentId,
  }) async {
    final response = await http.get(
      AppConfig.apiUri(
        '/student/badges',
        queryParameters: {'student_id': studentId},
      ),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to load student badges: ${response.statusCode}');
    }

    final decoded = jsonDecode(response.body) as List<dynamic>;
    return decoded
        .map((item) => StudentBadgeItem.fromJson(item as Map<String, dynamic>))
        .toList(growable: false);
  }

  static Future<StudentProfileData> getStudentProfile({
    required String studentId,
  }) async {
    final response = await http.get(
      AppConfig.apiUri(
        '/student/profile',
        queryParameters: {'student_id': studentId},
      ),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to load student profile: ${response.statusCode}');
    }

    return StudentProfileData.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  static Future<StudentProfileData> updateStudentProfile({
    required String studentId,
    required String address,
  }) async {
    final response = await http.put(
      AppConfig.apiUri(
        '/student/profile',
        queryParameters: {'student_id': studentId},
      ),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'address': address}),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to update student profile: ${response.statusCode}');
    }

    return StudentProfileData.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  static Future<List<LinkedStudent>> getLinkedStudents({
    required String parentPhone,
  }) async {
    final response = await http.get(
      AppConfig.apiUri(
        '/student/children',
        queryParameters: {'parent_phone': parentPhone},
      ),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to load linked children: ${response.statusCode}');
    }

    final decoded = jsonDecode(response.body) as List<dynamic>;
    return decoded
        .map((item) => LinkedStudent.fromJson(item as Map<String, dynamic>))
        .toList(growable: false);
  }

  static Future<List<TeacherBatchItem>> getTeacherBatches() async {
    final response = await http.get(AppConfig.apiUri('/teacher/batches'));
    if (response.statusCode != 200) {
      throw Exception('Failed to load teacher batches: ${response.statusCode}');
    }

    final decoded = jsonDecode(response.body) as List<dynamic>;
    if (decoded.isEmpty) {
      return const [];
    }

    final first = decoded.first as Map<String, dynamic>;
    final rawBatches = first['batches'] as List<dynamic>? ?? const [];
    return rawBatches
        .map((item) => TeacherBatchItem.fromJson(item as Map<String, dynamic>))
        .toList(growable: false);
  }

  static Future<List<TeacherStudentItem>> getTeacherStudents({String? batchId}) async {
    final response = await http.get(
      AppConfig.apiUri(
        '/teacher/students',
        queryParameters: {
          if (batchId != null && batchId.isNotEmpty) 'batch_id': batchId,
        },
      ),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to load teacher students: ${response.statusCode}');
    }

    final decoded = jsonDecode(response.body) as List<dynamic>;
    return decoded
        .map((item) => TeacherStudentItem.fromJson(item as Map<String, dynamic>))
        .toList(growable: false);
  }

  static Future<TeacherBatchAnalytics> getTeacherBatchAnalytics({
    required String batchId,
  }) async {
    final response = await http.get(
      AppConfig.apiUri('/teacher/batch/$batchId/analytics'),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to load teacher analytics: ${response.statusCode}');
    }

    return TeacherBatchAnalytics.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }
}

class ActivityCategory {
  final String id;
  final String name;
  final String? nameMl;

  const ActivityCategory({
    required this.id,
    required this.name,
    required this.nameMl,
  });

  factory ActivityCategory.fromJson(Map<String, dynamic> json) {
    return ActivityCategory(
      id: json['id'] as String,
      name: json['name'] as String? ?? '',
      nameMl: json['name_ml'] as String?,
    );
  }
}

class ActivityItem {
  final String id;
  final String categoryId;
  final String name;
  final String? nameMl;
  final bool hasQuantity;

  const ActivityItem({
    required this.id,
    required this.categoryId,
    required this.name,
    required this.nameMl,
    required this.hasQuantity,
  });

  factory ActivityItem.fromJson(Map<String, dynamic> json) {
    return ActivityItem(
      id: json['id'] as String,
      categoryId: json['category_id'] as String,
      name: json['name'] as String? ?? '',
      nameMl: json['name_ml'] as String?,
      hasQuantity: json['has_quantity'] as bool? ?? false,
    );
  }
}

class RatingOption {
  final String id;
  final String activityId;
  final String ratingName;
  final int marks;
  final int displayOrder;

  const RatingOption({
    required this.id,
    required this.activityId,
    required this.ratingName,
    required this.marks,
    required this.displayOrder,
  });

  factory RatingOption.fromJson(Map<String, dynamic> json) {
    return RatingOption(
      id: json['id'] as String,
      activityId: json['activity_id'] as String,
      ratingName: json['rating_name'] as String? ?? '',
      marks: json['marks'] as int? ?? 0,
      displayOrder: json['display_order'] as int? ?? 0,
    );
  }
}

class LeaderboardRow {
  const LeaderboardRow({
    required this.rank,
    required this.studentName,
    required this.totalMarks,
    required this.activitiesCompleted,
    this.batchName,
  });

  final int rank;
  final String studentName;
  final int totalMarks;
  final int activitiesCompleted;
  final String? batchName;

  factory LeaderboardRow.fromJson(Map<String, dynamic> json) {
    return LeaderboardRow(
      rank: (json['rank'] as num? ?? 0).toInt(),
      studentName: json['student_name'] as String? ?? '-',
      totalMarks: (json['total_marks'] as num? ?? 0).toInt(),
      activitiesCompleted: (json['activities_completed'] as num? ?? 0).toInt(),
      batchName: json['batch_name'] as String?,
    );
  }
}

class ProgressSummary {
  const ProgressSummary({
    required this.totalMarks,
    required this.totalActivities,
  });

  final int totalMarks;
  final int totalActivities;

  factory ProgressSummary.fromJson(Map<String, dynamic> json) {
    return ProgressSummary(
      totalMarks: (json['total_marks'] as num? ?? 0).toInt(),
      totalActivities: (json['total_activities'] as num? ?? 0).toInt(),
    );
  }
}

class ProgressLogRow {
  const ProgressLogRow({
    required this.logDate,
    required this.marksEarned,
  });

  final String logDate;
  final int marksEarned;

  factory ProgressLogRow.fromJson(Map<String, dynamic> json) {
    return ProgressLogRow(
      logDate: json['log_date'] as String? ?? '-',
      marksEarned: (json['marks_earned'] as num? ?? 0).toInt(),
    );
  }
}

class ProgressResult {
  const ProgressResult({required this.summary, required this.rows});

  final ProgressSummary summary;
  final List<ProgressLogRow> rows;

  factory ProgressResult.fromJson(Map<String, dynamic> json) {
    return ProgressResult(
      summary: ProgressSummary.fromJson(
        json['summary'] as Map<String, dynamic>? ?? const {},
      ),
      rows: (json['data'] as List<dynamic>? ?? const [])
          .map((item) => ProgressLogRow.fromJson(item as Map<String, dynamic>))
          .toList(growable: false),
    );
  }
}

class StudentBadgeItem {
  const StudentBadgeItem({
    required this.name,
    this.description,
    required this.bonusPoints,
    required this.earnedAt,
  });

  final String name;
  final String? description;
  final int bonusPoints;
  final String earnedAt;

  factory StudentBadgeItem.fromJson(Map<String, dynamic> json) {
    final badge = json['badges'] as Map<String, dynamic>? ?? const {};
    return StudentBadgeItem(
      name: badge['name'] as String? ?? '-',
      description: badge['description'] as String?,
      bonusPoints: (badge['bonus_points'] as num? ?? 0).toInt(),
      earnedAt: json['earned_at'] as String? ?? '-',
    );
  }
}

class StudentProfileData {
  const StudentProfileData({
    required this.id,
    required this.fatherName,
    required this.motherName,
    required this.parentPhone,
    required this.gender,
    this.address,
    this.batchName,
    this.className,
  });

  final String id;
  final String fatherName;
  final String motherName;
  final String parentPhone;
  final String gender;
  final String? address;
  final String? batchName;
  final String? className;

  factory StudentProfileData.fromJson(Map<String, dynamic> json) {
    final batch = json['batches'] as Map<String, dynamic>?;
    final classInfo = json['classes'] as Map<String, dynamic>?;
    return StudentProfileData(
      id: json['id'] as String? ?? '',
      fatherName: json['father_name'] as String? ?? '-',
      motherName: json['mother_name'] as String? ?? '-',
      parentPhone: json['parent_phone'] as String? ?? '-',
      gender: json['gender'] as String? ?? '-',
      address: json['address'] as String?,
      batchName: batch?['name'] as String?,
      className: classInfo?['name'] as String?,
    );
  }
}

class LinkedStudent {
  const LinkedStudent({
    required this.id,
    required this.fatherName,
    required this.motherName,
  });

  final String id;
  final String fatherName;
  final String motherName;

  String get displayName => '$fatherName / $motherName';

  factory LinkedStudent.fromJson(Map<String, dynamic> json) {
    return LinkedStudent(
      id: json['id'] as String? ?? '',
      fatherName: json['father_name'] as String? ?? '-',
      motherName: json['mother_name'] as String? ?? '-',
    );
  }
}

class TeacherBatchItem {
  const TeacherBatchItem({required this.id, required this.name});

  final String id;
  final String name;

  factory TeacherBatchItem.fromJson(Map<String, dynamic> json) {
    return TeacherBatchItem(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '-',
    );
  }
}

class TeacherStudentItem {
  const TeacherStudentItem({
    required this.id,
    required this.fatherName,
    required this.motherName,
    required this.parentPhone,
  });

  final String id;
  final String fatherName;
  final String motherName;
  final String parentPhone;

  String get displayName => '$fatherName / $motherName';

  factory TeacherStudentItem.fromJson(Map<String, dynamic> json) {
    return TeacherStudentItem(
      id: json['id'] as String? ?? '',
      fatherName: json['father_name'] as String? ?? '-',
      motherName: json['mother_name'] as String? ?? '-',
      parentPhone: json['parent_phone'] as String? ?? '-',
    );
  }
}

class TeacherBatchAnalytics {
  const TeacherBatchAnalytics({
    required this.students,
    required this.totalMarks,
    required this.totalActivities,
    required this.completionRate,
  });

  final int students;
  final int totalMarks;
  final int totalActivities;
  final double completionRate;

  factory TeacherBatchAnalytics.fromJson(Map<String, dynamic> json) {
    final summary = json['summary'] as Map<String, dynamic>? ?? const {};
    return TeacherBatchAnalytics(
      students: (summary['students'] as num? ?? 0).toInt(),
      totalMarks: (summary['total_marks'] as num? ?? 0).toInt(),
      totalActivities: (summary['total_activities'] as num? ?? 0).toInt(),
      completionRate: (summary['completion_rate'] as num? ?? 0).toDouble(),
    );
  }
}
