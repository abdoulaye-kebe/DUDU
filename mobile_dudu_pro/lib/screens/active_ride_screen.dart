import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
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
  /// Nombre d’écrans livraison actifs (empilement Navigator pour 2 courses).
  static int _stackedDeliveryScreens = 0;

  GoogleMapController? _mapController;
  Position? _currentPosition;
  Timer? _locationTimer;
  String _rideStatus = 'accepted'; // accepted, arrived, in_progress, completed
  bool _isLoading = false;
  bool _autoNavigationLaunched = false;
  Map<String, dynamic> _ridePayload = {};

  StreamSubscription<Map<String, dynamic>>? _extraDeliverySub;
  final Set<String> _hintedExtraDeliveryIds = <String>{};

  // Données de la course
  late String _passengerName;
  late String _pickupAddress;
  late String _destinationAddress;
  late int _price;
  late LatLng _pickupLocation;
  late LatLng _destinationLocation;

  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};

  bool get _isDeliveryRide {
    final t = widget.rideData['rideType']?.toString() ??
        widget.rideData['ride_type']?.toString();
    return t == 'delivery';
  }

  @override
  void initState() {
    super.initState();
    _ridePayload = Map<String, dynamic>.from(widget.rideData);
    if (_isDeliveryRide) {
      _stackedDeliveryScreens++;
    }
    _initRideData();
    _bootstrapRideData();
    _getCurrentLocation();
    _startLocationUpdates();
    _listenExtraDeliveryRequests();
  }

  /// Pendant une livraison, informer le livreur qu’une autre livraison est disponible (pile 2 courses).
  void _listenExtraDeliveryRequests() {
    if (!_isDeliveryRide) return;
    _extraDeliverySub = SocketService().rideRequestsStream.listen((data) {
      final id = data['id']?.toString() ?? data['rideId']?.toString();
      if (id == null || id == widget.rideId) return;
      if (data['rideType']?.toString() != 'delivery') return;
      if (_hintedExtraDeliveryIds.contains(id)) return;
      _hintedExtraDeliveryIds.add(id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 8),
          content: const Text(
            'Nouvelle livraison. Terminez celle-ci, puis revenez à l’écran des demandes pour accepter la suivante.',
          ),
        ),
      );
    });
  }

  /// Si les données socket sont incomplètes, recharger depuis l’API (évite écran « vide »)
  Future<void> _bootstrapRideData() async {
    final pickup = _ridePayload['pickup'];
    final hasCoords = pickup is Map &&
        (pickup['coordinates'] != null ||
            (pickup['location'] != null && pickup['location']['coordinates'] != null));
    if (hasCoords && (_ridePayload['passenger'] is Map)) {
      return;
    }

    final res = await ApiService.getRideDetails(widget.rideId);
    if (!mounted) return;
    final data = res?['data'];
    final ride = data is Map ? data['ride'] : null;
    if (ride is Map<String, dynamic>) {
      setState(() {
        _ridePayload = _mapApiRideToUi(ride);
        _initRideData();
      });
    }
  }

  Map<String, dynamic> _mapApiRideToUi(Map<String, dynamic> ride) {
    final p = ride['passenger'];
    final pickup = ride['pickup'];
    final dest = ride['destination'];
    final pricing = ride['pricing'];
    return {
      'passenger': p is Map
          ? p
          : {
              'name': p is Map && p['name'] != null ? p['name'] : 'Client',
            },
      'pickup': pickup ?? {},
      'destination': dest ?? {},
      'pricing': pricing ?? {},
    };
  }

  @override
  void dispose() {
    if (_isDeliveryRide && _stackedDeliveryScreens > 0) {
      _stackedDeliveryScreens--;
    }
    _extraDeliverySub?.cancel();
    _locationTimer?.cancel();
    _mapController?.dispose();
    super.dispose();
  }

  void _initRideData() {
    final passenger = _ridePayload['passenger'] ?? {};
    final pickup = _ridePayload['pickup'] ?? {};
    final destination = _ridePayload['destination'] ?? {};
    final pricing = _ridePayload['pricing'] ?? {};

    _passengerName = passenger['name']?.toString() ?? 'Client';
    _pickupAddress = pickup['address']?.toString() ?? 'Point de départ';
    _destinationAddress = destination['address']?.toString() ?? 'Destination';

    final totalPriceRaw = pricing['totalPrice'] ?? pricing['customPrice'];
    if (totalPriceRaw is int) {
      _price = totalPriceRaw;
    } else if (totalPriceRaw is num) {
      _price = totalPriceRaw.toInt();
    } else if (totalPriceRaw is String) {
      _price = int.tryParse(totalPriceRaw) ?? 0;
    } else {
      _price = 0;
    }

    _pickupLocation = _coordsToLatLng(pickup['coordinates'], 14.6928, -17.4467);
    _destinationLocation = _coordsToLatLng(destination['coordinates'], 14.7392, -17.4978);

    _updateMarkers();
  }

  LatLng _coordsToLatLng(dynamic coords, double defaultLat, double defaultLng) {
    if (coords is Map) {
      final lat = coords['latitude'];
      final lng = coords['longitude'];
      return LatLng(
        (lat is num) ? lat.toDouble() : (lat != null ? double.tryParse(lat.toString()) ?? defaultLat : defaultLat),
        (lng is num) ? lng.toDouble() : (lng != null ? double.tryParse(lng.toString()) ?? defaultLng : defaultLng),
      );
    }
    if (coords is List && coords.length >= 2) {
      final lng = coords[0];
      final lat = coords[1];
      return LatLng(
        (lat is num) ? lat.toDouble() : defaultLat,
        (lng is num) ? lng.toDouble() : defaultLng,
      );
    }
    return LatLng(defaultLat, defaultLng);
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
        
        // Envoyer la position au backend via Socket.io dès l'acceptation
        // Le client peut ainsi voir le véhicule se déplacer en temps réel
        if (_rideStatus == 'accepted' || _rideStatus == 'arrived' || _rideStatus == 'in_progress') {
          SocketService().updateDriverLocation(
            rideId: widget.rideId,
            latitude: position.latitude,
            longitude: position.longitude,
            heading: position.heading, // Direction pour rotation du marqueur
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
          content: Text('✅ Course démarrée — navigation plein écran'),
          backgroundColor: Colors.green,
        ),
      );
      _openNavigationFullscreenAfterStart();
    } catch (e) {
      setState(() => _isLoading = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
      );
    }
  }

  /// Ouvre la carte navigation (itinéraire + voix) en plein écran une fois le trajet démarré.
  void _openNavigationFullscreenAfterStart() {
    if (_autoNavigationLaunched || !mounted) return;
    _autoNavigationLaunched = true;
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      Navigator.of(context).push<void>(
        PageRouteBuilder<void>(
          opaque: true,
          barrierDismissible: false,
          pageBuilder: (context, animation, secondaryAnimation) {
            return NavigationScreen(
              rideId: widget.rideId,
              pickupLocation: _pickupLocation,
              destinationLocation: _destinationLocation,
              pickupAddress: _pickupAddress,
              destinationAddress: _destinationAddress,
              passengerName: _passengerName,
              rideStatus: 'in_progress',
            );
          },
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
        ),
      );
    });
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

          // Livraisons empilées : l’écran au-dessus indique qu’une autre course attend en dessous
          if (_isDeliveryRide &&
              _stackedDeliveryScreens > 1 &&
              (ModalRoute.of(context)?.isCurrent ?? true))
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                  child: Material(
                    color: Colors.orange.shade800,
                    borderRadius: BorderRadius.circular(10),
                    elevation: 4,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                      child: Row(
                        children: [
                          const Icon(Icons.layers, color: Colors.white, size: 22),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Plusieurs livraisons : terminez celle-ci, puis utilisez Retour pour la précédente.',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),

          // Header avec infos course
          Positioned(
            top: _isDeliveryRide &&
                    _stackedDeliveryScreens > 1 &&
                    (ModalRoute.of(context)?.isCurrent ?? true)
                ? 56
                : 0,
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
