import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'notification_service.dart';
import 'call_service.dart';
import 'api_service.dart';
import '../config/app_config.dart';

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
  final List<Map<String, dynamic>> _currentRideRequests = [];

  Stream<Map<String, dynamic>> get rideRequestsStream => _rideRequestController.stream;
  Stream<String> get rideClosedStream => _rideClosedController.stream;

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
      print('✅ Socket.io connecté (Chauffeur)');
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

    _socket!.on('new-ride-request', (data) {
      print('🔔 Nouvelle demande de course: ${data['rideId']}');
      if (data is Map) {
        final mapData = Map<String, dynamic>.from(data);
        final rideId = mapData['id']?.toString() ?? mapData['rideId']?.toString();
        if (rideId != null) {
          _currentRideRequests.removeWhere((r) =>
              r['id']?.toString() == rideId || r['rideId']?.toString() == rideId);
          _currentRideRequests.add(mapData);
        }
        try {
          // Déclencher une notification locale avec son + vibration
          final passengerRaw = mapData['passenger'];
          final pickupRaw = mapData['pickup'];
          final destinationRaw = mapData['destination'];
          final pricingRaw = mapData['pricing'];

          final passenger = passengerRaw is Map ? passengerRaw : <String, dynamic>{};
          final pricing = pricingRaw is Map ? pricingRaw : <String, dynamic>{};

          final passengerName = passenger['name']?.toString() ?? 'Client DUDU';

          String pickupAddress;
          if (pickupRaw is Map) {
            pickupAddress = pickupRaw['address']?.toString() ??
                pickupRaw['label']?.toString() ??
                'Point de départ';
          } else if (pickupRaw is String) {
            pickupAddress = pickupRaw;
          } else {
            pickupAddress = 'Point de départ';
          }

          String destinationAddress;
          if (destinationRaw is Map) {
            destinationAddress = destinationRaw['address']?.toString() ??
                destinationRaw['label']?.toString() ??
                'Destination';
          } else if (destinationRaw is String) {
            destinationAddress = destinationRaw;
          } else {
            destinationAddress = 'Destination';
          }

          final price = (pricing['customPrice'] ??
                  pricing['totalPrice'] ??
                  mapData['customPrice'] ??
                  0)
              .toDouble();

          NotificationService().showRideRequestNotification(
            rideId: rideId ?? '',
            passengerName: passengerName,
            pickupAddress: pickupAddress,
            destinationAddress: destinationAddress,
            price: price,
          );
        } catch (e) {
          print('⚠️ Erreur lors de la préparation de la notification de demande: $e');
        }

        // Toujours pousser les données sur le stream, même si la notif échoue
        _rideRequestController.add(mapData);
      }
    });

    _socket!.on('ride-cancelled', (data) {
      print('❌ Course annulée: ${data['rideId']}');
      final rideId = data is Map ? data['rideId']?.toString() : null;
      if (rideId != null) {
        _currentRideRequests.removeWhere((r) =>
            r['id']?.toString() == rideId || r['rideId']?.toString() == rideId);
        _rideClosedController.add(rideId);
      }
    });

    _socket!.on('ride-no-longer-available', (data) {
      final rideId = data is Map ? data['rideId']?.toString() : null;
      if (rideId != null) {
        _rideClosedController.add(rideId);
      }
    });

    // Écouter quand une course est acceptée par un autre chauffeur
    _socket!.on('ride-taken', (data) {
      print('🚫 Course prise par un autre chauffeur: ${data['rideId']}');
      final rideId = data is Map ? data['rideId']?.toString() : null;
      if (rideId != null) {
        // Retirer la course de la liste des demandes en cours
        _currentRideRequests.removeWhere((r) =>
            r['id']?.toString() == rideId || r['rideId']?.toString() == rideId);
        // Notifier les écrans que cette course n'est plus disponible
        _rideClosedController.add(rideId);
      }
    });

    _socket!.on('ride-accepted-success', (data) {
      final rideId = data is Map ? data['rideId']?.toString() : null;
      if (rideId != null && _pendingAccepts.containsKey(rideId)) {
        _pendingAccepts.remove(rideId)?.complete(Map<String, dynamic>.from(data));
      }
    });

    _socket!.on('accept-ride-rejected', (data) {
      if (data is! Map) return;
      final rideId = data['rideId']?.toString();
      final msg = data['message']?.toString() ?? 'Acceptation refusée';
      if (rideId != null && _pendingAccepts.containsKey(rideId)) {
        _pendingAccepts.remove(rideId)?.completeError(Exception(msg));
      }
    });
  }

  /// Émettre la position du chauffeur en temps réel
  void emitDriverLocation({
    required String rideId,
    required double latitude,
    required double longitude,
    required double speed,
    required double heading,
  }) {
    if (!_isConnected || _socket == null) {
      print('⚠️ Socket non connecté - impossible d\'envoyer la position');
      return;
    }

    _socket!.emit('driver-location-update', {
      'rideId': rideId,
      'latitude': latitude,
      'longitude': longitude,
      'speed': speed,
      'heading': heading,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  /// Déconnecter du serveur Socket.io
  void disconnect() {
    _locationUpdateTimer?.cancel();
    _locationUpdateTimer = null;
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
    _isConnected = false;
    _currentRideId = null;
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

    // Récupérer l'ID réel du chauffeur depuis ApiService
    final driverData = ApiService.lastDriverData;
    final driverId = driverData?['id']?.toString() ?? driverData?['_id']?.toString() ?? '';

    _socket!.emit('driver:update_location', {
      'rideId': rideId,
      'driverId': driverId,
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

    _socket!.emit('driver-arrived', {
      'rideId': rideId,
    });

    print('✅ Arrivée signalée: $rideId');
  }

  /// Démarrer le trajet (après avoir récupéré le client/colis)
  void startTrip(String rideId) {
    if (!_isConnected) return;

    _socket!.emit('start-ride', {
      'rideId': rideId,
    });

    print('🏁 Trajet démarré: $rideId');
  }

  /// Terminer la course
  void completeRide(String rideId) {
    if (!_isConnected) return;

    _socket!.emit('complete-ride', {
      'rideId': rideId,
    });

    _stopLocationUpdates();
    _currentRideId = null;

    print('🏁 Course terminée: $rideId');
  }

  /// Mettre à jour la position du chauffeur pendant une course
  void updateDriverLocation({
    required String rideId,
    required double latitude,
    required double longitude,
    double? heading,
  }) {
    if (!_isConnected) return;

    _socket!.emit('driver-location-update', {
      'rideId': rideId,
      'latitude': latitude,
      'longitude': longitude,
      'heading': heading ?? 0.0,
    });
  }

  Future<Map<String, dynamic>> acceptRide(String rideId) {
    if (!_isConnected) {
      throw Exception('Socket non connecté');
    }

    print('📨 Envoi accept-ride pour rideId=$rideId');
    final completer = Completer<Map<String, dynamic>>();
    _pendingAccepts[rideId] = completer;
    _socket!.emit('accept-ride', {'rideId': rideId});
    return completer.future.timeout(
      const Duration(seconds: 10),
      onTimeout: () {
        _pendingAccepts.remove(rideId);
        print('⏱️ Timeout accept-ride pour rideId=$rideId');
        throw TimeoutException('Aucune réponse du serveur pour l\'acceptation');
      },
    );
  }

  /// Refus d'une demande de course — notifie le passager via le serveur
  void refuseRide(String rideId) {
    if (!_isConnected || _socket == null) {
      print('⚠️ Socket non connecté — refus non envoyé');
      return;
    }
    _socket!.emit('refuse-ride', {'rideId': rideId});
    print('📤 refuse-ride émis pour $rideId');
  }

  void dispose() {
    _rideRequestController.close();
    _rideClosedController.close();
    _locationUpdateTimer?.cancel();
    _locationUpdateTimer = null;
    _pendingAccepts.clear();
    _currentRideRequests.clear();
  }

  /// Getters
  bool get isConnected => _isConnected;
  String? get currentRideId => _currentRideId;
  List<Map<String, dynamic>> get currentRideRequests => _currentRideRequests;
  IO.Socket? get rawSocket => _socket;

  /// Marquer une demande de course comme traitée
  void markRideRequestAsHandled(String rideId) {
    _currentRideRequests.removeWhere((r) =>
        r['id']?.toString() == rideId || r['rideId']?.toString() == rideId);
  }

  /// Alias utilisé par certains écrans (compatibilité)
  void removeRideRequest(String rideId) {
    markRideRequestAsHandled(rideId);
  }

  /// Démarrer un appel VOIP (BETA) pour une course donnée
  Future<void> startVoipCall(String rideId) async {
    if (!_isConnected || _socket == null) return;
    await CallService().startCall(rideId, _socket!);
  }
}
