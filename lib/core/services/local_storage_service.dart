// =============================================================================
// FILE: lib/core/services/local_storage_service.dart
// PURPOSE: Centralized local storage for school, session, portal type (mobile)
// Uses SharedPreferences — existing package
// =============================================================================

import 'package:shared_preferences/shared_preferences.dart';
import '../../models/school_identity.dart';

// Storage keys
const String KEY_SCHOOL_ID = 'vidyron_school_id';
const String KEY_SCHOOL_NAME = 'vidyron_school_name';
const String KEY_SCHOOL_CODE = 'vidyron_school_code';
const String KEY_SCHOOL_LOGO_URL = 'vidyron_school_logo_url';
const String KEY_SCHOOL_BOARD = 'vidyron_school_board';
const String KEY_SCHOOL_TYPE = 'vidyron_school_type';
const String KEY_GROUP_ID = 'vidyron_group_id';
const String KEY_GROUP_NAME = 'vidyron_group_name';
const String KEY_PORTAL_TYPE = 'vidyron_portal_type';
const String KEY_USER_PHONE = 'vidyron_user_phone';
const String KEY_SESSION_TOKEN = 'vidyron_session_token';
const String KEY_REFRESH_TOKEN = 'vidyron_refresh_token';
const String KEY_SESSION_EXPIRY = 'vidyron_session_expiry';
const String KEY_DEVICE_ID = 'vidyron_device_id';
const String KEY_IS_TRUSTED = 'vidyron_is_trusted';
const String KEY_TRUSTED_UNTIL = 'vidyron_trusted_until';
const String KEY_LAST_USER_NAME = 'vidyron_last_user_name';
const String KEY_LAST_USER_ROLE = 'vidyron_last_user_role';
const String KEY_LAST_USER_AVATAR = 'vidyron_last_user_avatar';

// Legacy key used by auth_guard_provider — we sync for compatibility
const String LEGACY_ACCESS_TOKEN = 'access_token';

class LocalStorageService {
  LocalStorageService();

  static SharedPreferences? _cached;
  static Future<SharedPreferences> get _instance async =>
      _cached ??= await SharedPreferences.getInstance();

  /// School identity (for mobile — no subdomain)
  Future<SchoolIdentity?> getSavedSchool() async {
    final p = await _instance;
    final id = p.getString(KEY_SCHOOL_ID);
    if (id == null || id.isEmpty) return null;
    return SchoolIdentity(
      id: id,
      name: p.getString(KEY_SCHOOL_NAME) ?? '',
      code: p.getString(KEY_SCHOOL_CODE) ?? '',
      logoUrl: p.getString(KEY_SCHOOL_LOGO_URL),
      board: p.getString(KEY_SCHOOL_BOARD) ?? '',
      type: p.getString(KEY_SCHOOL_TYPE) ?? 'school',
      studentCount: p.getInt('${KEY_SCHOOL_ID}_student_count'),
      active: p.getBool('${KEY_SCHOOL_ID}_active') ?? true,
    );
  }

  Future<void> saveSchool(SchoolIdentity school) async {
    final p = await _instance;
    await p.setString(KEY_SCHOOL_ID, school.id);
    await p.setString(KEY_SCHOOL_NAME, school.name);
    await p.setString(KEY_SCHOOL_CODE, school.code);
    await p.setString(KEY_SCHOOL_LOGO_URL, school.logoUrl ?? '');
    await p.setString(KEY_SCHOOL_BOARD, school.board);
    await p.setString(KEY_SCHOOL_TYPE, school.type);
    if (school.studentCount != null) {
      await p.setInt('${KEY_SCHOOL_ID}_student_count', school.studentCount!);
    }
    await p.setBool('${KEY_SCHOOL_ID}_active', school.active);
  }

  Future<void> clearSchool() async {
    final p = await _instance;
    await p.remove(KEY_SCHOOL_ID);
    await p.remove(KEY_SCHOOL_NAME);
    await p.remove(KEY_SCHOOL_CODE);
    await p.remove(KEY_SCHOOL_LOGO_URL);
    await p.remove(KEY_SCHOOL_BOARD);
    await p.remove(KEY_SCHOOL_TYPE);
    await p.remove('${KEY_SCHOOL_ID}_student_count');
    await p.remove('${KEY_SCHOOL_ID}_active');
    await p.remove(KEY_GROUP_ID);
    await p.remove(KEY_GROUP_NAME);
  }

  Future<bool> hasValidSession() async {
    final p = await _instance;
    final token = p.getString(KEY_SESSION_TOKEN) ?? p.getString(LEGACY_ACCESS_TOKEN);
    if (token == null || token.isEmpty) return false;
    final expiryStr = p.getString(KEY_SESSION_EXPIRY);
    if (expiryStr != null) {
      final expiry = DateTime.tryParse(expiryStr);
      if (expiry != null && expiry.isBefore(DateTime.now())) return false;
    }
    return true;
  }

  Future<void> saveSession(String token, String refresh, DateTime expiry) async {
    final p = await _instance;
    await p.setString(KEY_SESSION_TOKEN, token);
    await p.setString(KEY_REFRESH_TOKEN, refresh);
    await p.setString(KEY_SESSION_EXPIRY, expiry.toIso8601String());
    await p.setString(LEGACY_ACCESS_TOKEN, token); // sync with auth_guard
  }

  Future<void> clearSession() async {
    final p = await _instance;
    await p.remove(KEY_SESSION_TOKEN);
    await p.remove(KEY_REFRESH_TOKEN);
    await p.remove(KEY_SESSION_EXPIRY);
    await p.remove(LEGACY_ACCESS_TOKEN);
    await p.remove(KEY_IS_TRUSTED);
    await p.remove(KEY_TRUSTED_UNTIL);
    await p.remove(KEY_PORTAL_TYPE);
  }

  Future<String?> getSessionToken() async {
    final p = await _instance;
    return p.getString(KEY_SESSION_TOKEN) ?? p.getString(LEGACY_ACCESS_TOKEN);
  }

  Future<DateTime?> getSessionExpiry() async {
    final p = await _instance;
    final s = p.getString(KEY_SESSION_EXPIRY);
    return s != null ? DateTime.tryParse(s) : null;
  }

  Future<void> saveLastUser(String name, String role, String? avatarUrl) async {
    final p = await _instance;
    await p.setString(KEY_LAST_USER_NAME, name);
    await p.setString(KEY_LAST_USER_ROLE, role);
    await p.setString(KEY_LAST_USER_AVATAR, avatarUrl ?? '');
  }

  Future<Map<String, String>?> getLastUser() async {
    final p = await _instance;
    final name = p.getString(KEY_LAST_USER_NAME);
    if (name == null || name.isEmpty) return null;
    return {
      'name': name,
      'role': p.getString(KEY_LAST_USER_ROLE) ?? '',
      'avatar': p.getString(KEY_LAST_USER_AVATAR) ?? '',
    };
  }

  Future<void> setPortalType(String portalType) async {
    final p = await _instance;
    await p.setString(KEY_PORTAL_TYPE, portalType);
  }

  Future<String?> getPortalType() async {
    final p = await _instance;
    return p.getString(KEY_PORTAL_TYPE);
  }

  Future<void> setTrusted(bool trusted, DateTime? until) async {
    final p = await _instance;
    await p.setBool(KEY_IS_TRUSTED, trusted);
    if (until != null) {
      await p.setString(KEY_TRUSTED_UNTIL, until.toIso8601String());
    }
  }

  Future<void> saveUserPhone(String phone) async {
    final p = await _instance;
    await p.setString(KEY_USER_PHONE, phone);
  }

  Future<String?> getUserPhone() async {
    final p = await _instance;
    return p.getString(KEY_USER_PHONE);
  }

  /// Clears school, session, portal, and parent phone so splash opens [SchoolSetupScreen].
  /// Used by the hidden logo long-press on login screens.
  Future<void> resetToSchoolSetupEntry() async {
    await clearSchool();
    await clearSession();
    final p = await _instance;
    await p.remove(KEY_USER_PHONE);
    await p.remove('parent_login_phone');
  }
}
