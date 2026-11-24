import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class BiometricService {
  static final LocalAuthentication _auth = LocalAuthentication();
  static const FlutterSecureStorage _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  static const String _keyBiometricEnabled = 'app_biometric_enabled';
  static const String _keyUserPin = 'app_user_pin';

  /// Check if hardware supports biometrics
  static Future<bool> canAuthenticateWithBiometrics() async {
    try {
      final bool canCheck = await _auth.canCheckBiometrics;
      final bool isDeviceSupported = await _auth.isDeviceSupported();
      return canCheck || isDeviceSupported;
    } catch (_) {
      return false;
    }
  }

  /// Trigger biometric authentication prompt
  static Future<bool> authenticate({String reason = 'Unlock your F&O Trading Ledger'}) async {
    try {
      final isSupported = await canAuthenticateWithBiometrics();
      if (!isSupported) return true; // Gracefully bypass if device has no hardware lock

      return await _auth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: false, // Allows device PIN fallback
          useErrorDialogs: true,
        ),
      );
    } on PlatformException catch (_) {
      return false;
    } catch (_) {
      return false;
    }
  }

  /// Secure token storage in Android Keystore
  static Future<void> saveSecureToken(String key, String value) async {
    await _storage.write(key: key, value: value);
  }

  static Future<String?> getSecureToken(String key) async {
    return await _storage.read(key: key);
  }

  static Future<void> deleteSecureToken(String key) async {
    await _storage.delete(key: key);
  }
}
