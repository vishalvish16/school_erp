// =============================================================================
// FILE: lib/utils/subdomain_resolver.dart
// PURPOSE: Resolve subdomain from URL and fetch school identity
// =============================================================================

import 'package:shared_preferences/shared_preferences.dart';
import '../models/school_identity.dart';
import '../core/network/dio_client.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'hostname_stub.dart'
    if (dart.library.html) 'hostname_web.dart' as hostname_impl;

final subdomainResolverProvider = Provider<SubdomainResolver>((ref) {
  final dio = ref.watch(dioProvider);
  return SubdomainResolver(dio);
});

class SubdomainResolver {
  SubdomainResolver(this._dio);

  final dynamic _dio;

  static const _cacheKey = 'cached_school_identity';
  static const _subdomainKey = 'last_subdomain';

  SchoolIdentity? _cached;
  String? _lastSubdomain;

  /// Extract subdomain from hostname
  /// e.g. "dpssurat.vidyron.in" -> "dpssurat"
  static String? extractSubdomain(String hostname) {
    if (hostname.isEmpty) return null;
    final parts = hostname.split('.');
    if (parts.length >= 2) {
      return parts.first.toLowerCase();
    }
    return null;
  }

  /// Get subdomain from current context (web: URL, mobile: stored preference)
  static Future<String?> getCurrentSubdomain() async {
    final host = await hostname_impl.getHostname();
    if (host != null && host.isNotEmpty) {
      return extractSubdomain(host);
    }
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_subdomainKey);
  }

  /// Resolve subdomain to SchoolIdentity
  Future<SchoolIdentity?> resolve(String subdomain) async {
    if (subdomain.isEmpty) return null;
    if (_cached != null && _lastSubdomain == subdomain) return _cached;

    try {
      final response = await _dio.post(
        '/api/platform/auth/resolve-subdomain',
        data: {'subdomain': subdomain},
      );
      if (response.statusCode == 200 && response.data['success'] == true) {
        final data = response.data['data'];
        if (data != null) {
          _cached = SchoolIdentity.fromJson(Map<String, dynamic>.from(data));
          _lastSubdomain = subdomain;
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString(_cacheKey, subdomain);
          await prefs.setString(_subdomainKey, subdomain);
          return _cached;
        }
      }
    } catch (_) {}
    return null;
  }

  /// Resolve from current context (subdomain + API)
  Future<SchoolIdentity?> resolveCurrent() async {
    final sub = await getCurrentSubdomain();
    if (sub != null) return resolve(sub);
    return null;
  }

  static Future<void> saveSubdomain(String subdomain) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_subdomainKey, subdomain);
  }

  void clearCache() {
    _cached = null;
    _lastSubdomain = null;
  }
}
