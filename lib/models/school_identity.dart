// =============================================================================
// FILE: lib/models/school_identity.dart
// PURPOSE: School/Group identity model for subdomain resolution
// =============================================================================

class SchoolIdentity {
  const SchoolIdentity({
    required this.id,
    required this.name,
    required this.code,
    this.logoUrl,
    required this.board,
    required this.type,
    this.studentCount,
    required this.active,
  });

  final String id;
  final String name;
  final String code;
  final String? logoUrl;
  final String board;
  final String type; // "school" | "group"
  final int? studentCount;
  final bool active;

  factory SchoolIdentity.fromJson(Map<String, dynamic> json) {
    return SchoolIdentity(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      code: json['code']?.toString() ?? '',
      logoUrl: json['logo_url']?.toString(),
      board: json['board']?.toString() ?? '',
      type: json['type']?.toString() ?? 'school',
      studentCount: json['student_count'] is int
          ? json['student_count'] as int
          : int.tryParse(json['student_count']?.toString() ?? ''),
      active: json['active'] == true || json['is_active'] == true,
    );
  }
}
