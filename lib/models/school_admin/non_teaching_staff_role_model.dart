// =============================================================================
// FILE: lib/models/school_admin/non_teaching_staff_role_model.dart
// PURPOSE: Non-Teaching Staff Role model with category helpers.
// =============================================================================

import 'package:flutter/material.dart';
import '../../design_system/tokens/app_colors.dart';

class NonTeachingStaffRoleModel {
  final String id;
  final String code;
  final String displayName;
  final String category; // FINANCE | LIBRARY | LABORATORY | ADMIN_SUPPORT | GENERAL
  final bool isSystem;
  final bool isActive;
  final String? description;
  final int staffCount;

  const NonTeachingStaffRoleModel({
    required this.id,
    required this.code,
    required this.displayName,
    required this.category,
    required this.isSystem,
    required this.isActive,
    this.description,
    required this.staffCount,
  });

  factory NonTeachingStaffRoleModel.fromJson(Map<String, dynamic> json) {
    final countRaw = json['staffCount'] ?? json['staff_count'];
    final countFromRelation = json['_count'] is Map
        ? (json['_count'] as Map)['staff']
        : null;
    return NonTeachingStaffRoleModel(
      id: json['id'] as String? ?? '',
      code: json['code'] as String? ?? '',
      displayName: (json['displayName'] ?? json['display_name']) as String? ?? '',
      category: json['category'] as String? ?? 'GENERAL',
      isSystem: (json['isSystem'] ?? json['is_system']) as bool? ?? false,
      isActive: (json['isActive'] ?? json['is_active']) as bool? ?? true,
      description: json['description'] as String?,
      staffCount: countRaw != null
          ? (countRaw as num).toInt()
          : (countFromRelation != null ? (countFromRelation as num).toInt() : 0),
    );
  }

  Map<String, dynamic> toJson() => {
        'code': code,
        'display_name': displayName,
        'category': category,
        if (description != null) 'description': description,
      };

  Color get categoryColor {
    switch (category) {
      case 'FINANCE':
        return AppColors.success500;
      case 'LIBRARY':
        return AppColors.warning500;
      case 'LABORATORY':
        return AppColors.primary500;
      case 'ADMIN_SUPPORT':
        return AppColors.secondary500;
      default:
        return AppColors.neutral400;
    }
  }

  IconData get categoryIcon {
    switch (category) {
      case 'FINANCE':
        return Icons.account_balance_wallet;
      case 'LIBRARY':
        return Icons.local_library;
      case 'LABORATORY':
        return Icons.science;
      case 'ADMIN_SUPPORT':
        return Icons.admin_panel_settings;
      default:
        return Icons.badge;
    }
  }

  String get categoryLabel {
    switch (category) {
      case 'FINANCE':
        return 'Finance';
      case 'LIBRARY':
        return 'Library';
      case 'LABORATORY':
        return 'Laboratory';
      case 'ADMIN_SUPPORT':
        return 'Admin Support';
      default:
        return 'General';
    }
  }
}
