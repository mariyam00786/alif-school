import 'package:flutter/material.dart';
import 'package:alif_design_system/alif_design_system.dart';
import 'package:alif_student_teacher/models/badge_teacher.dart';
import 'package:alif_student_teacher/services/api_service.dart';

class StudentBadgesPage extends StatefulWidget {
  const StudentBadgesPage({super.key});

  @override
  State<StudentBadgesPage> createState() => _StudentBadgesPageState();
}

class _StudentBadgesPageState extends State<StudentBadgesPage> {
  bool _isLoading = true;
  String? _error;
  List<StudentBadge> _badges = const [];

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
      final badges = await ApiService.getBadges(studentId: studentId);

      if (!mounted) {
        return;
      }

      setState(() => _badges = badges);
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
          AlifCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Your Achievements',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: AlifSpacing.sm),
                Text(
                  'Earn badges by completing activities and maintaining streaks.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AlifColors.textSecondary,
                      ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AlifSpacing.md),
          if (_isLoading)
            const Center(child: CircularProgressIndicator())
          else if (_error != null)
            Text('Error: $_error', style: const TextStyle(color: Colors.red))
          else if (_badges.isEmpty)
            const AlifCard(child: Text('No badges earned yet. Keep practicing!'))
          else
            ..._badges.map((badge) {
              return Padding(
                padding: const EdgeInsets.only(bottom: AlifSpacing.md),
                child: AlifCard(
                  child: Row(
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: badge.earned
                              ? AlifColors.primaryContainer
                              : AlifColors.surface,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.workspace_premium_rounded,
                          size: 40,
                          color: badge.earned ? AlifColors.primary : AlifColors.neutral,
                        ),
                      ),
                      const SizedBox(width: AlifSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              badge.badgeName,
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            if ((badge.description ?? '').isNotEmpty)
                              Text(
                                badge.description!,
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            if (badge.awardedAt != null)
                              Text(
                                'Earned: ${badge.awardedAt!.toString().split(' ')[0]}',
                                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                    color: AlifColors.textSecondary,
                                    ),
                              ),
                          ],
                        ),
                      ),
                      if (badge.earned)
                        const Icon(Icons.check_circle, color: Colors.green)
                      else
                        const Icon(Icons.lock_outline, color: Colors.grey),
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
