import 'package:flutter/material.dart';
import 'package:alif_design_system/alif_design_system.dart';

import '../services/fcm_service.dart';
import '../models/notification_manager.dart';
import '../models/push_notification.dart';

/// FCM Test Screen - for development and testing
/// Add this to your navigation to test FCM functionality
class FcmTestScreen extends StatefulWidget {
  const FcmTestScreen({super.key});

  @override
  State<FcmTestScreen> createState() => _FcmTestScreenState();
}

class _FcmTestScreenState extends State<FcmTestScreen> {
  String? _fcmToken;
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    _fcmToken = FcmService.getToken();
  }

  Future<void> _refreshToken() async {
    setState(() => _isRefreshing = true);
    try {
      final token = await FcmService.refreshToken();
      if (!mounted) {
        return;
      }
      setState(() => _fcmToken = token);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Token refreshed successfully')),
      );
    } catch (e) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      setState(() => _isRefreshing = false);
    }
  }

  Future<void> _copyToken() async {
    if (_fcmToken != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Token copied to clipboard')),
      );
    }
  }

  Future<void> _deleteToken() async {
    try {
      await FcmService.deleteToken();
      if (!mounted) {
        return;
      }
      setState(() => _fcmToken = null);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Token deleted')),
      );
    } catch (e) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  void _clearHistory() {
    notificationManager.clearHistory();
    setState(() {});
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Notification history cleared')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('FCM Test'),
        backgroundColor: AlifColors.primary,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AlifSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // FCM Token Section
            Text(
              'FCM Token',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: AlifSpacing.md),
            Container(
              padding: const EdgeInsets.all(AlifSpacing.md),
              decoration: BoxDecoration(
                border: Border.all(color: AlifColors.border),
                borderRadius: BorderRadius.circular(AlifSpacing.md),
                color: AlifColors.bg,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _fcmToken ?? 'No token available',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontFamily: 'monospace',
                          color: _fcmToken == null ? Colors.grey : Colors.black,
                        ),
                  ),
                  const SizedBox(height: AlifSpacing.md),
                  Wrap(
                    spacing: AlifSpacing.sm,
                    children: [
                      ElevatedButton.icon(
                        icon: const Icon(Icons.refresh),
                        label: const Text('Refresh'),
                        onPressed: _isRefreshing ? null : _refreshToken,
                      ),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.copy),
                        label: const Text('Copy'),
                        onPressed: _fcmToken == null ? null : _copyToken,
                      ),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.delete),
                        label: const Text('Delete'),
                        onPressed: _fcmToken == null ? null : _deleteToken,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: AlifSpacing.xl),

            // Instructions
            Text(
              'How to Test',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: AlifSpacing.md),
            Container(
              padding: const EdgeInsets.all(AlifSpacing.md),
              decoration: BoxDecoration(
                border: Border.all(color: AlifColors.secondary),
                borderRadius: BorderRadius.circular(AlifSpacing.md),
                color: AlifColors.secondary.withValues(alpha: 0.1),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '1. Copy the FCM token above',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: AlifSpacing.sm),
                  Text(
                    '2. Send a test notification via API:',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: AlifSpacing.sm),
                  Text(
                    'curl -X POST http://localhost:4000/notifications/test -H "Content-Type: application/json" -d \'{"token":"YOUR_TOKEN"}\' ',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontFamily: 'monospace',
                        ),
                  ),
                  const SizedBox(height: AlifSpacing.sm),
                  Text(
                    '3. Check notifications below for received message',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
            const SizedBox(height: AlifSpacing.xl),

            // Notifications History
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Recent Notifications',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                ElevatedButton.icon(
                  icon: const Icon(Icons.clear_all, size: 18),
                  label: const Text('Clear'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AlifColors.danger,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: _clearHistory,
                ),
              ],
            ),
            const SizedBox(height: AlifSpacing.md),

            // Notifications List
            StreamBuilder<PushNotification>(
              stream: notificationManager.notifications,
              builder: (context, snapshot) {
                final history = notificationManager.getHistory();
                return history.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(AlifSpacing.lg),
                          child: Text(
                            'No notifications received yet',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.grey,
                            ),
                          ),
                        ),
                      )
                    : ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: history.length,
                        itemBuilder: (context, index) {
                          final notification = history[index];
                          return Container(
                            margin: const EdgeInsets.only(bottom: AlifSpacing.sm),
                            padding: const EdgeInsets.all(AlifSpacing.md),
                            decoration: BoxDecoration(
                              border: Border.all(color: AlifColors.success),
                              borderRadius: BorderRadius.circular(AlifSpacing.md),
                              color: AlifColors.success.withValues(alpha: 0.1),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  notification.title ?? 'No title',
                                  style: Theme.of(context).textTheme.titleSmall,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: AlifSpacing.xs),
                                Text(
                                  notification.body ?? 'No body',
                                  style: Theme.of(context).textTheme.bodySmall,
                                  maxLines: 3,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                if (notification.data.isNotEmpty) ...[
                                  const SizedBox(height: AlifSpacing.xs),
                                  Text(
                                    'Data: ${notification.data}',
                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                          color: Colors.grey,
                                          fontFamily: 'monospace',
                                        ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                                const SizedBox(height: AlifSpacing.xs),
                                Text(
                                  'At: ${notification.receivedAt.toString().substring(0, 19)}',
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                        color: Colors.grey,
                                      ),
                                ),
                              ],
                            ),
                          );
                        },
                      );
              },
            ),
          ],
        ),
      ),
    );
  }
}
