class NotificationItem {
  const NotificationItem({
    required this.id,
    required this.title,
    this.body,
    required this.targetType,
    this.targetId,
    this.scheduledAt,
    this.sentAt,
    this.createdAt,
  });

  final String id;
  final String title;
  final String? body;
  final String targetType;
  final String? targetId;
  final DateTime? scheduledAt;
  final DateTime? sentAt;
  final DateTime? createdAt;

  factory NotificationItem.fromJson(Map<String, dynamic> json) {
    return NotificationItem(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      body: json['body'] as String?,
      targetType: json['target_type'] as String? ?? 'all',
      targetId: json['target_id'] as String?,
      scheduledAt: DateTime.tryParse(json['scheduled_at'] as String? ?? ''),
      sentAt: DateTime.tryParse(json['sent_at'] as String? ?? ''),
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? ''),
    );
  }
}
