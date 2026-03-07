import 'package:local_auth/local_auth.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final biometricServiceProvider = Provider((ref) => BiometricService());

/// Biometric type for UI (face, fingerprint, or both)
enum BiometricTypeUI {
  face,
  fingerprint,
  both,
}

class BiometricService {
  final LocalAuthentication _auth = LocalAuthentication();

  /// Check if the device has biometric hardware and enrolled biometrics
  Future<bool> isBiometricAvailable() async {
    try {
      final bool canCheck = await _auth.canCheckBiometrics;
      final bool isSupported = await _auth.isDeviceSupported();
      if (!canCheck && !isSupported) return false;

      // Ensure at least one biometric is enrolled (face or fingerprint)
      final List<BiometricType> available = await _auth.getAvailableBiometrics();
      return available.isNotEmpty;
    } on PlatformException catch (e) {
      print('Error checking biometric availability: $e');
      return false;
    }
  }

  /// Get list of available biometrics (face, fingerprint, etc.)
  Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _auth.getAvailableBiometrics();
    } on PlatformException catch (e) {
      print('Error getting available biometrics: $e');
      return <BiometricType>[];
    }
  }

  /// Get primary biometric type for UI (icon/label).
  /// Supports face (Face ID/face unlock) and fingerprint.
  Future<BiometricTypeUI?> getPrimaryBiometricType() async {
    try {
      final available = await getAvailableBiometrics();
      if (available.isEmpty) return null;

      // iOS returns face/fingerprint; Android may return strong/weak
      final hasFace = available.contains(BiometricType.face) ||
          available.contains(BiometricType.strong);
      final hasFingerprint = available.contains(BiometricType.fingerprint) ||
          available.contains(BiometricType.weak);

      if (hasFace && hasFingerprint) return BiometricTypeUI.both;
      if (hasFace) return BiometricTypeUI.face;
      if (hasFingerprint) return BiometricTypeUI.fingerprint;

      // Fallback when only strong/weak (Android)
      if (available.contains(BiometricType.strong)) return BiometricTypeUI.face;
      if (available.contains(BiometricType.weak)) return BiometricTypeUI.fingerprint;
      return BiometricTypeUI.both;
    } on PlatformException catch (_) {
      return null;
    }
  }

  /// Authenticate using face or fingerprint (system chooses based on availability)
  Future<bool> authenticate({required String reason}) async {
    try {
      return await _auth.authenticate(localizedReason: reason);
    } on PlatformException catch (e) {
      print('Error during authentication: $e');
      return false;
    }
  }
}
