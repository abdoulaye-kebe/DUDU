import 'package:flutter/material.dart';
import 'dart:async';
import 'package:url_launcher/url_launcher.dart';
import '../services/mobile_payment_service.dart';

/// Écran de paiement mobile (Orange Money ou Wave)
class MobilePaymentScreen extends StatefulWidget {
  final String rideId;
  final int amount;
  final String method; // 'orange_money' ou 'wave'

  const MobilePaymentScreen({
    Key? key,
    required this.rideId,
    required this.amount,
    required this.method,
  }) : super(key: key);

  @override
  State<MobilePaymentScreen> createState() => _MobilePaymentScreenState();
}

class _MobilePaymentScreenState extends State<MobilePaymentScreen> {
  static const Color primaryGreen = Color(0xFF0d5d36);
  
  final TextEditingController _phoneController = TextEditingController();
  bool _isLoading = false;
  String? _paymentId;
  String? _paymentUrl;
  Timer? _statusCheckTimer;
  String _paymentStatus = 'pending';

  @override
  void dispose() {
    _phoneController.dispose();
    _statusCheckTimer?.cancel();
    super.dispose();
  }

  String get _methodName {
    return widget.method == 'orange_money' ? 'Orange Money' : 'Wave';
  }

  Color get _methodColor {
    return widget.method == 'orange_money' ? Colors.orange : Colors.blue;
  }

  IconData get _methodIcon {
    return widget.method == 'orange_money' ? Icons.phone_android : Icons.water_drop;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('Paiement $_methodName'),
        backgroundColor: _methodColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _paymentUrl != null
          ? _buildPaymentProcessing()
          : _buildPhoneInput(),
    );
  }

  Widget _buildPhoneInput() {
    final fees = MobilePaymentService.calculateFees(widget.amount, widget.method);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icône et titre
          Center(
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: _methodColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(_methodIcon, size: 60, color: _methodColor),
            ),
          ),
          const SizedBox(height: 24),

          Center(
            child: Text(
              'Paiement via $_methodName',
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 32),

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
                    const Text('Montant de la course'),
                    Text(
                      '${widget.amount} FCFA',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Frais ${fees['feePercentage']}%'),
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
                      '${widget.amount} FCFA',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: _methodColor,
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
            'Numéro de téléphone',
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
              prefixIcon: Icon(Icons.phone, color: _methodColor),
              prefixText: '+221 ',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: _methodColor, width: 2),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Entrez le numéro $_methodName à débiter',
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
                    'Paiement 100% sécurisé via $_methodName',
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
                backgroundColor: _methodColor,
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
                      'PAYER ${widget.amount} FCFA',
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
        if (_paymentStatus == 'processing')
          LinearProgressIndicator(
            backgroundColor: Colors.grey[300],
            valueColor: AlwaysStoppedAnimation<Color>(_methodColor),
          ),

        // Instructions
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          color: _methodColor.withOpacity(0.1),
          child: Column(
            children: [
              Icon(_methodIcon, size: 48, color: _methodColor),
              const SizedBox(height: 12),
              Text(
                _getStatusMessage(),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _getStatusDescription(),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[700],
                ),
              ),
            ],
          ),
        ),

        // Contenu selon le statut
        Expanded(
          child: _buildStatusContent(),
        ),

        // Boutons d'action
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: SafeArea(
            child: _buildActionButtons(),
          ),
        ),
      ],
    );
  }

  Widget _buildStatusContent() {
    switch (_paymentStatus) {
      case 'processing':
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 80,
                height: 80,
                child: CircularProgressIndicator(
                  strokeWidth: 6,
                  valueColor: AlwaysStoppedAnimation<Color>(_methodColor),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Vérification du paiement...',
                style: TextStyle(fontSize: 16),
              ),
            ],
          ),
        );

      case 'completed':
        return Center(
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
                '${widget.amount} FCFA',
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        );

      case 'failed':
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.error,
                  size: 80,
                  color: Colors.red,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Paiement échoué',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Le paiement n\'a pas pu être effectué',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[700],
                ),
              ),
            ],
          ),
        );

      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildActionButtons() {
    if (_paymentStatus == 'completed') {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: () {
            Navigator.pop(context, {
              'method': widget.method,
              'status': 'completed',
              'paymentId': _paymentId,
            });
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
      );
    } else if (_paymentStatus == 'failed') {
      return Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () => Navigator.pop(context),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('ANNULER'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton(
              onPressed: () {
                setState(() {
                  _paymentUrl = null;
                  _paymentId = null;
                  _paymentStatus = 'pending';
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: _methodColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('RÉESSAYER'),
            ),
          ),
        ],
      );
    } else {
      return TextButton(
        onPressed: _cancelPayment,
        child: const Text('Annuler le paiement'),
      );
    }
  }

  String _getStatusMessage() {
    switch (_paymentStatus) {
      case 'processing':
        return 'Paiement en cours...';
      case 'completed':
        return 'Paiement réussi !';
      case 'failed':
        return 'Paiement échoué';
      default:
        return 'Initialisation...';
    }
  }

  String _getStatusDescription() {
    switch (_paymentStatus) {
      case 'processing':
        return 'Veuillez compléter le paiement sur votre téléphone';
      case 'completed':
        return 'Votre paiement a été traité avec succès';
      case 'failed':
        return 'Une erreur est survenue lors du paiement';
      default:
        return '';
    }
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

    if (!MobilePaymentService.isValidPhoneNumber(phone)) {
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
      final normalizedPhone = MobilePaymentService.normalizePhoneNumber(phone);
      Map<String, dynamic> result;

      if (widget.method == 'orange_money') {
        result = await MobilePaymentService.initiateOrangeMoneyPayment(
          rideId: widget.rideId,
          amount: widget.amount,
          phone: normalizedPhone,
        );
        _paymentUrl = result['paymentUrl'];
      } else {
        result = await MobilePaymentService.initiateWavePayment(
          rideId: widget.rideId,
          amount: widget.amount,
          phone: normalizedPhone,
        );
        _paymentUrl = result['checkoutUrl'];
      }

      setState(() {
        _paymentId = result['paymentId']?.toString();
        _paymentStatus = 'processing';
        _isLoading = false;
      });

      // Démarrer la vérification du statut
      _startStatusCheck();

      if (_paymentUrl != null && _paymentUrl!.isNotEmpty) {
        final uri = Uri.parse(_paymentUrl!);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        } else if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Ouvrez ce lien pour payer : $_paymentUrl'),
              duration: const Duration(seconds: 8),
            ),
          );
        }
      }

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
        final status = await MobilePaymentService.checkPaymentStatus(_paymentId!);
        
        if (status['status'] == 'completed') {
          timer.cancel();
          setState(() => _paymentStatus = 'completed');
        } else if (status['status'] == 'failed') {
          timer.cancel();
          setState(() => _paymentStatus = 'failed');
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
      await MobilePaymentService.cancelPayment(_paymentId!);
      
      if (mounted) {
        Navigator.pop(context);
      }
    }
  }
}
