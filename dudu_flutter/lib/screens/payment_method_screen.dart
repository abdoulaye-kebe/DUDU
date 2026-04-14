import 'package:flutter/material.dart';
import 'mobile_payment_screen.dart';

/// Écran de sélection du mode de paiement
class PaymentMethodScreen extends StatefulWidget {
  final String rideId;
  final int amount;
  final String pickupAddress;
  final String destinationAddress;

  const PaymentMethodScreen({
    Key? key,
    required this.rideId,
    required this.amount,
    required this.pickupAddress,
    required this.destinationAddress,
  }) : super(key: key);

  @override
  State<PaymentMethodScreen> createState() => _PaymentMethodScreenState();
}

class _PaymentMethodScreenState extends State<PaymentMethodScreen> {
  static const Color primaryGreen = Color(0xFF0d5d36);
  String? _selectedMethod;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Mode de paiement'),
        backgroundColor: primaryGreen,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Résumé de la course
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: primaryGreen.withOpacity(0.1),
              border: Border(
                bottom: BorderSide(color: Colors.grey[300]!),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Résumé de la course',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: primaryGreen,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(Icons.radio_button_checked, color: Colors.green, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        widget.pickupAddress,
                        style: const TextStyle(fontSize: 13),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.place, color: Colors.red, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        widget.destinationAddress,
                        style: const TextStyle(fontSize: 13),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: primaryGreen,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Montant à payer',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        '${widget.amount} FCFA',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Liste des modes de paiement
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const Text(
                  'Choisissez votre mode de paiement',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),

                // Wave
                _buildPaymentOptionWithImage(
                  method: 'wave',
                  title: 'Wave',
                  subtitle: 'Paiement sécurisé via Wave',
                  imagePath: 'assets/images/payments/wave_logo.png',
                  color: Colors.blue,
                  fees: '1.5%',
                  enabled: true,
                ),
                const SizedBox(height: 12),

                _buildPaymentOptionWithImage(
                  method: 'orange_money',
                  title: 'Orange Money',
                  subtitle: 'Indisponible pour le moment',
                  imagePath: 'assets/images/payments/orange_money_logo.png',
                  color: Colors.orange,
                  fees: '—',
                  enabled: false,
                ),
                const SizedBox(height: 12),

                _buildPaymentOptionWithImage(
                  method: 'free_money',
                  title: 'Free Money',
                  subtitle: 'Indisponible pour le moment',
                  imagePath: 'assets/images/payments/free_money_logo..png',
                  color: Colors.teal,
                  fees: '—',
                  enabled: false,
                ),
                const SizedBox(height: 12),

                // Espèces
                _buildPaymentOption(
                  method: 'cash',
                  title: 'Espèces',
                  subtitle: 'Payer en espèces au chauffeur',
                  icon: Icons.payments,
                  color: Colors.green,
                  fees: 'Gratuit',
                  enabled: true,
                ),
              ],
            ),
          ),

          // Bouton de confirmation
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
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _selectedMethod == null ? null : _proceedToPayment,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryGreen,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                  ),
                  child: const Text(
                    'CONTINUER',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentOptionWithImage({
    required String method,
    required String title,
    required String subtitle,
    required String imagePath,
    required Color color,
    required String fees,
    bool enabled = true,
  }) {
    final isSelected = enabled && _selectedMethod == method;

    return Opacity(
      opacity: enabled ? 1 : 0.55,
      child: GestureDetector(
        onTap: enabled ? () => setState(() => _selectedMethod = method) : null,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isSelected ? color.withOpacity(0.1) : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? color : Colors.grey[300]!,
              width: isSelected ? 2 : 1,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: color.withOpacity(0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : [],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.grey[200]!, width: 1),
                ),
                child: Image.asset(
                  imagePath,
                  width: 44,
                  height: 44,
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: enabled
                                  ? (isSelected ? color : Colors.black87)
                                  : Colors.grey.shade700,
                            ),
                          ),
                        ),
                        if (!enabled)
                          Icon(Icons.lock_outline, size: 20, color: Colors.grey.shade600),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      enabled ? 'Frais: $fees' : 'Frais: —',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: enabled ? color : Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
              if (enabled)
                isSelected
                    ? Icon(Icons.check_circle, color: color, size: 28)
                    : Icon(Icons.radio_button_unchecked, color: Colors.grey[400], size: 28)
              else
                Icon(Icons.block, color: Colors.grey[400], size: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPaymentOption({
    required String method,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required String fees,
    bool enabled = true,
  }) {
    final isSelected = enabled && _selectedMethod == method;

    return Opacity(
      opacity: enabled ? 1 : 0.55,
      child: GestureDetector(
        onTap: enabled ? () => setState(() => _selectedMethod = method) : null,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isSelected ? color.withOpacity(0.1) : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? color : Colors.grey[300]!,
              width: isSelected ? 2 : 1,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: color.withOpacity(0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : [],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isSelected ? color : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Frais: $fees',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: color,
                      ),
                    ),
                  ],
                ),
              ),
              if (isSelected)
                Icon(Icons.check_circle, color: color, size: 28)
              else
                Icon(Icons.radio_button_unchecked, color: Colors.grey[400], size: 28),
            ],
          ),
        ),
      ),
    );
  }

  void _proceedToPayment() {
    if (_selectedMethod == null) return;

    if (_selectedMethod == 'cash') {
      // Paiement en espèces - retourner directement
      Navigator.pop(context, {
        'method': 'cash',
        'status': 'pending',
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('💵 Paiement en espèces sélectionné'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      // Paiement mobile - naviguer vers l'écran de paiement
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => MobilePaymentScreen(
            rideId: widget.rideId,
            amount: widget.amount,
          ),
        ),
      ).then((result) {
        if (result != null && mounted) {
          Navigator.pop(context, result);
        }
      });
    }
  }
}
