import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../services/secure_auth_service.dart';
import 'app_lock_screen.dart';
import 'dashboard_screen.dart';
import 'login_screen.dart';
import 'secure_setup_screen.dart';

class AppGate extends StatefulWidget {
  const AppGate({super.key});

  @override
  State<AppGate> createState() => _AppGateState();
}

class _AppGateState extends State<AppGate> with WidgetsBindingObserver {
  bool _loading = true;
  bool _hasPin = false;
  bool _biometricEnabled = false;
  bool _biometricAvailable = false;
  bool _unlocked = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _refreshPinState();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Biometric availability can change while the app is in background
      // (FaceID/TouchID disabled, permissions revoked, etc.). Refresh first to
      // avoid showing a lock screen with no available unlock method.
      _refreshPinState().then((_) {
        if (!mounted) return;
        final hasUsableBiometrics = _biometricEnabled && _biometricAvailable;
        if ((_hasPin || hasUsableBiometrics) && _unlocked) {
          setState(() {
            _unlocked = false;
          });
        }
      });
    }
  }

  Future<void> _refreshPinState() async {
    final hasPin = await SecureAuthService().hasPin();
    final biometricEnabled = await SecureAuthService().isBiometricEnabled();
    final biometricAvailable = await SecureAuthService().isBiometricAvailable();
    if (!mounted) return;
    setState(() {
      _hasPin = hasPin;
      _biometricEnabled = biometricEnabled;
      _biometricAvailable = biometricAvailable;
      _loading = false;
      if (!hasPin) {
        _unlocked = false;
      }
    });
  }

  Future<void> _onSetupComplete() async {
    await _refreshPinState();
    if (!mounted) return;
    setState(() {
      _unlocked = true;
    });
  }

  void _onUnlocked() {
    setState(() {
      _unlocked = true;
    });
  }

  Future<void> _onNoAuthMethods() async {
    await _refreshPinState();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        if (!authProvider.isAuthenticated) {
          return const LoginScreen();
        }

        // Accès direct au dashboard sans code PIN ni biométrie
        return const DashboardScreen();
      },
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
}
