import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';

import 'location_permission_screen.dart';
import 'login_screen.dart';
import 'pro_app_gate.dart';
import 'splash_screen.dart';

class StartupScreen extends StatefulWidget {
  const StartupScreen({super.key});

  @override
  State<StartupScreen> createState() => _StartupScreenState();
}

class _StartupScreenState extends State<StartupScreen> {
  bool _isBootstrapping = true;
  bool _showSplash = true;

  @override
  void initState() {
    super.initState();
    _showSplashThenBootstrap();
  }

  Future<void> _showSplashThenBootstrap() async {
    // Afficher le splash pendant 3 secondes
    await Future.delayed(const Duration(seconds: 3));
    
    if (!mounted) return;
    
    setState(() {
      _showSplash = false;
    });
    
    // Puis faire le bootstrap
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final wasFirstLaunchDone = prefs.getBool('pro_first_launch_done') ?? false;

      if (!mounted) return;

      if (!wasFirstLaunchDone) {
        await prefs.setBool('pro_first_launch_done', true);
        if (!mounted) return;

        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const LocationPermissionScreen()),
        );
        return;
      }

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const ProAppGate()),
      );
    } catch (_) {
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const ProAppGate()),
      );
    } finally {
      if (mounted) {
        setState(() => _isBootstrapping = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Afficher le splash screen pendant les 3 premières secondes
    if (_showSplash) {
      return const SplashScreen();
    }
    
    // Puis afficher l'écran de configuration
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(
                  'assets/images/logo_dudu_off.png',
                  width: 140,
                  height: 140,
                  fit: BoxFit.contain,
                ),
                const SizedBox(height: 24),
                const Text(
                  'Configuration en cours',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF0d5d36),
                  ),
                ),
                const SizedBox(height: 16),
                if (_isBootstrapping)
                  const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
