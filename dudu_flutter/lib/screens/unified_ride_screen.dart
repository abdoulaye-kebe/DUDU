import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:math' as math;
import '../services/api_service.dart';
import '../services/places_service.dart';
import '../services/socket_service.dart';
import 'ride_tracking_screen.dart';

/// Écran unifié pour les 4 types de courses (Standard, Express, Covoiturage, Femmes)
/// Avec sélection Point A, Point B et PRIX LIBRE
class UnifiedRideScreen extends StatefulWidget {
  const UnifiedRideScreen({Key? key}) : super(key: key);

  @override
  State<UnifiedRideScreen> createState() => _UnifiedRideScreenState();
}

class _UnifiedRideScreenState extends State<UnifiedRideScreen> {
  GoogleMapController? _mapController;
  Position? _currentPosition;
  final Set<Marker> _markers = {};
  final Set<Polyline> _polylines = {};
  bool _isSearchingDriver = false;
  
  // Couleurs DUDU
  static const Color primaryGreen = Color(0xFF0d5d36);
  static const Color lightGreen = Color(0xFF10b981);
  static const Color accentBlack = Color(0xFF1A1A1A);

  // Controllers
  final TextEditingController _pickupController = TextEditingController();
  final TextEditingController _destinationController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  
  // États
  bool _isLoading = true;
  bool _isSearching = false;
  String _selectedMode = 'ride'; // ride ou delivery
  String _selectedRideType = 'standard';
  String _pickupAddress = '';
  String _destinationAddress = '';
  LatLng? _pickupLatLng;
  LatLng? _destinationLatLng;
  int _customPrice = 0;
  double _estimatedDistance = 0;
  List<PlaceSuggestion> _suggestions = [];
  String _selectedPaymentMethod = '';
  // Véhicules simulés à proximité (pour affichage liste + markers)
  List<LatLng> _nearbyVehicles = [];
  
  // Types de courses disponibles
  final List<Map<String, dynamic>> _rideTypes = [
    {
      'id': 'standard',
      'name': 'Standard',
      'icon': Icons.directions_car,
      'color': Color(0xFF0d5d36),
      'description': 'Voiture standard • 1-4 passagers',
      'capacity': 4,
      'basePricePerKm': 400,
    },
    {
      'id': 'express',
      'name': 'Express',
      'icon': Icons.flash_on,
      'color': Colors.orange,
      'description': 'Arrivée plus rapide • 1-3 passagers',
      'badge': 'POPULAIRE',
      'capacity': 3,
      'basePricePerKm': 500,
    },
    {
      'id': 'women_only',
      'name': 'Femmes',
      'icon': Icons.woman,
      'color': Colors.pink,
      'description': 'Chauffeuse pour passagères',
      'capacity': 4,
      'basePricePerKm': 450,
    },
  ];

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
    _selectedPaymentMethod = 'cash';
  }

  Widget _buildNearbyVehiclesList() {
    if (_nearbyVehicles.isEmpty || _pickupLatLng == null) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Véhicules à proximité',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: accentBlack,
            ),
          ),
          const SizedBox(height: 6),
          Column(
            children: _nearbyVehicles.asMap().entries.map((entry) {
              final index = entry.key;
              final pos = entry.value;

              // Distance entre le véhicule et le point de départ (km)
              final distanceKm = _calculateDistance(
                pos.latitude,
                pos.longitude,
                _pickupLatLng!.latitude,
                _pickupLatLng!.longitude,
              );

              // Vitesse moyenne 25 km/h => ETA en minutes
              final etaMinutes = (distanceKm / 25 * 60).ceil().clamp(1, 30);

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: const Icon(Icons.directions_car, size: 18, color: primaryGreen),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Véhicule ${index + 1}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: accentBlack,
                      ),
                    ),
                    const Spacer(),
                    Icon(Icons.access_time, size: 14, color: primaryGreen),
                    const SizedBox(width: 4),
                    Text(
                      '$etaMinutes min',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: primaryGreen,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Future<void> _getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        // Si GPS désactivé, utiliser Dakar par défaut
        _useDakarAsDefault();
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _useDakarAsDefault();
          return;
        }
      }

      Position position = await Geolocator.getCurrentPosition();
      
      // Vérifier si la position est au Sénégal (latitude: 12-17, longitude: -18 à -11)
      bool isInSenegal = position.latitude >= 12.0 && position.latitude <= 17.0 &&
                         position.longitude >= -18.0 && position.longitude <= -11.0;
      
      if (!isInSenegal) {
        // Si position hors Sénégal (émulateur aux USA), utiliser Dakar
        print('⚠️ Position détectée hors Sénégal: ${position.latitude}, ${position.longitude}');
        _useDakarAsDefault();
        return;
      }

      setState(() {
        _currentPosition = position;
        _pickupAddress = 'Ma position actuelle';
        _isLoading = false;
      });

      _mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(
          LatLng(position.latitude, position.longitude),
          14.0,
        ),
      );
    } catch (e) {
      print('❌ Erreur localisation: $e');
      _useDakarAsDefault();
    }
  }

  void _useDakarAsDefault() {
    // Position par défaut: Place de l'Indépendance, Dakar
    final dakarPosition = Position(
      latitude: 14.6928,
      longitude: -17.4467,
      timestamp: DateTime.now(),
      accuracy: 0,
      altitude: 0,
      heading: 0,
      speed: 0,
      speedAccuracy: 0,
      altitudeAccuracy: 0,
      headingAccuracy: 0,
    );
    
    setState(() {
      _currentPosition = dakarPosition;
      _pickupAddress = 'Dakar, Sénégal';
      _pickupLatLng = const LatLng(14.6928, -17.4467);
      _isLoading = false;
      _addMarker(_pickupLatLng!, 'Départ', primaryGreen);
    });

    _mapController?.animateCamera(
      CameraUpdate.newLatLngZoom(
        const LatLng(14.6928, -17.4467),
        13.0,
      ),
    );
  }

  Widget _buildPaymentMethodSelector() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Moyen de paiement',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: accentBlack,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildPaymentChip(
                  label: 'Espèces',
                  value: 'cash',
                  icon: Icons.payments,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildPaymentChip(
                  label: 'Mobile money',
                  value: 'mobile_money',
                  icon: Icons.phone_iphone,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildPaymentChip(
                  label: 'Carte bancaire',
                  value: 'card',
                  icon: Icons.credit_card,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentChip({
    required String label,
    required String value,
    required IconData icon,
  }) {
    final isSelected = _selectedPaymentMethod == value;
    return InkWell(
      onTap: () {
        setState(() {
          _selectedPaymentMethod = value;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? primaryGreen : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? primaryGreen : Colors.grey[300]!,
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? Colors.white : primaryGreen,
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? Colors.white : accentBlack,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModeSelector() {
    return Container
    (
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: Colors.white,
      child: Row(
        children: [
          Expanded(
            child: _buildModeChip(
              label: 'Course',
              icon: Icons.directions_car,
              isSelected: _selectedMode == 'ride',
              onTap: () {
                setState(() {
                  _selectedMode = 'ride';
                });
              },
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildModeChip(
              label: 'Livraison (moto)',
              icon: Icons.delivery_dining,
              isSelected: _selectedMode == 'delivery',
              onTap: () {
                setState(() {
                  _selectedMode = 'delivery';
                });
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModeChip({
    required String label,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? primaryGreen : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? primaryGreen : Colors.grey[300]!,
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 18,
              color: isSelected ? Colors.white : primaryGreen,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : accentBlack,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      // Bouton flottant Accueil
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).popUntil((route) => route.isFirst);
        },
        backgroundColor: primaryGreen,
        child: const Icon(Icons.home, color: Colors.white),
        tooltip: 'Accueil',
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.startFloat,
      appBar: AppBar(
        title: Text(
          _selectedMode == 'delivery'
              ? 'Commander une livraison (moto)'
              : 'Commander une course',
        ),
        backgroundColor: primaryGreen,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Sélection Course / Livraison (moto)
          _buildModeSelector(),
          // Sélection du type de course
          _buildRideTypeSelector(),
          
          // Points A et B
          _buildLocationInputs(),
          
          // Carte - AGRANDIE (flex: 3)
          Expanded(
            flex: 3,
            child: _buildMap(),
          ),
          
          // Prix libre et bouton de confirmation - RÉDUIT
          _buildBottomSection(),
        ],
      ),
    );
  }

  Widget _buildRideTypeSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Choisissez votre type de véhicule',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: accentBlack,
            ),
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _rideTypes.map((type) {
                final isSelected = _selectedRideType == type['id'];
                final capacity = type['capacity'] as int? ?? 4;

                return Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: _buildRideTypeChip(
                    label: type['name'],
                    icon: type['icon'],
                    color: type['color'],
                    description: type['description'],
                    capacity: capacity,
                    isSelected: isSelected,
                    onTap: () => setState(() => _selectedRideType = type['id']),
                    badge: type['badge'],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRideTypeChip({
    required String label,
    required IconData icon,
    required Color color,
    required String description,
    required int capacity,
    required bool isSelected,
    required VoidCallback onTap,
    String? badge,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: 220,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.08) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? color : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: accentBlack,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        description,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                if (badge != null) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      badge,
                      style: TextStyle(
                        color: color,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.person, size: 14, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  '$capacity places',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationInputs() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.grey[50],
      child: Column(
        children: [
          // Point A (Départ)
          _buildLocationField(
            icon: Icons.radio_button_checked,
            iconColor: primaryGreen,
            hint: 'Point de départ',
            value: _pickupAddress,
            onTap: () => _showAddressSearch(true),
          ),
          
          // Ligne de connexion
          Padding(
            padding: const EdgeInsets.only(left: 20),
            child: Container(
              width: 2,
              height: 20,
              color: Colors.grey[300],
            ),
          ),
          
          // Point B (Destination)
          _buildLocationField(
            icon: Icons.place,
            iconColor: Colors.red,
            hint: 'Destination',
            value: _destinationAddress,
            onTap: () => _showAddressSearch(false),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationField({
    required IconData icon,
    required Color iconColor,
    required String hint,
    required String value,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Row(
          children: [
            Icon(icon, color: iconColor, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                value.isEmpty ? hint : value,
                style: TextStyle(
                  fontSize: 15,
                  color: value.isEmpty ? Colors.grey[500] : accentBlack,
                  fontWeight: value.isEmpty ? FontWeight.normal : FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMap() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    // Calcul simple d'un ETA en minutes (distance / 30 km/h)
    int? etaMinutes;
    if (_estimatedDistance > 0) {
      etaMinutes = (_estimatedDistance / 30 * 60).ceil();
    }

    return Stack(
      children: [
        GoogleMap(
          initialCameraPosition: CameraPosition(
            target: _currentPosition != null
                ? LatLng(_currentPosition!.latitude, _currentPosition!.longitude)
                : const LatLng(14.6928, -17.4467), // Dakar
            zoom: 14.0,
          ),
          onMapCreated: (controller) => _mapController = controller,
          markers: _markers,
          polylines: _polylines,
          myLocationEnabled: true,
          myLocationButtonEnabled: true,
          zoomControlsEnabled: false,
          mapType: MapType.normal,
        ),
        if (etaMinutes != null && _pickupLatLng != null)
          Positioned(
            top: 16,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: primaryGreen,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.access_time, color: Colors.white, size: 16),
                    const SizedBox(width: 6),
                    Text(
                      '$etaMinutes min',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  void _showAddressSearch(bool isPickup) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (_, controller) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Handle
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // En-tête "Votre itinéraire" avec bouton fermer
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 12, 8, 4),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                    ),
                    const Expanded(
                      child: Text(
                        'Votre itinéraire',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 48),
                  ],
                ),
              ),
              // Bouton "Ma position actuelle"
              if (isPickup)
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      Navigator.pop(context);
                      
                      // Afficher un indicateur de chargement
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Row(
                            children: [
                              SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              ),
                              SizedBox(width: 12),
                              Text('Récupération de votre position...'),
                            ],
                          ),
                          duration: Duration(seconds: 2),
                        ),
                      );
                      
                      try {
                        // Toujours essayer d'obtenir la position GPS actuelle
                        Position position = await Geolocator.getCurrentPosition(
                          desiredAccuracy: LocationAccuracy.high,
                          timeLimit: const Duration(seconds: 10),
                        );
                        
                        print('📍 Position GPS obtenue: ${position.latitude}, ${position.longitude}');
                        
                        // Obtenir l'adresse
                        final address = await PlacesService.reverseGeocode(
                          position.latitude,
                          position.longitude,
                        );
                        
                        setState(() {
                          _currentPosition = position;
                          _pickupAddress = address;
                          _pickupLatLng = LatLng(position.latitude, position.longitude);
                          _addMarker(_pickupLatLng!, 'Départ', primaryGreen);
                        });
                        
                        // Centrer la carte sur la position
                        _mapController?.animateCamera(
                          CameraUpdate.newLatLngZoom(
                            LatLng(position.latitude, position.longitude),
                            15.0,
                          ),
                        );
                        
                        if (_destinationLatLng != null) {
                          _drawRoute();
                        }
                        
                        ScaffoldMessenger.of(context).hideCurrentSnackBar();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Position définie: $address'),
                            backgroundColor: primaryGreen,
                          ),
                        );
                      } catch (e) {
                        print('❌ Erreur position: $e');
                        // Utiliser la position par défaut si disponible
                        if (_currentPosition != null) {
                          final address = await PlacesService.reverseGeocode(
                            _currentPosition!.latitude,
                            _currentPosition!.longitude,
                          );
                          setState(() {
                            _pickupAddress = address;
                            _pickupLatLng = LatLng(
                              _currentPosition!.latitude,
                              _currentPosition!.longitude,
                            );
                            _addMarker(_pickupLatLng!, 'Départ', primaryGreen);
                          });
                          if (_destinationLatLng != null) {
                            _drawRoute();
                          }
                        } else {
                          ScaffoldMessenger.of(context).hideCurrentSnackBar();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Impossible d\'obtenir votre position. Vérifiez que le GPS est activé.'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      }
                    },
                    icon: const Icon(Icons.my_location),
                    label: const Text('Utiliser ma position actuelle'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryGreen,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              // Barre de recherche
              Padding(
                padding: const EdgeInsets.all(16),
                child: TextField(
                  autofocus: true,
                  decoration: InputDecoration(
                    hintText: isPickup ? 'Lieu de prise en charge' : 'Lieu d\'arrivée',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _isSearching 
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: Padding(
                              padding: EdgeInsets.all(12),
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onChanged: (value) async {
                    if (value.length > 2) {
                      setState(() => _isSearching = true);
                      try {
                        // Passer la position actuelle pour des suggestions plus pertinentes
                        final suggestions = await PlacesService.getPlaceSuggestions(
                          value,
                          userLat: _currentPosition?.latitude ?? 14.6928,
                          userLng: _currentPosition?.longitude ?? -17.4467,
                        );
                        if (mounted) {
                          setState(() {
                            _suggestions = suggestions;
                            _isSearching = false;
                          });
                        }
                      } catch (e) {
                        print('Erreur recherche: $e');
                        if (mounted) {
                          setState(() => _isSearching = false);
                        }
                      }
                    } else {
                      setState(() {
                        _suggestions = [];
                        _isSearching = false;
                      });
                    }
                  },
                ),
              ),
              // Suggestions
              Expanded(
                child: _suggestions.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.search, size: 48, color: Colors.grey[400]),
                              const SizedBox(height: 16),
                              Text(
                                'Tapez au moins 3 caractères',
                                style: TextStyle(color: Colors.grey[600]),
                              ),
                              const SizedBox(height: 24),
                              const Text(
                                'Lieux populaires à Dakar:',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 12),
                              ..._getPopularPlaces().map((place) => ListTile(
                                leading: const Icon(Icons.star, color: Colors.amber),
                                title: Text(place['name']!),
                                subtitle: Text(place['address']!),
                                onTap: () {
                                  Navigator.pop(context);
                                  final lat = double.parse(place['lat']!);
                                  final lng = double.parse(place['lng']!);
                                  setState(() {
                                    if (isPickup) {
                                      _pickupAddress = place['name']!;
                                      _pickupLatLng = LatLng(lat, lng);
                                      _addMarker(_pickupLatLng!, 'Départ', primaryGreen);
                                    } else {
                                      _destinationAddress = place['name']!;
                                      _destinationLatLng = LatLng(lat, lng);
                                      _addMarker(_destinationLatLng!, 'Destination', Colors.red);
                                    }
                                  });
                                  if (_pickupLatLng != null && _destinationLatLng != null) {
                                    _drawRoute();
                                  }
                                },
                              )),
                            ],
                          ),
                        ),
                      )
                    : ListView.builder(
                        controller: controller,
                        itemCount: _suggestions.length,
                        itemBuilder: (context, index) {
                          final suggestion = _suggestions[index];
                          return ListTile(
                            leading: Icon(
                              suggestion.isLocal ? Icons.star : Icons.location_on,
                              color: suggestion.isLocal ? Colors.amber : null,
                            ),
                            title: Text(suggestion.mainText),
                            subtitle: Text(suggestion.secondaryText),
                            onTap: () async {
                              Navigator.pop(context);
                              
                              double? lat;
                              double? lng;
                              
                              // Si c'est une suggestion locale, utiliser les coordonnées directement
                              if (suggestion.isLocal && suggestion.localLat != null && suggestion.localLng != null) {
                                lat = suggestion.localLat;
                                lng = suggestion.localLng;
                              } else {
                                // Sinon, appeler l'API pour obtenir les coordonnées
                                final details = await PlacesService.getPlaceDetails(suggestion.placeId);
                                if (details != null) {
                                  lat = details.latitude;
                                  lng = details.longitude;
                                }
                              }
                              
                              if (lat != null && lng != null) {
                                setState(() {
                                  if (isPickup) {
                                    _pickupAddress = suggestion.description;
                                    _pickupLatLng = LatLng(lat!, lng!);
                                    _addMarker(_pickupLatLng!, 'Départ', primaryGreen);
                                  } else {
                                    _destinationAddress = suggestion.description;
                                    _destinationLatLng = LatLng(lat!, lng!);
                                    _addMarker(_destinationLatLng!, 'Destination', Colors.red);
                                  }
                                });
                                if (_pickupLatLng != null && _destinationLatLng != null) {
                                  _drawRoute();
                                }
                              }
                            },
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _addMarker(LatLng position, String title, Color color) {
    final markerId = MarkerId(title);
    final marker = Marker(
      markerId: markerId,
      position: position,
      infoWindow: InfoWindow(title: title),
      icon: BitmapDescriptor.defaultMarkerWithHue(
        color == primaryGreen ? BitmapDescriptor.hueGreen : BitmapDescriptor.hueRed,
      ),
    );
    setState(() {
      _markers.removeWhere((m) => m.markerId == markerId);
      _markers.add(marker);
    });
    _mapController?.animateCamera(CameraUpdate.newLatLng(position));
  }

  void _generateNearbyCarMarkers() {
    if (_pickupLatLng == null) return;

    final random = math.Random();
    final List<Marker> carMarkers = [];
    final List<LatLng> vehicles = [];

    for (int i = 0; i < 5; i++) {
      final dx = (random.nextDouble() - 0.5) / 500; // petit décalage latitude
      final dy = (random.nextDouble() - 0.5) / 500; // petit décalage longitude
      final carPosition = LatLng(
        _pickupLatLng!.latitude + dx,
        _pickupLatLng!.longitude + dy,
      );

      vehicles.add(carPosition);

      carMarkers.add(
        Marker(
          markerId: MarkerId('car_$i'),
          position: carPosition,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueYellow),
          infoWindow: const InfoWindow(title: 'Chauffeur à proximité'),
        ),
      );
    }

    setState(() {
      _nearbyVehicles = vehicles;
      _markers.removeWhere((m) => m.markerId.value.startsWith('car_'));
      _markers.addAll(carMarkers);
    });

    // Recentrer la caméra sur le point de départ pour bien voir les voitures
    _mapController?.animateCamera(
      CameraUpdate.newLatLngZoom(_pickupLatLng!, 15.5),
    );
  }

  void _clearNearbyCarMarkers() {
    setState(() {
      _markers.removeWhere((m) => m.markerId.value.startsWith('car_'));
    });
  }

  void _drawRoute() {
    if (_pickupLatLng == null || _destinationLatLng == null) return;

    // Calcul de la distance
    _estimatedDistance = _calculateDistance(
      _pickupLatLng!.latitude,
      _pickupLatLng!.longitude,
      _destinationLatLng!.latitude,
      _destinationLatLng!.longitude,
    );

    // Tracer une ligne simple (en production, utiliser Google Directions API)
    final polyline = Polyline(
      polylineId: const PolylineId('route'),
      points: [_pickupLatLng!, _destinationLatLng!],
      color: primaryGreen,
      width: 4,
    );

    setState(() {
      _polylines.clear();
      _polylines.add(polyline);
    });

    // Ajuster la caméra pour voir tout le trajet
    final bounds = LatLngBounds(
      southwest: LatLng(
        math.min(_pickupLatLng!.latitude, _destinationLatLng!.latitude),
        math.min(_pickupLatLng!.longitude, _destinationLatLng!.longitude),
      ),
      northeast: LatLng(
        math.max(_pickupLatLng!.latitude, _destinationLatLng!.latitude),
        math.max(_pickupLatLng!.longitude, _destinationLatLng!.longitude),
      ),
    );
    _mapController?.animateCamera(CameraUpdate.newLatLngBounds(bounds, 100));
  }

  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const p = 0.017453292519943295;
    final a = 0.5 - math.cos((lat2 - lat1) * p) / 2 +
        math.cos(lat1 * p) * math.cos(lat2 * p) * (1 - math.cos((lon2 - lon1) * p)) / 2;
    return 12742 * math.asin(math.sqrt(a)); // Distance en km
  }

  List<Map<String, String>> _getPopularPlaces() {
    return [
      {
        'name': 'Aéroport Blaise Diagne',
        'address': 'AIBD, Diass',
        'lat': '14.6700',
        'lng': '-17.0733',
      },
      {
        'name': 'Place de l\'Indépendance',
        'address': 'Plateau, Dakar',
        'lat': '14.6928',
        'lng': '-17.4467',
      },
      {
        'name': 'Université Cheikh Anta Diop',
        'address': 'UCAD, Dakar',
        'lat': '14.6937',
        'lng': '-17.4441',
      },
      {
        'name': 'King Fahd Palace',
        'address': 'Almadies, Dakar',
        'lat': '14.7392',
        'lng': '-17.5108',
      },
      {
        'name': 'Marché Sandaga',
        'address': 'Sandaga, Dakar',
        'lat': '14.6760',
        'lng': '-17.4634',
      },
    ];
  }

  Widget _buildBottomSection() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Moyen de paiement
            _buildPaymentMethodSelector(),

            if (_selectedPaymentMethod.isNotEmpty) ...[
              const SizedBox(height: 6),
              Row(
                children: [
                  Icon(
                    _selectedPaymentMethod == 'cash'
                        ? Icons.payments
                        : _selectedPaymentMethod == 'mobile_money'
                            ? Icons.phone_iphone
                            : Icons.credit_card,
                    size: 18,
                    color: primaryGreen,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _selectedPaymentMethod == 'cash'
                        ? 'Paiement en espèces'
                        : _selectedPaymentMethod == 'mobile_money'
                            ? 'Mobile money'
                            : 'Carte bancaire',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: accentBlack,
                    ),
                  ),
                ],
              ),
            ],

            const SizedBox(height: 8),

            // Liste des véhicules avec temps d'arrivée estimé
            _buildNearbyVehiclesList(),

            const SizedBox(height: 8),

            // Prix libre - COMPACT
            _buildPriceInput(),
            
            const SizedBox(height: 10),
            
            // Bouton de confirmation
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _customPrice > 0 && 
                           _pickupAddress.isNotEmpty && 
                           _destinationAddress.isNotEmpty &&
                           _pickupLatLng != null &&
                           _destinationLatLng != null &&
                           _selectedPaymentMethod.isNotEmpty
                    ? _confirmRide
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryGreen,
                  disabledBackgroundColor: Colors.grey[300],
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  _customPrice > 0
                      ? 'Confirmer - ${_customPrice} FCFA'
                      : 'Entrez votre prix',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPriceInput() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: lightGreen.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: lightGreen.withOpacity(0.3), width: 2),
      ),
      child: Row(
        children: [
          Icon(Icons.payments_outlined, color: primaryGreen, size: 18),
          const SizedBox(width: 8),
          const Text(
            'Votre prix libre',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: accentBlack,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: _priceController,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: primaryGreen,
              ),
              decoration: InputDecoration(
                hintText: '0',
                hintStyle: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[400],
                ),
                suffixText: 'FCFA',
                suffixStyle: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: accentBlack,
                ),
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
                isDense: true,
              ),
              onChanged: (value) {
                setState(() {
                  _customPrice = int.tryParse(value) ?? 0;
                });
              },
            ),
          ),
        ],
      ),
    );
  }

  void _confirmRide() async {
    if (_pickupLatLng == null || _destinationLatLng == null || _customPrice == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez remplir tous les champs')),
      );
      return;
    }

    if (mounted) {
      setState(() {
        _isSearchingDriver = true;
      });
      _generateNearbyCarMarkers();
    }

    // Préparer l'écoute de "ride-accepted" pour cette demande
    final socketService = SocketService();
    socketService.onRideAccepted = (data) {
      if (!mounted) return;

      try {
        final rideId = data['rideId']?.toString();
        if (rideId == null || _pickupLatLng == null || _destinationLatLng == null) {
          return;
        }

        final driver = data['driver'] ?? {};
        final vehicle = driver['vehicle'] ?? {};

        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => RideTrackingScreen(
              rideId: rideId,
              vehicleType: _selectedMode == 'delivery' ? 'moto' : 'car',
              pickupLocation: {
                'latitude': _pickupLatLng!.latitude,
                'longitude': _pickupLatLng!.longitude,
              },
              destinationLocation: {
                'latitude': _destinationLatLng!.latitude,
                'longitude': _destinationLatLng!.longitude,
              },
              driverInfo: {
                'name': driver['name'] ?? 'Chauffeur',
                'phone': driver['phone'] ?? '',
                'vehicle': vehicle['model'] != null
                    ? '${vehicle['make'] ?? ''} ${vehicle['model']}'
                    : '',
                'rating': driver['rating'] ?? 5.0,
              },
            ),
          ),
        );
      } catch (e) {
        print('Erreur lors de l\'ouverture du tracking: $e');
      }
    };

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Recherche de chauffeur...'),
          ],
        ),
      ),
    );

    try {
      // Envoyer la demande au backend
      final response = await ApiService.createRide(
        pickupLatitude: _pickupLatLng!.latitude,
        pickupLongitude: _pickupLatLng!.longitude,
        pickupAddress: _pickupAddress,
        destinationLatitude: _destinationLatLng!.latitude,
        destinationLongitude: _destinationLatLng!.longitude,
        destinationAddress: _destinationAddress,
        rideType: _selectedRideType,
        customPrice: _customPrice,
        estimatedDistance: _estimatedDistance,
        paymentMethod: _selectedPaymentMethod,
      );

      if (mounted) {
        Navigator.pop(context);
      }

      if (response.success) {
        if (mounted) {
          // Afficher un dialogue d'attente avec possibilité d'annuler
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: primaryGreen.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const CircularProgressIndicator(color: primaryGreen),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Demande envoyée !',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'En attente d\'un chauffeur...\nPrix proposé: $_customPrice FCFA',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 24),
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context); // Fermer le dialogue
                      Navigator.pop(context); // Retourner au dashboard
                    },
                    child: const Text('Annuler la demande', style: TextStyle(color: Colors.red)),
                  ),
                ],
              ),
            ),
          );
        }
      } else {
        if (mounted) {
          _clearNearbyCarMarkers();
          setState(() {
            _isSearchingDriver = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erreur: ${response.message}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        _clearNearbyCarMarkers();
        setState(() {
          _isSearchingDriver = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    }
  }

  @override
  void dispose() {
    _pickupController.dispose();
    _destinationController.dispose();
    _priceController.dispose();
    super.dispose();
  }
}
