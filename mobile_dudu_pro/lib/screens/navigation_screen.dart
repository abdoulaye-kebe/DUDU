import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:async';
import 'dart:math' as math;

/// Écran de navigation intelligent pour le chauffeur
/// Affiche la carte avec l'itinéraire optimal et les instructions de navigation
class NavigationScreen extends StatefulWidget {
  final String rideId;
  final LatLng pickupLocation;
  final LatLng destinationLocation;
  final String pickupAddress;
  final String destinationAddress;
  final String passengerName;
  final String rideStatus; // 'going_to_pickup' ou 'in_progress'

  const NavigationScreen({
    Key? key,
    required this.rideId,
    required this.pickupLocation,
    required this.destinationLocation,
    required this.pickupAddress,
    required this.destinationAddress,
    required this.passengerName,
    this.rideStatus = 'going_to_pickup',
  }) : super(key: key);

  @override
  State<NavigationScreen> createState() => _NavigationScreenState();
}

class _NavigationScreenState extends State<NavigationScreen> {
  GoogleMapController? _mapController;
  Position? _currentPosition;
  Timer? _locationTimer;
  
  final Set<Marker> _markers = {};
  final Set<Polyline> _polylines = {};
  
  double _distanceToTarget = 0;
  int _estimatedTimeMinutes = 0;
  String _currentInstruction = 'Calcul de l\'itinéraire...';
  
  bool _isNavigating = false;
  LatLng? _targetLocation;
  
  static const Color primaryGreen = Color(0xFF00A651);

  @override
  void initState() {
    super.initState();
    _targetLocation = widget.rideStatus == 'going_to_pickup' 
        ? widget.pickupLocation 
        : widget.destinationLocation;
    _getCurrentLocation();
    _startLocationUpdates();
  }

  @override
  void dispose() {
    _locationTimer?.cancel();
    _mapController?.dispose();
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      
      setState(() {
        _currentPosition = position;
        _isNavigating = true;
      });
      
      _updateMapAndRoute();
    } catch (e) {
      print('Erreur localisation: $e');
    }
  }

  void _startLocationUpdates() {
    _locationTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      _getCurrentLocation();
    });
  }

  void _updateMapAndRoute() {
    if (_currentPosition == null || _targetLocation == null) return;

    final currentLatLng = LatLng(
      _currentPosition!.latitude,
      _currentPosition!.longitude,
    );

    // Calculer la distance et le temps estimé
    _distanceToTarget = _calculateDistance(
      currentLatLng.latitude,
      currentLatLng.longitude,
      _targetLocation!.latitude,
      _targetLocation!.longitude,
    );

    // Estimation du temps (vitesse moyenne 30 km/h en ville)
    _estimatedTimeMinutes = (_distanceToTarget / 30 * 60).round();

    // Générer l'instruction de navigation
    _currentInstruction = _generateNavigationInstruction(currentLatLng, _targetLocation!);

    // Mettre à jour les marqueurs
    _updateMarkers(currentLatLng);

    // Tracer l'itinéraire
    _drawRoute(currentLatLng, _targetLocation!);

    // Centrer la carte
    _centerMap(currentLatLng, _targetLocation!);

    setState(() {});
  }

  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const R = 6371; // Rayon de la Terre en km
    final dLat = (lat2 - lat1) * math.pi / 180;
    final dLon = (lon2 - lon1) * math.pi / 180;
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(lat1 * math.pi / 180) *
            math.cos(lat2 * math.pi / 180) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return R * c;
  }

  String _generateNavigationInstruction(LatLng current, LatLng target) {
    final bearing = _calculateBearing(
      current.latitude,
      current.longitude,
      target.latitude,
      target.longitude,
    );

    String direction;
    if (bearing >= 337.5 || bearing < 22.5) {
      direction = 'Nord';
    } else if (bearing >= 22.5 && bearing < 67.5) {
      direction = 'Nord-Est';
    } else if (bearing >= 67.5 && bearing < 112.5) {
      direction = 'Est';
    } else if (bearing >= 112.5 && bearing < 157.5) {
      direction = 'Sud-Est';
    } else if (bearing >= 157.5 && bearing < 202.5) {
      direction = 'Sud';
    } else if (bearing >= 202.5 && bearing < 247.5) {
      direction = 'Sud-Ouest';
    } else if (bearing >= 247.5 && bearing < 292.5) {
      direction = 'Ouest';
    } else {
      direction = 'Nord-Ouest';
    }

    if (_distanceToTarget < 0.1) {
      return widget.rideStatus == 'going_to_pickup'
          ? 'Vous êtes arrivé au point de prise en charge'
          : 'Vous êtes arrivé à destination';
    } else if (_distanceToTarget < 0.5) {
      return 'Continuez tout droit, arrivée dans ${(_distanceToTarget * 1000).round()} mètres';
    } else {
      return 'Dirigez-vous vers le $direction sur ${_distanceToTarget.toStringAsFixed(1)} km';
    }
  }

  double _calculateBearing(double lat1, double lon1, double lat2, double lon2) {
    final dLon = (lon2 - lon1) * math.pi / 180;
    final y = math.sin(dLon) * math.cos(lat2 * math.pi / 180);
    final x = math.cos(lat1 * math.pi / 180) * math.sin(lat2 * math.pi / 180) -
        math.sin(lat1 * math.pi / 180) *
            math.cos(lat2 * math.pi / 180) *
            math.cos(dLon);
    final bearing = math.atan2(y, x) * 180 / math.pi;
    return (bearing + 360) % 360;
  }

  void _updateMarkers(LatLng currentLocation) {
    _markers.clear();

    // Marqueur position actuelle
    _markers.add(
      Marker(
        markerId: const MarkerId('current'),
        position: currentLocation,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
        infoWindow: const InfoWindow(title: 'Ma position'),
      ),
    );

    // Marqueur point de prise en charge
    if (widget.rideStatus == 'going_to_pickup') {
      _markers.add(
        Marker(
          markerId: const MarkerId('pickup'),
          position: widget.pickupLocation,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
          infoWindow: InfoWindow(
            title: 'Point de prise en charge',
            snippet: widget.pickupAddress,
          ),
        ),
      );
    }

    // Marqueur destination
    _markers.add(
      Marker(
        markerId: const MarkerId('destination'),
        position: widget.destinationLocation,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        infoWindow: InfoWindow(
          title: widget.rideStatus == 'going_to_pickup' ? 'Destination finale' : 'Destination',
          snippet: widget.destinationAddress,
        ),
      ),
    );
  }

  void _drawRoute(LatLng start, LatLng end) {
    _polylines.clear();

    // En production, utiliser Google Directions API ou HERE Routing API
    // Pour l'instant, tracer une ligne directe
    _polylines.add(
      Polyline(
        polylineId: const PolylineId('route'),
        points: [start, end],
        color: primaryGreen,
        width: 5,
        patterns: [PatternItem.dash(20), PatternItem.gap(10)],
      ),
    );
  }

  void _centerMap(LatLng start, LatLng end) {
    if (_mapController == null) return;

    final bounds = LatLngBounds(
      southwest: LatLng(
        math.min(start.latitude, end.latitude),
        math.min(start.longitude, end.longitude),
      ),
      northeast: LatLng(
        math.max(start.latitude, end.latitude),
        math.max(start.longitude, end.longitude),
      ),
    );

    _mapController!.animateCamera(
      CameraUpdate.newLatLngBounds(bounds, 100),
    );
  }

  Future<void> _openGoogleMaps() async {
    final url = 'https://www.google.com/maps/dir/?api=1&origin=${_currentPosition!.latitude},${_currentPosition!.longitude}&destination=${_targetLocation!.latitude},${_targetLocation!.longitude}&travelmode=driving';
    
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Impossible d\'ouvrir Google Maps')),
          );
        }
      }
    } catch (e) {
      print('Erreur ouverture Google Maps: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Carte Google Maps
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: _targetLocation ?? widget.pickupLocation,
              zoom: 14,
            ),
            markers: _markers,
            polylines: _polylines,
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            onMapCreated: (controller) {
              _mapController = controller;
              if (_currentPosition != null) {
                _updateMapAndRoute();
              }
            },
          ),

          // Panneau d'instructions en haut
          Positioned(
            top: 50,
            left: 16,
            right: 16,
            child: _buildInstructionPanel(),
          ),

          // Panneau d'informations en bas
          Positioned(
            bottom: 16,
            left: 16,
            right: 16,
            child: _buildInfoPanel(),
          ),

          // Bouton retour
          Positioned(
            top: 50,
            left: 16,
            child: FloatingActionButton(
              mini: true,
              backgroundColor: Colors.white,
              onPressed: () => Navigator.pop(context),
              child: const Icon(Icons.arrow_back, color: Colors.black),
            ),
          ),

          // Bouton centrer
          Positioned(
            bottom: 200,
            right: 16,
            child: FloatingActionButton(
              mini: true,
              backgroundColor: Colors.white,
              onPressed: () {
                if (_currentPosition != null && _targetLocation != null) {
                  _centerMap(
                    LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
                    _targetLocation!,
                  );
                }
              },
              child: const Icon(Icons.my_location, color: primaryGreen),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInstructionPanel() {
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [primaryGreen.withOpacity(0.1), Colors.white],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
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
                  child: const Icon(
                    Icons.navigation,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _currentInstruction,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _buildInfoChip(Icons.straighten, '${_distanceToTarget.toStringAsFixed(1)} km'),
                const SizedBox(width: 12),
                _buildInfoChip(Icons.access_time, '$_estimatedTimeMinutes min'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: primaryGreen),
          const SizedBox(width: 6),
          Text(
            text,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoPanel() {
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: primaryGreen,
                  child: Text(
                    widget.passengerName[0].toUpperCase(),
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.passengerName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        widget.rideStatus == 'going_to_pickup'
                            ? 'En route vers le client'
                            : 'Course en cours',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            _buildAddressRow(
              Icons.location_on,
              widget.rideStatus == 'going_to_pickup' ? 'Prise en charge' : 'Départ',
              widget.pickupAddress,
            ),
            const SizedBox(height: 8),
            _buildAddressRow(
              Icons.flag,
              'Destination',
              widget.destinationAddress,
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _openGoogleMaps,
                icon: const Icon(Icons.map),
                label: const Text('Ouvrir dans Google Maps'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryGreen,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddressRow(IconData icon, String label, String address) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: primaryGreen),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
              Text(
                address,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
