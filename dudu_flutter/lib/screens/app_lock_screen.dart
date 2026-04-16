import 'package:flutter/material.dart';
import '../services/secure_auth_service.dart';
import '../themes/app_theme.dart';

class AppLockScreen extends StatefulWidget {
  final VoidCallback onUnlocked;
  final VoidCallback? onNoAuthMethods;

  const AppLockScreen({super.key, required this.onUnlocked, this.onNoAuthMethods});

  @override
  State<AppLockScreen> createState() => _AppLockScreenState();
}

class _AppLockScreenState extends State<AppLockScreen> {
  final _pinController = TextEditingController();
  final FocusNode _pinFocusNode = FocusNode();

  bool _biometricEnabled = false;
  bool _biometricAvailable = false;
  bool _hasPin = false;
  bool _isUnlocking = false;
  int _biometricFailures = 0;
  bool _showPin = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _pinFocusNode.requestFocus();
      }
    });
  }

  Future<void> _load() async {
    final hasPin = await SecureAuthService().hasPin();
    final available = await SecureAuthService().isBiometricAvailable();
    final enabled = await SecureAuthService().isBiometricEnabled();
    if (!mounted) return;
    setState(() {
      _hasPin = hasPin;
      _biometricAvailable = available;
      _biometricEnabled = enabled;
    });

    // PIN is mandatory; if for any reason it's missing, force the setup screen.
    if (mounted && !_hasPin) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        widget.onNoAuthMethods?.call();
      });
      return;
    }

    final hasUsableBiometrics = enabled && available;
    if (mounted && hasUsableBiometrics && !_showPin && _biometricFailures < 3) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && !_isUnlocking) {
          _unlockWithBiometrics();
        }
      });
    } else {
      setState(() {
        _showPin = true;
      });
      _pinFocusNode.requestFocus();
    }
  }

  Future<void> _unlockWithBiometrics() async {
    if (!mounted) return;
    setState(() {
      _error = null;
      _isUnlocking = true;
    });

    bool ok = false;
    try {
      ok = await SecureAuthService()
          .authenticateWithBiometrics(reason: 'Déverrouiller DuDu')
          .timeout(const Duration(seconds: 15), onTimeout: () => false);
    } catch (_) {
      ok = false;
    } finally {
      if (mounted) {
        setState(() {
          _isUnlocking = false;
        });
      }
    }

    if (!mounted) return;
    if (ok) {
      widget.onUnlocked();
    } else {
      final failures = _biometricFailures + 1;
      setState(() {
        _biometricFailures = failures;
        if (failures >= 3) {
          _showPin = true;
          _error = 'Face ID échoué. Veuillez saisir votre PIN.';
        } else {
          _error = 'Authentification Face ID annulée ou échouée.';
        }
      });
      if (_showPin) {
        _pinFocusNode.requestFocus();
      }
    }
  }

  void _usePinNow() {
    setState(() {
      _showPin = true;
      _error = null;
    });
    _pinFocusNode.requestFocus();
  }

  Future<void> _unlockWithPin() async {
    final pin = _pinController.text.trim();
    setState(() {
      _error = null;
      _isUnlocking = true;
    });

    final ok = await SecureAuthService().verifyPin(pin);

    if (!mounted) return;
    setState(() {
      _isUnlocking = false;
    });

    if (ok) {
      widget.onUnlocked();
    } else {
      setState(() {
        _error = 'PIN incorrect.';
      });
    }
  }

  @override
  void dispose() {
    _pinController.dispose();
    _pinFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 40),
              const Text(
                'DuDu',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 34,
                  fontWeight: FontWeight.w900,
                  color: AppTheme.primaryColor,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Déverrouillez pour continuer',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.black54),
              ),
              const SizedBox(height: 40),
              if (_hasPin && _showPin) ...[
                TextField(
                  controller: _pinController,
                  focusNode: _pinFocusNode,
                  keyboardType: TextInputType.number,
                  obscureText: true,
                  maxLength: 4,
                  autofocus: true,
                  decoration: InputDecoration(
                    labelText: 'Code PIN',
                    counterText: '',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onSubmitted: (_) => _isUnlocking ? null : _unlockWithPin(),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _isUnlocking ? null : _unlockWithPin,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: _isUnlocking
                        ? const SizedBox(
                            height: 22,
                            width: 22,
                            child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                          )
                        : const Text(
                            'Déverrouiller',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                          ),
                  ),
                ),
              ],
              if (_biometricAvailable && _biometricEnabled && !_showPin) ...[
                const SizedBox(height: 14),
                SizedBox(
                  height: 52,
                  child: OutlinedButton(
                    onPressed: _isUnlocking ? null : _unlockWithBiometrics,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.primaryColor,
                      side: const BorderSide(color: AppTheme.primaryColor, width: 1.5),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: const Text(
                      'Déverrouiller avec Face ID',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ],
              if (_hasPin && (_biometricAvailable && _biometricEnabled) && !_showPin) ...[
                const SizedBox(height: 12),
                SizedBox(
                  height: 52,
                  child: TextButton(
                    onPressed: _isUnlocking ? null : _usePinNow,
                    child: const Text(
                      'Utiliser le PIN',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ],
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text(
                    _error!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}
