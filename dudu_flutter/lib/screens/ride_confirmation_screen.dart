import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class RideConfirmationScreen extends StatefulWidget {
  final String pickupAddress;
  final String destinationAddress;
  final LatLng pickupLatLng;
  final LatLng destinationLatLng;
  final double distance;
  final String selectedRideType;
  final String selectedMode;
  final int initialPrice;

  const RideConfirmationScreen({
    Key? key,
    required this.pickupAddress,
    required this.destinationAddress,
    required this.pickupLatLng,
    required this.destinationLatLng,
    required this.distance,
    required this.selectedRideType,
    required this.selectedMode,
    required this.initialPrice,
  }) : super(key: key);

  @override
  State<RideConfirmationScreen> createState() => _RideConfirmationScreenState();
}

class _RideConfirmationScreenState extends State<RideConfirmationScreen> {
  int _customPrice = 0;
  /// `cash` | `wave` | `orange_money` — aligné sur l’API et [PaymentMethodScreen].
  String _paymentMethod = 'cash';
  late final TextEditingController _priceController;
  final FocusNode _priceFocus = FocusNode();

  static const Color primaryGreen = Color(0xFF0d5d36);
  static const Color accentBlack = Color(0xFF1A1A1A);

  static const String _waveLogo = 'assets/images/payments/wave_logo.png';
  static const String _omLogo = 'assets/images/payments/orange_money_logo.png';

  @override
  void initState() {
    super.initState();
    _customPrice = widget.initialPrice;
    _priceController = TextEditingController(
      text: widget.initialPrice > 0 ? '${widget.initialPrice}' : '',
    );
  }

  @override
  void dispose() {
    _priceController.dispose();
    _priceFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: primaryGreen.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.arrow_back_ios_new, size: 20, color: primaryGreen),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Confirmer la course',
          style: TextStyle(
            color: accentBlack,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildRouteInfo(),
            const SizedBox(height: 24),
            _buildPriceInput(),
            const SizedBox(height: 24),
            _buildPaymentMethods(),
            const SizedBox(height: 32),
            _buildConfirmButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildRouteInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: primaryGreen.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.location_on, color: primaryGreen, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Départ',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.pickupAddress,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: accentBlack,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Row(
              children: [
                const SizedBox(width: 20),
                Container(
                  width: 2,
                  height: 30,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [primaryGreen.withOpacity(0.3), Colors.grey[300]!],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                ),
                const SizedBox(width: 18),
                Text(
                  '${widget.distance.toStringAsFixed(1)} km',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.flag, color: Colors.red, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Destination',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.destinationAddress,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: accentBlack,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPriceInput() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: primaryGreen.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: primaryGreen.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: primaryGreen,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.payments, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              const Text(
                'Votre prix proposé',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: accentBlack,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: primaryGreen.withOpacity(0.3)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: TextField(
                    controller: _priceController,
                    focusNode: _priceFocus,
                    keyboardType: TextInputType.number,
                    textInputAction: TextInputAction.done,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: primaryGreen,
                    ),
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      isDense: true,
                      hintText: 'Montant',
                      suffixText: 'FCFA',
                      suffixStyle: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: primaryGreen,
                      ),
                    ),
                    onChanged: (v) {
                      setState(() {
                        _customPrice = int.tryParse(v.replaceAll(' ', '')) ?? 0;
                      });
                    },
                    onSubmitted: (_) => _applyPriceOk(),
                  ),
                ),
                TextButton(
                  onPressed: _applyPriceOk,
                  child: const Text(
                    'OK',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Le chauffeur peut accepter ou vous proposer un supplément (jusqu’à +2000 FCFA)',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentMethods() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: primaryGreen.withOpacity(0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.account_balance_wallet_outlined, color: primaryGreen, size: 20),
            ),
            const SizedBox(width: 10),
            const Text(
              'Moyen de paiement',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: accentBlack,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _paymentTileWithAsset(
          method: 'wave',
          title: 'Wave',
          subtitle: 'Paiement mobile Wave',
          assetPath: _waveLogo,
          accent: const Color(0xFF21C1E6),
          fees: 'Frais ~1,5 %',
        ),
        const SizedBox(height: 10),
        _paymentTileWithAsset(
          method: 'orange_money',
          title: 'Orange Money',
          subtitle: 'Paiement Orange Money',
          assetPath: _omLogo,
          accent: Colors.orange.shade700,
          fees: 'Selon opérateur',
        ),
        const SizedBox(height: 10),
        _paymentTileCash(),
      ],
    );
  }

  Widget _paymentLeadingImage(String assetPath, {IconData? fallback}) {
    return Container(
      width: 52,
      height: 52,
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Image.asset(
        assetPath,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => Icon(fallback ?? Icons.image_not_supported_outlined, color: Colors.grey),
      ),
    );
  }

  Widget _paymentTileWithAsset({
    required String method,
    required String title,
    required String subtitle,
    required String assetPath,
    required Color accent,
    required String fees,
  }) {
    final selected = _paymentMethod == method;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => setState(() => _paymentMethod = method),
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: selected ? accent.withOpacity(0.08) : Colors.grey.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? accent : Colors.grey.shade300,
              width: selected ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              _paymentLeadingImage(assetPath),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: selected ? accent : accentBlack,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      fees,
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: accent.withOpacity(0.95)),
                    ),
                  ],
                ),
              ),
              Icon(
                selected ? Icons.check_circle : Icons.radio_button_unchecked,
                color: selected ? accent : Colors.grey.shade400,
                size: 26,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _paymentTileCash() {
    const method = 'cash';
    const accent = Color(0xFF2E7D32);
    final selected = _paymentMethod == method;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => setState(() => _paymentMethod = method),
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: selected ? accent.withOpacity(0.08) : Colors.grey.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? accent : Colors.grey.shade300,
              width: selected ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: accent.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: const Icon(Icons.payments_rounded, color: accent, size: 30),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Espèces',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: selected ? accent : accentBlack,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Payer en espèces au chauffeur',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Sans frais',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: accent.withOpacity(0.95)),
                    ),
                  ],
                ),
              ),
              Icon(
                selected ? Icons.check_circle : Icons.radio_button_unchecked,
                color: selected ? accent : Colors.grey.shade400,
                size: 26,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _applyPriceOk() {
    final parsed = int.tryParse(_priceController.text.replaceAll(' ', '')) ?? 0;
    setState(() => _customPrice = parsed);
    FocusScope.of(context).unfocus();
    if (parsed <= 0 && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Indiquez un montant supérieur à 0 FCFA'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  Widget _buildConfirmButton() {
    final isValid = _customPrice > 0;
    return ElevatedButton(
      onPressed: isValid
          ? () {
              Navigator.pop(context, {
                'price': _customPrice,
                'paymentMethod': _paymentMethod,
              });
            }
          : null,
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryGreen,
        disabledBackgroundColor: Colors.grey[300],
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        elevation: isValid ? 4 : 0,
      ),
      child: Text(
        isValid ? 'Confirmer la course' : 'Indiquez un prix',
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: isValid ? Colors.white : Colors.grey[500],
        ),
      ),
    );
  }
}
