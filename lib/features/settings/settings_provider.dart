import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/services/biometric_service.dart';
import 'settings_state.dart';

final settingsProvider = StateNotifierProvider<SettingsNotifier, SettingsState>(
  (ref) {
    return SettingsNotifier(ref);
  },
);

class SettingsNotifier extends StateNotifier<SettingsState> {
  SettingsNotifier(this._ref) : super(const SettingsState()) {
    _init();
  }

  final Ref _ref;
  static const String _biometricKey = 'biometric_login_enabled';
  static const String _autoLockKey = 'auto_lock_enabled';

  Future<void> _init() async {
    final prefs = await SharedPreferences.getInstance();
    final isEnabled = prefs.getBool(_biometricKey) ?? false;
    final isAutoLockEnabled =
        prefs.getBool(_autoLockKey) ?? true; // Default to true for security

    bool isSupported = false;
    if (!kIsWeb) {
      final biometricService = _ref.read(biometricServiceProvider);
      isSupported = await biometricService.isBiometricAvailable();
    }

    state = state.copyWith(
      isBiometricEnabled: isEnabled,
      isBiometricSupported: isSupported,
      isAutoLockEnabled: isAutoLockEnabled,
    );
  }

  Future<void> toggleBiometric(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_biometricKey, value);
    state = state.copyWith(isBiometricEnabled: value);
  }

  Future<void> toggleAutoLock(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_autoLockKey, value);
    state = state.copyWith(isAutoLockEnabled: value);
  }
}
