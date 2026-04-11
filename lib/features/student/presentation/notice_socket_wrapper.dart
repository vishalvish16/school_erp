// =============================================================================
// FILE: lib/features/student/presentation/notice_socket_wrapper.dart
// PURPOSE: Wraps Student shell content to connect Socket.IO for real-time notices.
// =============================================================================

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/config/api_config.dart';
import '../../../core/services/fcm_service.dart';
import '../../../core/services/notice_socket_service.dart';
import '../../../core/network/dio_client.dart';
import '../../../features/auth/auth_guard_provider.dart';
import '../data/student_providers.dart';

/// Wraps child to connect notice socket when student is logged in.
class StudentNoticeSocketWrapper extends ConsumerStatefulWidget {
  const StudentNoticeSocketWrapper({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<StudentNoticeSocketWrapper> createState() =>
      _StudentNoticeSocketWrapperState();
}

class _StudentNoticeSocketWrapperState
    extends ConsumerState<StudentNoticeSocketWrapper> {
  FcmService? _fcmService;
  bool _showNotificationBanner = false;
  bool _isRequestingPermission = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _connect());
  }

  void _navigateToNotices(String? route) {
    if (route != null && mounted) {
      try {
        context.go(route);
      } catch (_) {}
    }
  }

  Future<void> _connect() async {
    final auth = ref.read(authGuardProvider);
    final token = auth.accessToken;
    final schoolId = ref.read(authGuardProvider.notifier).getSchoolId();

    if (token == null || schoolId == null || schoolId.isEmpty || auth.portalType != 'student') return;

    NoticeSocketService.connect(
      token: token,
      schoolId: schoolId,
      portalType: 'student',
      onNoticeNew: (payload) {
        if (!mounted) return;
        ref.invalidate(studentNoticesProvider);
        ref.invalidate(studentDashboardProvider);
        final notice = payload['notice'] as Map?;
        final subject = notice?['title'] as String? ?? notice?['subject'] as String? ?? 'New notice';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(subject),
            action: SnackBarAction(
              label: 'View',
              onPressed: () => context.go('/student/notices'),
            ),
          ),
        );
      },
    );

    // FCM — check permission on every app open; prompt if not granted
    try {
      final dio = ref.read(dioProvider);
      _fcmService = await FcmService.initialize(
        dio: dio,
        onTap: _navigateToNotices,
      );
      if (kIsWeb) {
        await _fcmService?.registerToken(ApiConfig.studentFcmRegister);
      } else {
        final status = await FcmService.getNotificationStatus();
        if (status == AuthorizationStatus.authorized ||
            status == AuthorizationStatus.provisional) {
          await _fcmService?.registerToken(ApiConfig.studentFcmRegister);
        } else if (mounted) {
          setState(() => _showNotificationBanner = true);
        }
      }
    } catch (_) {}
  }

  Future<void> _onEnableNotifications() async {
    if (_fcmService == null || _isRequestingPermission) return;
    setState(() => _isRequestingPermission = true);
    try {
      final granted = await _fcmService!.requestPermissionAndRegister(
        ApiConfig.studentFcmRegister,
      );
      if (mounted && granted) {
        setState(() {
          _showNotificationBanner = false;
          _isRequestingPermission = false;
        });
      } else if (mounted) {
        setState(() => _isRequestingPermission = false);
      }
    } catch (_) {
      if (mounted) setState(() => _isRequestingPermission = false);
    }
  }

  @override
  void dispose() {
    NoticeSocketService.disconnect();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fcmService?.handleInitialMessage();
    });
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_showNotificationBanner) _buildNotificationBanner(context),
        Expanded(child: widget.child),
      ],
    );
  }

  Widget _buildNotificationBanner(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.primaryContainer,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Icon(Icons.notifications_active_outlined, color: scheme.onPrimaryContainer),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Enable notifications to receive important updates from school',
                  style: TextStyle(
                    fontSize: 13,
                    color: scheme.onPrimaryContainer,
                  ),
                ),
              ),
              TextButton(
                onPressed: _isRequestingPermission ? null : _onEnableNotifications,
                child: _isRequestingPermission
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Enable'),
              ),
              TextButton(
                onPressed: () => setState(() => _showNotificationBanner = false),
                child: const Text('Not now'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
