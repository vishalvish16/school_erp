// =============================================================================
// FILE: lib/core/services/fcm_service.dart
// PURPOSE: Firebase Cloud Messaging — foreground, background, terminated.
//          Registers token with backend, handles notification tap → notices.
// =============================================================================

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import '../../firebase_options.dart';

/// Background message handler — must be top-level function.
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.android);
  debugPrint('[FCM] Background: ${message.notification?.title}');
}

/// Callback when user taps notification (navigate to notices).
/// Receives route to navigate to. Caller provides navigation logic.
typedef OnNotificationTap = void Function(String? route);

class FcmService {
  FcmService(this._dio);

  final dynamic _dio;
  OnNotificationTap? onNotificationTap;
  String? _initialMessageRoute;

  /// Check current notification permission without requesting.
  static Future<AuthorizationStatus> getNotificationStatus() async {
    try {
      final settings = await FirebaseMessaging.instance.getNotificationSettings();
      return settings.authorizationStatus;
    } catch (_) {
      return AuthorizationStatus.denied;
    }
  }

  /// Request permission and register token if granted. Call when user taps "Enable".
  /// Returns true if permission granted and token registered.
  Future<bool> requestPermissionAndRegister(String endpoint) async {
    _registerEndpoint = endpoint;
    final settings = await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    if (settings.authorizationStatus == AuthorizationStatus.denied) {
      return false;
    }
    await _registerToken();
    return true;
  }

  /// Initialize FCM: set up listeners. Does NOT request permission.
  /// Caller should check getNotificationStatus() and either registerToken() or show prompt.
  static Future<FcmService> initialize({
    required dynamic dio,
    OnNotificationTap? onTap,
  }) async {
    final service = FcmService(dio);
    service.onNotificationTap = onTap;

    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Handle notification that opened app from terminated state
    final initialMessage = await FirebaseMessaging.instance.getInitialMessage();
    if (initialMessage != null) {
      service._initialMessageRoute = _routeFromMessage(initialMessage);
      debugPrint('[FCM] Initial (terminated): ${service._initialMessageRoute}');
    }

    // Foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('[FCM] Foreground: ${message.notification?.title}');
      if (message.notification != null) {
        // Show in-app notification when in foreground
        // The NoticeSocketWrapper already shows SnackBar for Socket.IO
        // We could show a local notification or SnackBar here
      }
    });

    // Background/terminated — user tapped notification
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      final route = _routeFromMessage(message);
      debugPrint('[FCM] Opened from background: $route');
      service.onNotificationTap?.call(route);
    });

    // Token refresh — will register when endpoint is set
    FirebaseMessaging.instance.onTokenRefresh.listen((token) {
      service._registerTokenWithBackend(token);
    });

    return service;
  }

  /// Call after app is built to handle initial message (terminated → tap).
  void handleInitialMessage() {
    final route = _initialMessageRoute;
    if (route != null) {
      _initialMessageRoute = null;
      onNotificationTap?.call(route);
    }
  }

  Future<void> _registerToken() async {
    String? token;
    if (kIsWeb) {
      token = await FirebaseMessaging.instance.getToken(
        vapidKey: null, // Web uses project config
      );
    } else {
      token = await FirebaseMessaging.instance.getToken();
    }
    if (token != null) {
      await _registerTokenWithBackend(token);
    }
  }

  Future<void> _registerTokenWithBackend(String token) async {
    // Endpoint must be set via setRegisterEndpoint before calling
    if (_registerEndpoint == null) return;
    try {
      await _dio.post(
        _registerEndpoint!,
        data: {'fcm_token': token},
      );
      debugPrint('[FCM] Token registered');
    } catch (e) {
      debugPrint('[FCM] Token register failed: $e');
    }
  }

  String? _registerEndpoint;

  /// Set endpoint and register token. Call after parent/student login.
  Future<void> registerToken(String endpoint) async {
    _registerEndpoint = endpoint;
    await _registerToken();
  }
}

String? _routeFromMessage(RemoteMessage message) {
  final data = message.data;
  if (data.isNotEmpty) {
    final type = data['type']?.toString();
    if (type == 'notice' || type == 'student_notice') {
      final portal = data['portal']?.toString();
      if (portal == 'parent') return '/parent/notices';
      if (portal == 'student') return '/student/notices';
    }
  }
  return '/parent/notices'; // default
}

