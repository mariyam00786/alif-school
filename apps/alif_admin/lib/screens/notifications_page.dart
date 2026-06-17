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
  bool _schedule = false;
  DateTime? _scheduledAt;
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
    if (date == null) {
      return;
    }

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (time == null) {
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

    try {
      setState(() => _isSubmitting = true);

      await NotificationService.createNotification(
        title: title,
        body: _bodyController.text.trim().isEmpty
            ? null
            : _bodyController.text.trim(),
        targetType: _targetType,
        scheduledAt: _schedule ? _scheduledAt : null,
      );

      _titleController.clear();
      _bodyController.clear();
      setState(() {
        _targetType = 'all';
        _schedule = false;
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
                      setState(() => _targetType = value);
                    }
                  },
                  decoration: const InputDecoration(labelText: 'Target Type'),
                ),
                const SizedBox(height: AlifSpacing.sm),
                SwitchListTile(
                  value: _schedule,
                  onChanged: (value) => setState(() => _schedule = value),
                  title: const Text('Schedule this notification'),
                  contentPadding: EdgeInsets.zero,
                ),
                if (_schedule) ...[
                  const SizedBox(height: AlifSpacing.sm),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          _scheduledAt == null
                              ? 'No schedule selected'
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
                        label: 'Send / Schedule',
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
