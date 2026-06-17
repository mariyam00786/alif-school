class BadgeItem {
  const BadgeItem({
    required this.id,
    required this.name,
    this.nameMl,
    this.description,
    this.icon,
    this.criteria,
    required this.bonusPoints,
    required this.status,
    this.createdAt,
  });

  final String id;
  final String name;
  final String? nameMl;
  final String? description;
  final String? icon;
  final Map<String, dynamic>? criteria;
  final int bonusPoints;
  final String status;
  final DateTime? createdAt;

  factory BadgeItem.fromJson(Map<String, dynamic> json) {
    return BadgeItem(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      nameMl: json['name_ml'] as String?,
      description: json['description'] as String?,
      icon: json['icon'] as String?,
      criteria: json['criteria'] as Map<String, dynamic>?,
      bonusPoints: (json['bonus_points'] as num? ?? 0).toInt(),
      status: json['status'] as String? ?? 'active',
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? ''),
    );
  }
}
