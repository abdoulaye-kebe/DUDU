import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'call_service.dart';
import '../config/app_config.dart';

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
  Function(Map<String, dynamic>)? onRideAccepted;
  Function(Map<String, dynamic>)? onRideRefusedByDriver;

  /// Connecter au serveur Socket.io
  void connect(String token) {
    if (_isConnected) {
      print('⚠️ Socket déjà connecté');
      return;
    }

    _socket = IO.io(
      AppConfig.socketUrl,
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
      // Attacher le CallService pour gérer la signalisation VOIP
      CallService().attachToSocket(_socket);
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

  /// Socket.io peut envoyer soit `{...}` soit `[{...}]` selon la version / le serveur.
  /// Utiliser une [List] avec une clé [String] provoque : type 'String' is not a subtype of type 'int'.
  static Map<String, dynamic>? _payloadAsMap(dynamic data) {
    if (data == null) return null;
    if (data is Map) {
      return Map<String, dynamic>.from(data as Map);
    }
    if (data is List && data.isNotEmpty && data.first is Map) {
      return Map<String, dynamic>.from(data.first as Map);
    }
    return null;
  }

  /// Configurer les écouteurs d'événements
  void _setupEventListeners() {
    // Course acceptée par un chauffeur
    _socket!.on('ride-accepted', (data) {
      print('✅ Course acceptée par un chauffeur');
      final map = _payloadAsMap(data);
      if (onRideAccepted != null && map != null) {
        onRideAccepted!(map);
      }
    });

    _socket!.on('ride-refused-by-driver', (data) {
      print('ℹ️ Refus chauffeur pour une demande: $data');
      final map = _payloadAsMap(data);
      if (onRideRefusedByDriver != null && map != null) {
        onRideRefusedByDriver!(map);
      }
    });

    // Le chauffeur arrive
    _socket!.on('ride:driver_coming', (data) {
      final map = _payloadAsMap(data);
      print('🚗 Chauffeur en route: ${map?['driverName']}');
      if (onDriverComing != null && map != null) {
        onDriverComing!(map);
      }
    });

    // Mise à jour position du chauffeur en temps réel
    _socket!.on('driver-location', (data) {
      final map = _payloadAsMap(data);
      print('📍 Position chauffeur mise à jour: ${map?['latitude']}, ${map?['longitude']}');
      if (onDriverLocationUpdate != null && map != null) {
        onDriverLocationUpdate!(map);
      }
    });

    // Chauffeur arrivé
    _socket!.on('ride:driver_arrived', (data) {
      print('✅ Chauffeur arrivé !');
      final map = _payloadAsMap(data);
      if (onDriverArrived != null && map != null) {
        onDriverArrived!(map);
      }
    });

    // Trajet démarré
    _socket!.on('ride:trip_started', (data) {
      print('🏁 Trajet démarré');
      final map = _payloadAsMap(data);
      if (onTripStarted != null && map != null) {
        onTripStarted!(map);
      }
    });

    // Course terminée
    _socket!.on('ride:completed', (data) {
      print('🎉 Course terminée !');
      final map = _payloadAsMap(data);
      if (onRideCompleted != null && map != null) {
        onRideCompleted!(map);
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
  IO.Socket? get rawSocket => _socket;

  /// Démarrer un appel VOIP (BETA) pour une course donnée
  Future<void> startVoipCall(String rideId) async {
    if (!_isConnected || _socket == null) return;
    await CallService().startCall(rideId, _socket!);
  }
}
