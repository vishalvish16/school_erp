// =============================================================================
// FILE: lib/models/group_admin/group_admin_models.dart
// PURPOSE: Immutable model classes for the Group Admin portal.
// =============================================================================

class GroupAdminDashboardStats {
  final String groupId;
  final String groupName;
  final String? groupSlug;
  final String? groupLogoUrl;
  final String groupStatus;
  final int totalSchools;
  final int activeSchools;
  final int totalStudents;
  final int totalTeachers;
  final int expiringSoon;
  final Map<String, int> subscriptionBreakdown;

  const GroupAdminDashboardStats({
    required this.groupId,
    required this.groupName,
    this.groupSlug,
    this.groupLogoUrl,
    required this.groupStatus,
    required this.totalSchools,
    required this.activeSchools,
    required this.totalStudents,
    required this.totalTeachers,
    required this.expiringSoon,
    required this.subscriptionBreakdown,
  });

  factory GroupAdminDashboardStats.fromJson(Map<String, dynamic> j) {
    final group = j['group'];
    final groupMap = group is Map ? Map<String, dynamic>.from(group) : null;

    final breakdown = <String, int>{};
    final rawBreakdown = j['subscription_breakdown'] ?? j['subscriptionBreakdown'];
    if (rawBreakdown is Map) {
      rawBreakdown.forEach((k, v) {
        breakdown[k.toString()] = (v is num) ? v.toInt() : 0;
      });
    }

    int toInt(dynamic v) => (v is num) ? v.toInt() : 0;

    return GroupAdminDashboardStats(
      groupId: groupMap?['id']?.toString() ?? j['group_id']?.toString() ?? j['id']?.toString() ?? '',
      groupName: groupMap?['name']?.toString() ?? j['group_name']?.toString() ?? j['name']?.toString() ?? '',
      groupSlug: groupMap?['slug']?.toString() ?? j['group_slug']?.toString() ?? j['slug']?.toString(),
      groupLogoUrl: groupMap?['logoUrl']?.toString() ?? groupMap?['logo_url']?.toString() ?? j['group_logo_url']?.toString() ?? j['logo_url']?.toString(),
      groupStatus: groupMap?['status']?.toString() ?? j['group_status']?.toString() ?? j['status']?.toString() ?? 'ACTIVE',
      totalSchools: toInt(j['total_schools'] ?? j['totalSchools']),
      activeSchools: toInt(j['active_schools'] ?? j['activeSchools']),
      totalStudents: toInt(j['total_students'] ?? j['totalStudents']),
      totalTeachers: toInt(j['total_teachers'] ?? j['totalTeachers']),
      expiringSoon: toInt(j['expiring_soon'] ?? j['expiringSoon']),
      subscriptionBreakdown: breakdown,
    );
  }
}

class GroupAdminSchoolModel {
  final String id;
  final String name;
  final String code;
  final String? city;
  final String? state;
  final String? board;
  final String status;
  final String subscriptionPlan;
  final DateTime? subscriptionEnd;
  final int userCount;

  const GroupAdminSchoolModel({
    required this.id,
    required this.name,
    required this.code,
    this.city,
    this.state,
    this.board,
    required this.status,
    required this.subscriptionPlan,
    this.subscriptionEnd,
    required this.userCount,
  });

  factory GroupAdminSchoolModel.fromJson(Map<String, dynamic> j) {
    final userCountRaw = j['user_count'] ?? j['userCount'];
    final userCount = (userCountRaw as num?)?.toInt() ?? 0;

    return GroupAdminSchoolModel(
      id: j['id']?.toString() ?? '',
      name: j['name']?.toString() ?? '',
      code: j['code']?.toString() ?? '',
      city: j['city']?.toString(),
      state: j['state']?.toString(),
      board: j['board']?.toString(),
      status: j['status']?.toString() ?? 'ACTIVE',
      subscriptionPlan: j['subscription_plan']?.toString() ??
          j['subscriptionPlan']?.toString() ??
          j['plan']?.toString() ??
          'BASIC',
      subscriptionEnd: (j['subscription_end'] ?? j['subscriptionEnd']) != null
          ? DateTime.tryParse((j['subscription_end'] ?? j['subscriptionEnd']).toString())
          : null,
      userCount: userCount,
    );
  }
}

class GroupAdminSchoolDetailModel {
  final String id;
  final String name;
  final String code;
  final String? email;
  final String? phone;
  final String? city;
  final String? state;
  final String? country;
  final String? pinCode;
  final String? board;
  final String? timezone;
  final String status;
  final String subscriptionPlan;
  final DateTime? subscriptionStart;
  final DateTime? subscriptionEnd;
  final int userCount;
  final String? schoolAdminName;
  final String? schoolAdminEmail;

  const GroupAdminSchoolDetailModel({
    required this.id,
    required this.name,
    required this.code,
    this.email,
    this.phone,
    this.city,
    this.state,
    this.country,
    this.pinCode,
    this.board,
    this.timezone,
    required this.status,
    required this.subscriptionPlan,
    this.subscriptionStart,
    this.subscriptionEnd,
    required this.userCount,
    this.schoolAdminName,
    this.schoolAdminEmail,
  });

  factory GroupAdminSchoolDetailModel.fromJson(Map<String, dynamic> j) {
    // user_count: backend may return _count.users (raw Prisma) or user_count (transformed)
    final userCountRaw = j['user_count'] ?? (j['_count'] is Map ? (j['_count'] as Map)['users'] : null);
    final userCount = (userCountRaw as num?)?.toInt() ?? 0;

    return GroupAdminSchoolDetailModel(
      id: j['id']?.toString() ?? '',
      name: j['name']?.toString() ?? '',
      code: j['code']?.toString() ?? '',
      email: j['email']?.toString(),
      phone: j['phone']?.toString(),
      city: j['city']?.toString(),
      state: j['state']?.toString(),
      country: j['country']?.toString(),
      pinCode: j['pin_code']?.toString() ?? j['pinCode']?.toString(),
      board: j['board']?.toString(),
      timezone: j['timezone']?.toString(),
      status: j['status']?.toString() ?? 'ACTIVE',
      subscriptionPlan: j['subscription_plan']?.toString() ??
          j['subscriptionPlan']?.toString() ??
          j['plan']?.toString() ??
          'BASIC',
      subscriptionStart: (j['subscription_start'] ?? j['subscriptionStart']) != null
          ? DateTime.tryParse((j['subscription_start'] ?? j['subscriptionStart']).toString())
          : null,
      subscriptionEnd: (j['subscription_end'] ?? j['subscriptionEnd']) != null
          ? DateTime.tryParse((j['subscription_end'] ?? j['subscriptionEnd']).toString())
          : null,
      userCount: userCount,
      schoolAdminName: j['school_admin_name']?.toString() ??
          j['admin_name']?.toString(),
      schoolAdminEmail: j['school_admin_email']?.toString() ??
          j['admin_email']?.toString(),
    );
  }
}

class GroupAdminProfileModel {
  final String userId;
  final String email;
  final String? firstName;
  final String? lastName;
  final String? phone;
  final DateTime? lastLogin;
  final String? avatarUrl;
  final String groupId;
  final String groupName;
  final String? groupSlug;
  final String? groupCountry;
  final String? groupLogoUrl;

  const GroupAdminProfileModel({
    required this.userId,
    required this.email,
    this.firstName,
    this.lastName,
    this.phone,
    this.lastLogin,
    this.avatarUrl,
    required this.groupId,
    required this.groupName,
    this.groupSlug,
    this.groupCountry,
    this.groupLogoUrl,
  });

  factory GroupAdminProfileModel.fromJson(Map<String, dynamic> j) {
    // Backend returns nested { user, group } structure
    final userMap = j['user'] is Map
        ? Map<String, dynamic>.from(j['user'] as Map)
        : null;
    final groupMap = j['group'] is Map
        ? Map<String, dynamic>.from(j['group'] as Map)
        : null;

    String? str(dynamic m, List<String> keys) {
      if (m == null) return null;
      for (final k in keys) {
        final v = m[k];
        if (v != null && v.toString().isNotEmpty) return v.toString();
      }
      return null;
    }

    String strReq(dynamic m, List<String> keys, String fallback) {
      final s = str(m, keys);
      return s != null && s.isNotEmpty ? s : fallback;
    }

    final u = userMap;
    final g = groupMap;

    return GroupAdminProfileModel(
      userId: u != null
          ? strReq(u, ['id', 'user_id'], '')
          : (j['user_id']?.toString() ?? j['id']?.toString() ?? ''),
      email: u != null
          ? strReq(u, ['email'], '')
          : (j['email']?.toString() ?? ''),
      firstName: u != null
          ? str(u, ['firstName', 'first_name'])
          : j['first_name']?.toString(),
      lastName: u != null
          ? str(u, ['lastName', 'last_name'])
          : j['last_name']?.toString(),
      phone: u != null
          ? str(u, ['phone'])
          : j['phone']?.toString(),
      lastLogin: _parseDateTime(
        u != null ? u['lastLogin'] ?? u['last_login'] : j['last_login'],
      ),
      avatarUrl: u != null
          ? str(u, ['avatarUrl', 'avatar_url'])
          : (j['avatar_url']?.toString() ?? j['avatarUrl']?.toString()),
      groupId: g != null
          ? strReq(g, ['id', 'group_id'], '')
          : (j['group_id']?.toString() ?? ''),
      groupName: g != null
          ? strReq(g, ['name', 'group_name'], '')
          : (j['group_name']?.toString() ?? j['name']?.toString() ?? ''),
      groupSlug: g != null
          ? str(g, ['slug', 'group_slug'])
          : (j['group_slug']?.toString() ?? j['slug']?.toString()),
      groupCountry: g != null
          ? str(g, ['country', 'group_country'])
          : (j['group_country']?.toString() ?? j['country']?.toString()),
      groupLogoUrl: g != null
          ? str(g, ['logoUrl', 'logo_url', 'group_logo_url'])
          : (j['group_logo_url']?.toString() ?? j['logo_url']?.toString()),
    );
  }

  static DateTime? _parseDateTime(dynamic v) {
    if (v == null) return null;
    return DateTime.tryParse(v.toString());
  }

  String get displayName {
    return [firstName, lastName]
        .where((s) => s != null && s.isNotEmpty)
        .join(' ');
  }

  String get initials {
    final name = displayName.isNotEmpty ? displayName : email;
    final parts = name.split(' ');
    return parts
        .take(2)
        .map((p) => p.isNotEmpty ? p[0].toUpperCase() : '')
        .join();
  }
}

// ── Analytics / Comparison Models ─────────────────────────────────────────────

class GroupAdminSchoolComparisonItem {
  final String id;
  final String name;
  final String code;
  final String? city;
  final String? state;
  final String? board;
  final String status;
  final String subscriptionPlan;
  final DateTime? subscriptionEnd;
  final int userCount;
  final String expiryStatus; // "ok" | "expiring_soon" | "expired"

  const GroupAdminSchoolComparisonItem({
    required this.id,
    required this.name,
    required this.code,
    this.city,
    this.state,
    this.board,
    required this.status,
    required this.subscriptionPlan,
    this.subscriptionEnd,
    required this.userCount,
    required this.expiryStatus,
  });

  factory GroupAdminSchoolComparisonItem.fromJson(Map<String, dynamic> j) {
    return GroupAdminSchoolComparisonItem(
      id: j['id']?.toString() ?? '',
      name: j['name']?.toString() ?? '',
      code: j['code']?.toString() ?? '',
      city: j['city']?.toString(),
      state: j['state']?.toString(),
      board: j['board']?.toString(),
      status: j['status']?.toString() ?? 'ACTIVE',
      subscriptionPlan: j['subscription_plan']?.toString() ??
          j['plan']?.toString() ??
          'BASIC',
      subscriptionEnd: j['subscription_end'] != null
          ? DateTime.tryParse(j['subscription_end'].toString())
          : null,
      userCount: (j['user_count'] as num?)?.toInt() ?? 0,
      expiryStatus: j['expiry_status']?.toString() ?? 'ok',
    );
  }
}

class GroupAdminComparisonReport {
  final List<GroupAdminSchoolComparisonItem> schools;
  final int totalSchools;
  final int totalUsers;
  final Map<String, int> statusBreakdown;
  final Map<String, int> planBreakdown;

  const GroupAdminComparisonReport({
    required this.schools,
    required this.totalSchools,
    required this.totalUsers,
    required this.statusBreakdown,
    required this.planBreakdown,
  });

  factory GroupAdminComparisonReport.fromJson(Map<String, dynamic> j) {
    final rawSchools = j['schools'];
    final schools = rawSchools is List
        ? rawSchools
            .map((e) => GroupAdminSchoolComparisonItem.fromJson(
                  e is Map<String, dynamic> ? e : {},
                ))
            .toList()
        : <GroupAdminSchoolComparisonItem>[];

    Map<String, int> parseIntMap(dynamic raw) {
      final result = <String, int>{};
      if (raw is Map) {
        raw.forEach((k, v) {
          result[k.toString()] = (v is num) ? v.toInt() : 0;
        });
      }
      return result;
    }

    return GroupAdminComparisonReport(
      schools: schools,
      totalSchools: (j['total_schools'] as num?)?.toInt() ?? schools.length,
      totalUsers: (j['total_users'] as num?)?.toInt() ?? 0,
      statusBreakdown: parseIntMap(j['status_breakdown']),
      planBreakdown: parseIntMap(j['plan_breakdown']),
    );
  }
}

// ── Notification Model ────────────────────────────────────────────────────────

class GroupAdminNotificationModel {
  final String id;
  final String type;
  final String title;
  final String body;
  final bool isRead;
  final String? link;
  final DateTime createdAt;

  const GroupAdminNotificationModel({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    required this.isRead,
    this.link,
    required this.createdAt,
  });

  factory GroupAdminNotificationModel.fromJson(Map<String, dynamic> j) {
    return GroupAdminNotificationModel(
      id: j['id']?.toString() ?? '',
      type: j['type']?.toString() ?? j['notification_type']?.toString() ?? '',
      title: j['title']?.toString() ?? '',
      body: j['body']?.toString() ?? j['message']?.toString() ?? '',
      isRead: j['is_read'] == true,
      link: j['link']?.toString(),
      createdAt: j['created_at'] != null
          ? (DateTime.tryParse(j['created_at'].toString()) ?? DateTime.now())
          : DateTime.now(),
    );
  }
}
