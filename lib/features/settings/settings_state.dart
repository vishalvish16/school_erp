import 'package:flutter/foundation.dart';

@immutable
class SettingsState {
  const SettingsState({
    this.isBiometricEnabled = false,
    this.isBiometricSupported = false,
    this.isAutoLockEnabled = false,
  });

  final bool isBiometricEnabled;
  final bool isBiometricSupported;
  final bool isAutoLockEnabled;

  SettingsState copyWith({
    bool? isBiometricEnabled,
    bool? isBiometricSupported,
    bool? isAutoLockEnabled,
  }) {
    return SettingsState(
      isBiometricEnabled: isBiometricEnabled ?? this.isBiometricEnabled,
      isBiometricSupported: isBiometricSupported ?? this.isBiometricSupported,
      isAutoLockEnabled: isAutoLockEnabled ?? this.isAutoLockEnabled,
    );
  }
}
