import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import 'dart:math' as math;
import 'dart:async';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../services/places_service.dart';
import '../services/socket_service.dart';
import '../services/search_history_service.dart';
import '../constants/map_style.dart';
import '../constants/senegal_map.dart';
import '../services/map_style_service.dart';
import '../services/directions_service.dart';
import 'delivery_tracking_screen.dart';
import 'ride_tracking_screen.dart';
import 'ride_confirmation_screen.dart';

/// Écran unifié pour les 4 types de courses (Standard, Express, Covoiturage, Femmes)
/// Avec sélection Point A, Point B et PRIX LIBRE
class UnifiedRideScreen extends StatefulWidget {
  /// `delivery` : ouvre directement le mode livraison (carte + prix + itinéraire).
  const UnifiedRideScreen({Key? key, this.initialMode}) : super(key: key);

  final String? initialMode;

  @override
  State<UnifiedRideScreen> createState() => _UnifiedRideScreenState();
}

class _UnifiedRideScreenState extends State<UnifiedRideScreen> {
  GoogleMapController? _mapController;
  Position? _currentPosition;
  final Set<Marker> _markers = {};
  final Set<Polyline> _polylines = {};
  bool _isSearchingDriver = false;
  String? _pendingRideMongoId;
  Timer? _searchDebounce;
  int _searchToken = 0;
  
  // Couleurs DuDu
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
  double _motoPricePerKm = 500;
  // Véhicules simulés à proximité (pour affichage liste + markers)
  List<LatLng> _nearbyVehicles = [];
  bool _isRouteLoading = false;
  /// Durée d'itinéraire (Google Directions), en secondes — sinon estimation locale.
  int? _routeDurationSeconds;
  /// Livraison prioritaire (un seul colis à la fois côté livreur) — sinon empilement possible (2 courses).
  bool _deliveryUrgent = false;

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
      'id': 'comfort',
      'name': 'Confort',
      'icon': Icons.chair,
      'color': Colors.orange,
      'description': 'Confort • Climatisation • 1-4 passagers',
      'badge': 'CONFORT',
      'capacity': 4,
      'basePricePerKm': 600,
    },
    {
      'id': 'women_only',
      'name': 'Femme',
      'icon': Icons.woman,
      'color': Colors.pink,
      'description': 'Femmes • Sécurité • 1-4 passagers',
      'badge': 'FEMME',
      'capacity': 4,
      'basePricePerKm': 650,
    },
    {
      'id': 'luxe',
      'name': 'Luxe',
      'icon': Icons.diamond,
      'color': Colors.black,
      'description': 'Luxe • Voiture premium • 1-4 passagers',
      'badge': 'LUXE',
      'capacity': 4,
      'basePricePerKm': 5000,
    },
    {
      'id': 'moto',
      'name': 'Moto',
      'icon': Icons.motorcycle,
      'assetPath': 'assets/images/ride_types/coursemoto.png',
      'color': Colors.blueGrey,
      'description': 'Moto • Rapide • 1 passager',
      'badge': 'MOTO',
      'capacity': 1,
      'basePricePerKm': 500,
    },
  ];

  String get _backendRideType {
    if (_selectedMode == 'delivery') return 'delivery';
    if (_selectedRideType == 'women_only') return 'women_only';
    if (_selectedRideType == 'comfort') return 'comfort';
    if (_selectedRideType == 'luxe') return 'luxe';
    if (_selectedRideType == 'moto') return 'moto';
    return 'standard';
  }

  @override
  void initState() {
    super.initState();
    if (widget.initialMode == 'delivery') {
      _selectedMode = 'delivery';
    }
    _getCurrentLocation();
  }

  /// Affiche « X min » ou « X h Y min » si durée > 60 min.
  static String _formatTripDurationMinutes(int totalMinutes) {
    if (totalMinutes <= 60) return '$totalMinutes min';
    final h = totalMinutes ~/ 60;
    final m = totalMinutes % 60;
    if (m <= 0) return '$h h';
    return '$h h $m min';
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
        _pickupLatLng = LatLng(position.latitude, position.longitude);
        _isLoading = false;
      });

      if (_pickupLatLng != null) {
        _addMarker(_pickupLatLng!, 'Départ', primaryGreen);
      }

      _mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(
          LatLng(position.latitude, position.longitude),
          18.0,
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
        18.0,
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
                _setMode('ride');
              },
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildModeChip(
              label: 'Livraison (moto)',
              icon: Icons.delivery_dining,
              assetPath: 'assets/images/ride_types/livraion.png',
              isSelected: _selectedMode == 'delivery',
              onTap: () {
                _setMode('delivery');
              },
            ),
          ),
        ],
      ),
    );
  }

  void _setMode(String mode) {
    if (_selectedMode == mode) return;

    setState(() {
      _selectedMode = mode;

      _pendingRideMongoId = null;

      _pickupController.clear();
      _destinationController.clear();
      _priceController.clear();

      _pickupAddress = '';
      _destinationAddress = '';
      _pickupLatLng = null;
      _destinationLatLng = null;
      _customPrice = 0;
      _estimatedDistance = 0;
      _suggestions = [];
      _isSearching = false;
      _isSearchingDriver = false;
      _nearbyVehicles = [];

      _markers.clear();
      _polylines.clear();
      _routeDurationSeconds = null;
      _isRouteLoading = false;
      _deliveryUrgent = false;
    });

    _searchDebounce?.cancel();
    _searchToken++;
  }

  Widget _buildModeChip({
    required String label,
    required IconData icon,
    String? assetPath,
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
            if (assetPath != null)
              Image.asset(
                assetPath,
                width: 18,
                height: 18,
                errorBuilder: (_, __, ___) => Icon(
                  icon,
                  size: 18,
                  color: isSelected ? Colors.white : primaryGreen,
                ),
              )
            else
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
          // Sélection du type de course (pas de types en livraison)
          if (_selectedMode != 'delivery') _buildRideTypeSelector(),
          
          // Points A et B
          _buildLocationInputs(),
          
          // Carte (un peu moins de hauteur pour laisser la place aux champs / prix)
          Expanded(
            flex: 4,
            child: _buildMap(),
          ),

          // Bas de page (scrollable pour éviter l'overflow et ne pas masquer les boutons)
          Expanded(
            flex: 6,
            child: SingleChildScrollView(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom + 16,
              ),
              child: _buildBottomSection(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRideTypeSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
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
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: accentBlack,
            ),
          ),
          const SizedBox(height: 6),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _rideTypes.map((type) {
                final isSelected = _selectedRideType == type['id'];
                final capacity = type['capacity'] as int? ?? 4;

                return Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: _buildRideTypeChip(
                    label: type['name'],
                    icon: type['icon'],
                    assetPath: type['assetPath'],
                    color: type['color'],
                    description: type['description'],
                    capacity: capacity,
                    isSelected: isSelected,
                    onTap: () {
                      setState(() {
                        _selectedRideType = type['id'];

                        if (_selectedMode != 'delivery') {
                          // Pour Luxe, pas de calcul automatique, juste un prix minimum de 15000 FCFA
                          if (_selectedRideType == 'luxe') {
                            _customPrice = 15000; // Prix minimum
                            _priceController.text = '';
                          }
                          if (_selectedRideType == 'moto' && _estimatedDistance > 0) {
                            _customPrice = (_motoPricePerKm * _estimatedDistance).round();
                          }
                        }
                      });
                    },
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
    String? assetPath,
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
        width: 190,
        padding: const EdgeInsets.all(10),
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
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: assetPath != null
                      ? Image.asset(
                          assetPath,
                          width: 18,
                          height: 18,
                          errorBuilder: (_, __, ___) => Icon(icon, color: color, size: 18),
                        )
                      : Icon(icon, color: color, size: 18),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: TextStyle(
                          fontSize: 14,
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
                          fontSize: 11,
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
    final bool hasValue = value.isNotEmpty;
    
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: hasValue ? primaryGreen.withOpacity(0.05) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: hasValue ? primaryGreen : Colors.grey[300]!,
            width: hasValue ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: iconColor, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (hasValue)
                    Text(
                      hint,
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  Text(
                    hasValue ? value : hint,
                    style: TextStyle(
                      fontSize: hasValue ? 15 : 15,
                      color: hasValue ? primaryGreen : Colors.grey[500],
                      fontWeight: hasValue ? FontWeight.bold : FontWeight.normal,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if (hasValue)
              Icon(Icons.check_circle, color: primaryGreen, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildMap() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    // ETA : priorité à la durée routière (Directions), sinon distance / 30 km/h
    int? etaMinutes;
    if (_routeDurationSeconds != null && _routeDurationSeconds! > 0) {
      etaMinutes = (_routeDurationSeconds! / 60).ceil();
    } else if (_estimatedDistance > 0) {
      etaMinutes = (_estimatedDistance / 30 * 60).ceil();
    }

    return Stack(
      children: [
        GoogleMap(
          initialCameraPosition: CameraPosition(
            target: _currentPosition != null
                ? LatLng(_currentPosition!.latitude, _currentPosition!.longitude)
                : SenegalMap.dakar,
            zoom: 18.0,
          ),
          style: kDuDuMapStyle,
          cameraTargetBounds: MapStyleService.senegalBounds,
          minMaxZoomPreference: MapStyleService.zoomPreference,
          onMapCreated: (controller) async {
            _mapController = controller;
            await MapStyleService.apply(controller);
          },
          markers: _markers,
          polylines: _polylines,
          myLocationEnabled: true,
          myLocationButtonEnabled: true,
          zoomControlsEnabled: false,
          mapType: MapType.normal,
          mapToolbarEnabled: false,
          compassEnabled: false,
          rotateGesturesEnabled: false,
          tiltGesturesEnabled: false,
          liteModeEnabled: false,
        ),

        if (_isRouteLoading)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: LinearProgressIndicator(
              minHeight: 3,
              backgroundColor: Colors.white24,
              color: primaryGreen,
            ),
          ),
        
        // Animation de recherche de chauffeur
        if (_isSearchingDriver)
          Positioned.fill(
            child: Container(
              color: Colors.black.withOpacity(0.3),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Icône de voiture tournante
                      TweenAnimationBuilder(
                        tween: Tween<double>(begin: 0, end: 1),
                        duration: const Duration(seconds: 2),
                        builder: (context, double value, child) {
                          return Transform.rotate(
                            angle: value * 2 * 3.14159,
                            child: Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                color: primaryGreen.withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.directions_car,
                                size: 40,
                                color: primaryGreen,
                              ),
                            ),
                          );
                        },
                        onEnd: () {
                          if (_isSearchingDriver && mounted) {
                            setState(() {});
                          }
                        },
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _selectedMode == 'delivery' 
                          ? 'Recherche de livreur...' 
                          : 'Recherche de chauffeur...',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: accentBlack,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Veuillez patienter',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        
        if (etaMinutes != null && _pickupLatLng != null && !_isSearchingDriver)
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
                      _formatTripDurationMinutes(etaMinutes),
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
      builder: (context) => StatefulBuilder(
        builder: (context, modalSetState) => DraggableScrollableSheet(
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
                              18.0,
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
                    onChanged: (value) {
                      final query = value.trim();
                      _searchDebounce?.cancel();

                      if (query.length <= 2) {
                        setState(() {
                          _suggestions = [];
                          _isSearching = false;
                        });
                        modalSetState(() {});
                        _searchToken++;
                        return;
                      }

                      final int token = ++_searchToken;
                      setState(() => _isSearching = true);
                      modalSetState(() {});

                      _searchDebounce = Timer(const Duration(milliseconds: 220), () async {
                        if (!mounted) return;
                        if (_searchToken != token) return;

                        final current = query;
                        if (current.length <= 2) return;

                        try {
                          final suggestions = await PlacesService.getPlaceSuggestions(
                            current,
                            userLat: _currentPosition?.latitude ?? 14.6928,
                            userLng: _currentPosition?.longitude ?? -17.4467,
                          );

                          if (!mounted) return;
                          if (_searchToken != token) return;

                          setState(() {
                            _suggestions = suggestions;
                            _isSearching = false;
                          });
                          if (mounted) {
                            modalSetState(() {});
                          }
                        } catch (e) {
                          print('Erreur recherche: $e');
                          if (!mounted) return;
                          if (_searchToken != token) return;
                          setState(() => _isSearching = false);
                          if (mounted) {
                            modalSetState(() {});
                          }
                        }
                      });
                    },
                  ),
                ),
                // Suggestions
                Expanded(
                  child: _suggestions.isEmpty
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: SingleChildScrollView(
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
                                          } else {
                                            _focusOnLatLng(LatLng(lat, lng));
                                          }
                                        },
                                      )),
                                ],
                              ),
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
                                print('🔍 Suggestion sélectionnée: ${suggestion.description}');
                                print('📍 localLat: ${suggestion.localLat}, localLng: ${suggestion.localLng}');
                                print('🆔 placeId: ${suggestion.placeId}, isLocal: ${suggestion.isLocal}');

                                double? lat;
                                double? lng;

                                // Si les coordonnées sont déjà présentes (HERE Maps ou suggestions locales)
                                if (suggestion.localLat != null && suggestion.localLng != null) {
                                  lat = suggestion.localLat;
                                  lng = suggestion.localLng;
                                  print('✅ Coordonnées disponibles directement: $lat, $lng');
                                } else {
                                  // Sinon, appeler l'API pour obtenir les coordonnées
                                  print('🔄 Récupération des coordonnées via API...');
                                  final details = await PlacesService.getPlaceDetails(suggestion.placeId);
                                  if (details != null) {
                                    lat = details.latitude;
                                    lng = details.longitude;
                                    print('✅ Coordonnées récupérées: $lat, $lng');
                                  } else {
                                    print('❌ Impossible de récupérer les coordonnées');
                                  }
                                }

                                if (lat != null && lng != null) {
                                  setState(() {
                                    if (isPickup) {
                                      _pickupAddress = suggestion.description;
                                      _pickupLatLng = LatLng(lat!, lng!);
                                      _addMarker(_pickupLatLng!, 'Départ', primaryGreen);
                                      print('✅ Pickup défini: $_pickupAddress');
                                    } else {
                                      _destinationAddress = suggestion.description;
                                      _destinationLatLng = LatLng(lat!, lng!);
                                      _addMarker(_destinationLatLng!, 'Destination', Colors.red);
                                      print('✅ Destination définie: $_destinationAddress');
                                    }
                                  });
                                  if (_pickupLatLng != null && _destinationLatLng != null) {
                                    _drawRoute();
                                  } else {
                                    _focusOnLatLng(LatLng(lat, lng));
                                  }
                                } else {
                                  print('❌ Aucune coordonnée disponible pour cette suggestion');
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
  }

  LatLngBounds _boundsFromLatLngs(List<LatLng> points) {
    final lats = points.map((p) => p.latitude).toList();
    final lngs = points.map((p) => p.longitude).toList();
    final southWest = LatLng(
      lats.reduce((a, b) => a < b ? a : b),
      lngs.reduce((a, b) => a < b ? a : b),
    );
    final northEast = LatLng(
      lats.reduce((a, b) => a > b ? a : b),
      lngs.reduce((a, b) => a > b ? a : b),
    );
    return LatLngBounds(southwest: southWest, northeast: northEast);
  }

  Future<void> _focusOnLatLng(LatLng target, {double zoom = 18}) async {
    if (_mapController == null) return;
    await _mapController!.animateCamera(
      CameraUpdate.newLatLngZoom(target, zoom),
    );
  }

  Future<void> _fitCameraToRoutePoints(
    List<LatLng> points, {
    double padding = 72,
  }) async {
    if (_mapController == null || points.length < 2) return;
    final bounds = _boundsFromLatLngs(points);
    await _mapController!.animateCamera(
      CameraUpdate.newLatLngBounds(bounds, padding),
    );
  }

  void _generateNearbyCarMarkers() {
    if (_pickupLatLng == null) return;

    final random = math.Random();
    final List<Marker> carMarkers = [];
    final List<LatLng> vehicles = [];

    final String rideType = _backendRideType;
    final int count = rideType == 'comfort' ? 3 : 5;
    final String markerPrefix = rideType == 'delivery' ? 'moto_' : 'car_';
    final double hue = rideType == 'delivery' ? BitmapDescriptor.hueOrange : BitmapDescriptor.hueYellow;

    for (int i = 0; i < count; i++) {
      final dx = (random.nextDouble() - 0.5) / 500; // petit décalage latitude
      final dy = (random.nextDouble() - 0.5) / 500; // petit décalage longitude
      final carPosition = LatLng(
        _pickupLatLng!.latitude + dx,
        _pickupLatLng!.longitude + dy,
      );

      vehicles.add(carPosition);

      carMarkers.add(
        Marker(
          markerId: MarkerId('${markerPrefix}$i'),
          position: carPosition,
          icon: BitmapDescriptor.defaultMarkerWithHue(hue),
          infoWindow: InfoWindow(
            title: rideType == 'delivery' ? 'Livreur à proximité' : 'Chauffeur à proximité',
          ),
        ),
      );
    }

    setState(() {
      _nearbyVehicles = vehicles;
      _markers.removeWhere((m) => m.markerId.value.startsWith('car_') || m.markerId.value.startsWith('moto_'));
      _markers.addAll(carMarkers);
    });

    // Recentrer la caméra sur le point de départ pour bien voir les voitures
    _mapController?.animateCamera(
      CameraUpdate.newLatLngZoom(_pickupLatLng!, 18.0),
    );
  }

  void _clearNearbyCarMarkers() {
    setState(() {
      _markers.removeWhere((m) => m.markerId.value.startsWith('car_') || m.markerId.value.startsWith('moto_'));
    });
  }

  void _clearPassengerRideSocketListeners() {
    final s = SocketService();
    s.onRideAccepted = null;
    s.onRideRefusedByDriver = null;
    s.onRideCounterOffer = null;
  }

  Future<void> _drawRoute() async {
    if (_pickupLatLng == null || _destinationLatLng == null) return;

    final p0 = _pickupLatLng!;
    final p1 = _destinationLatLng!;

    final haversineKm = _calculateDistance(
      p0.latitude,
      p0.longitude,
      p1.latitude,
      p1.longitude,
    );

    if (!mounted) return;
    setState(() {
      _isRouteLoading = true;
      _estimatedDistance = haversineKm;
      _routeDurationSeconds = null;
      if (_selectedMode != 'delivery' && _selectedRideType == 'moto') {
        _customPrice =
            (_motoPricePerKm * (haversineKm <= 0 ? 0 : haversineKm)).round();
      }
    });

    final route = await DirectionsService.getDrivingRoute(p0, p1);

    if (!mounted) return;

    if (route == null || route.points.length < 2) {
      setState(() {
        _isRouteLoading = false;
        _polylines.clear();
        // Ligne d’attente (approximation) pour que l’itinéraire reste visible
        _polylines.add(
          Polyline(
            polylineId: const PolylineId('route_fallback'),
            points: [p0, p1],
            color: Colors.deepOrange.shade600,
            width: 4,
            patterns: [PatternItem.dash(20), PatternItem.gap(12)],
          ),
        );
        _routeDurationSeconds = null;
        _estimatedDistance = haversineKm;
        if (_selectedMode != 'delivery' && _selectedRideType == 'moto') {
          _customPrice = (_motoPricePerKm *
                  (haversineKm <= 0 ? 0 : haversineKm))
              .round();
        }
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Itinéraire détaillé indisponible. Un trajet approximatif est affiché sur la carte.',
            ),
            backgroundColor: Colors.deepOrange,
            duration: Duration(seconds: 4),
          ),
        );
      }
      await _fitCameraToRoutePoints([p0, p1], padding: 72);
      return;
    }

    final linePoints = route.points;
    final distanceKm = route.distanceKm;
    final durationSec = route.durationSeconds;

    setState(() {
      _isRouteLoading = false;
      _estimatedDistance = distanceKm;
      _routeDurationSeconds = durationSec;

      if (_selectedMode != 'delivery' && _selectedRideType == 'moto') {
        _customPrice = (_motoPricePerKm *
                (_estimatedDistance <= 0 ? 0 : _estimatedDistance))
            .round();
      }

      _polylines.clear();
      _polylines.add(
        Polyline(
          polylineId: const PolylineId('route'),
          points: linePoints,
          color: primaryGreen,
          width: 5,
          jointType: JointType.round,
          startCap: Cap.roundCap,
          endCap: Cap.roundCap,
        ),
      );
    });

    if (!mounted) return;
    await _fitCameraToRoutePoints(linePoints, padding: 72);
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
            _buildPriceInput(),
            if (_selectedMode == 'delivery') ...[
              const SizedBox(height: 4),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text(
                  'Livraison urgente',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                ),
                subtitle: const Text(
                  'Activé : livreur dédié à votre course. Désactivé (défaut) : le livreur peut combiner avec une autre livraison non urgente.',
                  style: TextStyle(fontSize: 11),
                ),
                value: _deliveryUrgent,
                onChanged: (v) => setState(() => _deliveryUrgent = v),
              ),
            ],
            const SizedBox(height: 10),

            // Liste des véhicules avec temps d'arrivée estimé
            _buildNearbyVehiclesList(),

            const SizedBox(height: 16),
            
            // Bouton Continuer vers la page de confirmation
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _pickupAddress.isNotEmpty && 
                           _destinationAddress.isNotEmpty &&
                           _pickupLatLng != null &&
                           _destinationLatLng != null &&
                           (_backendRideType == 'luxe' ? _customPrice >= 15000 : 
                            _backendRideType == 'moto' ? _customPrice > 0 : 
                            _customPrice > 0)
                    ? _navigateToConfirmation
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryGreen,
                  disabledBackgroundColor: Colors.grey[300],
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'Continuer',
                  style: TextStyle(
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
    final isMoto = _selectedMode != 'delivery' && _selectedRideType == 'moto';
    final isLuxe = _selectedMode != 'delivery' && _selectedRideType == 'luxe';

    if (isMoto) {
      final total = (_motoPricePerKm * (_estimatedDistance <= 0 ? 0 : _estimatedDistance)).round();
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: lightGreen.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: lightGreen.withOpacity(0.3), width: 2),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.payments_outlined, color: primaryGreen, size: 18),
                const SizedBox(width: 8),
                const Text(
                  'Prix / km (Moto)',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: accentBlack,
                  ),
                ),
                const Spacer(),
                Text(
                  '${_motoPricePerKm.round()} FCFA/km',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: primaryGreen,
                  ),
                ),
              ],
            ),
            Slider(
              min: 500,
              max: 5000,
              divisions: 45,
              value: _motoPricePerKm.clamp(500, 5000),
              activeColor: primaryGreen,
              onChanged: (v) {
                setState(() {
                  _motoPricePerKm = v;
                  _customPrice = (_motoPricePerKm * (_estimatedDistance <= 0 ? 0 : _estimatedDistance)).round();
                });
              },
            ),
            Row(
              children: [
                Text(
                  'Total estimé: $total FCFA',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: accentBlack,
                  ),
                ),
                const Spacer(),
                Text(
                  'Min 500 • Max 5000',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    }

    if (isLuxe) {
      // Pour Luxe : prix de base 15000 FCFA, le client peut proposer le montant qu'il souhaite
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.black.withOpacity(0.05),
              Colors.grey.withOpacity(0.05),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.black.withOpacity(0.3), width: 2),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.diamond, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Service Luxe Premium',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      Text(
                        'Prix de base : 15 000 FCFA',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.black54,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              'Proposez votre prix :',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.black.withOpacity(0.2)),
              ),
              child: TextField(
                controller: _priceController,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                textAlign: TextAlign.right,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
                decoration: InputDecoration(
                  hintText: '15000',
                  hintStyle: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[300],
                  ),
                  suffixText: 'FCFA',
                  suffixStyle: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                ),
                onChanged: (value) {
                  setState(() {
                    final enteredPrice = int.tryParse(value) ?? 15000;
                    _customPrice = enteredPrice < 15000 ? 15000 : enteredPrice;
                  });
                },
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.info_outline, size: 14, color: Colors.grey[600]),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Vous définissez le montant selon votre destination (minimum 15 000 FCFA)',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey[600],
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    }

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
              textInputAction: TextInputAction.done,
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
              onSubmitted: (_) => FocusScope.of(context).unfocus(),
            ),
          ),
          TextButton(
            onPressed: () => FocusScope.of(context).unfocus(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _navigateToConfirmation() async {
    if (_pickupLatLng == null || _destinationLatLng == null) {
      return;
    }

    // Naviguer vers la page de confirmation
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RideConfirmationScreen(
          pickupAddress: _pickupAddress,
          destinationAddress: _destinationAddress,
          pickupLatLng: _pickupLatLng!,
          destinationLatLng: _destinationLatLng!,
          distance: _estimatedDistance,
          selectedRideType: _selectedRideType,
          selectedMode: _selectedMode,
          initialPrice: _customPrice,
        ),
      ),
    );

    // Si l'utilisateur a confirmé avec un prix
    if (result != null && result is Map<String, dynamic>) {
      setState(() {
        _customPrice = result['price'] ?? 0;
        if (_selectedMode != 'delivery' && _selectedRideType == 'moto') {
          final distance = _estimatedDistance <= 0 ? 0 : _estimatedDistance;
          if (distance > 0) {
            _motoPricePerKm = (_customPrice / distance).clamp(500, 5000).toDouble();
          }
        }
      });
      
      // Lancer la confirmation de la course
      _confirmRide();
    }
  }

  void _confirmRide() async {
    final isMotoRide = _backendRideType == 'moto';
    final isLuxeRide = _backendRideType == 'luxe';

    final hasLocations = _pickupLatLng != null && _destinationLatLng != null;
    final hasClassicPrice = _customPrice > 0;
    final hasMotoPricePerKm = _motoPricePerKm >= 500 && _motoPricePerKm <= 5000;

    if (!hasLocations || (!isLuxeRide && !isMotoRide && !hasClassicPrice) || (isMotoRide && !hasMotoPricePerKm)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez remplir tous les champs')),
      );
      return;
    }

    // Sauvegarder la destination dans l'historique
    if (_destinationAddress.isNotEmpty && _destinationLatLng != null) {
      await SearchHistoryService.addToHistory(
        SearchHistoryItem(
          title: _destinationAddress.split(',').first.trim(),
          subtitle: _destinationAddress,
          latitude: _destinationLatLng!.latitude,
          longitude: _destinationLatLng!.longitude,
        ),
      );
    }

    if (mounted) {
      setState(() {
        _isSearchingDriver = true;
      });
      _generateNearbyCarMarkers();
    }

    final searchingLabel = _selectedMode == 'delivery' ? 'Recherche de livreur...' : 'Recherche de chauffeur...';
    bool cancelRequested = false;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(searchingLabel),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () {
                cancelRequested = true;
                Navigator.pop(context);
                if (!mounted) return;
                _clearNearbyCarMarkers();
                setState(() {
                  _isSearchingDriver = false;
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Demande annulée'),
                    backgroundColor: Colors.orange,
                  ),
                );
              },
              child: const Text('Annuler', style: TextStyle(color: Colors.red)),
            ),
          ],
        ),
      ),
    );

    try {
      // Envoyer la demande au backend
      final isMotoRide = _backendRideType == 'moto';
      final isLuxeRide = _backendRideType == 'luxe';

      final response = await ApiService.createRide(
        pickupLatitude: _pickupLatLng!.latitude,
        pickupLongitude: _pickupLatLng!.longitude,
        pickupAddress: _pickupAddress,
        destinationLatitude: _destinationLatLng!.latitude,
        destinationLongitude: _destinationLatLng!.longitude,
        destinationAddress: _destinationAddress,
        rideType: _backendRideType,
        customPrice: (isLuxeRide || (!isMotoRide && !isLuxeRide && _customPrice > 0)) ? _customPrice : null,
        customPricePerKm: isMotoRide ? _motoPricePerKm : null,
        estimatedDistance: _estimatedDistance,
        paymentMethod: 'cash',
        isUrgentDelivery: _selectedMode == 'delivery' ? _deliveryUrgent : null,
      );

      if (response.success) {
        String? rideMongoId;
        final raw = response.data;
        String? status;
        if (raw is Map) {
          final data = raw['data'];
          if (data is Map) {
            final s = data['status'];
            if (s is String) status = s;
            final dynamic rid = data['rideId'] ?? (data['ride'] is Map ? (data['ride']['id'] ?? data['ride']['_id']) : null);
            if (rid != null) rideMongoId = rid.toString();
          }
        }

        if (rideMongoId != null && rideMongoId.isNotEmpty) {
          _pendingRideMongoId = rideMongoId;
        }

        if (cancelRequested) {
          if (rideMongoId != null && rideMongoId.isNotEmpty) {
            try {
              await ApiService.cancelRide(rideMongoId, 'passenger_cancelled');
            } catch (_) {}
          }
          _pendingRideMongoId = null;
          return;
        }

        if (status == 'no_driver') {
          await Future.delayed(const Duration(seconds: 2));

          if (mounted) {
            Navigator.pop(context);
          }

          if (mounted) {
            _clearNearbyCarMarkers();
            setState(() {
              _isSearchingDriver = false;
            });

            final String message;
            if (_selectedMode == 'delivery') {
              message = 'Aucun livreur disponible pour le moment. Veuillez réessayer.';
            } else if (_backendRideType == 'women_only') {
              message = 'Aucune chauffeuse disponible pour le moment. Veuillez réessayer.';
            } else {
              message = 'Aucun chauffeur disponible pour le moment. Veuillez réessayer.';
            }

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(message),
                backgroundColor: Colors.orange,
              ),
            );
          }
          return;
        }

        if (mounted) {
          Navigator.pop(context);
        }

        // Écoute après création course et _pendingRideMongoId (évite course fantôme / refus prématuré)
        final pendingId = _pendingRideMongoId;
        if (pendingId != null && pendingId.isNotEmpty) {
          final socketService = SocketService();
          socketService.onRideRefusedByDriver = (data) {
            if (!mounted) return;
            final rideId = data['rideId']?.toString();
            final msg = data['message']?.toString() ??
                'Un chauffeur a refusé. Nous cherchons un autre chauffeur.';
            if (rideId != null && rideId == pendingId) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(msg),
                  backgroundColor: Colors.blueGrey,
                  duration: const Duration(seconds: 5),
                ),
              );
            }
          };
          socketService.onRideCounterOffer = (data) async {
            if (!mounted) return;
            final rideId = data['rideId']?.toString();
            if (rideId == null || rideId != pendingId) return;

            final add = (data['additionalAmount'] as num?)?.toInt();
            final proposed = (data['proposedTotalPrice'] as num?)?.toInt();
            final base = (data['baseTotalPrice'] as num?)?.toInt();
            final driverRaw = data['driver'];
            String driverName = 'Le chauffeur';
            if (driverRaw is Map) {
              final fn = driverRaw['firstName']?.toString() ?? '';
              final ln = driverRaw['lastName']?.toString() ?? '';
              final n = ('$fn $ln').trim();
              if (n.isNotEmpty) driverName = n;
            }

            final accept = await showDialog<bool>(
              context: context,
              barrierDismissible: false,
              builder: (ctx) => AlertDialog(
                title: const Text('Nouvelle proposition de prix'),
                content: Text(
                  '$driverName propose un supplément de ${add ?? '—'} FCFA '
                  'sur votre offre (${base ?? '—'} FCFA). '
                  'Nouveau total : ${proposed ?? '—'} FCFA.',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    child: const Text('Refuser'),
                  ),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(ctx, true),
                    style: ElevatedButton.styleFrom(backgroundColor: primaryGreen),
                    child: const Text('Accepter'),
                  ),
                ],
              ),
            );

            if (!mounted || accept == null) return;
            final res = await ApiService.respondToRideCounterOffer(
              rideId: rideId,
              accept: accept,
            );
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  res.success
                      ? (accept
                          ? 'Prix mis à jour. Le chauffeur peut accepter la course.'
                          : 'Vous avez refusé la proposition.')
                      : res.message,
                ),
                backgroundColor: res.success ? primaryGreen : Colors.red,
              ),
            );
            if (res.success && accept && proposed != null) {
              setState(() => _customPrice = proposed);
            }
          };
          socketService.onRideAccepted = (data) {
            if (!mounted) return;
            _clearPassengerRideSocketListeners();

            try {
              // Fermer le dialogue « Demande envoyée / attente chauffeur » s’il est encore ouvert
              if (Navigator.canPop(context)) {
                Navigator.of(context).pop();
              }
              if (mounted) {
                setState(() {
                  _isSearchingDriver = false;
                });
              }

              Map<String, dynamic> asMap(dynamic v) {
                if (v is Map) return Map<String, dynamic>.from(v);
                return {};
              }

              final rideId = data['rideId']?.toString();
              if (rideId == null || _pickupLatLng == null || _destinationLatLng == null) {
                return;
              }

              final driver = asMap(data['driver']);
              final vehicle = asMap(driver['vehicle']);

              if (_selectedMode == 'delivery') {
                final confirmationCode = data['confirmationCode']?.toString() ?? '----';
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => DeliveryTrackingScreen(
                      deliveryId: rideId,
                      confirmationCode: confirmationCode,
                    ),
                  ),
                );
              } else {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => RideTrackingScreen(
                      rideId: rideId,
                      vehicleType: 'car',
                      pickupLocation: {
                        'latitude': _pickupLatLng!.latitude,
                        'longitude': _pickupLatLng!.longitude,
                      },
                      destinationLocation: {
                        'latitude': _destinationLatLng!.latitude,
                        'longitude': _destinationLatLng!.longitude,
                      },
                      pickupAddressLabel: _pickupAddress,
                      destinationAddressLabel: _destinationAddress,
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
              }
            } catch (e) {
              print('Erreur lors de l\'ouverture du tracking: $e');
            }
          };
        }

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
                    _selectedMode == 'delivery'
                        ? 'En attente d\'un livreur...\nPrix proposé: $_customPrice FCFA'
                        : 'En attente d\'un chauffeur...\nPrix proposé: $_customPrice FCFA',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 24),
                  TextButton(
                    onPressed: () async {
                      final rideId = _pendingRideMongoId;
                      if (rideId == null || rideId.isEmpty) {
                        Navigator.pop(context);
                        if (mounted) {
                          _clearPassengerRideSocketListeners();
                          _clearNearbyCarMarkers();
                          setState(() {
                            _isSearchingDriver = false;
                          });
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Demande annulée'),
                              backgroundColor: Colors.orange,
                            ),
                          );
                          Navigator.pop(context);
                        }
                        return;
                      }

                      try {
                        final cancelRes = await ApiService.cancelRide(rideId, 'passenger_cancelled');
                        Navigator.pop(context);
                        if (mounted) {
                          _pendingRideMongoId = null;
                          _clearPassengerRideSocketListeners();
                          _clearNearbyCarMarkers();
                          setState(() {
                            _isSearchingDriver = false;
                          });
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(cancelRes.success ? 'Demande annulée' : 'Annulation échouée: ${cancelRes.message}'),
                              backgroundColor: cancelRes.success ? Colors.orange : Colors.red,
                            ),
                          );
                          Navigator.pop(context);
                        }
                      } catch (e) {
                        Navigator.pop(context);
                        if (mounted) {
                          _clearPassengerRideSocketListeners();
                          _clearNearbyCarMarkers();
                          setState(() {
                            _isSearchingDriver = false;
                          });
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Erreur annulation: $e'),
                              backgroundColor: Colors.red,
                            ),
                          );
                          Navigator.pop(context);
                        }
                      }
                    },
                    child: const Text('Annuler la demande', style: TextStyle(color: Colors.red)),
                  ),
                ],
              ),
            ),
          );
        }
      } else {
        final lowerMsg = response.message.toLowerCase();
        final isAuthExpired = lowerMsg.contains('token expir') ||
            lowerMsg.contains('session expir') ||
            lowerMsg.contains('jwt') ||
            lowerMsg.contains('unauthorized') ||
            lowerMsg.contains('non autoris') ||
            lowerMsg.contains('accès requis') ||
            lowerMsg.contains('authentification');

        if (mounted) {
          Navigator.pop(context);
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

          if (isAuthExpired) {
            await context.read<AuthProvider>().clearLocalSession(
                  message: response.message,
                );
            if (!mounted) return;
            Navigator.of(context).pushNamedAndRemoveUntil(
                '/login', (route) => false);
          }
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
    _searchDebounce?.cancel();
    _pickupController.dispose();
    _destinationController.dispose();
    _priceController.dispose();
    super.dispose();
  }
}
