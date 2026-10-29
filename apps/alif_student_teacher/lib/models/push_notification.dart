/// Represents a push notification received by the app
class PushNotification {
  final String? title;
  final String? body;
  final Map<String, dynamic> data;
  final DateTime receivedAt;

  PushNotification({
    required this.title,
    required this.body,
    required this.data,
    required this.receivedAt,
  });

  /// Convert to a readable string
  @override
  String toString() => 'PushNotification(title: $title, body: $body)';

  /// Get a specific data value
  T? getData<T>(String key) {
    final value = data[key];
    if (value is T) return value;
    return null;
  }
}
