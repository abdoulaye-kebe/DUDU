import 'package:flutter/material.dart';
import '../services/secure_auth_service.dart';
import '../themes/app_theme.dart';

class SecureSetupScreen extends StatefulWidget {
  final VoidCallback onComplete;

  const SecureSetupScreen({super.key, required this.onComplete});

  @override
  State<SecureSetupScreen> createState() => _SecureSetupScreenState();
}

class _SecureSetupScreenState extends State<SecureSetupScreen> {
  final _pin1Controller = TextEditingController();
  final _pin2Controller = TextEditingController();

  bool _biometricAvailable = false;
  bool _enableBiometrics = true;
  bool _isSaving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadBiometricAvailability();
  }

  Future<void> _loadBiometricAvailability() async {
    final available = await SecureAuthService().isBiometricAvailable();
    if (!mounted) return;
    setState(() {
      _biometricAvailable = available;
      _enableBiometrics = available;
    });
  }

  bool _isPinValid(String pin) {
    if (pin.length != 4) return false;
    return RegExp(r'^\d{4}$').hasMatch(pin);
  }

  Future<void> _save() async {
    final pin1 = _pin1Controller.text.trim();
    final pin2 = _pin2Controller.text.trim();

    setState(() {
      _error = null;
    });

    if (!_isPinValid(pin1)) {
      setState(() {
        _error = 'Le code PIN doit contenir 4 chiffres.';
      });
      return;
    }

    if (pin1 != pin2) {
      setState(() {
        _error = 'Les deux codes PIN ne correspondent pas.';
      });
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      await SecureAuthService().setPin(pin1);
      await SecureAuthService().setBiometricEnabled(_biometricAvailable && _enableBiometrics);

      if (!mounted) return;
      widget.onComplete();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Erreur lors de la configuration: $e';
        _isSaving = false;
      });
    }
  }

  @override
  void dispose() {
    _pin1Controller.dispose();
    _pin2Controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Sécuriser votre compte',
          style: TextStyle(color: AppTheme.textColor),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Créez un code PIN (4 chiffres) et activez Face ID si disponible.',
                style: TextStyle(fontSize: 15, color: Colors.black54),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _pin1Controller,
                keyboardType: TextInputType.number,
                obscureText: true,
                maxLength: 4,
                decoration: InputDecoration(
                  labelText: 'Code PIN',
                  counterText: '',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _pin2Controller,
                keyboardType: TextInputType.number,
                obscureText: true,
                maxLength: 4,
                decoration: InputDecoration(
                  labelText: 'Confirmer le code PIN',
                  counterText: '',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 12),
              if (_biometricAvailable)
                SwitchListTile(
                  value: _enableBiometrics,
                  onChanged: _isSaving ? null : (v) => setState(() => _enableBiometrics = v),
                  title: const Text('Activer Face ID / Touch ID'),
                  activeColor: AppTheme.primaryColor,
                  contentPadding: EdgeInsets.zero,
                ),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    _error!,
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
              const Spacer(),
              SizedBox(
                height: 52,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                        )
                      : const Text(
                          'Continuer',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
