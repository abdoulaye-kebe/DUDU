import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import '../services/geocoding_service.dart';
import '../services/places_service.dart' as places;
import '../widgets/address_autocomplete.dart';

class YangoStyleMapScreen extends StatefulWidget {
  const YangoStyleMapScreen({Key? key}) : super(key: key);

  @override
  State<YangoStyleMapScreen> createState() => _YangoStyleMapScreenState();
}

class _YangoStyleMapScreenState extends State<YangoStyleMapScreen> {
  GoogleMapController? _mapController;
  places.PlaceSuggestion? _pickupPlace;
  places.PlaceSuggestion? _destinationPlace;
  
  // États de l'interface
  bool _showPickupField = false;
  bool _showDestinationField = false;
  bool _isCalculatingRoute = false;
  double _estimatedPrice = 0.0;
  int _estimatedDuration = 0;
  double _estimatedDistance = 0.0;
  
  // Position par défaut : Dakar
  final LatLng _dakarCenter = const LatLng(14.6928, -17.4467);
  
  // Types de course disponibles
  final List<Map<String, dynamic>> _rideTypes = [
    {
      'id': 'standard',
      'name': 'Standard',
      'icon': Icons.directions_car,
      'price': 1.0,
      'description': 'Voiture standard',
      'color': Colors.blue,
    },
    {
      'id': 'express',
      'name': 'Express',
      'icon': Icons.flash_on,
      'price': 1.5,
      'description': 'Course rapide',
      'color': Colors.orange,
    },
    {
      'id': 'premium',
      'name': 'Premium',
      'icon': Icons.star,
      'price': 2.0,
      'description': 'Voiture haut de gamme',
      'color': Colors.purple,
    },
    {
      'id': 'shared',
      'name': 'Partagé',
      'icon': Icons.people,
      'price': 0.7,
      'description': 'Covoiturage',
      'color': Colors.green,
    },
  ];
  
  String _selectedRideType = 'standard';

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
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
          _pickupPlace = PlaceSuggestion(
            name: 'Ma position',
            address: 'Position actuelle',
            latitude: position.latitude,
            longitude: position.longitude,
            type: 'current',
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

      // Calculer le prix
      double basePrice = 1000;
      double distancePrice = distance * 500;
      double timePrice = 300;
      
      // Multiplicateur selon le type de course
      double multiplier = _rideTypes.firstWhere((type) => type['id'] == _selectedRideType)['price'];
      
      setState(() {
        _estimatedDistance = distance;
        _estimatedDuration = (distance * 2).round();
        _estimatedPrice = (basePrice + distancePrice + timePrice) * multiplier;
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
            onMapCreated: (GoogleMapController controller) {
              _mapController = controller;
            },
            initialCameraPosition: CameraPosition(
              target: _dakarCenter,
              zoom: 16.5,
            ),
            markers: _buildMarkers(),
            polylines: _buildPolylines(),
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            onTap: (LatLng position) {
              // Fermer les champs de recherche si on clique sur la carte
              setState(() {
                _showPickupField = false;
                _showDestinationField = false;
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
                
                // Panneau de sélection de course en bas
                if (_pickupPlace != null && _destinationPlace != null)
                  _buildRideSelectionPanel(),
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
                      _pickupPlace?.address ?? 'D\'où partez-vous ?',
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
                      _destinationPlace?.address ?? 'Où allez-vous ?',
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

  Widget _buildRideSelectionPanel() {
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
                    '${_estimatedPrice.toStringAsFixed(0)} FCFA',
                    style: TextStyle(
                      color: Colors.blue[600],
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
              ],
            ),
          ),
          
          // Sélection du type de course
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Choisissez votre type de course',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                ..._rideTypes.map((rideType) => _buildRideTypeCard(rideType)),
              ],
            ),
          ),
          
          // Bouton de commande
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            child: ElevatedButton(
              onPressed: _estimatedPrice > 0 ? _orderRide : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue[600],
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Commander une course',
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

  Widget _buildRideTypeCard(Map<String, dynamic> rideType) {
    final isSelected = _selectedRideType == rideType['id'];
    final color = rideType['color'] as Color;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedRideType = rideType['id'];
          });
          _calculateRoute();
        },
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isSelected ? color.withOpacity(0.1) : Colors.grey[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? color : Colors.grey[300]!,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              Icon(
                rideType['icon'],
                color: color,
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      rideType['name'],
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: isSelected ? color : Colors.black,
                      ),
                    ),
                    Text(
                      rideType['description'],
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              if (isSelected)
                Icon(
                  Icons.check_circle,
                  color: color,
                  size: 20,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Set<Marker> _buildMarkers() {
    Set<Marker> markers = {};
    
    if (_pickupPlace != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('pickup'),
          position: LatLng(_pickupPlace!.latitude, _pickupPlace!.longitude),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
          infoWindow: InfoWindow(
            title: 'Départ',
            snippet: _pickupPlace!.name,
          ),
        ),
      );
    }
    
    if (_destinationPlace != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('destination'),
          position: LatLng(_destinationPlace!.latitude, _destinationPlace!.longitude),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
          infoWindow: InfoWindow(
            title: 'Destination',
            snippet: _destinationPlace!.name,
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
          LatLng(_pickupPlace!.latitude, _pickupPlace!.longitude),
          LatLng(_destinationPlace!.latitude, _destinationPlace!.longitude),
        ],
        color: Colors.blue,
        width: 4,
      ),
    };
  }

  void _orderRide() {
    // Ici, vous implémenteriez la logique de commande de course
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Course commandée !'),
        backgroundColor: Colors.green,
      ),
    );
  }
}
















