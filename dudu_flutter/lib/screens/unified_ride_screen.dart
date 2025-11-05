import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:math' as math;
import '../services/api_service.dart';
import '../services/places_service.dart';

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
  String _selectedRideType = 'standard';
  String _pickupAddress = '';
  String _destinationAddress = '';
  LatLng? _pickupLatLng;
  LatLng? _destinationLatLng;
  int _customPrice = 0;
  double _estimatedDistance = 0;
  List<PlaceSuggestion> _suggestions = [];
  
  // Types de courses disponibles
  final List<Map<String, dynamic>> _rideTypes = [
    {
      'id': 'standard',
      'name': 'Standard',
      'icon': Icons.directions_car,
      'color': Color(0xFF0d5d36),
      'description': 'Course classique',
    },
    {
      'id': 'express',
      'name': 'Express',
      'icon': Icons.flash_on,
      'color': Colors.orange,
      'description': 'Course rapide',
      'badge': 'POPULAIRE',
    },
    {
      'id': 'shared',
      'name': 'Covoiturage',
      'icon': Icons.people,
      'color': Colors.blue,
      'description': 'Partage de trajet',
      'badge': '-30%',
    },
    {
      'id': 'women_only',
      'name': 'Femmes',
      'icon': Icons.woman,
      'color': Colors.pink,
      'description': 'Femmes uniquement',
    },
  ];

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
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
      _isLoading = false;
    });

    _mapController?.animateCamera(
      CameraUpdate.newLatLngZoom(
        const LatLng(14.6928, -17.4467),
        13.0,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Commander une course'),
        backgroundColor: primaryGreen,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Sélection du type de course
          _buildRideTypeSelector(),
          
          // Points A et B
          _buildLocationInputs(),
          
          // Carte
          Expanded(
            child: _buildMap(),
          ),
          
          // Prix libre et bouton de confirmation
          _buildBottomSection(),
        ],
      ),
    );
  }

  Widget _buildRideTypeSelector() {
    return Container(
      padding: const EdgeInsets.all(16),
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
            'Type de course',
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
                return Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: _buildRideTypeChip(
                    type['name'],
                    type['icon'],
                    type['color'],
                    isSelected,
                    () => setState(() => _selectedRideType = type['id']),
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

  Widget _buildRideTypeChip(
    String label,
    IconData icon,
    Color color,
    bool isSelected,
    VoidCallback onTap, {
    String? badge,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? color : Colors.white,
          border: Border.all(
            color: isSelected ? color : Colors.grey[300]!,
            width: 2,
          ),
          borderRadius: BorderRadius.circular(25),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.white : color,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : accentBlack,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
            if (badge != null) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.white.withOpacity(0.3) : color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  badge,
                  style: TextStyle(
                    color: isSelected ? Colors.white : color,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
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

    return GoogleMap(
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
              // Bouton "Ma position actuelle"
              if (isPickup)
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      Navigator.pop(context);
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
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Localisation non disponible'),
                          ),
                        );
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
                    hintText: isPickup ? 'Rechercher le point de départ' : 'Rechercher la destination',
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
                            leading: const Icon(Icons.location_on),
                            title: Text(suggestion.mainText),
                            subtitle: Text(suggestion.secondaryText),
                            onTap: () async {
                              Navigator.pop(context);
                              final details = await PlacesService.getPlaceDetails(suggestion.placeId);
                              if (details != null) {
                                setState(() {
                                  if (isPickup) {
                                    _pickupAddress = suggestion.description;
                                    _pickupLatLng = LatLng(details.latitude, details.longitude);
                                    _addMarker(_pickupLatLng!, 'Départ', primaryGreen);
                                  } else {
                                    _destinationAddress = suggestion.description;
                                    _destinationLatLng = LatLng(details.latitude, details.longitude);
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
      padding: const EdgeInsets.all(20),
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
            // Prix libre
            _buildPriceInput(),
            
            const SizedBox(height: 16),
            
            // Bouton de confirmation
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: _customPrice > 0 && 
                           _pickupAddress.isNotEmpty && 
                           _destinationAddress.isNotEmpty &&
                           _pickupLatLng != null &&
                           _destinationLatLng != null
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
      padding: const EdgeInsets.all(16),
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
              Icon(Icons.payments_outlined, color: primaryGreen, size: 20),
              const SizedBox(width: 8),
              const Text(
                'Votre prix libre',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: accentBlack,
                ),
              ),
              const Spacer(),
              Icon(Icons.info_outline, color: Colors.grey[600], size: 18),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _priceController,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: primaryGreen,
            ),
            decoration: InputDecoration(
              hintText: '0',
              hintStyle: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.grey[400],
              ),
              suffixText: 'FCFA',
              suffixStyle: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: accentBlack,
              ),
              border: InputBorder.none,
              contentPadding: EdgeInsets.zero,
            ),
            onChanged: (value) {
              setState(() {
                _customPrice = int.tryParse(value) ?? 0;
              });
            },
          ),
          const SizedBox(height: 8),
          Text(
            'Le chauffeur acceptera ou refusera selon votre offre',
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

  void _confirmRide() async {
    if (_pickupLatLng == null || _destinationLatLng == null || _customPrice == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez remplir tous les champs')),
      );
      return;
    }

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
      );

      if (mounted) Navigator.pop(context);

      if (response.success) {
        if (mounted) {
          // Trouver le nom du type de course
          final rideTypeName = _rideTypes.firstWhere(
            (t) => t['id'] == _selectedRideType,
            orElse: () => {'name': _selectedRideType}
          )['name'];
          
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('✅ Demande envoyée'),
              content: Text(
                'Votre demande de course a été envoyée aux chauffeurs disponibles.\n\n'
                'Type: $rideTypeName\n'
                'Prix proposé: $_customPrice FCFA\n'
                'Distance: ${_estimatedDistance.toStringAsFixed(1)} km',
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
      } else {
        if (mounted) {
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
