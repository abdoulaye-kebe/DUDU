import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:async';
import 'dart:math' as math;
import '../services/api_service.dart';
import '../services/socket_service.dart';
import '../services/map_style_service.dart';
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

  /// Après GET `/rides/:id` (chauffeur assigné) pour un payload cohérent avec l’UI.
  static Map<String, dynamic> ridePayloadFromApiRide(Map<String, dynamic> ride) {
    final p = ride['passenger'];
    final pickup = ride['pickup'];
    final dest = ride['destination'];
    final pricing = ride['pricing'];
    return {
      'passenger': p is Map
          ? Map<String, dynamic>.from(p)
          : {
              'name': p is Map && p['name'] != null ? p['name'] : 'Client',
            },
      'pickup': pickup ?? {},
      'destination': dest ?? {},
      'pricing': pricing ?? {},
      'rideType': ride['rideType'],
      'scheduledFor': ride['scheduledFor'],
      'scheduledPickupEnRouteAt': ride['scheduledPickupEnRouteAt'],
      'scheduledPickupArrivedAt': ride['scheduledPickupArrivedAt'],
      'status': ride['status'],
    };
  }

  @override
  State<ActiveRideScreen> createState() => _ActiveRideScreenState();
}

class _ActiveRideScreenState extends State<ActiveRideScreen> {
  /// Nombre d’écrans livraison actifs (empilement Navigator pour 2 courses).
  static int _stackedDeliveryScreens = 0;

  GoogleMapController? _mapController;
  Position? _currentPosition;
  Timer? _locationTimer;
  /// Identifiant MongoDB pour les appels API (le socket peut envoyer un autre format au départ).
  late String _effectiveRideId;
  String _rideStatus = 'accepted'; // accepted, arrived, in_progress, completed
  bool _isLoading = false;
  bool _autoNavigationLaunched = false;
  Map<String, dynamic> _ridePayload = {};

  StreamSubscription<Map<String, dynamic>>? _extraDeliverySub;
  final Set<String> _hintedExtraDeliveryIds = <String>{};

  // Données de la course
  late String _passengerName;
  String _passengerPhone = '';
  late String _pickupAddress;
  late String _destinationAddress;
  late int _price;
  late LatLng _pickupLocation;
  late LatLng _destinationLocation;

  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};

  DateTime? _scheduledFor;
  bool _scheduledEnRouteSent = false;
  bool _scheduledAtPickupSent = false;

  bool get _isDeliveryRide {
    final t = widget.rideData['rideType']?.toString() ??
        widget.rideData['ride_type']?.toString();
    return t == 'delivery';
  }

  bool get _isScheduledRide =>
      _scheduledFor != null && !_isDeliveryRide;

  void _parseScheduledMeta() {
    final src = _ridePayload;
    final raw = src['scheduledFor'];
    DateTime? dt;
    if (raw is String) {
      dt = DateTime.tryParse(raw);
    } else if (raw != null) {
      dt = DateTime.tryParse(raw.toString());
    }
    final en = src['scheduledPickupEnRouteAt'];
    final ap = src['scheduledPickupArrivedAt'];
    _scheduledEnRouteSent = en != null;
    _scheduledAtPickupSent = ap != null;
    _scheduledFor = dt;
  }

  @override
  void initState() {
    super.initState();
    _effectiveRideId = widget.rideId;
    _ridePayload = Map<String, dynamic>.from(widget.rideData);
    if (_isDeliveryRide) {
      _stackedDeliveryScreens++;
    }
    _parseScheduledMeta();
    _initRideData();
    _syncRideStatusFromPayload();
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
      if (id == null || id == _effectiveRideId) return;
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

    final res = await ApiService.getRideDetails(_effectiveRideId);
    if (!mounted) return;
    final data = res?['data'];
    final ride = data is Map ? data['ride'] : null;
    if (ride is Map<String, dynamic>) {
      setState(() {
        _ridePayload = _mapApiRideToUi(ride);
        final id = ride['_id'] ?? ride['id'];
        if (id != null && id.toString().isNotEmpty) {
          _effectiveRideId = id.toString();
        }
        _parseScheduledMeta();
        _initRideData();
        _syncRideStatusFromPayload();
      });
      WidgetsBinding.instance.addPostFrameCallback((_) => _fitMapToRoute());
    }
  }

  Map<String, dynamic> _mapApiRideToUi(Map<String, dynamic> ride) =>
      ActiveRideScreen.ridePayloadFromApiRide(ride);

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

  Map<String, dynamic> _normalizePlace(dynamic raw) {
    if (raw is Map) {
      return Map<String, dynamic>.from(raw);
    }
    if (raw is String) {
      return {'address': raw, 'coordinates': <String, dynamic>{}};
    }
    return {};
  }

  void _initRideData() {
    final passenger = _ridePayload['passenger'] is Map
        ? Map<String, dynamic>.from(_ridePayload['passenger'] as Map)
        : <String, dynamic>{};
    final pickup = Map<String, dynamic>.from(_normalizePlace(_ridePayload['pickup']));
    final destination =
        Map<String, dynamic>.from(_normalizePlace(_ridePayload['destination']));
    final pricing = _ridePayload['pricing'] is Map
        ? Map<String, dynamic>.from(_ridePayload['pricing'] as Map)
        : <String, dynamic>{};

    _passengerName = passenger['name']?.toString() ?? 'Client';
    _passengerPhone = passenger['phone']?.toString().trim() ?? '';
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

    _pickupLocation = _placeToLatLng(pickup, 14.6928, -17.4467);
    _destinationLocation = _placeToLatLng(destination, 14.7392, -17.4978);

    _updateMarkers();
  }

  /// Préfère `coordinates` { lat, lng } ; sinon GeoJSON `location.coordinates` [lng, lat].
  LatLng _placeToLatLng(Map<String, dynamic> place, double defLat, double defLng) {
    final coords = place['coordinates'];
    if (coords != null) {
      return _coordsToLatLng(coords, defLat, defLng);
    }
    final loc = place['location'];
    if (loc is Map && loc['coordinates'] is List) {
      return _coordsToLatLng(loc['coordinates'], defLat, defLng);
    }
    return LatLng(defLat, defLng);
  }

  /// Distance km (haversine).
  double _distanceKm(LatLng a, LatLng b) {
    const earth = 6371.0;
    double rad(double d) => d * math.pi / 180.0;
    final dLat = rad(b.latitude - a.latitude);
    final dLon = rad(b.longitude - a.longitude);
    final la1 = rad(a.latitude);
    final la2 = rad(b.latitude);
    final h = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(la1) * math.cos(la2) * math.sin(dLon / 2) * math.sin(dLon / 2);
    return 2 * earth * math.asin(math.min(1.0, math.sqrt(h)));
  }

  /// Alignement UI avec le statut Mongo (`started` → course en cours).
  void _syncRideStatusFromPayload() {
    final raw = _ridePayload['status']?.toString();
    if (raw == null || raw.isEmpty) return;
    switch (raw) {
      case 'started':
        _rideStatus = 'in_progress';
        break;
      case 'arrived':
        _rideStatus = 'arrived';
        break;
      case 'arriving':
      case 'accepted':
        _rideStatus = 'accepted';
        break;
      case 'completed':
        _rideStatus = 'completed';
        break;
      default:
        break;
    }
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
      _fitMapToRoute();
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
        _fitMapToRoute();

        // Envoyer la position au backend via Socket.io dès l'acceptation
        // Le client peut ainsi voir le véhicule se déplacer en temps réel
        if (_rideStatus == 'accepted' || _rideStatus == 'arrived' || _rideStatus == 'in_progress') {
          SocketService().updateDriverLocation(
            rideId: _effectiveRideId,
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

  /// Cadre la carte sur le trajet (Dakar / route) sans inclure un GPS simulateur éloigné
  /// (sinon zoom minimal → toute l’Afrique de l’Ouest).
  void _fitMapToRoute() {
    if (_mapController == null) return;

    final points = <LatLng>[_pickupLocation, _destinationLocation];

    if (_currentPosition != null) {
      final driver = LatLng(_currentPosition!.latitude, _currentPosition!.longitude);
      final mid = LatLng(
        (_pickupLocation.latitude + _destinationLocation.latitude) / 2,
        (_pickupLocation.longitude + _destinationLocation.longitude) / 2,
      );
      if (_distanceKm(driver, mid) <= 120) {
        points.add(driver);
      }
    }

    var minLat = points.first.latitude;
    var maxLat = points.first.latitude;
    var minLng = points.first.longitude;
    var maxLng = points.first.longitude;
    for (final p in points) {
      minLat = math.min(minLat, p.latitude);
      maxLat = math.max(maxLat, p.latitude);
      minLng = math.min(minLng, p.longitude);
      maxLng = math.max(maxLng, p.longitude);
    }
    if ((maxLat - minLat).abs() < 0.002 && (maxLng - minLng).abs() < 0.002) {
      minLat -= 0.008;
      maxLat += 0.008;
      minLng -= 0.008;
      maxLng += 0.008;
    }

    final bounds = LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );

    try {
      _mapController!.animateCamera(CameraUpdate.newLatLngBounds(bounds, 64));
    } catch (_) {
      _mapController!.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: LatLng((minLat + maxLat) / 2, (minLng + maxLng) / 2),
            zoom: 12.5,
          ),
        ),
      );
    }
  }

  void _notifyScheduledEnRoute() {
    if (!_isScheduledRide) return;
    SocketService().emitScheduledPickupEnRoute(_effectiveRideId);
    setState(() => _scheduledEnRouteSent = true);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Le client a été notifié que vous êtes en route.'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _notifyScheduledAtPickup() {
    if (!_isScheduledRide) return;
    SocketService().emitScheduledPickupAtPickup(_effectiveRideId);
    setState(() => _scheduledAtPickupSent = true);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Le client a été notifié que vous êtes sur place.'),
        backgroundColor: Colors.green,
      ),
    );
  }

  Future<void> _signalArrival() async {
    setState(() => _isLoading = true);
    try {
      await ApiService.arriveAtPickup(_effectiveRideId);
      SocketService().arrivedAtPickup(_effectiveRideId);
      
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
      await ApiService.startRide(_effectiveRideId);
      SocketService().startTrip(_effectiveRideId);
      
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
              rideId: _effectiveRideId,
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

  Future<void> _callPassengerByPhone() async {
    final raw = _passengerPhone.trim();
    if (raw.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Numéro du client indisponible. Rouvrez la course ou attendez le chargement des détails.',
          ),
        ),
      );
      return;
    }
    final uri = Uri(scheme: 'tel', path: raw);
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Impossible d’ouvrir l’application téléphone.')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur appel: $e')),
      );
    }
  }

  Future<void> _startVoipToPassenger() async {
    if (!SocketService().isConnected) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Connexion temps réel indisponible. Réessayez dans quelques secondes.'),
        ),
      );
      return;
    }
    await SocketService().startVoipCall(_effectiveRideId);
  }

  Future<void> _completeRide() async {
    setState(() => _isLoading = true);
    try {
      await ApiService.completeRide(_effectiveRideId);
      
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
                      rideId: _effectiveRideId,
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
            cameraTargetBounds: MapStyleService.senegalBounds,
            minMaxZoomPreference: MapStyleService.zoomPreference,
            markers: _markers,
            polylines: _polylines,
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            onMapCreated: (controller) async {
              _mapController = controller;
              await MapStyleService.apply(controller);
              _fitMapToRoute();
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
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        OutlinedButton.icon(
                          onPressed: _callPassengerByPhone,
                          icon: const Icon(Icons.phone, size: 18),
                          label: const Text('Téléphone'),
                        ),
                        OutlinedButton.icon(
                          onPressed: _startVoipToPassenger,
                          icon: const Icon(Icons.headset_mic, size: 18),
                          label: const Text('Appel DuDu'),
                        ),
                      ],
                    ),
                    if (_isScheduledRide && _rideStatus == 'accepted') ...[
                      const SizedBox(height: 12),
                      Text(
                        'Trajet planifié',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[700],
                        ),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: _isLoading || _scheduledEnRouteSent
                              ? null
                              : _notifyScheduledEnRoute,
                          icon: const Icon(Icons.navigation, size: 18),
                          label: const Text('Je pars vous chercher'),
                        ),
                      ),
                      const SizedBox(height: 6),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: _isLoading || _scheduledAtPickupSent
                              ? null
                              : _notifyScheduledAtPickup,
                          icon: const Icon(Icons.place, size: 18),
                          label: const Text('Je suis sur place'),
                        ),
                      ),
                    ],
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
                        rideId: _effectiveRideId,
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
