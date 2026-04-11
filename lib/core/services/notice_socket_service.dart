// =============================================================================
// FILE: lib/core/services/notice_socket_service.dart
// PURPOSE: Socket.IO client for real-time notice push notifications.
//          Connects when parent/student is logged in; listens for notice:new.
// =============================================================================

import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;
import '../config/api_config.dart';

/// Callback when a new notice is received (for parent or student)
typedef OnNoticeNew = void Function(Map<String, dynamic> payload);

/// Manages Socket.IO connection for real-time notice updates.
/// Used by Parent and Student portals.
class NoticeSocketService {
  NoticeSocketService._();

  static io.Socket? _socket;
  static OnNoticeNew? _onNoticeNew;

  /// Connect and listen for notice:new. Call when parent/student logs in.
  static void connect({
    required String token,
    required String schoolId,
    required String portalType,
    OnNoticeNew? onNoticeNew,
  }) {
    if (portalType != 'parent' && portalType != 'student') return;

    _onNoticeNew = onNoticeNew;

    if (_socket != null) {
      _socket!.disconnect();
      _socket!.dispose();
      _socket = null;
    }

    final uri = Uri.parse(ApiConfig.baseUrl);
    _socket = io.io(
      uri.origin,
      io.OptionBuilder()
          .setTransports(['websocket', 'polling'])
          .enableAutoConnect()
          .enableReconnection()
          .setAuth({'token': token})
          .build(),
    );

    _socket!.onConnect((_) {
      debugPrint('[NoticeSocket] Connected');
    });

    _socket!.on('notice:new', (data) {
      if (data is! Map) return;
      final payload = Map<String, dynamic>.from(data);
      final type = payload['type'] as String?;

      bool shouldNotify = false;

      if (type == 'school_notice') {
        // School-wide notice — filter by targetRole
        final targetRole = (payload['targetRole'] as String?)?.toLowerCase() ?? 'all';
        shouldNotify = targetRole == 'all' ||
            (portalType == 'parent' && targetRole == 'parent') ||
            (portalType == 'student' && targetRole == 'student');
      } else if (type == 'student_notice') {
        final targetStudent = payload['targetStudent'] as bool? ?? false;
        final targetParent = payload['targetParent'] as bool? ?? false;
        final studentId = payload['studentId'] as String?;
        if (portalType == 'student' && targetStudent && studentId != null) {
          shouldNotify = true;
        } else if (portalType == 'parent' && targetParent) {
          shouldNotify = true;
        }
      }

      if (shouldNotify && _onNoticeNew != null) {
        _onNoticeNew!(payload);
      }
    });

    _socket!.onDisconnect((_) {
      debugPrint('[NoticeSocket] Disconnected');
    });

    _socket!.onConnectError((err) {
      debugPrint('[NoticeSocket] Connect error: $err');
    });
  }

  /// Disconnect when user logs out.
  static void disconnect() {
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
    _onNoticeNew = null;
  }

  static bool get isConnected => _socket?.connected ?? false;
}
