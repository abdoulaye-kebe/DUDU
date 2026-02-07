import 'package:flutter/material.dart';
import 'dart:async';
import '../services/api_service.dart';

class SubscriptionPaymentOMScreen extends StatefulWidget {
  final String subscriptionId;
  final int amount;
  final String planName;

  const SubscriptionPaymentOMScreen({
    Key? key,
    required this.subscriptionId,
    required this.amount,
    required this.planName,
  }) : super(key: key);

  @override
  State<SubscriptionPaymentOMScreen> createState() => _SubscriptionPaymentOMScreenState();
}

class _SubscriptionPaymentOMScreenState extends State<SubscriptionPaymentOMScreen> {
  static const Color primaryGreen = Color(0xFF0d5d36);
  static const Color lightGreen = Color(0xFF10b981);
  
  final TextEditingController _phoneController = TextEditingController();
  final ApiService _apiService = ApiService();
  
  bool _isLoading = false;
  bool _paymentInitiated = false;
  String? _paymentId;
  String? _qrCode;
  Map<String, dynamic>? _deeplinks;
  String _paymentStatus = 'pending';
  Timer? _statusCheckTimer;
  int _checkCount = 0;

  @override
  void dispose() {
    _statusCheckTimer?.cancel();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _initiatePayment() async {
    if (_phoneController.text.isEmpty) {
      _showError('Veuillez entrer votre numéro de téléphone');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await _apiService.initiateSubscriptionPaymentOM(
        subscriptionId: widget.subscriptionId,
        amount: widget.amount,
        phone: _phoneController.text,
      );

      if (response['success']) {
        setState(() {
          _paymentInitiated = true;
          _paymentId = response['data']['paymentId'];
          _qrCode = response['data']['qrCode'];
          _deeplinks = response['data']['deeplinks'];
        });

        _startStatusCheck();
      } else {
        _showError(response['message'] ?? 'Erreur lors de l\'initiation du paiement');
      }
    } catch (e) {
      _showError('Erreur: ${e.toString()}');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _startStatusCheck() {
    _statusCheckTimer = Timer.periodic(const Duration(seconds: 3), (timer) async {
      _checkCount++;
      
      if (_checkCount > 60) {
        timer.cancel();
        setState(() {
          _paymentStatus = 'timeout';
        });
        return;
      }

      try {
        final status = await _apiService.checkPaymentStatus(_paymentId!);
        
        if (status['success']) {
          final newStatus = status['data']['status'];
          
          setState(() {
            _paymentStatus = newStatus;
          });

          if (newStatus == 'completed') {
            timer.cancel();
            _showSuccess();
          } else if (newStatus == 'failed' || newStatus == 'cancelled') {
            timer.cancel();
          }
        }
      } catch (e) {
        print('Erreur vérification statut: $e');
      }
    });
  }

  void _showSuccess() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green, size: 32),
            SizedBox(width: 12),
            Text('Paiement réussi !'),
          ],
        ),
        content: Text('Votre abonnement ${widget.planName} a été activé avec succès.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop();
              Navigator.of(context).pop();
            },
            child: const Text('OK', style: TextStyle(color: primaryGreen)),
          ),
        ],
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: primaryGreen,
        elevation: 0,
        title: const Text(
          'Paiement Orange Money',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _paymentInitiated ? _buildPaymentStatus() : _buildPaymentForm(),
    );
  }

  Widget _buildPaymentForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: primaryGreen.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: primaryGreen.withOpacity(0.3)),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Abonnement',
                      style: TextStyle(fontSize: 16, color: Colors.black87),
                    ),
                    Text(
                      widget.planName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: primaryGreen,
                      ),
                    ),
                  ],
                ),
                const Divider(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Montant',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      '${widget.amount} FCFA',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: primaryGreen,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          const Text(
            'Numéro Orange Money',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            decoration: InputDecoration(
              hintText: '77 123 45 67',
              prefixIcon: const Icon(Icons.phone, color: primaryGreen),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: primaryGreen, width: 2),
              ),
            ),
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _initiatePayment,
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryGreen,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 2,
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 24,
                      width: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text(
                      'Payer maintenant',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentStatus() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          if (_qrCode != null) ...[
            const Text(
              'Scannez le QR Code',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Image.memory(
                Uri.parse(_qrCode!).data!.contentAsBytes(),
                width: 250,
                height: 250,
              ),
            ),
            const SizedBox(height: 32),
          ],
          _buildStatusIndicator(),
          const SizedBox(height: 24),
          const Text(
            'Ouvrez votre application Orange Money ou MAX IT pour compléter le paiement',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: Colors.black54),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusIndicator() {
    IconData icon;
    Color color;
    String message;

    switch (_paymentStatus) {
      case 'completed':
        icon = Icons.check_circle;
        color = Colors.green;
        message = 'Paiement réussi !';
        break;
      case 'failed':
      case 'cancelled':
        icon = Icons.error;
        color = Colors.red;
        message = 'Paiement échoué';
        break;
      case 'timeout':
        icon = Icons.access_time;
        color = Colors.orange;
        message = 'Délai expiré';
        break;
      default:
        icon = Icons.pending;
        color = Colors.blue;
        message = 'En attente de paiement...';
    }

    return Column(
      children: [
        Icon(icon, size: 64, color: color),
        const SizedBox(height: 16),
        Text(
          message,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        if (_paymentStatus == 'pending' || _paymentStatus == 'processing') ...[
          const SizedBox(height: 16),
          const CircularProgressIndicator(),
        ],
      ],
    );
  }
}
