import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

class DeliveryRequestScreen extends StatefulWidget {
  final Position? pickupLocation;
  final Position? destinationLocation;
  final String pickupAddress;
  final String destinationAddress;

  const DeliveryRequestScreen({
    Key? key,
    this.pickupLocation,
    this.destinationLocation,
    required this.pickupAddress,
    required this.destinationAddress,
  }) : super(key: key);

  @override
  State<DeliveryRequestScreen> createState() => _DeliveryRequestScreenState();
}

class _DeliveryRequestScreenState extends State<DeliveryRequestScreen> {
  final _formKey = GlobalKey<FormState>();
  
  // Type de colis
  String _packageType = 'small_package';
  
  // Informations du colis
  final _descriptionController = TextEditingController();
  final _weightController = TextEditingController();
  final _lengthController = TextEditingController();
  final _widthController = TextEditingController();
  final _heightController = TextEditingController();
  
  // Contact expéditeur
  final _senderNameController = TextEditingController();
  final _senderPhoneController = TextEditingController();
  
  // Contact destinataire
  final _recipientNameController = TextEditingController();
  final _recipientPhoneController = TextEditingController();
  final _instructionsController = TextEditingController();
  
  // Options
  bool _isFragile = false;
  bool _requiresSignature = false;
  
  // Prix estimé
  double _estimatedPrice = 1500;

  @override
  void initState() {
    super.initState();
    _calculatePrice();
  }

  void _calculatePrice() {
    // Calcul du prix basé sur le type et la distance
    double basePrice = 1000;
    
    switch (_packageType) {
      case 'document':
        basePrice = 800;
        break;
      case 'small_package':
        basePrice = 1500;
        break;
      case 'medium_package':
        basePrice = 2500;
        break;
      case 'large_package':
        basePrice = 4000;
        break;
      case 'food':
        basePrice = 1200;
        break;
      case 'fragile':
        basePrice = 3000;
        break;
    }
    
    if (_isFragile) basePrice += 500;
    if (_requiresSignature) basePrice += 300;
    
    setState(() {
      _estimatedPrice = basePrice;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Livraison de colis 🏍️'),
        backgroundColor: const Color(0xFFFF6B00),
        foregroundColor: Colors.white,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Adresses
            _buildSection(
              'Informations de livraison',
              Icons.location_on,
              [
                _buildInfoRow('Expédition', widget.pickupAddress),
                _buildInfoRow('Livraison', widget.destinationAddress),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // Type de colis
            _buildSection(
              'Type de colis',
              Icons.inventory_2,
              [
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _buildPackageTypeChip('Document', 'document', Icons.description),
                    _buildPackageTypeChip('Petit colis', 'small_package', Icons.shopping_bag),
                    _buildPackageTypeChip('Moyen', 'medium_package', Icons.inventory),
                    _buildPackageTypeChip('Grand', 'large_package', Icons.inventory_2),
                    _buildPackageTypeChip('Nourriture', 'food', Icons.restaurant),
                    _buildPackageTypeChip('Fragile', 'fragile', Icons.warning),
                  ],
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // Détails du colis
            _buildSection(
              'Détails du colis',
              Icons.info,
              [
                TextFormField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Description du colis',
                    hintText: 'Ex: Documents administratifs',
                    prefixIcon: Icon(Icons.edit),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Veuillez décrire le colis';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                
                // Poids et dimensions
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _weightController,
                        decoration: const InputDecoration(
                          labelText: 'Poids (kg)',
                          prefixIcon: Icon(Icons.scale),
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextFormField(
                        controller: _lengthController,
                        decoration: const InputDecoration(
                          labelText: 'Long. (cm)',
                          prefixIcon: Icon(Icons.straighten),
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _widthController,
                        decoration: const InputDecoration(
                          labelText: 'Larg. (cm)',
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextFormField(
                        controller: _heightController,
                        decoration: const InputDecoration(
                          labelText: 'Haut. (cm)',
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // Contact expéditeur
            _buildSection(
              'Contact expéditeur',
              Icons.person,
              [
                TextFormField(
                  controller: _senderNameController,
                  decoration: const InputDecoration(
                    labelText: 'Nom de l\'expéditeur',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Nom requis';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _senderPhoneController,
                  decoration: const InputDecoration(
                    labelText: 'Téléphone expéditeur',
                    prefixIcon: Icon(Icons.phone),
                    hintText: '77 XXX XX XX',
                  ),
                  keyboardType: TextInputType.phone,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Téléphone requis';
                    }
                    return null;
                  },
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // Contact destinataire
            _buildSection(
              'Contact destinataire',
              Icons.person_pin,
              [
                TextFormField(
                  controller: _recipientNameController,
                  decoration: const InputDecoration(
                    labelText: 'Nom du destinataire',
                    prefixIcon: Icon(Icons.person),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Nom requis';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _recipientPhoneController,
                  decoration: const InputDecoration(
                    labelText: 'Téléphone destinataire',
                    prefixIcon: Icon(Icons.phone),
                    hintText: '77 XXX XX XX',
                  ),
                  keyboardType: TextInputType.phone,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Téléphone requis';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _instructionsController,
                  decoration: const InputDecoration(
                    labelText: 'Instructions spéciales (optionnel)',
                    prefixIcon: Icon(Icons.note),
                    hintText: 'Ex: Sonner 2 fois',
                  ),
                  maxLines: 2,
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // Options
            _buildSection(
              'Options',
              Icons.tune,
              [
                SwitchListTile(
                  title: const Text('Colis fragile'),
                  subtitle: const Text('Manipulation délicate requise (+500 FCFA)'),
                  value: _isFragile,
                  activeColor: const Color(0xFFFF6B00),
                  onChanged: (value) {
                    setState(() {
                      _isFragile = value;
                    });
                    _calculatePrice();
                  },
                ),
                SwitchListTile(
                  title: const Text('Signature requise'),
                  subtitle: const Text('Preuve de livraison avec signature (+300 FCFA)'),
                  value: _requiresSignature,
                  activeColor: const Color(0xFFFF6B00),
                  onChanged: (value) {
                    setState(() {
                      _requiresSignature = value;
                    });
                    _calculatePrice();
                  },
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // Prix estimé
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFFFF6B00).withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFFF6B00)),
              ),
              child: Column(
                children: [
                  const Text(
                    'Prix estimé de la livraison',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${_estimatedPrice.toInt()} FCFA',
                    style: const TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFFF6B00),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Livraison rapide par moto-taxi',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Bouton de confirmation
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _confirmDelivery,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF6B00),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Confirmer la livraison',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, IconData icon, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: const Color(0xFFFF6B00)),
            const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ...children,
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPackageTypeChip(String label, String value, IconData icon) {
    final isSelected = _packageType == value;
    return FilterChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: isSelected ? Colors.white : const Color(0xFFFF6B00)),
          const SizedBox(width: 4),
          Text(label),
        ],
      ),
      selected: isSelected,
      selectedColor: const Color(0xFFFF6B00),
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : Colors.black87,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      onSelected: (selected) {
        if (selected) {
          setState(() {
            _packageType = value;
          });
          _calculatePrice();
        }
      },
    );
  }

  void _confirmDelivery() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Générer un code de confirmation aléatoire
    final confirmationCode = _generateConfirmationCode();

    final deliveryData = {
      'rideType': 'delivery',
      'pickup': {
        'address': widget.pickupAddress,
        'coordinates': {
          'latitude': widget.pickupLocation?.latitude,
          'longitude': widget.pickupLocation?.longitude,
        },
      },
      'destination': {
        'address': widget.destinationAddress,
        'coordinates': {
          'latitude': widget.destinationLocation?.latitude,
          'longitude': widget.destinationLocation?.longitude,
        },
      },
      'delivery': {
        'packageType': _packageType,
        'description': _descriptionController.text,
        'weight': double.tryParse(_weightController.text) ?? 0,
        'dimensions': {
          'length': double.tryParse(_lengthController.text) ?? 0,
          'width': double.tryParse(_widthController.text) ?? 0,
          'height': double.tryParse(_heightController.text) ?? 0,
        },
        'pickupContact': _senderNameController.text,
        'pickupContactPhone': _senderPhoneController.text,
        'recipientName': _recipientNameController.text,
        'recipientPhone': _recipientPhoneController.text,
        'instructions': _instructionsController.text,
        'isFragile': _isFragile,
        'requiresSignature': _requiresSignature,
        'confirmationCode': confirmationCode,
      },
      'pricing': {
        'totalPrice': _estimatedPrice,
      },
    };

    // TODO: Envoyer la demande via API
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Livraison confirmée ! 🎉'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Votre demande de livraison a été créée.'),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  const Text(
                    'Code de confirmation',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    confirmationCode,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFFF6B00),
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'À communiquer au destinataire',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text('Prix: ${_estimatedPrice.toInt()} FCFA'),
            const SizedBox(height: 8),
            const Text(
              'Un moto-taxi va récupérer votre colis sous peu.',
              style: TextStyle(fontSize: 12),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  String _generateConfirmationCode() {
    // Génère un code à 4 chiffres
    return (1000 + DateTime.now().millisecondsSinceEpoch % 9000).toString();
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _weightController.dispose();
    _lengthController.dispose();
    _widthController.dispose();
    _heightController.dispose();
    _senderNameController.dispose();
    _senderPhoneController.dispose();
    _recipientNameController.dispose();
    _recipientPhoneController.dispose();
    _instructionsController.dispose();
    super.dispose();
  }
}

