import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'call_service.dart';
import 'notification_service.dart';
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
  Function(Map<String, dynamic>)? onRideCounterOffer;

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

  static void _notifyDriverAccepted(Map<String, dynamic> map) {
    final d = map['driver'];
    if (d is! Map) return;
    final dm = Map<String, dynamic>.from(d);
    final name = (dm['fullName'] ?? dm['name'] ?? 'Chauffeur').toString();
    final vehicle = dm['vehicle'];
    String vehicleLine = '';
    if (vehicle is Map) {
      final vm = Map<String, dynamic>.from(vehicle);
      final model =
          '${vm['make'] ?? vm['brand'] ?? ''} ${vm['model'] ?? ''}'.trim();
      final color = vm['color']?.toString() ?? '';
      final plate =
          vm['plateNumber']?.toString() ?? vm['plate']?.toString() ?? '';
      vehicleLine = [color, model, plate]
          .where((s) => s.trim().isNotEmpty)
          .join(' • ');
    }
    final etaRaw = map['estimatedArrivalMinutes'] ?? map['estimatedArrival'];
    int? etaM;
    if (etaRaw is num) etaM = etaRaw.round();
    NotificationService().showDriverAcceptedNotification(
      driverLine: name,
      vehicleLine: vehicleLine.isEmpty ? null : vehicleLine,
      estimatedMinutes: etaM,
    );
  }

  /// Configurer les écouteurs d'événements
  void _setupEventListeners() {
    // Course acceptée par un chauffeur
    _socket!.on('ride-accepted', (data) {
      print('✅ Course acceptée par un chauffeur');
      final map = _payloadAsMap(data);
      if (!kIsWeb && map != null) {
        _notifyDriverAccepted(map);
      }
      if (onRideAccepted != null && map != null) {
        onRideAccepted!(map);
      }
    });

    _socket!.on('ride-refused-by-driver', (data) {
      print('ℹ️ Refus chauffeur pour une demande: $data');
      final map = _payloadAsMap(data);
      if (!kIsWeb && map != null) {
        final msg = map['message']?.toString() ??
            'Un chauffeur a décliné. Nous cherchons un autre chauffeur.';
        NotificationService().showRideRefusedByDriverNotification(body: msg);
      }
      if (onRideRefusedByDriver != null && map != null) {
        onRideRefusedByDriver!(map);
      }
    });

    _socket!.on('ride-counter-offer', (data) {
      final map = _payloadAsMap(data);
      if (onRideCounterOffer != null && map != null) {
        onRideCounterOffer!(map);
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

    // Chauffeur arrivé (le backend émet `driver-arrived` vers passenger_* ; tracking peut utiliser ride:driver_arrived)
    void handleDriverArrived(dynamic data) {
      print('✅ Chauffeur arrivé !');
      final map = _payloadAsMap(data);
      if (map == null) return;
      map.putIfAbsent(
        'message',
        () => 'Votre chauffeur est arrivé au point de prise en charge',
      );

      if (!kIsWeb) {
        final driverName = map['driverName']?.toString() ??
            (map['driver'] is Map
                ? (map['driver'] as Map)['name']?.toString()
                : null) ??
            'Votre chauffeur';
        final msg = map['message']?.toString();
        NotificationService().showDriverArrivedNotification(
          driverName: driverName,
          bodyText: msg,
        );
        HapticFeedback.heavyImpact();
        Future<void> pulse() async {
          await Future<void>.delayed(const Duration(milliseconds: 120));
          HapticFeedback.mediumImpact();
          await Future<void>.delayed(const Duration(milliseconds: 140));
          HapticFeedback.mediumImpact();
        }

        pulse();
      }

      onDriverArrived?.call(map);
    }

    _socket!.on('ride:driver_arrived', handleDriverArrived);
    _socket!.on('driver-arrived', handleDriverArrived);

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
