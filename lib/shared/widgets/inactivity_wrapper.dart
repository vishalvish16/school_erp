import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/auth/auto_lock_provider.dart';
import '../../features/auth/lock_screen.dart';
import '../../features/auth/auth_guard_provider.dart';

class InactivityWrapper extends ConsumerWidget {
  const InactivityWrapper({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lockState = ref.watch(autoLockProvider);
    final isAuthenticated = ref.watch(
      authGuardProvider.select((s) => s.isAuthenticated),
    );

    if (!isAuthenticated) return child;

    return Listener(
      onPointerDown: (_) => ref.read(autoLockProvider.notifier).resetTimer(),
      onPointerMove: (_) => ref.read(autoLockProvider.notifier).resetTimer(),
      onPointerHover: (_) => ref.read(autoLockProvider.notifier).resetTimer(),
      behavior: HitTestBehavior.translucent,
      child: Stack(
        children: [child, if (lockState.isLocked) const LockScreen()],
      ),
    );
  }
}
