import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import '../services/geocoding_service.dart';
import '../services/places_service.dart' as places;
import '../constants/senegal_map.dart';
import '../services/map_style_service.dart';
import '../widgets/address_autocomplete.dart';

class InDriverStyleScreen extends StatefulWidget {
  const InDriverStyleScreen({Key? key}) : super(key: key);

  @override
  State<InDriverStyleScreen> createState() => _InDriverStyleScreenState();
}

class _InDriverStyleScreenState extends State<InDriverStyleScreen> {
  GoogleMapController? _mapController;
  places.PlaceSuggestion? _pickupPlace;
  places.PlaceSuggestion? _destinationPlace;
  
  // États de l'interface
  bool _showPickupField = false;
  bool _showDestinationField = false;
  bool _isCalculatingRoute = false;
  bool _showDriverSelection = false;
  
  // Prix et négociation (style InDriver)
  double _suggestedPrice = 0.0;
  double _myOfferPrice = 0.0;
  double _estimatedDistance = 0.0;
  int _estimatedDuration = 0;
  
  // Chauffeurs disponibles
  List<Map<String, dynamic>> _availableDrivers = [];
  
  // Position par défaut : Dakar
  final LatLng _dakarCenter = SenegalMap.dakar;

  LatLng _latLngOrFallback(places.PlaceSuggestion? p, LatLng fallback) {
    final lat = p?.localLat;
    final lng = p?.localLng;
    if (lat == null || lng == null) return fallback;
    return LatLng(lat, lng);
  }
  
  // Types de véhicules
  final List<Map<String, dynamic>> _vehicleTypes = [
    {
      'id': 'standard',
      'name': 'Standard',
      'icon': Icons.directions_car,
      'basePrice': 1.0,
      'description': 'Voiture standard',
      'color': Colors.blue,
      'capacity': 4,
    },
    {
      'id': 'comfort',
      'name': 'Confort',
      'icon': Icons.directions_car,
      'basePrice': 1.3,
      'description': 'Voiture confortable',
      'color': Colors.green,
      'capacity': 4,
    },
    {
      'id': 'premium',
      'name': 'Premium',
      'icon': Icons.star,
      'basePrice': 1.8,
      'description': 'Voiture haut de gamme',
      'color': Colors.purple,
      'capacity': 4,
    },
    {
      'id': 'moto',
      'name': 'Moto',
      'icon': Icons.motorcycle,
      'basePrice': 0.6,
      'description': 'Moto pour livraison',
      'color': Colors.orange,
      'capacity': 1,
    },
  ];
  
  String _selectedVehicleType = 'standard';

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
    _loadAvailableDrivers();
  }

  Future<void> _getCurrentLocation() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        return;
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      if (mounted) {
        setState(() {
          _pickupPlace = places.PlaceSuggestion(
            placeId: 'current_location',
            description: 'Position actuelle',
            mainText: 'Ma position',
            secondaryText: 'Position actuelle',
            localLat: position.latitude,
            localLng: position.longitude,
          );
        });

        _mapController?.animateCamera(
          CameraUpdate.newLatLng(LatLng(position.latitude, position.longitude)),
        );
      }
    } catch (e) {
      print('Erreur localisation: $e');
    }
  }

  void _loadAvailableDrivers() {
    // Simuler des chauffeurs disponibles
    _availableDrivers = [
      {
        'id': '1',
        'name': 'Amadou Diallo',
        'rating': 4.8,
        'trips': 1250,
        'vehicle': 'Toyota Corolla',
        'plate': 'DK-1234-AB',
        'distance': 0.8,
        'eta': 3,
        'price': 2500,
        'photo': '👨🏿',
        'isOnline': true,
      },
      {
        'id': '2',
        'name': 'Fatou Sarr',
        'rating': 4.9,
        'trips': 2100,
        'vehicle': 'Honda Civic',
        'plate': 'DK-5678-CD',
        'distance': 1.2,
        'eta': 5,
        'price': 2800,
        'photo': '👩🏿',
        'isOnline': true,
      },
      {
        'id': '3',
        'name': 'Moussa Ba',
        'rating': 4.7,
        'trips': 890,
        'vehicle': 'Nissan Sentra',
        'plate': 'DK-9012-EF',
        'distance': 2.1,
        'eta': 8,
        'price': 2200,
        'photo': '👨🏿',
        'isOnline': true,
      },
    ];
  }

  void _onPickupSelected(places.PlaceSuggestion place) {
    print('🔍 Pickup sélectionné: ${place.description}');
    print('📍 Coordonnées: ${place.localLat}, ${place.localLng}');
    
    setState(() {
      _pickupPlace = place;
      _showPickupField = false;
    });
    
    if (place.localLat != null && place.localLng != null) {
      _mapController?.animateCamera(
        CameraUpdate.newLatLng(LatLng(place.localLat!, place.localLng!)),
      );
    }
    
    if (_destinationPlace != null) {
      _calculateRoute();
    }
  }

  void _onDestinationSelected(places.PlaceSuggestion place) {
    print('🔍 Destination sélectionnée: ${place.description}');
    print('📍 Coordonnées: ${place.localLat}, ${place.localLng}');
    
    setState(() {
      _destinationPlace = place;
      _showDestinationField = false;
    });
    
    if (place.localLat != null && place.localLng != null) {
      _mapController?.animateCamera(
        CameraUpdate.newLatLng(LatLng(place.localLat!, place.localLng!)),
      );
    }
    
    if (_pickupPlace != null) {
      _calculateRoute();
    }
  }

  Future<void> _calculateRoute() async {
    if (_pickupPlace == null || _destinationPlace == null) return;

    setState(() {
      _isCalculatingRoute = true;
    });

    try {
      // Simuler le calcul d'itinéraire
      await Future.delayed(const Duration(seconds: 1));
      
      // Calculer la distance
      double distance = GeocodingService.calculateDistance(
        _pickupPlace!.localLat ?? 0.0,
        _pickupPlace!.localLng ?? 0.0,
        _destinationPlace!.localLat ?? 0.0,
        _destinationPlace!.localLng ?? 0.0,
      );

      // Calculer le prix suggéré
      double basePrice = 1000;
      double distancePrice = distance * 500;
      double timePrice = 300;
      
      // Multiplicateur selon le type de véhicule
      double multiplier = _vehicleTypes.firstWhere((type) => type['id'] == _selectedVehicleType)['basePrice'];
      
      setState(() {
        _estimatedDistance = distance;
        _estimatedDuration = (distance * 2).round();
        _suggestedPrice = (basePrice + distancePrice + timePrice) * multiplier;
        _myOfferPrice = _suggestedPrice;
        _isCalculatingRoute = false;
      });
    } catch (e) {
      setState(() {
        _isCalculatingRoute = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Carte Google Maps
          GoogleMap(
            cameraTargetBounds: MapStyleService.senegalBounds,
            minMaxZoomPreference: MapStyleService.zoomPreference,
            onMapCreated: (GoogleMapController controller) async {
              _mapController = controller;
              await MapStyleService.apply(controller);
            },
            initialCameraPosition: CameraPosition(
              target: _dakarCenter,
              zoom: 15.0,
            ),
            markers: _buildMarkers(),
            polylines: _buildPolylines(),
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            onTap: (LatLng position) {
              setState(() {
                _showPickupField = false;
                _showDestinationField = false;
                _showDriverSelection = false;
              });
            },
          ),
          
          // Interface utilisateur
          SafeArea(
            child: Column(
              children: [
                // Barre de recherche en haut
                _buildSearchBar(),
                
                const Spacer(),
                
                // Panneau de sélection de chauffeurs (style InDriver)
                if (_pickupPlace != null && _destinationPlace != null)
                  _showDriverSelection ? _buildDriverSelectionPanel() : _buildRideRequestPanel(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          // Champ de départ
          InkWell(
            onTap: () {
              setState(() {
                _showPickupField = !_showPickupField;
                _showDestinationField = false;
                _showDriverSelection = false;
              });
            },
            child: Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: const BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _pickupPlace?.description ?? 'D\'où partez-vous ?',
                      style: TextStyle(
                        fontSize: 16,
                        color: _pickupPlace != null ? Colors.black : Colors.grey[600],
                      ),
                    ),
                  ),
                  if (_pickupPlace != null)
                    IconButton(
                      icon: const Icon(Icons.clear, size: 20),
                      onPressed: () {
                        setState(() {
                          _pickupPlace = null;
                        });
                      },
                    ),
                ],
              ),
            ),
          ),
          
          // Champ de destination
          InkWell(
            onTap: () {
              setState(() {
                _showDestinationField = !_showDestinationField;
                _showPickupField = false;
                _showDriverSelection = false;
              });
            },
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(color: Colors.grey[200]!),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _destinationPlace?.description ?? 'Où allez-vous ?',
                      style: TextStyle(
                        fontSize: 16,
                        color: _destinationPlace != null ? Colors.black : Colors.grey[600],
                      ),
                    ),
                  ),
                  if (_destinationPlace != null)
                    IconButton(
                      icon: const Icon(Icons.clear, size: 20),
                      onPressed: () {
                        setState(() {
                          _destinationPlace = null;
                        });
                      },
                    ),
                ],
              ),
            ),
          ),
          
          // Champs de recherche avec autocomplétion
          if (_showPickupField)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(color: Colors.grey[200]!),
                ),
              ),
              child: AddressAutocomplete(
                label: 'Départ',
                hint: 'Saisissez votre adresse de départ',
                icon: Icons.location_on,
                onPlaceSelected: _onPickupSelected,
                initialValue: _pickupPlace?.description,
              ),
            ),
          
          if (_showDestinationField)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(color: Colors.grey[200]!),
                ),
              ),
              child: AddressAutocomplete(
                label: 'Destination',
                hint: 'Saisissez votre destination',
                icon: Icons.flag,
                onPlaceSelected: _onDestinationSelected,
                initialValue: _destinationPlace?.description,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildRideRequestPanel() {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Column(
        children: [
          // Informations de l'itinéraire
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.route, color: Colors.blue[600]),
                const SizedBox(width: 8),
                Text(
                  '${_estimatedDistance.toStringAsFixed(1)} km • ${_estimatedDuration} min',
                  style: TextStyle(
                    color: Colors.blue[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const Spacer(),
                if (_isCalculatingRoute)
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else
                  Text(
                    'Prix suggéré: ${_suggestedPrice.toStringAsFixed(0)} FCFA',
                    style: TextStyle(
                      color: Colors.blue[600],
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
              ],
            ),
          ),
          
          // Sélection du type de véhicule
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Type de véhicule',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _vehicleTypes.map((vehicle) => _buildVehicleTypeChip(vehicle)).toList(),
                  ),
                ),
              ],
            ),
          ),
          
          // Négociation de prix (style InDriver)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Votre offre',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    IconButton(
                      onPressed: _myOfferPrice > 500 ? () {
                        setState(() {
                          _myOfferPrice -= 100;
                        });
                      } : null,
                      icon: const Icon(Icons.remove),
                    ),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey[300]!),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${_myOfferPrice.toStringAsFixed(0)} FCFA',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: _myOfferPrice < 10000 ? () {
                        setState(() {
                          _myOfferPrice += 100;
                        });
                      } : null,
                      icon: const Icon(Icons.add),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Prix suggéré: ${_suggestedPrice.toStringAsFixed(0)} FCFA',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          
          // Bouton pour voir les chauffeurs
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            child: ElevatedButton(
              onPressed: _estimatedDistance > 0 ? () {
                setState(() {
                  _showDriverSelection = true;
                });
              } : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue[600],
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Voir les chauffeurs disponibles',
                style: TextStyle(
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

  Widget _buildVehicleTypeChip(Map<String, dynamic> vehicle) {
    final isSelected = _selectedVehicleType == vehicle['id'];
    final color = vehicle['color'] as Color;
    
    return Container(
      margin: const EdgeInsets.only(right: 8),
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedVehicleType = vehicle['id'];
          });
          _calculateRoute();
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? color.withOpacity(0.1) : Colors.grey[50],
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected ? color : Colors.grey[300]!,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                vehicle['icon'],
                color: color,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                vehicle['name'],
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: isSelected ? color : Colors.black,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDriverSelectionPanel() {
    return Container(
      height: MediaQuery.of(context).size.height * 0.6,
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Column(
        children: [
          // En-tête
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.directions_car, color: Colors.blue[600]),
                const SizedBox(width: 8),
                Text(
                  'Chauffeurs disponibles (${_availableDrivers.length})',
                  style: TextStyle(
                    color: Colors.blue[600],
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () {
                    setState(() {
                      _showDriverSelection = false;
                    });
                  },
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
          ),
          
          // Liste des chauffeurs
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _availableDrivers.length,
              itemBuilder: (context, index) {
                final driver = _availableDrivers[index];
                return _buildDriverCard(driver);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDriverCard(Map<String, dynamic> driver) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          // Photo du chauffeur
          CircleAvatar(
            radius: 25,
            backgroundColor: Colors.blue[100],
            child: Text(
              driver['photo'],
              style: const TextStyle(fontSize: 24),
            ),
          ),
          const SizedBox(width: 12),
          
          // Informations du chauffeur
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  driver['name'],
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.star, color: Colors.amber, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      '${driver['rating']} • ${driver['trips']} courses',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '${driver['vehicle']} • ${driver['plate']}',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.location_on, color: Colors.green, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      '${driver['distance']} km • ${driver['eta']} min',
                      style: TextStyle(
                        color: Colors.green[600],
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Prix et bouton
          Column(
            children: [
              Text(
                '${driver['price']} FCFA',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: () => _selectDriver(driver),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue[600],
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text('Choisir'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Set<Marker> _buildMarkers() {
    Set<Marker> markers = {};
    
    if (_pickupPlace != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('pickup'),
          position: _latLngOrFallback(_pickupPlace, _dakarCenter),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
          infoWindow: InfoWindow(
            title: 'Départ',
            snippet: _pickupPlace!.mainText,
          ),
        ),
      );
    }
    
    if (_destinationPlace != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('destination'),
          position: _latLngOrFallback(_destinationPlace, _dakarCenter),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
          infoWindow: InfoWindow(
            title: 'Destination',
            snippet: _destinationPlace!.mainText,
          ),
        ),
      );
    }
    
    // Marqueurs des chauffeurs disponibles
    for (int i = 0; i < _availableDrivers.length; i++) {
      final driver = _availableDrivers[i];
      markers.add(
        Marker(
          markerId: MarkerId('driver_${driver['id']}'),
          position: LatLng(
            _dakarCenter.latitude + (i * 0.01),
            _dakarCenter.longitude + (i * 0.01),
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
          infoWindow: InfoWindow(
            title: driver['name'],
            snippet: '${driver['vehicle']} • ${driver['price']} FCFA',
          ),
        ),
      );
    }
    
    return markers;
  }

  Set<Polyline> _buildPolylines() {
    if (_pickupPlace == null || _destinationPlace == null) {
      return {};
    }
    
    return {
      Polyline(
        polylineId: const PolylineId('route'),
        points: [
          _latLngOrFallback(_pickupPlace, _dakarCenter),
          _latLngOrFallback(_destinationPlace, _dakarCenter),
        ],
        color: Colors.blue,
        width: 4,
      ),
    };
  }

  void _selectDriver(Map<String, dynamic> driver) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Chauffeur ${driver['name']} sélectionné !'),
        backgroundColor: Colors.green,
      ),
    );
    
    setState(() {
      _showDriverSelection = false;
    });
  }
}
















