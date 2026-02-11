import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:async';
import '../services/api_service.dart';
import '../services/socket_service.dart';
import 'rate_passenger_screen.dart';
import 'navigation_screen.dart';

/// Écran de suivi de course active pour le chauffeur
class ActiveRideScreen extends StatefulWidget {
  final String rideId;
  final Map<String, dynamic> rideData;

  const ActiveRideScreen({
    Key? key,
    required this.rideId,
    required this.rideData,
  }) : super(key: key);

  @override
  State<ActiveRideScreen> createState() => _ActiveRideScreenState();
}

class _ActiveRideScreenState extends State<ActiveRideScreen> {
  GoogleMapController? _mapController;
  Position? _currentPosition;
  Timer? _locationTimer;
  String _rideStatus = 'accepted'; // accepted, arrived, in_progress, completed
  bool _isLoading = false;

  // Données de la course
  late String _passengerName;
  late String _pickupAddress;
  late String _destinationAddress;
  late int _price;
  late LatLng _pickupLocation;
  late LatLng _destinationLocation;

  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};

  @override
  void initState() {
    super.initState();
    _initRideData();
    _getCurrentLocation();
    _startLocationUpdates();
  }

  @override
  void dispose() {
    _locationTimer?.cancel();
    _mapController?.dispose();
    super.dispose();
  }

  void _initRideData() {
    final passenger = widget.rideData['passenger'] ?? {};
    final pickup = widget.rideData['pickup'] ?? {};
    final destination = widget.rideData['destination'] ?? {};
    final pricing = widget.rideData['pricing'] ?? {};

    _passengerName = passenger['name']?.toString() ?? 'Client';
    _pickupAddress = pickup['address']?.toString() ?? 'Point de départ';
    _destinationAddress = destination['address']?.toString() ?? 'Destination';
    _price = pricing['totalPrice']?.toInt() ?? pricing['customPrice']?.toInt() ?? 0;

    final pickupCoords = pickup['coordinates'] ?? {};
    final destCoords = destination['coordinates'] ?? {};

    _pickupLocation = LatLng(
      (pickupCoords['latitude'] ?? 14.6928).toDouble(),
      (pickupCoords['longitude'] ?? -17.4467).toDouble(),
    );

    _destinationLocation = LatLng(
      (destCoords['latitude'] ?? 14.7392).toDouble(),
      (destCoords['longitude'] ?? -17.4978).toDouble(),
    );

    _updateMarkers();
  }

  void _updateMarkers() {
    _markers = {
      Marker(
        markerId: const MarkerId('pickup'),
        position: _pickupLocation,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
        infoWindow: InfoWindow(title: 'Prise en charge', snippet: _pickupAddress),
      ),
      Marker(
        markerId: const MarkerId('destination'),
        position: _destinationLocation,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        infoWindow: InfoWindow(title: 'Destination', snippet: _destinationAddress),
      ),
    };

    if (_currentPosition != null) {
      _markers.add(
        Marker(
          markerId: const MarkerId('driver'),
          position: LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
          infoWindow: const InfoWindow(title: 'Vous'),
        ),
      );
    }

    if (mounted) setState(() {});
  }

  Future<void> _getCurrentLocation() async {
    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );
      setState(() {
        _currentPosition = position;
      });
      _updateMarkers();
      _centerMap();
    } catch (e) {
      print('Erreur localisation: $e');
    }
  }

  void _startLocationUpdates() {
    _locationTimer = Timer.periodic(const Duration(seconds: 3), (timer) async {
      try {
        final position = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
        );
        
        setState(() {
          _currentPosition = position;
        });
        
        _updateMarkers();
        
        // Envoyer la position au backend via Socket.io
        if (_rideStatus == 'in_progress') {
          SocketService().updateDriverLocation(
            rideId: widget.rideId,
            latitude: position.latitude,
            longitude: position.longitude,
          );
        }
      } catch (e) {
        print('Erreur mise à jour position: $e');
      }
    });
  }

  void _centerMap() {
    if (_mapController == null || _currentPosition == null) return;

    LatLngBounds bounds;
    if (_rideStatus == 'accepted' || _rideStatus == 'arrived') {
      // Centrer sur chauffeur et pickup
      bounds = LatLngBounds(
        southwest: LatLng(
          _currentPosition!.latitude < _pickupLocation.latitude
              ? _currentPosition!.latitude
              : _pickupLocation.latitude,
          _currentPosition!.longitude < _pickupLocation.longitude
              ? _currentPosition!.longitude
              : _pickupLocation.longitude,
        ),
        northeast: LatLng(
          _currentPosition!.latitude > _pickupLocation.latitude
              ? _currentPosition!.latitude
              : _pickupLocation.latitude,
          _currentPosition!.longitude > _pickupLocation.longitude
              ? _currentPosition!.longitude
              : _pickupLocation.longitude,
        ),
      );
    } else {
      // Centrer sur chauffeur et destination
      bounds = LatLngBounds(
        southwest: LatLng(
          _currentPosition!.latitude < _destinationLocation.latitude
              ? _currentPosition!.latitude
              : _destinationLocation.latitude,
          _currentPosition!.longitude < _destinationLocation.longitude
              ? _currentPosition!.longitude
              : _destinationLocation.longitude,
        ),
        northeast: LatLng(
          _currentPosition!.latitude > _destinationLocation.latitude
              ? _currentPosition!.latitude
              : _destinationLocation.latitude,
          _currentPosition!.longitude > _destinationLocation.longitude
              ? _currentPosition!.longitude
              : _destinationLocation.longitude,
        ),
      );
    }

    _mapController!.animateCamera(CameraUpdate.newLatLngBounds(bounds, 100));
  }

  Future<void> _signalArrival() async {
    setState(() => _isLoading = true);
    try {
      await ApiService.arriveAtPickup(widget.rideId);
      SocketService().arrivedAtPickup(widget.rideId);
      
      setState(() {
        _rideStatus = 'arrived';
        _isLoading = false;
      });
      
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Arrivée signalée au client'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      setState(() => _isLoading = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _startRide() async {
    setState(() => _isLoading = true);
    try {
      await ApiService.startRide(widget.rideId);
      SocketService().startTrip(widget.rideId);
      
      setState(() {
        _rideStatus = 'in_progress';
        _isLoading = false;
      });
      
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Course démarrée'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      setState(() => _isLoading = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _completeRide() async {
    setState(() => _isLoading = true);
    try {
      await ApiService.completeRide(widget.rideId);
      
      setState(() {
        _rideStatus = 'completed';
        _isLoading = false;
      });
      
      if (!mounted) return;
      
      // Afficher dialog de fin de course avec option d'évaluation
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: const Text('🎉 Course terminée'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Félicitations ! La course est terminée.'),
              const SizedBox(height: 16),
              Text(
                '$_price FCFA',
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0d5d36),
                ),
              ),
              const SizedBox(height: 8),
              const Text('Montant de la course'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Fermer dialog
                Navigator.pop(context); // Retour au dashboard
              },
              child: const Text('PASSER'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context); // Fermer dialog
                // Navigation vers écran d'évaluation
                final rated = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => RatePassengerScreen(
                      rideId: widget.rideId,
                      passengerName: _passengerName,
                    ),
                  ),
                );
                if (mounted) {
                  Navigator.pop(context); // Retour au dashboard
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0d5d36),
              ),
              child: const Text('ÉVALUER LE CLIENT'),
            ),
          ],
        ),
      );
    } catch (e) {
      setState(() => _isLoading = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
      );
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
              target: _pickupLocation,
              zoom: 14,
            ),
            markers: _markers,
            polylines: _polylines,
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            onMapCreated: (controller) {
              _mapController = controller;
              _centerMap();
            },
          ),

          // Header avec infos course
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back),
                          onPressed: () => Navigator.pop(context),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _getStatusText(),
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                _passengerName,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0d5d36),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '$_price FCFA',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 24),
                    Row(
                      children: [
                        const Icon(Icons.radio_button_checked, color: Colors.green, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _pickupAddress,
                            style: const TextStyle(fontSize: 13),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.place, color: Colors.red, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _destinationAddress,
                            style: const TextStyle(fontSize: 13),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Bouton de navigation intelligent
          if (_rideStatus != 'completed')
            Positioned(
              bottom: 100,
              right: 16,
              child: FloatingActionButton.extended(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => NavigationScreen(
                        rideId: widget.rideId,
                        pickupLocation: _pickupLocation,
                        destinationLocation: _destinationLocation,
                        pickupAddress: _pickupAddress,
                        destinationAddress: _destinationAddress,
                        passengerName: _passengerName,
                        rideStatus: _rideStatus == 'accepted' || _rideStatus == 'arrived' 
                            ? 'going_to_pickup' 
                            : 'in_progress',
                      ),
                    ),
                  );
                },
                backgroundColor: const Color(0xFF0d5d36),
                icon: const Icon(Icons.navigation, color: Colors.white),
                label: const Text(
                  'Navigation',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
            ),

          // Boutons d'action en bas
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Container(
                margin: const EdgeInsets.all(16),
                child: _buildActionButton(),
              ),
            ),
          ),

          // Loading overlay
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.3),
              child: const Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
            ),
        ],
      ),
    );
  }

  String _getStatusText() {
    switch (_rideStatus) {
      case 'accepted':
        return '🚗 En route vers le client';
      case 'arrived':
        return '📍 Arrivé - En attente du client';
      case 'in_progress':
        return '🏁 Course en cours';
      case 'completed':
        return '✅ Course terminée';
      default:
        return 'Course active';
    }
  }

  Widget _buildActionButton() {
    if (_rideStatus == 'accepted') {
      return ElevatedButton(
        onPressed: _isLoading ? null : _signalArrival,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF0d5d36),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 4,
        ),
        child: const Text(
          'SIGNALER MON ARRIVÉE',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      );
    } else if (_rideStatus == 'arrived') {
      return ElevatedButton(
        onPressed: _isLoading ? null : _startRide,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.orange,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 4,
        ),
        child: const Text(
          'DÉMARRER LA COURSE',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      );
    } else if (_rideStatus == 'in_progress') {
      return ElevatedButton(
        onPressed: _isLoading ? null : _completeRide,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.red,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 4,
        ),
        child: const Text(
          'TERMINER LA COURSE',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      );
    }
    
    return const SizedBox.shrink();
  }
}
