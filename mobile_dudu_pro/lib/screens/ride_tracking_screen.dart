import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../models/ride.dart';
import '../services/tracking_service.dart';
import '../services/notification_service.dart';
import '../services/directions_service.dart';
import '../services/socket_service.dart';

class RideTrackingScreen extends StatefulWidget {
  final Ride ride;

  const RideTrackingScreen({
    Key? key,
    required this.ride,
  }) : super(key: key);

  @override
  State<RideTrackingScreen> createState() => _RideTrackingScreenState();
}

class _RideTrackingScreenState extends State<RideTrackingScreen> {
  GoogleMapController? _mapController;
  TrackingService _trackingService = TrackingService();
  NotificationService _notificationService = NotificationService();
  RideStatus? _rideStatus;
  DateTime? _rideStartTime;
  
  LatLng? _currentPosition;
  List<RideTracking> _trackingPoints = [];
  bool _isTracking = false;
  double _currentSpeed = 0.0;
  double _totalDistance = 0.0;
  Duration _rideDuration = Duration.zero;
  Timer? _durationTimer;
  
  // Itinéraire calculé
  DirectionsResult? _routeResult;
  bool _isCalculatingRoute = false;
  String? _routeTarget;
  DateTime? _lastRouteCalcAt;
  LatLng? _lastRouteCalcOrigin;

  @override
  void initState() {
    super.initState();
    final initial = widget.ride.status;
    _rideStatus = initial == RideStatus.accepted ? RideStatus.arriving : initial;
    _rideStartTime = widget.ride.timing.startedAt;
    _initializeTracking();
  }

  @override
  void dispose() {
    _durationTimer?.cancel();
    super.dispose();
  }

  Future<void> _initializeTracking() async {
    try {
      await _trackingService.initialize();

      // Démarrer le suivi
      await _trackingService.startTracking(
        rideId: widget.ride.id,
        onLocationUpdate: _onLocationUpdate,
        onTrackingUpdate: _onTrackingUpdate,
        onRideStatusUpdate: _onRideStatusUpdate,
      );

      // Démarrer le timer de durée
      _durationTimer = Timer.periodic(const Duration(seconds: 1), (_) {
        final start = _rideStartTime;
        setState(() {
          _rideDuration = Duration(
            seconds: DateTime.now().difference(start ?? DateTime.now()).inSeconds,
          );
        });
      });

      setState(() {
        _isTracking = true;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur initialisation suivi: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  double _distanceMeters(LatLng a, LatLng b) {
    const r = 6371000.0;
    final dLat = (b.latitude - a.latitude) * math.pi / 180.0;
    final dLng = (b.longitude - a.longitude) * math.pi / 180.0;
    final lat1 = a.latitude * math.pi / 180.0;
    final lat2 = b.latitude * math.pi / 180.0;

    final h = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(lat1) * math.cos(lat2) * math.sin(dLng / 2) * math.sin(dLng / 2);
    final c = 2 * math.atan2(math.sqrt(h), math.sqrt(1 - h));
    return r * c;
  }

  bool _shouldRecalculateRoute({required LatLng origin, required String targetKey}) {
    if (_isCalculatingRoute) return false;
    if (_routeTarget != targetKey) return true;

    final lastAt = _lastRouteCalcAt;
    final lastOrigin = _lastRouteCalcOrigin;
    if (lastAt == null || lastOrigin == null) return true;

    final secondsSince = DateTime.now().difference(lastAt).inSeconds;
    final movedMeters = _distanceMeters(lastOrigin, origin);

    // Limiter les appels API
    if (secondsSince < 30 && movedMeters < 250) return false;
    return true;
  }

  /// Calculer l'itinéraire le plus court entre deux points
  Future<void> _calculateRoute({
    required LatLng origin,
    required LatLng destination,
    required String targetKey,
  }) async {
    setState(() {
      _isCalculatingRoute = true;
    });

    try {
      _routeTarget = targetKey;
      _lastRouteCalcAt = DateTime.now();
      _lastRouteCalcOrigin = origin;

      final result = await DirectionsService.getDirections(
        origin: origin,
        destination: destination,
        travelMode: 'driving',
        alternatives: true,
      );

      if (result != null) {
        setState(() {
          _routeResult = result;
          _isCalculatingRoute = false;
        });

        // Ajuster la caméra pour voir tout l'itinéraire
        if (_mapController != null && result.points.isNotEmpty) {
          _fitRouteBounds(result.points);
        }

        print('✅ Itinéraire (plus court) calculé: ${result.distance.toStringAsFixed(2)} km, ${result.duration.toStringAsFixed(0)} min');
      } else {
        setState(() {
          _isCalculatingRoute = false;
        });
        print('⚠️ Impossible de calculer l\'itinéraire');
      }
    } catch (e) {
      setState(() {
        _isCalculatingRoute = false;
      });
      print('❌ Erreur calcul itinéraire: $e');
    }
  }

  /// Ajuster la caméra pour voir tout l'itinéraire
  void _fitRouteBounds(List<LatLng> points) {
    if (points.isEmpty) return;

    double minLat = points[0].latitude;
    double maxLat = points[0].latitude;
    double minLng = points[0].longitude;
    double maxLng = points[0].longitude;

    for (final point in points) {
      minLat = minLat < point.latitude ? minLat : point.latitude;
      maxLat = maxLat > point.latitude ? maxLat : point.latitude;
      minLng = minLng < point.longitude ? minLng : point.longitude;
      maxLng = maxLng > point.longitude ? maxLng : point.longitude;
    }

    final bounds = LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );

    _mapController?.animateCamera(
      CameraUpdate.newLatLngBounds(bounds, 100.0),
    );
  }

  void _onLocationUpdate(LatLng position, double speed, double heading) {
    setState(() {
      _currentPosition = position;
      _currentSpeed = speed;
    });

    final status = _rideStatus ?? widget.ride.status;
    final pickup = LatLng(widget.ride.pickup.latitude, widget.ride.pickup.longitude);
    final destination = LatLng(widget.ride.destination.latitude, widget.ride.destination.longitude);

    // Itinéraire chauffeur -> pickup (avant départ)
    if (status == RideStatus.arriving || status == RideStatus.accepted || status == RideStatus.requested) {
      if (_shouldRecalculateRoute(origin: position, targetKey: 'to_pickup')) {
        _calculateRoute(origin: position, destination: pickup, targetKey: 'to_pickup');
      }
    }

    // Itinéraire chauffeur -> destination (pendant la course)
    if (status == RideStatus.started) {
      if (_shouldRecalculateRoute(origin: position, targetKey: 'to_destination')) {
        _calculateRoute(origin: position, destination: destination, targetKey: 'to_destination');
      }
    }

    // Mettre à jour la caméra de la carte
    _mapController?.animateCamera(
      CameraUpdate.newLatLng(position),
    );
  }

  void _onTrackingUpdate(List<RideTracking> points) {
    setState(() {
      _trackingPoints = points;
      _totalDistance = _trackingService.calculateDistanceTraveled();
    });
  }

  void _onRideStatusUpdate(String rideId, RideStatus status) {
    if (!mounted) return;
    setState(() {
      _rideStatus = status;
      if (status == RideStatus.started && _rideStartTime == null) {
        _rideStartTime = DateTime.now();
      }
    });

    // Recalculer l'itinéraire selon le statut
    final current = _currentPosition;
    if (current != null) {
      final pickup = LatLng(widget.ride.pickup.latitude, widget.ride.pickup.longitude);
      final destination = LatLng(widget.ride.destination.latitude, widget.ride.destination.longitude);

      if (status == RideStatus.arriving || status == RideStatus.accepted || status == RideStatus.requested) {
        _calculateRoute(origin: current, destination: pickup, targetKey: 'to_pickup');
      }
      if (status == RideStatus.started) {
        _calculateRoute(origin: current, destination: destination, targetKey: 'to_destination');
      }
    }
    // Gérer les changements de statut
    switch (status) {
      case RideStatus.completed:
        _handleRideCompleted();
        break;
      case RideStatus.cancelled:
        _handleRideCancelled();
        break;
      default:
        break;
    }
  }

  void _handleRideCompleted() {
    _trackingService.stopTracking();
    _durationTimer?.cancel();
    
    _notificationService.showRideCompletedNotification(
      rideId: widget.ride.id,
      amount: widget.ride.pricing.totalPrice,
      paymentMethod: _getPaymentMethodName(widget.ride.payment.method),
    );

    Navigator.of(context).pop(true); // Retourner avec succès
  }

  void _handleRideCancelled() {
    _trackingService.stopTracking();
    _durationTimer?.cancel();
    
    Navigator.of(context).pop(false); // Retourner avec annulation
  }

  @override
  Widget build(BuildContext context) {
    final status = _rideStatus ?? widget.ride.status;
    return Scaffold(
      appBar: AppBar(
        title: Text('Course ${widget.ride.rideId}'),
        backgroundColor: Colors.blue[600],
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(_isTracking ? Icons.pause : Icons.play_arrow),
            onPressed: _toggleTracking,
            tooltip: _isTracking ? 'Pause' : 'Reprendre',
          ),
        ],
      ),
      body: Column(
        children: [
          // Carte
          Expanded(
            flex: 4,
            child: Stack(
              children: [
                GoogleMap(
                  onMapCreated: (GoogleMapController controller) {
                    _mapController = controller;
                    // Attendre un peu puis ajuster la caméra
                    Future.delayed(const Duration(milliseconds: 300), () {
                      if (_routeResult != null && _routeResult!.points.isNotEmpty) {
                        _fitRouteBounds(_routeResult!.points);
                      } else {
                        // Ajuster pour voir départ et destination
                        final bounds = LatLngBounds(
                          southwest: LatLng(
                            widget.ride.pickup.latitude < widget.ride.destination.latitude
                                ? widget.ride.pickup.latitude
                                : widget.ride.destination.latitude,
                            widget.ride.pickup.longitude < widget.ride.destination.longitude
                                ? widget.ride.pickup.longitude
                                : widget.ride.destination.longitude,
                          ),
                          northeast: LatLng(
                            widget.ride.pickup.latitude > widget.ride.destination.latitude
                                ? widget.ride.pickup.latitude
                                : widget.ride.destination.latitude,
                            widget.ride.pickup.longitude > widget.ride.destination.longitude
                                ? widget.ride.pickup.longitude
                                : widget.ride.destination.longitude,
                          ),
                        );
                        _mapController?.animateCamera(
                          CameraUpdate.newLatLngBounds(bounds, 100.0),
                        );
                      }
                    });
                  },
                  initialCameraPosition: CameraPosition(
                    target: LatLng(
                      widget.ride.pickup.latitude,
                      widget.ride.pickup.longitude,
                    ),
                    zoom: 16,
                  ),
                  markers: _buildMarkers(),
                  polylines: _buildPolylines(),
                  myLocationEnabled: true,
                  myLocationButtonEnabled: false,
                  zoomControlsEnabled: false,
                ),
                // Indicateur de chargement de l'itinéraire
                if (_isCalculatingRoute)
                  Positioned(
                    top: 16,
                    left: 16,
                    right: 16,
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                            const SizedBox(width: 12),
                            const Text('Calcul de l\'itinéraire...'),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          
          // Informations de suivi
          Expanded(
            flex: 1,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Column(
                children: [
                  // Statut de la course
                  _buildStatusCard(status),
                  const SizedBox(height: 16),
                  
                  // Informations de suivi
                  _buildTrackingInfo(),
                  const SizedBox(height: 16),
                  
                  // Actions
                  _buildActionButtons(status),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusCard(RideStatus status) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _getStatusColor(status),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            _getStatusIcon(status),
            color: Colors.white,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  status.displayName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Course ${widget.ride.rideId}',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          if (_isTracking)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'EN COURS',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTrackingInfo() {
    return Row(
      children: [
        Expanded(
          child: _buildInfoCard(
            icon: Icons.speed,
            label: 'Vitesse',
            value: '${_currentSpeed.toStringAsFixed(0)} km/h',
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildInfoCard(
            icon: Icons.straighten,
            label: 'Distance',
            value: '${_totalDistance.toStringAsFixed(1)} km',
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildInfoCard(
            icon: Icons.timer,
            label: 'Durée',
            value: _formatDuration(_rideDuration),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        children: [
          Icon(icon, color: Colors.blue[600], size: 20),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(RideStatus status) {
    String primaryLabel;
    IconData primaryIcon;
    Color primaryColor;
    VoidCallback? primaryAction;

    if (status == RideStatus.arriving || status == RideStatus.accepted) {
      primaryLabel = 'Arrivé au point';
      primaryIcon = Icons.location_on;
      primaryColor = Colors.purple;
      primaryAction = _markArrivedAtPickup;
    } else if (status == RideStatus.arrived) {
      primaryLabel = 'Démarrer la course';
      primaryIcon = Icons.play_arrow;
      primaryColor = Colors.green;
      primaryAction = _startRideNow;
    } else if (status == RideStatus.started) {
      primaryLabel = 'Terminer la course';
      primaryIcon = Icons.check;
      primaryColor = Colors.blue;
      primaryAction = _completeRide;
    } else {
      primaryLabel = 'Course terminée';
      primaryIcon = Icons.check_circle;
      primaryColor = Colors.grey;
      primaryAction = null;
    }

    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: primaryAction,
            icon: Icon(primaryIcon),
            label: Text(primaryLabel),
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              foregroundColor: Colors.white,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: _cancelRide,
            icon: const Icon(Icons.cancel),
            label: const Text('Annuler'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.red,
              side: const BorderSide(color: Colors.red, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }

  void _markArrivedAtPickup() {
    final rideId = widget.ride.id;
    SocketService().arrivedAtPickup(rideId);
    setState(() {
      _rideStatus = RideStatus.arrived;
    });
  }

  void _startRideNow() {
    final rideId = widget.ride.id;
    SocketService().startTrip(rideId);
    setState(() {
      _rideStatus = RideStatus.started;
      _rideStartTime ??= DateTime.now();
    });
  }

  Set<Marker> _buildMarkers() {
    Set<Marker> markers = {};
    
    // Marqueur de départ
    markers.add(
      Marker(
        markerId: const MarkerId('pickup'),
        position: LatLng(
          widget.ride.pickup.latitude,
          widget.ride.pickup.longitude,
        ),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
        infoWindow: InfoWindow(
          title: 'Départ',
          snippet: widget.ride.pickup.address,
        ),
      ),
    );
    
    // Marqueur de destination
    markers.add(
      Marker(
        markerId: const MarkerId('destination'),
        position: LatLng(
          widget.ride.destination.latitude,
          widget.ride.destination.longitude,
        ),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        infoWindow: InfoWindow(
          title: 'Destination',
          snippet: widget.ride.destination.address,
        ),
      ),
    );
    
    // Marqueur de position actuelle
    if (_currentPosition != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('current'),
          position: _currentPosition!,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
          infoWindow: const InfoWindow(
            title: 'Position actuelle',
            snippet: 'Vous êtes ici',
          ),
        ),
      );
    }
    
    return markers;
  }

  Set<Polyline> _buildPolylines() {
    Set<Polyline> polylines = {};
    
    // Itinéraire calculé avec Google Directions API
    if (_routeResult != null && _routeResult!.points.isNotEmpty) {
      polylines.add(
        Polyline(
          polylineId: const PolylineId('route'),
          points: _routeResult!.points,
          color: Colors.blue,
          width: 5,
          patterns: [],
        ),
      );
    } else {
      // Trajet prévu (ligne droite si pas d'itinéraire calculé)
      polylines.add(
        Polyline(
          polylineId: const PolylineId('route'),
          points: [
            LatLng(widget.ride.pickup.latitude, widget.ride.pickup.longitude),
            LatLng(widget.ride.destination.latitude, widget.ride.destination.longitude),
          ],
          color: Colors.blue,
          width: 4,
        ),
      );
    }
    
    // Trajet parcouru (en vert)
    if (_trackingPoints.length > 1) {
      List<LatLng> traveledPoints = _trackingPoints
          .map((point) => LatLng(point.latitude, point.longitude))
          .toList();
      
      polylines.add(
        Polyline(
          polylineId: const PolylineId('traveled'),
          points: traveledPoints,
          color: Colors.green,
          width: 4,
        ),
      );
    }
    
    return polylines;
  }

  Color _getStatusColor(RideStatus status) {
    switch (status) {
      case RideStatus.requested:
      case RideStatus.searching:
        return Colors.orange;
      case RideStatus.accepted:
      case RideStatus.arriving:
        return Colors.blue;
      case RideStatus.arrived:
        return Colors.purple;
      case RideStatus.started:
        return Colors.green;
      case RideStatus.completed:
        return Colors.green[700]!;
      case RideStatus.cancelled:
        return Colors.red;
      case RideStatus.noDriver:
      case RideStatus.expired:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(RideStatus status) {
    switch (status) {
      case RideStatus.requested:
        return Icons.access_time;
      case RideStatus.searching:
        return Icons.search;
      case RideStatus.accepted:
        return Icons.check_circle;
      case RideStatus.arriving:
        return Icons.directions_car;
      case RideStatus.arrived:
        return Icons.location_on;
      case RideStatus.started:
        return Icons.play_arrow;
      case RideStatus.completed:
        return Icons.check;
      case RideStatus.cancelled:
        return Icons.cancel;
      case RideStatus.noDriver:
        return Icons.person_off;
      case RideStatus.expired:
        return Icons.timer_off;
    }
  }

  String _getPaymentMethodName(String method) {
    switch (method) {
      case 'cash':
        return 'Espèces';
      case 'wave':
      case 'orange_money':
      case 'free_money':
        return 'Wave';
      default:
        return method;
    }
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return '${twoDigits(duration.inHours)}:$twoDigitMinutes:$twoDigitSeconds';
  }

  Future<void> _toggleTracking() async {
    if (_isTracking) {
      await _pauseTracking();
    } else {
      await _resumeTracking();
    }
  }

  Future<void> _pauseTracking() async {
    await _trackingService.stopTracking();
    setState(() {
      _isTracking = false;
    });
  }

  Future<void> _resumeTracking() async {
    await _trackingService.startTracking(
      rideId: widget.ride.id,
      onLocationUpdate: _onLocationUpdate,
      onTrackingUpdate: _onTrackingUpdate,
      onRideStatusUpdate: _onRideStatusUpdate,
    );
    setState(() {
      _isTracking = true;
    });
  }

  Future<void> _completeRide() async {
    try {
      SocketService().completeRide(widget.ride.id);
      if (mounted) {
        setState(() {
          _rideStatus = RideStatus.completed;
        });
      }
      await _trackingService.completeRide(widget.ride.id);
      _handleRideCompleted();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _cancelRide() async {
    try {
      await _trackingService.cancelRide(widget.ride.id);
      if (mounted) {
        setState(() {
          _rideStatus = RideStatus.cancelled;
        });
      }
      _handleRideCancelled();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
