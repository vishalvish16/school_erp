import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../settings/settings_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'auth_guard_provider.dart';

class AutoLockState {
  const AutoLockState({this.isLocked = false, this.lastInteraction = 0});

  final bool isLocked;
  final int lastInteraction; // timestamp

  AutoLockState copyWith({bool? isLocked, int? lastInteraction}) {
    return AutoLockState(
      isLocked: isLocked ?? this.isLocked,
      lastInteraction: lastInteraction ?? this.lastInteraction,
    );
  }
}

class AutoLockNotifier extends StateNotifier<AutoLockState> {
  AutoLockNotifier(this._ref) : super(const AutoLockState()) {
    _startTimer();
  }

  final Ref _ref;
  Timer? _timer;
  static const Duration _lockDuration = Duration(minutes: 30);

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _checkInactivity();
    });
  }

  void resetTimer() {
    if (state.isLocked) return;
    final now = DateTime.now().millisecondsSinceEpoch;
    // Only emit a new state at most once every 10 seconds to avoid
    // rebuilding the entire widget tree on every pointer hover event.
    if (now - state.lastInteraction < 10000) return;
    state = state.copyWith(lastInteraction: now);
  }

  void _checkInactivity() {
    final settings = _ref.read(settingsProvider);
    final auth = _ref.read(authGuardProvider);

    if (!auth.isAuthenticated || !settings.isAutoLockEnabled || state.isLocked) {
      return;
    }

    final now = DateTime.now().millisecondsSinceEpoch;
    final last = state.lastInteraction == 0 ? now : state.lastInteraction;

    if (now - last > _lockDuration.inMilliseconds) {
      lock();
    }
  }

  void lock() async {
    state = state.copyWith(isLocked: true);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_session_locked_persistently', true);
  }

  void unlock() async {
    state = state.copyWith(
      isLocked: false,
      lastInteraction: DateTime.now().millisecondsSinceEpoch,
    );
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('is_session_locked_persistently');
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

final autoLockProvider = StateNotifierProvider<AutoLockNotifier, AutoLockState>(
  (ref) {
    return AutoLockNotifier(ref);
  },
);
