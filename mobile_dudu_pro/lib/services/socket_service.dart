import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

/// Service Socket.io pour communication temps réel
class SocketService {
  static final SocketService _instance = SocketService._internal();
  factory SocketService() => _instance;
  SocketService._internal();

  IO.Socket? _socket;
  bool _isConnected = false;
  String? _currentRideId;
  Timer? _locationUpdateTimer;
  final _rideRequestController = StreamController<Map<String, dynamic>>.broadcast();
  final _rideClosedController = StreamController<String>.broadcast();
  final Map<String, Completer<Map<String, dynamic>>> _pendingAccepts = {};

  Stream<Map<String, dynamic>> get rideRequestsStream => _rideRequestController.stream;
  Stream<String> get rideClosedStream => _rideClosedController.stream;

  /// Connecter au serveur Socket.io
  void connect(String token) {
    if (_isConnected) {
      print('⚠️ Socket déjà connecté');
      return;
    }

    _socket = IO.io(
      'http://213.154.90.11',
      IO.OptionBuilder()
          .setTransports(['websocket'])
          .enableAutoConnect()
          .enableReconnection()
          .setAuth({'token': token})
          .build(),
    );

    _socket!.onConnect((_) {
      print('✅ Socket.io connecté (Chauffeur)');
      _isConnected = true;
    });

    _socket!.onDisconnect((_) {
      print('❌ Socket.io déconnecté');
      _isConnected = false;
    });

    _socket!.onError((error) {
      print('❌ Erreur Socket.io: $error');
    });

    // Écouter les nouvelles demandes de courses
    _socket!.on('new-ride-request', (data) {
      print('🔔 Nouvelle demande de course: ${data['rideId']}');
      if (data is Map) {
        _rideRequestController.add(Map<String, dynamic>.from(data));
      }
    });

    _socket!.on('ride-cancelled', (data) {
      print('❌ Course annulée: ${data['rideId']}');
      final rideId = data is Map ? data['rideId']?.toString() : null;
      if (rideId != null) {
        _rideClosedController.add(rideId);
      }
    });

    _socket!.on('ride-no-longer-available', (data) {
      final rideId = data is Map ? data['rideId']?.toString() : null;
      if (rideId != null) {
        _rideClosedController.add(rideId);
      }
    });

    _socket!.on('ride-accepted-success', (data) {
      final rideId = data is Map ? data['rideId']?.toString() : null;
      if (rideId != null && _pendingAccepts.containsKey(rideId)) {
        _pendingAccepts.remove(rideId)?.complete(Map<String, dynamic>.from(data));
      }
    });
  }

  /// Déconnecter
  void disconnect() {
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
    _isConnected = false;
    _stopLocationUpdates();
    print('🔌 Socket.io déconnecté');
  }

  /// Démarrer une course (aller chercher le client/colis)
  void startRide({
    required String rideId,
    required String driverId,
    required String passengerId,
    required String vehicleType, // 'car' ou 'moto'
    required String driverName,
    required Map<String, dynamic> vehicleInfo,
  }) {
    if (!_isConnected) {
      print('⚠️ Socket non connecté');
      return;
    }

    _currentRideId = rideId;

    _socket!.emit('driver:start_ride', {
      'rideId': rideId,
      'driverId': driverId,
      'passengerId': passengerId,
      'vehicleType': vehicleType,
      'driverName': driverName,
      'vehicleInfo': vehicleInfo,
    });

    print('🚀 Course démarrée: $rideId ($vehicleType)');

    // Démarrer l'envoi de position GPS
    _startLocationUpdates(rideId);
  }

  /// Envoyer la position GPS toutes les 3 secondes
  void _startLocationUpdates(String rideId) {
    _stopLocationUpdates();

    _locationUpdateTimer = Timer.periodic(const Duration(seconds: 3), (timer) async {
      try {
        final position = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
          ),
        );

        _updateLocation(
          rideId: rideId,
          latitude: position.latitude,
          longitude: position.longitude,
          heading: position.heading,
          speed: position.speed * 3.6, // Convertir m/s en km/h
        );
      } catch (e) {
        print('❌ Erreur envoi position: $e');
      }
    });

    print('🟢 Envoi position GPS actif (toutes les 3s)');
  }

  /// Arrêter l'envoi de position
  void _stopLocationUpdates() {
    _locationUpdateTimer?.cancel();
    _locationUpdateTimer = null;
    print('⏹️ Envoi position GPS arrêté');
  }

  /// Mettre à jour la position GPS
  void _updateLocation({
    required String rideId,
    required double latitude,
    required double longitude,
    required double heading,
    required double speed,
  }) {
    if (!_isConnected) return;

    _socket!.emit('driver:update_location', {
      'rideId': rideId,
      'driverId': 'current_driver_id', // TODO: Récupérer l'ID réel
      'latitude': latitude,
      'longitude': longitude,
      'heading': heading,
      'speed': speed,
    });

    print('📡 Position envoyée: ${latitude.toStringAsFixed(6)}, ${longitude.toStringAsFixed(6)}');
  }

  /// Signaler l'arrivée au pickup
  void arrivedAtPickup(String rideId) {
    if (!_isConnected) return;

    _socket!.emit('driver:arrived_pickup', {
      'rideId': rideId,
    });

    print('✅ Arrivée signalée: $rideId');
  }

  /// Démarrer le trajet (après avoir récupéré le client/colis)
  void startTrip(String rideId) {
    if (!_isConnected) return;

    _socket!.emit('driver:start_trip', {
      'rideId': rideId,
    });

    print('🏁 Trajet démarré: $rideId');
  }

  /// Terminer la course
  void completeRide(String rideId) {
    if (!_isConnected) return;

    _socket!.emit('driver:complete_ride', {
      'rideId': rideId,
    });

    _stopLocationUpdates();
    _currentRideId = null;

    print('🏁 Course terminée: $rideId');
  }

  Future<Map<String, dynamic>> acceptRide(String rideId) {
    if (!_isConnected) {
      throw Exception('Socket non connecté');
    }

    final completer = Completer<Map<String, dynamic>>();
    _pendingAccepts[rideId] = completer;
    _socket!.emit('accept-ride', {'rideId': rideId});
    return completer.future.timeout(
      const Duration(seconds: 10),
      onTimeout: () {
        _pendingAccepts.remove(rideId);
        throw TimeoutException('Aucune réponse du serveur pour l\'acceptation');
      },
    );
  }

  void dispose() {
    _rideRequestController.close();
    _rideClosedController.close();
    _locationUpdateTimer?.cancel();
    _locationUpdateTimer = null;
    _pendingAccepts.clear();
  }

  /// Getters
  bool get isConnected => _isConnected;
  String? get currentRideId => _currentRideId;
}


