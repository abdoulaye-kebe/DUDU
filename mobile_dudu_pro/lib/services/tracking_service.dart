import 'dart:async';
import 'dart:math';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../models/ride.dart';
import 'api_service.dart';
import 'socket_service.dart';

class TrackingService {
  static final TrackingService _instance = TrackingService._internal();
  factory TrackingService() => _instance;
  TrackingService._internal();

  StreamSubscription<Position>? _positionSubscription;
  Timer? _trackingTimer;
  bool _isTracking = false;
  String? _currentRideId;
  List<RideTracking> _trackingPoints = [];
  
  // Callbacks pour les mises à jour
  Function(LatLng position, double speed, double heading)? _onLocationUpdate;
  Function(List<RideTracking> points)? _onTrackingUpdate;
  Function(String rideId, RideStatus status)? _onRideStatusUpdate;

  // Configuration du suivi
  static const Duration _trackingInterval = Duration(seconds: 5);
  static const double _minDistanceForUpdate = 10.0; // mètres
  static const double _maxSpeed = 200.0; // km/h

  Future<void> initialize() async {
    // Vérifier les permissions de localisation
    await _checkLocationPermissions();
  }

  Future<void> _checkLocationPermissions() async {
    LocationPermission permission = await Geolocator.checkPermission();
    
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Permissions de localisation refusées');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception('Permissions de localisation définitivement refusées');
    }
  }

  Future<void> startTracking({
    required String rideId,
    Function(LatLng position, double speed, double heading)? onLocationUpdate,
    Function(List<RideTracking> points)? onTrackingUpdate,
    Function(String rideId, RideStatus status)? onRideStatusUpdate,
  }) async {
    if (_isTracking) {
      await stopTracking();
    }

    _currentRideId = rideId;
    _onLocationUpdate = onLocationUpdate;
    _onTrackingUpdate = onTrackingUpdate;
    _onRideStatusUpdate = onRideStatusUpdate;
    _trackingPoints.clear();

    try {
      // Démarrer le suivi de position
      _positionSubscription = Geolocator.getPositionStream(
        locationSettings: LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: _minDistanceForUpdate.toInt(),
        ),
      ).listen(
        _handlePositionUpdate,
        onError: _handleTrackingError,
      );

      // Démarrer le timer pour envoyer les données
      _trackingTimer = Timer.periodic(_trackingInterval, (_) {
        _sendTrackingData();
      });

      _isTracking = true;
      print('Suivi GPS démarré pour la course $rideId');
    } catch (e) {
      print('Erreur démarrage suivi: $e');
      throw Exception('Impossible de démarrer le suivi GPS');
    }
  }

  Future<void> stopTracking() async {
    if (!_isTracking) return;

    try {
      // Envoyer les dernières données
      await _sendTrackingData();

      // Arrêter les subscriptions
      await _positionSubscription?.cancel();
      _positionSubscription = null;

      _trackingTimer?.cancel();
      _trackingTimer = null;

      _isTracking = false;
      _currentRideId = null;
      _trackingPoints.clear();

      print('Suivi GPS arrêté');
    } catch (e) {
      print('Erreur arrêt suivi: $e');
    }
  }

  void _handlePositionUpdate(Position position) {
    if (!_isTracking || _currentRideId == null) return;

    // Vérifier la validité de la position
    if (!_isValidPosition(position)) {
      print('Position invalide ignorée: ${position.latitude}, ${position.longitude}');
      return;
    }

    // Créer le point de suivi
    final trackingPoint = RideTracking(
      latitude: position.latitude,
      longitude: position.longitude,
      timestamp: DateTime.now(),
      speed: position.speed * 3.6, // Conversion m/s vers km/h
      heading: position.heading,
    );

    // Ajouter le point à la liste
    _trackingPoints.add(trackingPoint);

    // Limiter le nombre de points en mémoire
    if (_trackingPoints.length > 1000) {
      _trackingPoints = _trackingPoints.skip(100).toList();
    }

    // Notifier les callbacks
    _onLocationUpdate?.call(
      LatLng(position.latitude, position.longitude),
      trackingPoint.speed ?? 0.0,
      trackingPoint.heading ?? 0.0,
    );

    _onTrackingUpdate?.call(List.from(_trackingPoints));

    print('Position mise à jour: ${position.latitude}, ${position.longitude}, vitesse: ${trackingPoint.speed} km/h');
  }

  void _handleTrackingError(dynamic error) {
    print('Erreur suivi GPS: $error');
    
    // Notifier l'erreur
    _onRideStatusUpdate?.call(_currentRideId ?? '', RideStatus.cancelled);
  }

  bool _isValidPosition(Position position) {
    // Vérifier les coordonnées
    if (position.latitude < -90 || position.latitude > 90) return false;
    if (position.longitude < -180 || position.longitude > 180) return false;

    // Vérifier la vitesse (filtrer les positions aberrantes)
    if (position.speed > _maxSpeed) return false;

    // Vérifier la précision
    if (position.accuracy > 100) return false; // Plus de 100m de précision

    return true;
  }

  Future<void> _sendTrackingData() async {
    if (_trackingPoints.isEmpty || _currentRideId == null) return;

    try {
      // Envoyer les données via l'API
      await RideApiMethods.updateRideTracking(
        _currentRideId!,
        _trackingPoints,
      );

      // Envoyer via WebSocket si disponible
      await SocketService().sendTrackingUpdate(
        _currentRideId!,
        _trackingPoints.last.toJson(),
      );

      print('Données de suivi envoyées: ${_trackingPoints.length} points');
    } catch (e) {
      print('Erreur envoi données suivi: $e');
    }
  }

  // Méthodes publiques pour le contrôle du suivi
  Future<void> startRide(String rideId) async {
    await startTracking(rideId: rideId);
    _onRideStatusUpdate?.call(rideId, RideStatus.started);
  }

  Future<void> completeRide(String rideId) async {
    await stopTracking();
    _onRideStatusUpdate?.call(rideId, RideStatus.completed);
  }

  Future<void> cancelRide(String rideId) async {
    await stopTracking();
    _onRideStatusUpdate?.call(rideId, RideStatus.cancelled);
  }

  // Calculer la distance parcourue
  double calculateDistanceTraveled() {
    if (_trackingPoints.length < 2) return 0.0;

    double totalDistance = 0.0;
    for (int i = 1; i < _trackingPoints.length; i++) {
      final prev = _trackingPoints[i - 1];
      final curr = _trackingPoints[i];
      
      totalDistance += Geolocator.distanceBetween(
        prev.latitude,
        prev.longitude,
        curr.latitude,
        curr.longitude,
      );
    }

    return totalDistance / 1000; // Retourner en kilomètres
  }

  // Calculer la vitesse moyenne
  double calculateAverageSpeed() {
    if (_trackingPoints.isEmpty) return 0.0;

    double totalSpeed = 0.0;
    int validSpeeds = 0;

    for (final point in _trackingPoints) {
      if (point.speed != null && point.speed! > 0) {
        totalSpeed += point.speed!;
        validSpeeds++;
      }
    }

    return validSpeeds > 0 ? totalSpeed / validSpeeds : 0.0;
  }

  // Obtenir la position actuelle
  LatLng? getCurrentPosition() {
    if (_trackingPoints.isEmpty) return null;
    final lastPoint = _trackingPoints.last;
    return LatLng(lastPoint.latitude, lastPoint.longitude);
  }

  // Obtenir l'historique de suivi
  List<RideTracking> getTrackingHistory() {
    return List.from(_trackingPoints);
  }

  // Vérifier si le suivi est actif
  bool get isTracking => _isTracking;

  // Obtenir l'ID de la course en cours
  String? get currentRideId => _currentRideId;

  // Nettoyer les ressources
  Future<void> dispose() async {
    await stopTracking();
    _onLocationUpdate = null;
    _onTrackingUpdate = null;
    _onRideStatusUpdate = null;
  }

  // Méthodes utilitaires pour les calculs géographiques
  static double calculateDistance(LatLng point1, LatLng point2) {
    return Geolocator.distanceBetween(
      point1.latitude,
      point1.longitude,
      point2.latitude,
      point2.longitude,
    );
  }

  static double calculateBearing(LatLng from, LatLng to) {
    final lat1 = from.latitude * pi / 180;
    final lat2 = to.latitude * pi / 180;
    final deltaLon = (to.longitude - from.longitude) * pi / 180;

    final y = sin(deltaLon) * cos(lat2);
    final x = cos(lat1) * sin(lat2) - sin(lat1) * cos(lat2) * cos(deltaLon);

    final bearing = atan2(y, x) * 180 / pi;
    return (bearing + 360) % 360;
  }

  static bool isWithinRadius(LatLng point, LatLng center, double radiusMeters) {
    final distance = calculateDistance(point, center);
    return distance <= radiusMeters;
  }
}
