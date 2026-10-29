import 'package:alif_design_system/alif_design_system.dart';
import 'package:flutter/material.dart';

import '../models/notification_item.dart';
import '../services/notification_service.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();

  List<NotificationItem> _notifications = [];
  String _targetType = 'all';
  String? _targetId;
  bool _schedule = false;
  DateTime? _scheduledAt;
  bool _isRecurring = false;
  String _recurringType = 'once'; // once, daily, weekly, monthly
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
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final list = await NotificationService.listNotifications();
      if (!mounted) {
        return;
      }
      setState(() => _notifications = list);
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

  Future<void> _pickSchedule() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );
    if (!mounted || date == null) {
      return;
    }

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (!mounted || time == null) {
      return;
    }

    setState(() {
      _scheduledAt = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
    });
  }

  Future<void> _submit() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Title is required')));
      return;
    }

    if ((_schedule || _isRecurring) && _scheduledAt == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pick date and time for scheduled delivery')),
      );
      return;
    }

    try {
      setState(() => _isSubmitting = true);

      await NotificationService.createNotification(
        title: title,
        body: _bodyController.text.trim().isEmpty
            ? null
            : _bodyController.text.trim(),
        targetType: _targetType,
        targetId: _targetId,
        scheduledAt: _schedule || _isRecurring ? _scheduledAt : null,
        frequency: _isRecurring ? _recurringType : null,
      );

      _titleController.clear();
      _bodyController.clear();
      setState(() {
        _targetType = 'all';
        _targetId = null;
        _schedule = false;
        _isRecurring = false;
        _recurringType = 'once';
        _scheduledAt = null;
      });

      await _load();
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Notification created successfully')),
      );
    } catch (e) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Create failed: $e')));
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  Future<void> _delete(NotificationItem item) async {
    try {
      await NotificationService.deleteNotification(item.id);
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

  @override
  Widget build(BuildContext context) {
    return AlifAppShell(
      title: 'Notifications',
      body: ListView(
        padding: const EdgeInsets.all(AlifSpacing.md),
        children: [
          AlifCard(
            child: Column(
              children: [
                TextField(
                  controller: _titleController,
                  decoration: const InputDecoration(labelText: 'Title'),
                ),
                const SizedBox(height: AlifSpacing.md),
                TextField(
                  controller: _bodyController,
                  minLines: 2,
                  maxLines: 4,
                  decoration: const InputDecoration(labelText: 'Message'),
                ),
                const SizedBox(height: AlifSpacing.md),
                DropdownButtonFormField<String>(
                  initialValue: _targetType,
                  items: const [
                    DropdownMenuItem(value: 'all', child: Text('All')),
                    DropdownMenuItem(value: 'batch', child: Text('Batch')),
                    DropdownMenuItem(value: 'class', child: Text('Class')),
                    DropdownMenuItem(value: 'student', child: Text('Student')),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _targetType = value;
                        _targetId = null;
                      });
                    }
                  },
                  decoration: const InputDecoration(labelText: 'Target Type'),
                ),
                if (_targetType != 'all') ...[
                  const SizedBox(height: AlifSpacing.sm),
                  TextField(
                    decoration: InputDecoration(
                      labelText: 'Target ID (UUID)',
                      hintText: 'Leave empty to target all ${_targetType}s',
                    ),
                    onChanged: (value) => setState(() => _targetId = value.isEmpty ? null : value),
                  ),
                ],
                const SizedBox(height: AlifSpacing.md),
                SwitchListTile(
                  value: _isRecurring,
                  onChanged: (value) => setState(() => _isRecurring = value),
                  title: const Text('Recurring notification'),
                  subtitle: const Text('Send repeatedly on a schedule'),
                  contentPadding: EdgeInsets.zero,
                ),
                if (_isRecurring) ...[
                  const SizedBox(height: AlifSpacing.sm),
                  DropdownButtonFormField<String>(
                    initialValue: _recurringType,
                    items: const [
                      DropdownMenuItem(value: 'daily', child: Text('Daily')),
                      DropdownMenuItem(value: 'weekly', child: Text('Weekly')),
                      DropdownMenuItem(value: 'monthly', child: Text('Monthly')),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _recurringType = value);
                      }
                    },
                    decoration: const InputDecoration(labelText: 'Repeat'),
                  ),
                ],
                const SizedBox(height: AlifSpacing.md),
                SwitchListTile(
                  value: _schedule,
                  onChanged: (value) => setState(() => _schedule = value),
                  title: const Text('Schedule this notification'),
                  contentPadding: EdgeInsets.zero,
                ),
                if (_schedule || _isRecurring) ...[
                  const SizedBox(height: AlifSpacing.sm),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          _scheduledAt == null
                              ? 'Pick date & time'
                              : 'Scheduled: ${_scheduledAt!.toLocal()}',
                        ),
                      ),
                      FilledButton.tonal(
                        onPressed: _pickSchedule,
                        child: const Text('Pick Date & Time'),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: AlifSpacing.md),
                Row(
                  children: [
                    Expanded(
                      child: AlifButton(
                        label: _isRecurring
                            ? 'Create Recurring'
                            : (_schedule ? 'Schedule' : 'Send Now'),
                        isLoading: _isSubmitting,
                        onPressed: _isSubmitting ? null : _submit,
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
              ],
            ),
          ),
          const SizedBox(height: AlifSpacing.md),
          if (_isLoading)
            const Center(child: CircularProgressIndicator())
          else if (_error != null)
            Text('Error: $_error', style: const TextStyle(color: Colors.red))
          else if (_notifications.isEmpty)
            const AlifCard(child: Text('No notifications found.'))
          else
            ..._notifications.map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: AlifSpacing.md),
                child: AlifCard(
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.title,
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            if ((item.body ?? '').isNotEmpty)
                              Text(
                                item.body!,
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            const SizedBox(height: AlifSpacing.xs),
                            Text(
                              'Target: ${item.targetType} | Sent: ${item.sentAt != null ? 'yes' : 'no'}',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => _delete(item),
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
