import 'package:flutter/material.dart';
import 'dart:async';
import 'package:url_launcher/url_launcher.dart';
import '../services/api_service.dart';

/// Écran de paiement d'abonnement pour les chauffeurs
class SubscriptionPaymentScreen extends StatefulWidget {
  final Map<String, dynamic> subscription;

  const SubscriptionPaymentScreen({
    Key? key,
    required this.subscription,
  }) : super(key: key);

  @override
  State<SubscriptionPaymentScreen> createState() => _SubscriptionPaymentScreenState();
}

class _SubscriptionPaymentScreenState extends State<SubscriptionPaymentScreen> {
  static const Color primaryGreen = Color(0xFF0d5d36);
  static const String _waveLogo = 'assets/images/payments/wave_logo.png';
  
  final TextEditingController _phoneController = TextEditingController();
  bool _isLoading = false;
  String? _paymentId;
  String _paymentStatus = 'pending';
  Timer? _statusCheckTimer;

  @override
  void dispose() {
    _phoneController.dispose();
    _statusCheckTimer?.cancel();
    super.dispose();
  }

  String get _planName => widget.subscription['name'] ?? 'Abonnement';
  int get _planPrice => widget.subscription['price'] ?? 0;
  String get _planDuration => widget.subscription['duration'] ?? '30 jours';
  List<dynamic> get _planFeatures => widget.subscription['features'] ?? [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Paiement Wave'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _paymentStatus == 'processing'
          ? _buildPaymentProcessing()
          : _paymentStatus == 'completed'
              ? _buildPaymentSuccess()
              : _buildPhoneInput(),
    );
  }

  Widget _buildPhoneInput() {
    final fees = _calculateFees(_planPrice);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Logo Wave
          Center(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Image.asset(
                _waveLogo,
                width: 72,
                height: 72,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => const Icon(
                  Icons.water_drop,
                  size: 60,
                  color: Colors.blue,
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),

          Center(
            child: Text(
              'Paiement Abonnement',
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 32),

          // Détails de l'abonnement
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: primaryGreen.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: primaryGreen),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.card_membership, color: primaryGreen),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _planName,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'Durée: $_planDuration',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[700],
                  ),
                ),
                const SizedBox(height: 8),
                const Divider(),
                const SizedBox(height: 8),
                const Text(
                  'Avantages inclus:',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                ..._planFeatures.map((feature) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    children: [
                      Icon(Icons.check_circle, color: primaryGreen, size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          feature.toString(),
                          style: const TextStyle(fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                )),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Détails du montant
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Prix de l\'abonnement'),
                    Text(
                      '$_planPrice FCFA',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Frais Wave (${fees['feePercentage']}%)'),
                    Text(
                      '${fees['fees']} FCFA',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[700],
                      ),
                    ),
                  ],
                ),
                const Divider(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Total à payer',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '$_planPrice FCFA',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // Champ numéro de téléphone
          const Text(
            'Numéro Wave',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            decoration: InputDecoration(
              hintText: '77 123 45 67',
              prefixIcon: const Icon(Icons.phone, color: Colors.blue),
              prefixText: '+221 ',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.blue, width: 2),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Entrez le numéro Wave à débiter',
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 32),

          // Informations de sécurité
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue[200]!),
            ),
            child: Row(
              children: [
                Icon(Icons.security, color: Colors.blue[700]),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Paiement 100% sécurisé via Wave',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.blue[900],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // Bouton de paiement
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _initiatePayment,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 2,
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : Text(
                      'PAYER $_planPrice FCFA',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentProcessing() {
    return Column(
      children: [
        // Barre de progression
        LinearProgressIndicator(
          backgroundColor: Colors.grey[300],
          valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
        ),

        // Instructions
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          color: Colors.blue.withOpacity(0.1),
          child: Column(
            children: [
              Image.asset(
                _waveLogo,
                width: 48,
                height: 48,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => const Icon(
                  Icons.water_drop,
                  size: 48,
                  color: Colors.blue,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Paiement en cours...',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Veuillez compléter le paiement sur votre téléphone',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[700],
                ),
              ),
            ],
          ),
        ),

        // Contenu
        Expanded(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 80,
                  height: 80,
                  child: CircularProgressIndicator(
                    strokeWidth: 6,
                    valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Vérification du paiement...',
                  style: TextStyle(fontSize: 16),
                ),
              ],
            ),
          ),
        ),

        // Bouton annuler
        Container(
          padding: const EdgeInsets.all(16),
          child: TextButton(
            onPressed: _cancelPayment,
            child: const Text('Annuler le paiement'),
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentSuccess() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle,
                size: 80,
                color: Colors.green,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Paiement réussi !',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '$_planPrice FCFA',
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: primaryGreen.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  const Icon(Icons.card_membership, color: primaryGreen, size: 40),
                  const SizedBox(height: 12),
                  Text(
                    'Abonnement $_planName activé',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Valable pendant $_planDuration',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[700],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context, true);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'TERMINER',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Map<String, dynamic> _calculateFees(int amount) {
    const feePercentage = 0.015; // 1.5% pour Wave
    final fees = (amount * feePercentage).round();
    final netAmount = amount - fees;

    return {
      'amount': amount,
      'fees': fees,
      'netAmount': netAmount,
      'feePercentage': (feePercentage * 100).toStringAsFixed(1),
    };
  }

  String _normalizePhoneNumber(String phone) {
    String normalized = phone.trim().replaceAll(RegExp(r'\s+'), '');
    
    if (normalized.startsWith('+')) {
      normalized = normalized.substring(1);
    }
    
    if (normalized.length == 9) {
      normalized = '221$normalized';
    }
    
    if (!normalized.startsWith('+')) {
      normalized = '+$normalized';
    }
    
    return normalized;
  }

  bool _isValidPhoneNumber(String phone) {
    final normalized = _normalizePhoneNumber(phone);
    return RegExp(r'^\+221[0-9]{9}$').hasMatch(normalized);
  }

  Future<void> _initiatePayment() async {
    final phone = _phoneController.text.trim();

    if (phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez entrer votre numéro de téléphone'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (!_isValidPhoneNumber(phone)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Numéro de téléphone invalide'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final normalizedPhone = _normalizePhoneNumber(phone);
      
      final result = await ApiService.initiateSubscriptionPayment(
        subscriptionId: widget.subscription['_id'] ?? widget.subscription['id'],
        amount: _planPrice,
        phone: normalizedPhone,
      );

      final checkoutUrl = result['checkoutUrl']?.toString();
      if (checkoutUrl != null && checkoutUrl.isNotEmpty) {
        final uri = Uri.tryParse(checkoutUrl);
        final host = uri?.host.toLowerCase() ?? '';
        if (uri == null ||
            !uri.hasScheme ||
            (host != 'pay.wave.com' && host != 'checkout.wave.com')) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Lien Wave invalide (attendu pay.wave.com). Réessayez ou contactez le support.\n$checkoutUrl',
                ),
                duration: const Duration(seconds: 10),
                backgroundColor: Colors.orange,
              ),
            );
          }
        } else {
          final launched = await launchUrl(
            uri,
            mode: LaunchMode.externalApplication,
          );
          if (!launched && mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Impossible d\'ouvrir Wave. Copiez le lien depuis l\'admin ou réessayez.',
                ),
                backgroundColor: Colors.orange,
              ),
            );
          }
        }
      }

      setState(() {
        _paymentId = result['paymentId'];
        _paymentStatus = 'processing';
        _isLoading = false;
      });

      // Démarrer la vérification du statut
      _startStatusCheck();

    } catch (e) {
      setState(() => _isLoading = false);
      
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _startStatusCheck() {
    _statusCheckTimer = Timer.periodic(const Duration(seconds: 3), (timer) async {
      if (_paymentId == null) {
        timer.cancel();
        return;
      }

      try {
        final status = await ApiService.checkPaymentStatus(_paymentId!);
        
        if (status['status'] == 'completed') {
          timer.cancel();
          setState(() => _paymentStatus = 'completed');
        } else if (status['status'] == 'failed') {
          timer.cancel();
          setState(() => _paymentStatus = 'failed');
          
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Le paiement a échoué'),
                backgroundColor: Colors.red,
              ),
            );
            Navigator.pop(context);
          }
        }
      } catch (e) {
        print('Erreur vérification statut: $e');
      }
    });
  }

  Future<void> _cancelPayment() async {
    if (_paymentId == null) {
      Navigator.pop(context);
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Annuler le paiement ?'),
        content: const Text('Êtes-vous sûr de vouloir annuler ce paiement ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('NON'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('OUI, ANNULER'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      _statusCheckTimer?.cancel();
      
      if (mounted) {
        Navigator.pop(context);
      }
    }
  }
}
