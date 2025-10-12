import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../themes/app_theme.dart';
import 'working_map_screen.dart';

class ImprovedRideRequestScreen extends StatefulWidget {
  const ImprovedRideRequestScreen({super.key});

  @override
  State<ImprovedRideRequestScreen> createState() => _ImprovedRideRequestScreenState();
}

class _ImprovedRideRequestScreenState extends State<ImprovedRideRequestScreen> {
  LatLng? _pickupLocation;
  LatLng? _destinationLocation;
  String _pickupAddress = '';
  String _destinationAddress = '';
  bool _isRequesting = false;
  String _selectedRideType = 'standard';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Demander une course'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF2E7D32),
              Color(0xFF4CAF50),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Zone de sélection des lieux
              Expanded(
                flex: 3,
                child: Container(
                  margin: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // En-tête
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor,
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(12),
                            topRight: Radius.circular(12),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.directions_car, color: Colors.white),
                            const SizedBox(width: 8),
                            Text(
                              'Planifiez votre trajet',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Sélection des lieux
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: [
                              // Point de départ
                              _buildLocationSelector(
                                'Point de départ',
                                _pickupAddress.isEmpty ? 'Sélectionner le lieu de départ' : _pickupAddress,
                                Icons.my_location,
                                AppTheme.primaryColor,
                                _selectPickupLocation,
                              ),
                              const SizedBox(height: 16),
                              // Flèche
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: Colors.grey[100],
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.arrow_downward,
                                  color: Colors.grey[600],
                                ),
                              ),
                              const SizedBox(height: 16),
                              // Destination
                              _buildLocationSelector(
                                'Destination',
                                _destinationAddress.isEmpty ? 'Sélectionner la destination' : _destinationAddress,
                                Icons.location_on,
                                Colors.orange,
                                _selectDestinationLocation,
                              ),
                              const SizedBox(height: 24),
                              // Type de course
                              _buildRideTypeSelector(),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Zone de résumé et action
              Expanded(
                flex: 2,
                child: Container(
                  margin: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.blue[50],
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(12),
                            topRight: Radius.circular(12),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.info_outline, color: Colors.blue[700]),
                            const SizedBox(width: 8),
                            Text(
                              'Résumé de votre course',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                color: Colors.blue[700],
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: [
                              // Informations du trajet
                              if (_pickupLocation != null && _destinationLocation != null) ...[
                                _buildRideInfo(),
                                const SizedBox(height: 16),
                              ],
                              // Bouton de demande
                              SizedBox(
                                width: double.infinity,
                                height: 50,
                                child: ElevatedButton(
                                  onPressed: _canRequestRide() ? _requestRide : null,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: _canRequestRide() ? AppTheme.primaryColor : Colors.grey,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  child: _isRequesting
                                      ? const Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            SizedBox(
                                              width: 20,
                                              height: 20,
                                              child: CircularProgressIndicator(
                                                color: Colors.white,
                                                strokeWidth: 2,
                                              ),
                                            ),
                                            SizedBox(width: 12),
                                            Text('Recherche de chauffeur...'),
                                          ],
                                        )
                                      : const Text(
                                          'Demander une course',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLocationSelector(
    String title,
    String subtitle,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 14,
                      color: subtitle.contains('Sélectionner') ? Colors.grey[400] : Colors.grey[800],
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: Colors.grey[400],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRideTypeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Type de course',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _buildRideTypeOption(
                'Standard',
                'Voiture classique',
                'standard',
                Icons.directions_car,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildRideTypeOption(
                'Confort',
                'Voiture premium',
                'comfort',
                Icons.airline_seat_flat,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRideTypeOption(String title, String subtitle, String value, IconData icon) {
    final isSelected = _selectedRideType == value;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedRideType = value;
        });
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected ? AppTheme.primaryColor : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(8),
          color: isSelected ? AppTheme.primaryColor.withOpacity(0.05) : null,
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected ? AppTheme.primaryColor : Colors.grey[600],
              size: 20,
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: isSelected ? AppTheme.primaryColor : Colors.grey[800],
              ),
            ),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRideInfo() {
    final distance = _calculateDistance();
    final estimatedPrice = _calculatePrice();
    final estimatedTime = _calculateTime();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.route, color: AppTheme.primaryColor, size: 20),
              const SizedBox(width: 8),
              Text(
                'Informations du trajet',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildInfoItem('Distance', '${distance.toStringAsFixed(1)} km', Icons.straighten),
              _buildInfoItem('Durée', '$estimatedTime min', Icons.access_time),
              _buildInfoItem('Prix estimé', '${estimatedPrice.toStringAsFixed(0)} FCFA', Icons.monetization_on),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: AppTheme.primaryColor, size: 16),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Future<void> _selectPickupLocation() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => WorkingMapScreen(
          title: 'Sélectionner le lieu de départ',
          onLocationSelected: (data) {
            setState(() {
              _pickupLocation = LatLng(
                data['location']['lat'],
                data['location']['lng'],
              );
              _pickupAddress = data['address'];
            });
          },
        ),
      ),
    );

    if (result != null) {
      setState(() {
        _pickupLocation = LatLng(
          result['location']['lat'],
          result['location']['lng'],
        );
        _pickupAddress = result['address'];
      });
    }
  }

  Future<void> _selectDestinationLocation() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => WorkingMapScreen(
          title: 'Sélectionner la destination',
          onLocationSelected: (data) {
            setState(() {
              _destinationLocation = LatLng(
                data['location']['lat'],
                data['location']['lng'],
              );
              _destinationAddress = data['address'];
            });
          },
        ),
      ),
    );

    if (result != null) {
      setState(() {
        _destinationLocation = LatLng(
          result['location']['lat'],
          result['location']['lng'],
        );
        _destinationAddress = result['address'];
      });
    }
  }

  bool _canRequestRide() {
    return _pickupLocation != null && 
           _destinationLocation != null && 
           !_isRequesting;
  }

  double _calculateDistance() {
    if (_pickupLocation == null || _destinationLocation == null) return 0.0;
    
    // Calcul approximatif de distance (formule de Haversine simplifiée)
    const double earthRadius = 6371; // km
    final lat1 = _pickupLocation!.latitude * (3.14159 / 180);
    final lat2 = _destinationLocation!.latitude * (3.14159 / 180);
    final deltaLat = (lat2 - lat1);
    final deltaLng = (_destinationLocation!.longitude - _pickupLocation!.longitude) * (3.14159 / 180);

    final a = (deltaLat / 2) * (deltaLat / 2) + 
              (deltaLng / 2) * (deltaLng / 2) * 
              math.cos(lat1) * math.cos(lat2);
    final c = 2 * math.asin(math.sqrt(a));
    
    return earthRadius * c;
  }

  double _calculatePrice() {
    final distance = _calculateDistance();
    final basePrice = 500; // Prix de base en FCFA
    final pricePerKm = _selectedRideType == 'comfort' ? 400 : 300; // Prix par km
    
    return basePrice + (distance * pricePerKm);
  }

  int _calculateTime() {
    final distance = _calculateDistance();
    const averageSpeed = 30; // km/h en ville
    return ((distance / averageSpeed) * 60).round();
  }

  Future<void> _requestRide() async {
    setState(() {
      _isRequesting = true;
    });

    // Simulation de la demande de course
    await Future.delayed(const Duration(seconds: 3));

    setState(() {
      _isRequesting = false;
    });

    // Afficher un message de succès
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Course demandée avec succès ! Recherche de chauffeur...'),
          backgroundColor: AppTheme.primaryColor,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }
}

// Classe LatLng simplifiée
class LatLng {
  final double latitude;
  final double longitude;
  
  const LatLng(this.latitude, this.longitude);
}

