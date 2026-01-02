import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/api_service.dart';
import '../services/secure_auth_service.dart';
import 'app_lock_screen.dart';
import 'login_screen.dart';
import 'new_driver_dashboard.dart';
import 'secure_setup_screen.dart';

class ProAppGate extends StatefulWidget {
  const ProAppGate({super.key});

  @override
  State<ProAppGate> createState() => _ProAppGateState();
}

class _ProAppGateState extends State<ProAppGate> with WidgetsBindingObserver {
  bool _loading = true;
  bool _hasToken = false;

  bool _hasPin = false;
  bool _biometricEnabled = false;
  bool _biometricAvailable = false;
  bool _unlocked = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _bootstrap();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _refreshSecurityState().then((_) {
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

  Future<void> _bootstrap() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('pro_auth_token');

    if (token != null && token.isNotEmpty) {
      ApiService.setAuthToken(token);
    }

    if (!mounted) return;
    setState(() {
      _hasToken = token != null && token.isNotEmpty;
    });

    await _refreshSecurityState();
    if (!mounted) return;
    setState(() {
      _loading = false;
    });
  }

  Future<void> _refreshSecurityState() async {
    final hasPin = await SecureAuthService().hasPin();
    final biometricEnabled = await SecureAuthService().isBiometricEnabled();
    final biometricAvailable = await SecureAuthService().isBiometricAvailable();

    if (!mounted) return;
    setState(() {
      _hasPin = hasPin;
      _biometricEnabled = biometricEnabled;
      _biometricAvailable = biometricAvailable;
      if (!hasPin) {
        _unlocked = false;
      }
    });
  }

  Future<void> _onSetupComplete() async {
    await _refreshSecurityState();
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

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (!_hasToken) {
      return const LoginScreen();
    }

    if (!_hasPin) {
      return SecureSetupScreen(onComplete: _onSetupComplete);
    }

    if (!_unlocked) {
      return AppLockScreen(onUnlocked: _onUnlocked);
    }

    return const NewDriverDashboard();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
}
