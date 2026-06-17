class ActivityCategory {
  final String id;
  final String name;
  final String? nameMl;
  final String? icon;
  final int displayOrder;
  final String status;

  ActivityCategory({
    required this.id,
    required this.name,
    this.nameMl,
    this.icon,
    required this.displayOrder,
    required this.status,
  });

  factory ActivityCategory.fromJson(Map<String, dynamic> json) {
    return ActivityCategory(
      id: json['id'] as String,
      name: json['name'] as String,
      nameMl: json['name_ml'] as String?,
      icon: json['icon'] as String?,
      displayOrder: json['display_order'] as int? ?? 0,
      status: json['status'] as String? ?? 'active',
    );
  }
}