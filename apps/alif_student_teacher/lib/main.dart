import 'package:flutter/material.dart';
import 'package:alif_design_system/alif_design_system.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Models
import 'package:alif_student_teacher/models/student.dart';
import 'package:alif_student_teacher/models/activity.dart';
import 'package:alif_student_teacher/models/leaderboard.dart';
import 'package:alif_student_teacher/models/auth_session.dart';
import 'package:alif_student_teacher/config/app_config.dart';

// Services
import 'package:alif_student_teacher/services/api_service.dart';
import 'package:alif_student_teacher/services/auth_service.dart';
import 'package:alif_student_teacher/services/device_token_service.dart';
import 'package:alif_student_teacher/services/fcm_service.dart';

// Screens
import 'package:alif_student_teacher/screens/login_page.dart';
import 'package:alif_student_teacher/screens/student_badges_page.dart';
import 'package:alif_student_teacher/screens/student_profile_page.dart';
import 'package:alif_student_teacher/screens/teacher_dashboard_page.dart';
import 'package:alif_student_teacher/screens/parent_insights_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: AppConfig.supabaseUrl,
    publishableKey: AppConfig.supabasePublishableKey,
  );
  
  // Initialize FCM
  try {
    await FcmService.initialize();
  } catch (e) {
    debugPrint('FCM initialization error (continuing anyway): $e');
  }
  
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
      home: const _StudentTeacherAppShell(),
    );
  }
}

class _StudentTeacherAppShell extends StatefulWidget {
  const _StudentTeacherAppShell();

  @override
  State<_StudentTeacherAppShell> createState() => _StudentTeacherAppShellState();
}

class _StudentTeacherAppShellState extends State<_StudentTeacherAppShell> {
  bool _restoring = true;
  AuthSession? _session;
  bool _tokenRefreshListenerAttached = false;

  Future<void> _registerFcmForSession(AuthSession session) async {
    final token = FcmService.getToken() ?? await FcmService.refreshToken();
    if (token == null || token.isEmpty) {
      return;
    }

    try {
      await DeviceTokenService.registerToken(
        accessToken: session.accessToken,
        token: token,
      );
    } catch (error) {
      debugPrint('FCM token registration failed: $error');
    }

    if (_tokenRefreshListenerAttached) {
      return;
    }

    FcmService.onTokenRefresh((newToken) {
      DeviceTokenService.registerToken(
        accessToken: session.accessToken,
        token: newToken,
      ).catchError((error) {
        debugPrint('FCM token refresh registration failed: $error');
      });
    });
    _tokenRefreshListenerAttached = true;
  }

  @override
  void initState() {
    super.initState();
    _restoreSession();
  }

  Future<void> _restoreSession() async {
    final session = await AuthService.restoreSession();
    if (!mounted) {
      return;
    }

    setState(() {
      _session = session;
      _restoring = false;
    });

    if (session != null) {
      _registerFcmForSession(session);
    }
  }

  Future<void> _signOut() async {
    final session = _session;
    final token = FcmService.getToken();
    if (session != null && token != null && token.isNotEmpty) {
      try {
        await DeviceTokenService.unregisterToken(
          accessToken: session.accessToken,
          token: token,
        );
      } catch (error) {
        debugPrint('FCM token unregister failed: $error');
      }
    }

    await AuthService.logout();
    if (!mounted) {
      return;
    }

    setState(() => _session = null);
  }

  @override
  Widget build(BuildContext context) {
    if (_restoring) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_session == null) {
      return LoginPage(
        onSignedIn: (session) {
          setState(() => _session = session);
          _registerFcmForSession(session);
        },
      );
    }

    return StudentTeacherHomePage(onSignOut: _signOut);
  }
}

class StudentTeacherHomePage extends StatelessWidget {
  const StudentTeacherHomePage({super.key, required this.onSignOut});

  final Future<void> Function() onSignOut;

  @override
  Widget build(BuildContext context) {
    final session = AuthService.currentSession;
    return Scaffold(
      backgroundColor: AlifColors.bg,
      appBar: AppBar(
        title: const Text('Student & Teacher'),
        actions: [
          if (session != null)
            Center(
              child: Padding(
                padding: const EdgeInsets.only(right: AlifSpacing.sm),
                child: Text(
                  '${session.user.fullName} (${session.user.role})',
                  style: Theme.of(context).textTheme.labelMedium,
                ),
              ),
            ),
          IconButton(
            tooltip: 'Sign out',
            onPressed: () async => onSignOut(),
            icon: const Icon(Icons.logout_rounded),
          ),
        ],
      ),
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
                          FilledButton.tonalIcon(
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute<void>(
                                  builder: (_) => const ParentInsightsPage(),
                                ),
                              );
                            },
                            icon: const Icon(Icons.family_restroom_rounded),
                            label: const Text('Parent Insights'),
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

// ====================== Daily Activity Marking Page ======================

class DailyActivityMarkingPage extends StatefulWidget {
  const DailyActivityMarkingPage({super.key});

  @override
  State<DailyActivityMarkingPage> createState() =>
      _DailyActivityMarkingPageState();
}

class _DailyActivityMarkingPageState extends State<DailyActivityMarkingPage> {
  static const int _maxBackfillDays = 30;

  bool _loading = true;
  bool _saving = false;
  String? _error;
  String? _studentId;
  DateTime _selectedDate = DateTime.now();
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

      final session = AuthService.currentSession;
      final linkedStudents = session?.user.role == 'parent'
          ? await ApiService.getLinkedStudents(parentPhone: session!.user.phone)
          : const <LinkedStudent>[];
      final fallbackStudentId = linkedStudents.isNotEmpty
          ? linkedStudents.first.id
          : await ApiService.getFirstStudentId();
      final categories = await ApiService.listCategories();
      final activities = await ApiService.listActivities();
      final ratings = await ApiService.listRatings();

      if (!mounted) {
        return;
      }

      setState(() {
        _studentId = fallbackStudentId;
        _linkedStudents = linkedStudents;
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
    return _ratings
      .where((item) => item.activityId == activityId)
        .toList(growable: false);
  }

  String _dateLabel(DateTime date) {
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  Future<void> _pickLogDate() async {
    final now = DateTime.now();
    final firstDate = now.subtract(const Duration(days: _maxBackfillDays));
    final selected = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: firstDate,
      lastDate: now,
    );

    if (selected == null) {
      return;
    }

    setState(() => _selectedDate = selected);
  }

  Future<void> _saveSelectedDate() async {
    if (_studentId == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No student selected.')),
      );
      return;
    }

    if (_selectedRatings.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select at least one activity rating.')),
      );
      return;
    }

    final logDate = _dateLabel(_selectedDate);

    try {
      setState(() => _saving = true);

      for (final entry in _selectedRatings.entries) {
        final activityId = entry.key;
        final ratingId = entry.value;
        final quantityText = _quantityControllers[activityId]?.text.trim();
        final quantity = (quantityText == null || quantityText.isEmpty)
            ? null
            : int.tryParse(quantityText);

        await ApiService.createActivityLog(
          studentId: _studentId!,
          activityId: activityId,
          ratingId: ratingId,
          logDate: logDate,
          quantity: quantity,
        );
      }

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Activity marks saved for $logDate.')),
      );
      _selectedRatings.clear();
      for (final controller in _quantityControllers.values) {
        controller.clear();
      }
      setState(() {});
    } catch (e) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save marks: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.today_rounded, color: AlifColors.primary),
                    const SizedBox(width: AlifSpacing.sm),
                    Expanded(
                      child: Text(
                        'Select a date, rate each activity, and save once.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AlifColors.textSecondary,
                            ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AlifSpacing.md),
                Row(
                  children: [
                    const Icon(Icons.event_note_rounded, size: 20),
                    const SizedBox(width: AlifSpacing.sm),
                    Expanded(
                      child: Text(
                        'Log Date: ${_dateLabel(_selectedDate)}',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                    ),
                    FilledButton.tonal(
                      onPressed: _pickLogDate,
                      child: const Text('Pick Date'),
                    ),
                  ],
                ),
                if (_linkedStudents.isNotEmpty) ...[
                  const SizedBox(height: AlifSpacing.md),
                  DropdownButtonFormField<String>(
                    initialValue: _studentId,
                    items: _linkedStudents
                        .map(
                          (student) => DropdownMenuItem<String>(
                            value: student.id,
                            child: Text(student.name),
                          ),
                        )
                        .toList(growable: false),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _studentId = value);
                      }
                    },
                    decoration: const InputDecoration(labelText: 'Student'),
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
                                              _selectedRatings[activity.id] =
                                                  option.id;
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
            label: _saving
                ? 'Saving...'
                : 'Save Marks for ${_dateLabel(_selectedDate)}',
            isLoading: _saving,
            onPressed: _saving ? null : _saveSelectedDate,
          ),
        ],
      ),
    );
  }
}

// ====================== Leaderboard Page ======================

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

// ====================== Progress Page ======================

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
              const AlifCard(child: Text('No progress data available.'))
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
