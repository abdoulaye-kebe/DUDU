import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';

class SecureAuthService {
  static final SecureAuthService _instance = SecureAuthService._internal();
  factory SecureAuthService() => _instance;
  SecureAuthService._internal();

  static const _storage = FlutterSecureStorage();
  final LocalAuthentication _localAuth = LocalAuthentication();

  static const String _kPinHash = 'pro_app_pin_hash';
  static const String _kBiometricEnabled = 'pro_biometric_enabled';

  Future<bool> hasPin() async {
    final v = await _storage.read(key: _kPinHash);
    return v != null && v.isNotEmpty;
  }

  Future<void> setPin(String pin) async {
    final hash = sha256.convert(utf8.encode(pin)).toString();
    await _storage.write(key: _kPinHash, value: hash);
  }

  Future<bool> verifyPin(String pin) async {
    final stored = await _storage.read(key: _kPinHash);
    if (stored == null || stored.isEmpty) return false;
    final hash = sha256.convert(utf8.encode(pin)).toString();
    return stored == hash;
  }

  Future<void> clearPin() async {
    await _storage.delete(key: _kPinHash);
  }

  Future<bool> isBiometricAvailable() async {
    if (kIsWeb) return false;
    try {
      final canCheck = await _localAuth.canCheckBiometrics;
      final supported = await _localAuth.isDeviceSupported();
      return canCheck && supported;
    } catch (_) {
      return false;
    }
  }

  Future<bool> isBiometricEnabled() async {
    final v = await _storage.read(key: _kBiometricEnabled);
    return v == 'true';
  }

  Future<void> setBiometricEnabled(bool enabled) async {
    await _storage.write(key: _kBiometricEnabled, value: enabled ? 'true' : 'false');
  }

  Future<bool> authenticateWithBiometrics({required String reason}) async {
    if (kIsWeb) return false;
    try {
      return await _localAuth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
        ),
      );
    } catch (_) {
      return false;
    }
  }
}
