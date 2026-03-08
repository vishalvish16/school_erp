// =============================================================================
// FILE: lib/models/super_admin/platform_feature_model.dart
// PURPOSE: Super Admin platform feature model
// =============================================================================

class SuperAdminPlatformFeatureModel {
  final String id;
  final String featureKey;
  final String featureName;
  final String category;
  final String? description;
  final bool isEnabled;

  SuperAdminPlatformFeatureModel({
    required this.id,
    required this.featureKey,
    required this.featureName,
    this.category = 'feature',
    this.description,
    this.isEnabled = true,
  });

  factory SuperAdminPlatformFeatureModel.fromJson(Map<String, dynamic> json) {
    return SuperAdminPlatformFeatureModel(
      id: json['id']?.toString() ?? '',
      featureKey: json['feature_key'] ?? json['featureKey'] ?? '',
      featureName: json['feature_name'] ?? json['featureName'] ?? '',
      category: json['category'] ?? 'feature',
      description: json['description'],
      isEnabled: json['is_enabled'] ?? json['isEnabled'] ?? true,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'feature_key': featureKey,
        'feature_name': featureName,
        'category': category,
        'description': description,
        'is_enabled': isEnabled,
      };
}
