import 'package:alif_design_system/alif_design_system.dart';
import 'package:flutter/material.dart';

import '../models/badge.dart';
import '../services/badge_service.dart';

class BadgesPage extends StatefulWidget {
  const BadgesPage({super.key});

  @override
  State<BadgesPage> createState() => _BadgesPageState();
}

class _BadgesPageState extends State<BadgesPage> {
  List<BadgeItem> _badges = [];
  bool _isLoading = true;
  String? _error;
  String _status = 'active';

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

      final badges = await BadgeService.listBadges(status: _status);
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

  Future<void> _deleteBadge(BadgeItem badge) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Badge'),
        content: Text('Delete ${badge.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed != true) {
      return;
    }

    try {
      await BadgeService.deleteBadge(badge.id);
      await _load();
    } catch (e) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Delete failed: $e')));
    }
  }

  Future<void> _showBadgeDialog([BadgeItem? badge]) async {
    final nameController = TextEditingController(text: badge?.name ?? '');
    final nameMlController = TextEditingController(text: badge?.nameMl ?? '');
    final descriptionController = TextEditingController(
      text: badge?.description ?? '',
    );
    final iconController = TextEditingController(text: badge?.icon ?? '');
    final bonusController = TextEditingController(
      text: (badge?.bonusPoints ?? 0).toString(),
    );
    String status = badge?.status ?? 'active';

    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(badge == null ? 'Create Badge' : 'Edit Badge'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Badge Name'),
                ),
                TextField(
                  controller: nameMlController,
                  decoration: const InputDecoration(
                    labelText: 'Badge Name (Malayalam)',
                  ),
                ),
                TextField(
                  controller: descriptionController,
                  decoration: const InputDecoration(labelText: 'Description'),
                ),
                TextField(
                  controller: iconController,
                  decoration: const InputDecoration(labelText: 'Icon'),
                ),
                TextField(
                  controller: bonusController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Bonus Points'),
                ),
                const SizedBox(height: AlifSpacing.sm),
                DropdownButtonFormField<String>(
                  initialValue: status,
                  items: const [
                    DropdownMenuItem(value: 'active', child: Text('Active')),
                    DropdownMenuItem(
                      value: 'inactive',
                      child: Text('Inactive'),
                    ),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setDialogState(() => status = value);
                    }
                  },
                  decoration: const InputDecoration(labelText: 'Status'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );

    if (saved != true) {
      return;
    }

    try {
      final bonus = int.tryParse(bonusController.text.trim()) ?? 0;
      if (badge == null) {
        await BadgeService.createBadge(
          name: nameController.text.trim(),
          nameMl: nameMlController.text.trim().isEmpty
              ? null
              : nameMlController.text.trim(),
          description: descriptionController.text.trim().isEmpty
              ? null
              : descriptionController.text.trim(),
          icon: iconController.text.trim().isEmpty
              ? null
              : iconController.text.trim(),
          bonusPoints: bonus,
          status: status,
        );
      } else {
        await BadgeService.updateBadge(
          badge.id,
          name: nameController.text.trim(),
          nameMl: nameMlController.text.trim().isEmpty
              ? null
              : nameMlController.text.trim(),
          description: descriptionController.text.trim().isEmpty
              ? null
              : descriptionController.text.trim(),
          icon: iconController.text.trim().isEmpty
              ? null
              : iconController.text.trim(),
          bonusPoints: bonus,
          status: status,
        );
      }

      await _load();
    } catch (e) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Save failed: $e')));
    } finally {
      nameController.dispose();
      nameMlController.dispose();
      descriptionController.dispose();
      iconController.dispose();
      bonusController.dispose();
    }
  }

  Future<void> _showRulesDialog(BadgeItem badge) async {
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Award Rules for ${badge.name}'),
        content: SizedBox(
          width: 500,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Badge award rules can be created to automatically grant this badge when students meet certain criteria.',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(height: AlifSpacing.md),
                const Text(
                  'Supported Rule Types:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Text(
                    '• activity_count: Award when student completes N activities\n'
                    '• total_marks: Award when student earns N total marks\n'
                    '• activity_streak: Award for completing activities N days in a row\n'
                    '• first_completion: Award on first completion of a specific activity',
                    style: TextStyle(fontSize: 12),
                  ),
                ),
                const SizedBox(height: AlifSpacing.md),
                Text(
                  'API Endpoint: POST /api/badges/${badge.id}/rules',
                  style: const TextStyle(fontSize: 10, fontFamily: 'monospace'),
                ),
                const SizedBox(height: AlifSpacing.md),
                const Text(
                  'Example Request:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                ),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    '{\n'
                    '  "rule_type": "activity_count",\n'
                    '  "rule_config": {\n'
                    '    "threshold": 10\n'
                    '  },\n'
                    '  "is_active": true\n'
                    '}',
                    style: TextStyle(fontSize: 10, fontFamily: 'monospace'),
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Use API directly or admin dashboard to manage rules'),
                ),
              );
            },
            child: const Text('Learn More'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlifAppShell(
      title: 'Badges',
      actions: [
        Padding(
          padding: const EdgeInsets.all(AlifSpacing.md),
          child: AlifButton(
            label: '+ Add Badge',
            expand: false,
            onPressed: _showBadgeDialog,
          ),
        ),
      ],
      body: ListView(
        padding: const EdgeInsets.all(AlifSpacing.md),
        children: [
          AlifCard(
            child: Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: _status,
                    items: const [
                      DropdownMenuItem(value: 'active', child: Text('Active')),
                      DropdownMenuItem(
                        value: 'inactive',
                        child: Text('Inactive'),
                      ),
                    ],
                    onChanged: (value) async {
                      if (value == null) {
                        return;
                      }

                      setState(() => _status = value);
                      await _load();
                    },
                    decoration: const InputDecoration(labelText: 'Status'),
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
          else if (_badges.isEmpty)
            const AlifCard(child: Text('No badges found for this filter.'))
          else
            ..._badges.map(
              (badge) => Padding(
                padding: const EdgeInsets.only(bottom: AlifSpacing.md),
                child: AlifCard(
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              badge.name,
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            if ((badge.nameMl ?? '').isNotEmpty)
                              Text(
                                badge.nameMl!,
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            const SizedBox(height: AlifSpacing.xs),
                            Text(
                              'Bonus: ${badge.bonusPoints} | Status: ${badge.status}',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                            if ((badge.description ?? '').isNotEmpty)
                              Text(
                                badge.description!,
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => _showBadgeDialog(badge),
                        icon: const Icon(Icons.edit),
                      ),
                      IconButton(
                        onPressed: () => _showRulesDialog(badge),
                        icon: const Icon(Icons.rule_outlined),
                        tooltip: 'Manage Award Rules',
                      ),
                      IconButton(
                        onPressed: () => _deleteBadge(badge),
                        icon: const Icon(Icons.delete_outline),
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
