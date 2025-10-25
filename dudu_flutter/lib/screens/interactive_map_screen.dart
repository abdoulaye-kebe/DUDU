import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import '../services/api_service.dart';
import 'dart:async';

/// Écran de carte Google Maps interactive avec fonctionnalités avancées
class InteractiveMapScreen extends StatefulWidget {
  const InteractiveMapScreen({Key? key}) : super(key: key);

  @override
  State<InteractiveMapScreen> createState() => _InteractiveMapScreenState();
}

class _InteractiveMapScreenState extends State<InteractiveMapScreen> {
  GoogleMapController? _mapController;
  Position? _currentPosition;
  LatLng? _pickedLocation;
  
  // Marqueurs
  final Set<Marker> _markers = {};
  final Set<Polyline> _polylines = {};
  final Set<Circle> _circles = {};
  
  // Contrôles UI
  MapType _currentMapType = MapType.normal;
  bool _trafficEnabled = false;
  bool _myLocationEnabled = true;
  bool _isLoading = false;
  
  // Information card
  String? _selectedLocationInfo;
  
  @override
  void initState() {
    super.initState();
    _initializeMap();
  }

  Future<void> _initializeMap() async {
    setState(() => _isLoading = true);
    
    try {
      // Obtenir la position actuelle
      await _getCurrentLocation();
      
      // Charger les marqueurs initiaux
      _loadInitialMarkers();
    } catch (e) {
      print('Erreur initialisation carte: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _showError('Services de localisation désactivés');
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _showError('Permission de localisation refusée');
          return;
        }
      }

      Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      setState(() {
        _currentPosition = position;
      });

      // Centrer la carte sur la position
      _mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(
          LatLng(position.latitude, position.longitude),
          15.0,
        ),
      );

      // Ajouter marqueur de position actuelle
      _addMarker(
        'current_location',
        LatLng(position.latitude, position.longitude),
        'Ma position',
        BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
      );

      // Cercle de rayon de recherche
      _addCircle(
        LatLng(position.latitude, position.longitude),
        2000, // 2km en mètres
      );
    } catch (e) {
      print('Erreur géolocalisation: $e');
      _showError('Impossible d\'obtenir votre position');
      
      // Position par défaut : Dakar
      setState(() {
        _currentPosition = Position(
          latitude: 14.6928,
          longitude: -17.4467,
          timestamp: DateTime.now(),
          accuracy: 0,
          altitude: 0,
          altitudeAccuracy: 0,
          heading: 0,
          headingAccuracy: 0,
          speed: 0,
          speedAccuracy: 0,
        );
      });
    }
  }

  void _loadInitialMarkers() {
    // Marqueurs des villes principales du Sénégal
    final cities = [
      {
        'id': 'dakar',
        'name': 'Dakar',
        'lat': 14.6928,
        'lng': -17.4467,
        'type': 'capital',
      },
      {
        'id': 'thies',
        'name': 'Thiès',
        'lat': 14.7896,
        'lng': -16.9260,
        'type': 'city',
      },
      {
        'id': 'kaolack',
        'name': 'Kaolack',
        'lat': 14.1510,
        'lng': -16.0755,
        'type': 'city',
      },
      {
        'id': 'ziguinchor',
        'name': 'Ziguinchor',
        'lat': 12.5641,
        'lng': -16.2630,
        'type': 'city',
      },
      {
        'id': 'saint_louis',
        'name': 'Saint-Louis',
        'lat': 16.0179,
        'lng': -16.4896,
        'type': 'city',
      },
    ];

    for (var city in cities) {
      _addMarker(
        city['id'] as String,
        LatLng(city['lat'] as double, city['lng'] as double),
        city['name'] as String,
        city['type'] == 'capital'
            ? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen)
            : BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
      );
    }
  }

  void _addMarker(String id, LatLng position, String title, BitmapDescriptor icon) {
    setState(() {
      _markers.add(
        Marker(
          markerId: MarkerId(id),
          position: position,
          infoWindow: InfoWindow(
            title: title,
          ),
          icon: icon,
          onTap: () {
            _onMarkerTap(title, position);
          },
        ),
      );
    });
  }

  void _addCircle(LatLng center, double radius) {
    setState(() {
      _circles.add(
        Circle(
          circleId: const CircleId('search_radius'),
          center: center,
          radius: radius,
          strokeColor: Colors.blue.withOpacity(0.3),
          fillColor: Colors.blue.withOpacity(0.1),
          strokeWidth: 2,
        ),
      );
    });
  }

  void _drawRoute(LatLng from, LatLng to) {
    setState(() {
      _polylines.add(
        Polyline(
          polylineId: const PolylineId('route'),
          points: [from, to],
          color: Colors.blue,
          width: 5,
          patterns: [PatternItem.dash(50), PatternItem.gap(20)],
        ),
      );
    });
  }

  void _onMarkerTap(String title, LatLng position) {
    setState(() {
      _selectedLocationInfo = title;
    });

    // Afficher les infos
    _showLocationInfo(title, position);
  }

  void _showLocationInfo(String title, LatLng position) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Coordonnées: ${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)}',
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: () {
                    _setDestination(position);
                  },
                  icon: const Icon(Icons.flag),
                  label: const Text('Définir destination'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00A651),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    _getDirections(position);
                  },
                  icon: const Icon(Icons.directions),
                  label: const Text('Itinéraire'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _setDestination(LatLng destination) {
    setState(() {
      _pickedLocation = destination;
    });

    // Ajouter marqueur destination
    _addMarker(
      'destination',
      destination,
      'Destination',
      BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
    );

    // Dessiner une ligne si on a une position de départ
    if (_currentPosition != null) {
      _drawRoute(
        LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
        destination,
      );
    }

    _mapController?.animateCamera(
      CameraUpdate.newLatLng(destination),
    );

    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Destination définie')),
    );
  }

  void _getDirections(LatLng destination) {
    if (_currentPosition == null) return;

    // TODO: Intégrer avec Google Directions API
    _drawRoute(
      LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
      destination,
    );

    // Afficher infos trajet
    final distance = Geolocator.distanceBetween(
      _currentPosition!.latitude,
      _currentPosition!.longitude,
      destination.latitude,
      destination.longitude,
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Itinéraire'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Distance: ${(distance / 1000).toStringAsFixed(2)} km'),
            Text('Temps estimé: ${(distance / 1000 * 2).toStringAsFixed(0)} min'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }

  void _toggleMapType() {
    setState(() {
      _currentMapType = _currentMapType == MapType.normal
          ? MapType.satellite
          : MapType.normal;
    });
  }

  void _toggleTraffic() {
    setState(() {
      _trafficEnabled = !_trafficEnabled;
    });
  }

  void _toggleMyLocation() {
    setState(() {
      _myLocationEnabled = !_myLocationEnabled;
    });
  }

  void _centerOnCurrentLocation() {
    if (_currentPosition != null) {
      _mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(
          LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
          15.0,
        ),
      );
    } else {
      _getCurrentLocation();
    }
  }

  void _zoomIn() {
    _mapController?.animateCamera(CameraUpdate.zoomIn());
  }

  void _zoomOut() {
    _mapController?.animateCamera(CameraUpdate.zoomOut());
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Carte Interactive DUDU'),
        backgroundColor: const Color(0xFF00A651),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              // TODO: Recherche d'adresse
              _showError('Fonctionnalité à venir');
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          // Carte Google Maps
          GoogleMap(
            onMapCreated: (controller) {
              _mapController = controller;
            },
            initialCameraPosition: CameraPosition(
              target: _currentPosition != null
                  ? LatLng(_currentPosition!.latitude, _currentPosition!.longitude)
                  : const LatLng(14.6928, -17.4467), // Dakar par défaut
              zoom: 13.0,
            ),
            markers: _markers,
            polylines: _polylines,
            circles: _circles,
            mapType: _currentMapType,
            trafficEnabled: _trafficEnabled,
            myLocationEnabled: _myLocationEnabled,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            onTap: (LatLng position) {
              // Ajouter marqueur au clic
              setState(() {
                _selectedLocationInfo = null;
              });
            },
            onLongPress: (LatLng position) {
              // Marqueur à long press
              _addMarker(
                'temp_${DateTime.now().millisecondsSinceEpoch}',
                position,
                'Position sélectionnée',
                BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueViolet),
              );
            },
          ),

          // Contrôles de zoom
          Positioned(
            top: 80,
            right: 10,
            child: Column(
              children: [
                FloatingActionButton.small(
                  onPressed: _zoomIn,
                  backgroundColor: Colors.white,
                  heroTag: 'zoom_in',
                  child: const Icon(Icons.add),
                ),
                const SizedBox(height: 10),
                FloatingActionButton.small(
                  onPressed: _zoomOut,
                  backgroundColor: Colors.white,
                  heroTag: 'zoom_out',
                  child: const Icon(Icons.remove),
                ),
              ],
            ),
          ),

          // Boutons de contrôle
          Positioned(
            bottom: 20,
            left: 10,
            right: 10,
            child: Column(
              children: [
                // Contrôles principaux
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildControlButton(
                        Icons.map,
                        'Type',
                        _toggleMapType,
                      ),
                      _buildControlButton(
                        Icons.traffic,
                        'Trafic',
                        _toggleTraffic,
                        isActive: _trafficEnabled,
                      ),
                      _buildControlButton(
                        Icons.my_location,
                        'Ma position',
                        _centerOnCurrentLocation,
                      ),
                      _buildControlButton(
                        Icons.layers_clear,
                        'Effacer',
                        _clearMarkers,
                      ),
                    ],
                  ),
                ),

                // Information de localisation sélectionnée
                if (_selectedLocationInfo != null)
                  Container(
                    margin: const EdgeInsets.only(top: 10),
                    padding: const EdgeInsets.all(15),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.location_on, color: Color(0xFF00A651)),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(_selectedLocationInfo!),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),

          // Indicateur de chargement
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.3),
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildControlButton(
    IconData icon,
    String label,
    VoidCallback onTap, {
    bool isActive = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFF00A651) : Colors.grey[100],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isActive ? Colors.white : Colors.black87,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: isActive ? Colors.white : Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _clearMarkers() {
    setState(() {
      _markers.removeWhere((marker) => marker.markerId.value.startsWith('temp_'));
      _polylines.clear();
      _circles.clear();
      _selectedLocationInfo = null;
    });
  }
}



