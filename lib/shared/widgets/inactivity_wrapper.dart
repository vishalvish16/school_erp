import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/auth/auto_lock_provider.dart';
import '../../features/auth/lock_screen.dart';
import '../../features/auth/auth_guard_provider.dart';

class InactivityWrapper extends ConsumerStatefulWidget {
  const InactivityWrapper({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<InactivityWrapper> createState() => _InactivityWrapperState();
}

class _InactivityWrapperState extends ConsumerState<InactivityWrapper> {
  bool _keyboardHandlerAdded = false;

  bool _handleKeyEvent(KeyEvent event) {
    ref.read(autoLockProvider.notifier).resetTimer();
    return false; // Don't handle - let event propagate
  }

  void _updateKeyboardHandler(bool isAuthenticated) {
    if (isAuthenticated && !_keyboardHandlerAdded) {
      HardwareKeyboard.instance.addHandler(_handleKeyEvent);
      _keyboardHandlerAdded = true;
    } else if (!isAuthenticated && _keyboardHandlerAdded) {
      HardwareKeyboard.instance.removeHandler(_handleKeyEvent);
      _keyboardHandlerAdded = false;
    }
  }

  @override
  void dispose() {
    if (_keyboardHandlerAdded) {
      HardwareKeyboard.instance.removeHandler(_handleKeyEvent);
      _keyboardHandlerAdded = false;
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lockState = ref.watch(autoLockProvider);
    final isAuthenticated = ref.watch(
      authGuardProvider.select((s) => s.isAuthenticated),
    );
    _updateKeyboardHandler(isAuthenticated);

    if (!isAuthenticated) return widget.child;

    return Listener(
      onPointerDown: (_) => ref.read(autoLockProvider.notifier).resetTimer(),
      onPointerMove: (_) => ref.read(autoLockProvider.notifier).resetTimer(),
      onPointerHover: (_) => ref.read(autoLockProvider.notifier).resetTimer(),
      onPointerUp: (_) => ref.read(autoLockProvider.notifier).resetTimer(),
      behavior: HitTestBehavior.translucent,
      child: Stack(
        children: [widget.child, if (lockState.isLocked) const LockScreen()],
      ),
    );
  }
}
