// =============================================================================
// FILE: lib/models/super_admin/plan_model.dart
// PURPOSE: Super Admin plan model (UUID-based schema)
// =============================================================================

class SuperAdminPlanModel {
  final String id;
  final String name;
  final String slug;
  final String? description;
  final String? iconEmoji;
  final String? colorHex;
  final String? supportLevel;
  final String? status;
  final double pricePerStudent;
  final int? maxStudents;
  final int? sortOrder;
  final Map<String, bool> features;
  final int schoolCount;
  final double mrr;

  SuperAdminPlanModel({
    required this.id,
    required this.name,
    required this.slug,
    this.description,
    this.iconEmoji,
    this.colorHex,
    this.supportLevel,
    this.status,
    this.pricePerStudent = 0,
    this.maxStudents,
    this.sortOrder,
    this.features = const {},
    this.schoolCount = 0,
    this.mrr = 0,
  });

  factory SuperAdminPlanModel.fromJson(Map<String, dynamic> json) {
    final featuresMap = <String, bool>{};
    final pf = json['plan_features'] ?? json['features'] ?? [];
    if (pf is List) {
      for (final f in pf) {
        final key = f['feature_key'] ?? f['featureKey'];
        if (key != null) {
          featuresMap[key.toString()] = f['is_enabled'] ?? f['isEnabled'] ?? true;
        }
      }
    } else if (pf is Map) {
      featuresMap.addAll(
        (pf).map((k, v) => MapEntry(k.toString(), v == true)),
      );
    }
    return SuperAdminPlanModel(
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? '',
      slug: json['slug'] ?? '',
      description: json['description'],
      iconEmoji: json['icon_emoji'] ?? json['iconEmoji'],
      colorHex: json['color_hex'] ?? json['colorHex'],
      supportLevel: json['support_level'] ?? json['supportLevel'],
      status: json['status'],
      pricePerStudent: (json['price_per_student'] ?? json['pricePerStudent'] ?? 0) is num
          ? (json['price_per_student'] ?? json['pricePerStudent'] ?? 0).toDouble()
          : double.tryParse(json['price_per_student']?.toString() ?? '') ?? 0,
      maxStudents: json['max_students'] ?? json['maxStudents'],
      sortOrder: json['sort_order'] ?? json['sortOrder'],
      features: featuresMap,
      schoolCount: json['school_count'] ?? json['schoolCount'] ?? 0,
      mrr: (json['mrr'] ?? 0) is num ? (json['mrr'] ?? 0).toDouble() : 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'slug': slug,
        'description': description,
        'icon_emoji': iconEmoji,
        'color_hex': colorHex,
        'support_level': supportLevel,
        'status': status,
        'price_per_student': pricePerStudent,
        'max_students': maxStudents,
        'sort_order': sortOrder,
        'school_count': schoolCount,
        'mrr': mrr,
      };
}
