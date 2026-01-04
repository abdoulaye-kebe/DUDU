import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/api_service.dart';
import 'login_screen.dart';
import 'new_driver_dashboard.dart';

class ProAppGate extends StatefulWidget {
  const ProAppGate({super.key});

  @override
  State<ProAppGate> createState() => _ProAppGateState();
}

class _ProAppGateState extends State<ProAppGate> with WidgetsBindingObserver {
  bool _loading = true;
  bool _hasToken = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _bootstrap();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // no-op
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
    if (!mounted) return;
    setState(() {
      _loading = false;
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
    return const NewDriverDashboard();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
}
