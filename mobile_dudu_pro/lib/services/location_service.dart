import 'package:geolocator/geolocator.dart';
import 'dart:async';

/// Service pour gérer la localisation GPS du chauffeur
class LocationService {
  static final LocationService _instance = LocationService._internal();
  factory LocationService() => _instance;
  LocationService._internal();

  StreamSubscription<Position>? _positionStreamSubscription;
  Position? _lastPosition;
  bool _isTracking = false;

  /// Callback appelé à chaque mise à jour de position
  Function(Position)? onLocationUpdate;

  /// Démarrer le suivi GPS en continu
  Future<void> startTracking() async {
    if (_isTracking) {
      print('⚠️ Tracking déjà actif');
      return;
    }

    try {
      // Vérifier et demander les permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        throw Exception('Permission de localisation refusée');
      }

      // Vérifier que le service est activé
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception('Service de localisation désactivé');
      }

      print('✅ Démarrage du tracking GPS');

      // Configuration du stream de position
      const LocationSettings locationSettings = LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10, // Mise à jour tous les 10 mètres
      );

      // Écouter les changements de position
      _positionStreamSubscription = Geolocator.getPositionStream(
        locationSettings: locationSettings,
      ).listen((Position position) {
        _lastPosition = position;
        _isTracking = true;

        print('📍 GPS: ${position.latitude.toFixed(6)}, ${position.longitude.toFixed(6)} - ${position.speed.toStringAsFixed(1)} m/s');

        // Appeler le callback si défini
        if (onLocationUpdate != null) {
          onLocationUpdate!(position);
        }
      }, onError: (error) {
        print('❌ Erreur GPS: $error');
        _isTracking = false;
      });

      print('🟢 Tracking GPS actif');
    } catch (e) {
      print('❌ Erreur démarrage tracking: $e');
      _isTracking = false;
      rethrow;
    }
  }

  /// Arrêter le suivi GPS
  void stopTracking() {
    _positionStreamSubscription?.cancel();
    _positionStreamSubscription = null;
    _isTracking = false;
    print('⏹️ Tracking GPS arrêté');
  }

  /// Obtenir la dernière position connue
  Position? get lastPosition => _lastPosition;

  /// Vérifier si le tracking est actif
  bool get isTracking => _isTracking;

  /// Obtenir la position actuelle (une seule fois)
  Future<Position?> getCurrentPosition() async {
    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
      _lastPosition = position;
      return position;
    } catch (e) {
      print('❌ Erreur obtention position: $e');
      return null;
    }
  }
}

extension PositionExtension on Position {
  /// Convertir la position en Map pour Socket.io
  Map<String, dynamic> toMap() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      'speed': speed,
      'heading': heading,
      'accuracy': accuracy,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}

extension DoubleExtension on double {
  String toFixed(int decimals) {
    return toStringAsFixed(decimals);
  }
}


