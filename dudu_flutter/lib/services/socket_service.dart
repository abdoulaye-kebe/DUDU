import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'dart:async';

/// Service Socket.io côté client pour recevoir les mises à jour en temps réel
class SocketService {
  static final SocketService _instance = SocketService._internal();
  factory SocketService() => _instance;
  SocketService._internal();

  IO.Socket? _socket;
  bool _isConnected = false;

  // Callbacks pour les événements
  Function(Map<String, dynamic>)? onDriverComing;
  Function(Map<String, dynamic>)? onDriverLocationUpdate;
  Function(Map<String, dynamic>)? onDriverArrived;
  Function(Map<String, dynamic>)? onTripStarted;
  Function(Map<String, dynamic>)? onRideCompleted;

  /// Connecter au serveur Socket.io
  void connect(String token) {
    if (_isConnected) {
      print('⚠️ Socket déjà connecté');
      return;
    }

    _socket = IO.io(
      'http://127.0.0.1:8000',
      IO.OptionBuilder()
          .setTransports(['websocket'])
          .enableAutoConnect()
          .enableReconnection()
          .setAuth({'token': token})
          .build(),
    );

    _socket!.onConnect((_) {
      print('✅ Socket.io connecté (Client)');
      _isConnected = true;
    });

    _socket!.onDisconnect((_) {
      print('❌ Socket.io déconnecté');
      _isConnected = false;
    });

    _socket!.onError((error) {
      print('❌ Erreur Socket.io: $error');
    });

    // Écouter les événements de course
    _setupEventListeners();
  }

  /// Configurer les écouteurs d'événements
  void _setupEventListeners() {
    // Le chauffeur arrive
    _socket!.on('ride:driver_coming', (data) {
      print('🚗 Chauffeur en route: ${data['driverName']}');
      if (onDriverComing != null) {
        onDriverComing!(Map<String, dynamic>.from(data));
      }
    });

    // Mise à jour position du chauffeur
    _socket!.on('ride:driver_location', (data) {
      print('📍 Position chauffeur mise à jour');
      if (onDriverLocationUpdate != null) {
        onDriverLocationUpdate!(Map<String, dynamic>.from(data));
      }
    });

    // Chauffeur arrivé
    _socket!.on('ride:driver_arrived', (data) {
      print('✅ Chauffeur arrivé !');
      if (onDriverArrived != null) {
        onDriverArrived!(Map<String, dynamic>.from(data));
      }
    });

    // Trajet démarré
    _socket!.on('ride:trip_started', (data) {
      print('🏁 Trajet démarré');
      if (onTripStarted != null) {
        onTripStarted!(Map<String, dynamic>.from(data));
      }
    });

    // Course terminée
    _socket!.on('ride:completed', (data) {
      print('🎉 Course terminée !');
      if (onRideCompleted != null) {
        onRideCompleted!(Map<String, dynamic>.from(data));
      }
    });
  }

  /// Démarrer le suivi d'une course
  void trackRide(String rideId) {
    if (!_isConnected) return;

    _socket!.emit('track-ride', {
      'rideId': rideId,
    });

    print('👁️ Suivi de course activé: $rideId');
  }

  /// Demander la position actuelle du chauffeur
  void requestCurrentLocation(String rideId) {
    if (!_isConnected) return;

    _socket!.emit('passenger:request_location', {
      'rideId': rideId,
    });
  }

  /// Annuler une course
  void cancelRide(String rideId, String reason) {
    if (!_isConnected) return;

    _socket!.emit('cancel-ride', {
      'rideId': rideId,
      'reason': reason,
    });

    print('❌ Course annulée: $rideId');
  }

  /// Déconnecter
  void disconnect() {
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
    _isConnected = false;
    print('🔌 Socket.io déconnecté');
  }

  /// Getters
  bool get isConnected => _isConnected;
}


