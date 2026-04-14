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
  final String initialPaymentMethod;

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
    required this.initialPaymentMethod,
  }) : super(key: key);

  @override
  State<RideConfirmationScreen> createState() => _RideConfirmationScreenState();
}

class _RideConfirmationScreenState extends State<RideConfirmationScreen> {
  String _selectedPaymentMethod = 'wave';
  int _customPrice = 0;
  late final TextEditingController _priceController;
  final FocusNode _priceFocus = FocusNode();

  static const Map<String, String> _paymentLogos = {
    'orange_money': 'assets/images/payments/orange_money_logo.png',
    'wave': 'assets/images/payments/wave_logo.png',
    'free_money': 'assets/images/payments/free_money_logo.png',
  };

  static const Color primaryGreen = Color(0xFF0d5d36);
  static const Color lightGreen = Color(0xFF10b981);
  static const Color accentBlack = Color(0xFF1A1A1A);

  @override
  void initState() {
    super.initState();
    _customPrice = widget.initialPrice;
    _priceController = TextEditingController(
      text: widget.initialPrice > 0 ? '${widget.initialPrice}' : '',
    );
    var m = widget.initialPaymentMethod.isNotEmpty
        ? widget.initialPaymentMethod
        : 'wave';
    if (m == 'orange_money' || m == 'free_money') m = 'wave';
    _selectedPaymentMethod = m;
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
            'Le chauffeur peut accepter ou proposer un autre prix',
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
        const Text(
          'Mode de paiement',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: accentBlack,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _buildPaymentOption('cash', 'Espèces', enabled: true),
            _buildPaymentOption('wave', 'Wave', enabled: true),
            _buildPaymentOption('orange_money', 'Orange Money', enabled: false),
            _buildPaymentOption('free_money', 'Free Money', enabled: false),
          ],
        ),
      ],
    );
  }

  Widget _buildPaymentOption(String method, String label, {bool enabled = true}) {
    final isSelected = _selectedPaymentMethod == method;
    return Opacity(
      opacity: enabled ? 1 : 0.55,
      child: InkWell(
        onTap: enabled
            ? () {
                setState(() {
                  _selectedPaymentMethod = method;
                });
              }
            : null,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: isSelected && enabled ? primaryGreen.withOpacity(0.1) : Colors.grey[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected && enabled ? primaryGreen : Colors.grey[300]!,
              width: isSelected && enabled ? 2 : 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!enabled)
                Icon(Icons.lock_outline, size: 18, color: Colors.grey.shade600)
              else if (method == 'cash')
                Icon(
                  Icons.payments,
                  color: isSelected ? primaryGreen : Colors.grey[600],
                  size: 20,
                )
              else if (_paymentLogos[method] != null)
                Image.asset(
                  _paymentLogos[method]!,
                  width: 22,
                  height: 22,
                  errorBuilder: (_, __, ___) => Icon(
                    Icons.account_balance_wallet,
                    size: 18,
                    color: isSelected ? primaryGreen : Colors.grey[600],
                  ),
                )
              else
                Icon(
                  Icons.account_balance_wallet,
                  size: 18,
                  color: isSelected ? primaryGreen : Colors.grey[600],
                ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: isSelected && enabled ? FontWeight.w600 : FontWeight.w500,
                  color: !enabled
                      ? Colors.grey.shade600
                      : (isSelected ? primaryGreen : accentBlack),
                ),
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
    final isValid = _customPrice > 0 && _selectedPaymentMethod.isNotEmpty;
    return ElevatedButton(
      onPressed: isValid
          ? () {
              Navigator.pop(context, {
                'price': _customPrice,
                'paymentMethod': _selectedPaymentMethod,
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
        isValid ? 'OK — Confirmer la course' : 'Indiquez le prix et le paiement',
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
