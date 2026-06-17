import 'category.dart';

class ActivityItem {
  final String id;
  final String categoryId;
  final String name;
  final String? nameMl;
  final int displayOrder;
  final bool hasQuantity;
  final String status;
  final ActivityCategory? category;

  ActivityItem({
    required this.id,
    required this.categoryId,
    required this.name,
    this.nameMl,
    required this.displayOrder,
    required this.hasQuantity,
    required this.status,
    this.category,
  });

  factory ActivityItem.fromJson(Map<String, dynamic> json) {
    return ActivityItem(
      id: json['id'] as String,
      categoryId: json['category_id'] as String,
      name: json['name'] as String,
      nameMl: json['name_ml'] as String?,
      displayOrder: json['display_order'] as int? ?? 0,
      hasQuantity: json['has_quantity'] as bool? ?? false,
      status: json['status'] as String? ?? 'active',
      category: json['activity_categories'] != null
          ? ActivityCategory.fromJson(
              json['activity_categories'] as Map<String, dynamic>,
            )
          : null,
    );
  }
}