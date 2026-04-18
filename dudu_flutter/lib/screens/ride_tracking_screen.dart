import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:async';
import 'dart:math' as math;
import 'package:url_launcher/url_launcher.dart';
import '../services/socket_service.dart';
import '../services/api_service.dart';
import '../services/map_style_service.dart';
import 'share_ride_screen.dart';
import 'rating_screen.dart';

/// Écran de suivi de course en temps réel
/// Affiche le véhicule (voiture ou moto) qui se déplace vers le client
class RideTrackingScreen extends StatefulWidget {
  final String rideId;
  final String vehicleType; // 'car' ou 'moto'
  final Map<String, dynamic> pickupLocation;
  final Map<String, dynamic> destinationLocation;
  final Map<String, dynamic> driverInfo;
  /// Libellés affichés pour le partage sécurité (depuis la recherche d’adresse)
  final String pickupAddressLabel;
  final String destinationAddressLabel;
  /// Code à communiquer au destinataire (livraison colis)
  final String? confirmationCode;

  const RideTrackingScreen({
    Key? key,
    required this.rideId,
    required this.vehicleType,
    required this.pickupLocation,
    required this.destinationLocation,
    required this.driverInfo,
    this.pickupAddressLabel = '',
    this.destinationAddressLabel = '',
    this.confirmationCode,
  }) : super(key: key);

  @override
  State<RideTrackingScreen> createState() => _RideTrackingScreenState();
}

Map<String, dynamic> _asStringKeyMap(dynamic v) {
  if (v is Map) return Map<String, dynamic>.from(v as Map);
  return {};
}

bool _isCourierVehicleType(String t) => t == 'moto' || t == 'delivery';

double? _readLocationLat(Map<String, dynamic> loc) {
  final c = loc['coordinates'];
  if (c is Map) {
    final lat = (c as Map)['latitude'];
    if (lat is num) return lat.toDouble();
  }
  final lat = loc['latitude'];
  if (lat is num) return lat.toDouble();
  return null;
}

double? _readLocationLng(Map<String, dynamic> loc) {
  final c = loc['coordinates'];
  if (c is Map) {
    final lng = (c as Map)['longitude'];
    if (lng is num) return lng.toDouble();
  }
  final lng = loc['longitude'];
  if (lng is num) return lng.toDouble();
  return null;
}

class _RideTrackingScreenState extends State<RideTrackingScreen> {
  GoogleMapController? _mapController;
  final Set<Marker> _markers = {};
  final Set<Polyline> _polylines = {};
  
  // Position actuelle du véhicule
  LatLng? _vehiclePosition;
  double _vehicleHeading = 0;
  
  // Statut de la course
  String _rideStatus = 'going_to_pickup'; // going_to_pickup, arrived, in_progress, completed
  int _estimatedTime = 5; // minutes
  double _distance = 0; // km
  /// Libellé dynamique (ex. « Votre chauffeur arrive dans environ 3 min »)
  String _etaPhrase = 'En attente de la position du chauffeur…';
  
  // Timer pour simulation
  Timer? _movementTimer;
  
  BitmapDescriptor? _vehicleIcon;
  BitmapDescriptor? _pickupIcon;
  BitmapDescriptor? _destinationIcon;

  @override
  void initState() {
    super.initState();
    _loadCustomMarkers();
    _setupSocketListeners();
    _initializeMap();
  }

  @override
  void dispose() {
    _movementTimer?.cancel();
    // Nettoyer les callbacks Socket.io
    SocketService().onDriverLocationUpdate = null;
    SocketService().onDriverArrived = null;
    SocketService().onTripStarted = null;
    SocketService().onRideCompleted = null;
    super.dispose();
  }

  /// Charger les icônes personnalisées pour les marqueurs
  Future<void> _loadCustomMarkers() async {
    // Déterminer quelle icône de véhicule utiliser selon le type
    String vehicleAsset = 'assets/images/vehicles/standard.png';
    
    if (widget.vehicleType == 'moto') {
      vehicleAsset = 'assets/images/vehicles/moto.png';
    } else if (widget.vehicleType == 'delivery') {
      vehicleAsset = 'assets/images/vehicles/delivery.png';
    } else if (widget.vehicleType == 'luxe') {
      vehicleAsset = 'assets/images/vehicles/luxe.png';
    } else if (widget.vehicleType == 'comfort') {
      vehicleAsset = 'assets/images/vehicles/comfort.png';
    } else if (widget.vehicleType == 'women_only') {
      vehicleAsset = 'assets/images/vehicles/women_only.png';
    }

    _vehicleIcon = await BitmapDescriptor.asset(
      ImageConfiguration(size: Size(48, 48)),
      vehicleAsset,
    );

    _pickupIcon = await BitmapDescriptor.asset(
      ImageConfiguration(size: Size(48, 48)),
      'assets/images/flaggps.png',
    );

    _destinationIcon = await BitmapDescriptor.asset(
      ImageConfiguration(size: Size(48, 48)),
      'assets/images/flaggps.png',
    );

    if (mounted) {
      setState(() {
        _updateMarkers();
      });
    }
  }

  /// Configurer les écouteurs Socket.io pour recevoir les mises à jour en temps réel
  void _setupSocketListeners() {
    final socketService = SocketService();

    // Écouter les mises à jour de position du véhicule
    socketService.onDriverLocationUpdate = (data) {
      final latitude = (data['latitude'] as num?)?.toDouble();
      final longitude = (data['longitude'] as num?)?.toDouble();
      final heading = (data['heading'] as num?)?.toDouble() ?? 0.0;
      final eta = (data['etaMinutes'] as num?)?.round();
      final dist = (data['distanceToTargetKm'] as num?)?.toDouble();
      final phase = data['targetPhase']?.toString();

      if (latitude != null && longitude != null && mounted) {
        setState(() {
          if (dist != null && dist >= 0) {
            _distance = dist;
          }
          if (eta != null) {
            _estimatedTime = eta;
            _etaPhrase = _formatDriverEtaPhrase(eta, phase: phase);
          }
          _animateVehicleToPosition(
            LatLng(latitude, longitude),
            heading: heading,
          );
        });
      }
    };

    // Chauffeur arrivé au pickup
    socketService.onDriverArrived = (data) {
      if (mounted) {
        setState(() {
          _rideStatus = 'arrived';
          _etaPhrase = _isCourierVehicleType(widget.vehicleType)
              ? 'Votre livreur est au point de rencontre'
              : 'Votre chauffeur est arrivé au point de prise en charge';
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              data['message'] ?? 'Chauffeur arrivé !',
              style: const TextStyle(fontSize: 16),
            ),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    };

    // Trajet démarré
    socketService.onTripStarted = (data) {
      if (mounted) {
        setState(() {
          _rideStatus = 'in_progress';
          _etaPhrase = 'En route vers la destination…';
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              data['message'] ?? 'Course en cours !',
              style: const TextStyle(fontSize: 16),
            ),
            backgroundColor: const Color(0xFF00A651),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    };

    // Course terminée
    socketService.onRideCompleted = (data) {
      if (mounted) {
        setState(() {
          _rideStatus = 'completed';
        });

        _showCompletionDialog();
      }
    };

    // Commencer le suivi de cette course
    socketService.trackRide(widget.rideId);
  }

  /// Animer le véhicule vers une nouvelle position
  void _animateVehicleToPosition(LatLng newPosition, {double? heading}) {
    if (_vehiclePosition == null) {
      // Première position
      setState(() {
        _vehiclePosition = newPosition;
        if (heading != null) _vehicleHeading = heading;
        _updateVehicleMarker();
      });
      return;
    }

    // Animation fluide vers la nouvelle position
    final startLat = _vehiclePosition!.latitude;
    final startLng = _vehiclePosition!.longitude;
    final endLat = newPosition.latitude;
    final endLng = newPosition.longitude;

    const steps = 20; // 20 frames
    int currentStep = 0;

    _movementTimer?.cancel();
    _movementTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (currentStep >= steps) {
        timer.cancel();
        return;
      }

      final progress = currentStep / steps;
      final smoothProgress = _easeInOutCubic(progress);

      final currentLat = startLat + (endLat - startLat) * smoothProgress;
      final currentLng = startLng + (endLng - startLng) * smoothProgress;

      if (mounted) {
        setState(() {
          _vehiclePosition = LatLng(currentLat, currentLng);
          if (heading != null) {
            _vehicleHeading = heading;
          }
          _updateVehicleMarker();
        });

        // Suivre le véhicule avec la caméra
        _mapController?.animateCamera(
          CameraUpdate.newLatLng(_vehiclePosition!),
        );
      }

      currentStep++;
    });
  }

  /// Fonction d'easing pour une animation fluide
  double _easeInOutCubic(double t) {
    return t < 0.5
        ? 4 * t * t * t
        : 1 - math.pow(-2 * t + 2, 3) / 2;
  }

  /// Afficher le dialogue de fin de course
  Future<void> _showPaymentDialog() async {
    int amount = 2500;
    try {
      final response = await ApiService.getRide(widget.rideId);
      if (response.success && response.data != null) {
        amount = response.data!.pricing.totalPrice.round();
      }
    } catch (_) {}
    final driverPhone = widget.driverInfo['phone'] ?? '';
    
    final paymentMethod = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Choisir le mode de paiement'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Montant: $amount FCFA',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF00A651),
              ),
            ),
            const SizedBox(height: 24),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF00D9A5).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.payment, color: Color(0xFF00D9A5)),
              ),
              title: const Text('Wave'),
              subtitle: const Text('Paiement mobile Wave'),
              onTap: () => Navigator.pop(context, 'wave'),
            ),
            const SizedBox(height: 8),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.money, color: Colors.green),
              ),
              title: const Text('Espèces'),
              subtitle: const Text('Payer en espèces au chauffeur'),
              onTap: () => Navigator.pop(context, 'cash'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
        ],
      ),
    );
    
    if (paymentMethod == null) return;
    
    if (paymentMethod == 'cash') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez payer en espèces au chauffeur'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.of(context).popUntil((route) => route.isFirst);
      return;
    }
    
    // Paiement mobile : Wave uniquement
    try {
      const appName = 'Wave';
      final deepLinkUrl =
          'wave://send?phone=$driverPhone&amount=$amount&note=Course DuDu ${widget.rideId}';
      
      final uri = Uri.parse(deepLinkUrl);
      bool launched = false;
      
      try {
        if (await canLaunchUrl(uri)) {
          launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
        }
      } catch (e) {
        print('Erreur ouverture $appName: $e');
      }
      
      if (!launched) {
        // Afficher dialogue avec instructions
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('Paiement $appName'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Montant: $amount FCFA'),
                const SizedBox(height: 8),
                Text('Numéro chauffeur: $driverPhone'),
                const SizedBox(height: 16),
                const Text(
                  '1. Ouvrez votre application de paiement\n'
                  '2. Envoyez le montant au numéro ci-dessus\n'
                  '3. Confirmez le paiement',
                  style: TextStyle(fontSize: 14),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.of(context).popUntil((route) => route.isFirst);
                },
                child: const Text('OK'),
              ),
            ],
          ),
        );
      } else {
        // Paiement lancé avec succès
        await Future.delayed(const Duration(seconds: 2));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Paiement $appName en cours...'),
            backgroundColor: Colors.blue,
          ),
        );
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    } catch (e) {
      print('Erreur paiement: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showCompletionDialog() {
    final driverName = widget.driverInfo['fullName'] ?? widget.driverInfo['name'] ?? 'Chauffeur';
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF00A651).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle,
                color: Color(0xFF00A651),
                size: 32,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _isCourierVehicleType(widget.vehicleType)
                  ? 'Livraison terminée !' 
                  : 'Course terminée !',
                style: const TextStyle(fontSize: 18),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _isCourierVehicleType(widget.vehicleType)
                  ? 'Votre colis a été livré avec succès'
                  : 'Merci d\'avoir utilisé DuDu',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildSummaryChip(
                  icon: Icons.route,
                  label: '${_distance.toStringAsFixed(1)} km',
                ),
                _buildSummaryChip(
                  icon: Icons.access_time,
                  label: '$_estimatedTime min',
                ),
                _buildSummaryChip(
                  icon: widget.vehicleType == 'delivery'
                      ? Icons.local_shipping
                      : (_isCourierVehicleType(widget.vehicleType)
                          ? Icons.motorcycle
                          : Icons.directions_car),
                  label: _isCourierVehicleType(widget.vehicleType)
                      ? (widget.vehicleType == 'delivery' ? 'Livraison' : 'Moto')
                      : 'Voiture',
                ),
              ],
            ),
          ],
        ),
        actions: [
          // Bouton Payer
          ElevatedButton.icon(
            onPressed: () async {
              Navigator.of(dialogContext).pop();
              await _showPaymentDialog();
            },
            icon: const Icon(Icons.payment),
            label: const Text('Payer'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
          ),
          const SizedBox(width: 8),
          // Bouton Noter
          ElevatedButton.icon(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              // Ouvrir l'écran de notation dédié
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => RatingScreen(
                    rideId: widget.rideId,
                    driverName: driverName,
                    vehicleType: widget.vehicleType,
                  ),
                ),
              );
            },
            icon: const Icon(Icons.star),
            label: const Text('Noter'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00A651),
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryChip({
    required IconData icon,
    required String label,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: const Color(0xFF00A651)),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  void _initializeMap() {
    _initializeTracking();
  }

  void _updateMarkers() {
    // Cette méthode est appelée après le chargement des icônes personnalisées
    // pour mettre à jour les marqueurs avec les nouvelles icônes
    if (_vehiclePosition != null) {
      _updateVehicleMarker();
    }
  }

  Future<void> _initializeTracking() async {
    final pickupLat = _readLocationLat(widget.pickupLocation) ?? 14.6928;
    final pickupLng = _readLocationLng(widget.pickupLocation) ?? -17.4467;
    final destLat = _readLocationLat(widget.destinationLocation) ?? pickupLat;
    final destLng = _readLocationLng(widget.destinationLocation) ?? pickupLng;

    setState(() {
      _vehiclePosition = null;
      _markers
        ..clear()
        ..add(
          Marker(
            markerId: const MarkerId('pickup'),
            position: LatLng(pickupLat, pickupLng),
            icon: _pickupIcon ??
                BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
            infoWindow: const InfoWindow(title: '📍 Point de récupération'),
          ),
        )
        ..add(
          Marker(
            markerId: const MarkerId('destination'),
            position: LatLng(destLat, destLng),
            icon: _destinationIcon ??
                BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
            infoWindow: const InfoWindow(title: '🎯 Destination'),
          ),
        );
    });
  }

  /// Mettre à jour le marqueur du véhicule
  void _updateVehicleMarker() {
    if (_vehiclePosition == null) return;
    
    // Retirer l'ancien marqueur véhicule
    _markers.removeWhere((m) => m.markerId.value == 'vehicle');
    
    final driverName = widget.driverInfo['fullName'] ?? widget.driverInfo['name'] ?? 'Chauffeur';
    final vehicleInfo = widget.driverInfo['vehicle'] ?? {};
    final plateNumber = vehicleInfo['plateNumber'] ?? vehicleInfo['plate'] ?? '';
    
    // Ajouter le nouveau marqueur avec rotation et icône personnalisée
    _markers.add(
      Marker(
        markerId: const MarkerId('vehicle'),
        position: _vehiclePosition!,
        rotation: _vehicleHeading,
        anchor: const Offset(0.5, 0.5),
        icon: _vehicleIcon ?? BitmapDescriptor.defaultMarkerWithHue(
          _isCourierVehicleType(widget.vehicleType)
            ? BitmapDescriptor.hueOrange 
            : BitmapDescriptor.hueYellow
        ),
        infoWindow: InfoWindow(
          title: _isCourierVehicleType(widget.vehicleType) ? '🏍️ $driverName' : '🚗 $driverName',
          snippet: plateNumber.isNotEmpty ? plateNumber : 'En route vers vous',
        ),
      ),
    );
  }

  String _formatDriverEtaPhrase(int minutes, {String? phase}) {
    final courier = _isCourierVehicleType(widget.vehicleType);
    final role = courier ? 'livreur' : 'chauffeur';
    if (minutes <= 1) {
      if (phase == 'destination') {
        return courier
            ? 'Arrivée à destination dans moins d\'une minute'
            : 'Vous arrivez à destination dans moins d\'une minute';
      }
      return 'Votre $role est à moins d\'une minute';
    }
    if (phase == 'destination') {
      return 'Temps estimé jusqu\'à destination : environ $minutes min';
    }
    return 'Votre $role arrive dans environ $minutes min';
  }

  String _mapsLink(Map<String, dynamic> loc) {
    final lat = _readLocationLat(loc) ?? 14.6928;
    final lng = _readLocationLng(loc) ?? -17.4467;
    return 'https://www.google.com/maps?q=$lat,$lng';
  }

  String _vehicleLabel() {
    final v = widget.driverInfo['vehicle'];
    if (v is Map) {
      final s = '${v['make'] ?? v['brand'] ?? ''} ${v['model'] ?? ''}'.trim();
      final plate = v['plateNumber'] ?? v['plate'];
      if (plate != null && '$plate'.isNotEmpty) {
        return s.isEmpty ? '$plate' : '$s • $plate';
      }
      return s.isNotEmpty ? s : 'Véhicule';
    }
    if (v is String && v.isNotEmpty) return v;
    return 'Véhicule';
  }

  /// Partage itinéraire avec un proche (sécurité) — écran dédié (WhatsApp, SMS, etc.)
  void _openSafetyShare() {
    final pickup = widget.pickupAddressLabel.trim().isNotEmpty
        ? widget.pickupAddressLabel.trim()
        : _mapsLink(widget.pickupLocation);
    final dest = widget.destinationAddressLabel.trim().isNotEmpty
        ? widget.destinationAddressLabel.trim()
        : _mapsLink(widget.destinationLocation);
    final driverName =
        widget.driverInfo['fullName'] ?? widget.driverInfo['name'] ?? 'Chauffeur';
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ShareRideScreen(
          rideId: widget.rideId,
          driverName: driverName,
          vehicleInfo: _vehicleLabel(),
          pickupAddress: pickup,
          destinationAddress: dest,
          currentLat: _vehiclePosition?.latitude,
          currentLng: _vehiclePosition?.longitude,
        ),
      ),
    );
  }

  void _showCancelConfirmation() {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text(
            'Êtes-vous sûr(e) ?',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: const Text(
            'Vous devrez peut-être attendre plus longtemps si vous annulez.\nLa modification de la réservation peut ne pas vous conduire à destination plus rapidement.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Attendre le chauffeur'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();

                final response = await ApiService.cancelRide(
                  widget.rideId,
                  'Client a annulé la course',
                );

                if (!mounted) return;

                if (response.success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Course annulée'),
                      backgroundColor: Colors.red,
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(response.message ?? 'Impossible d\'annuler la course'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }

                Navigator.of(context).popUntil((route) => route.isFirst);
              },
              child: const Text(
                'Annuler le trajet',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final driverName = widget.driverInfo['fullName'] ?? widget.driverInfo['name'] ?? 'Chauffeur';
    final driverPhone = widget.driverInfo['phone'] ?? '';
    final vehicleInfo = _asStringKeyMap(widget.driverInfo['vehicle']);
    final vehicleBrand = vehicleInfo['brand'] ?? vehicleInfo['make'] ?? '';
    final vehicleModel = vehicleInfo['model'] ?? '';
    final vehicleColor = vehicleInfo['color'] ?? '';
    final plateNumber = vehicleInfo['plateNumber'] ?? vehicleInfo['plate'] ?? '';
    final driverRating = widget.driverInfo['rating'] ?? 4.5;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _isCourierVehicleType(widget.vehicleType)
            ? '🏍️ Suivi de livraison' 
            : '🚗 Suivi de course'
        ),
        backgroundColor: const Color(0xFF00A651),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.shield_outlined),
            tooltip: 'Partager l\'itinéraire avec un proche (sécurité)',
            onPressed: _openSafetyShare,
          ),
        ],
      ),
      body: Stack(
        children: [
          // Carte Google Maps
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: _vehiclePosition ??
                  LatLng(
                    _readLocationLat(widget.pickupLocation) ?? 14.6928,
                    _readLocationLng(widget.pickupLocation) ?? -17.4467,
                  ),
              zoom: 14,
            ),
            markers: _markers,
            polylines: _polylines,
            cameraTargetBounds: MapStyleService.senegalBounds,
            minMaxZoomPreference: MapStyleService.zoomPreference,
            onMapCreated: (controller) async {
              _mapController = controller;
              await MapStyleService.apply(controller);
            },
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            mapToolbarEnabled: false,
          ),
          
          // Info du statut en haut
          Positioned(
            top: MediaQuery.of(context).padding.top + 16,
            left: 16,
            right: 16,
            child: Card(
              elevation: 8,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        // Photo du chauffeur ou avatar
                        CircleAvatar(
                          radius: 30,
                          backgroundColor: const Color(0xFF00A651),
                          child: Text(
                            driverName.isNotEmpty ? driverName[0].toUpperCase() : 'C',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      driverName,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  Row(
                                    children: [
                                      const Icon(Icons.star, color: Colors.amber, size: 16),
                                      const SizedBox(width: 4),
                                      Text(
                                        driverRating.toStringAsFixed(1),
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              if (vehicleBrand.isNotEmpty || vehicleModel.isNotEmpty)
                                Text(
                                  '$vehicleBrand $vehicleModel'.trim(),
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey[700],
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              if (vehicleColor.isNotEmpty || plateNumber.isNotEmpty)
                                Text(
                                  '${vehicleColor.isNotEmpty ? vehicleColor : ''} ${plateNumber.isNotEmpty ? '• $plateNumber' : ''}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                ),
                            ],
                          ),
                        ),
                        // Bouton téléphone
                        if (driverPhone.isNotEmpty)
                          Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFF00A651).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: IconButton(
                              icon: const Icon(Icons.phone, color: Color(0xFF00A651)),
                              onPressed: () async {
                                final uri = Uri.parse('tel:$driverPhone');
                                if (await canLaunchUrl(uri)) {
                                  await launchUrl(uri);
                                }
                              },
                              tooltip: 'Appeler le chauffeur',
                            ),
                          ),
                      ],
                    ),
                    if (widget.confirmationCode != null &&
                        widget.confirmationCode!.trim().isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF6B00).withOpacity(0.12),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFFF6B00)),
                        ),
                        child: Column(
                          children: [
                            const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.key, color: Color(0xFFFF6B00), size: 18),
                                SizedBox(width: 8),
                                Text(
                                  'Code de confirmation',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              widget.confirmationCode!.trim(),
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFFFF6B00),
                                letterSpacing: 3,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'À communiquer au destinataire',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey[700],
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ],
                    if (_rideStatus == 'going_to_pickup' ||
                        _rideStatus == 'in_progress') ...[
                      const SizedBox(height: 10),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF00A651).withOpacity(0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(
                              Icons.schedule,
                              color: Color(0xFF00A651),
                              size: 22,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                _etaPhrase,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  height: 1.25,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _openSafetyShare,
                        icon: const Icon(Icons.group_add_outlined),
                        label: const Text(
                          'Partager l\'itinéraire avec un ami (sécurité)',
                          textAlign: TextAlign.center,
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0B6E4F),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Center(
                      child: TextButton(
                        onPressed: _showCancelConfirmation,
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.red,
                        ),
                        child: Text(
                          _isCourierVehicleType(widget.vehicleType)
                              ? 'Annuler la livraison'
                              : 'Annuler la course',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          
          // Info du chauffeur en bas
          Positioned(
            bottom: 16,
            left: 16,
            right: 16,
            child: Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      children: [
                        // Avatar
                        CircleAvatar(
                          radius: 30,
                          backgroundColor: const Color(0xFF00A651),
                          child: Icon(
                            widget.vehicleType == 'delivery'
                                ? Icons.local_shipping
                                : (_isCourierVehicleType(widget.vehicleType)
                                    ? Icons.motorcycle
                                    : Icons.directions_car),
                            color: Colors.white,
                            size: 32,
                          ),
                        ),
                        const SizedBox(width: 16),
                        
                        // Info chauffeur
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                driverName,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '$vehicleBrand $vehicleModel'.trim(),
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  const Icon(Icons.star, size: 16, color: Colors.amber),
                                  const SizedBox(width: 4),
                                  Text(
                                    driverRating.toStringAsFixed(1),
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        
                        // Bouton d'appel classique
                        IconButton(
                          onPressed: () async {
                            final phone = widget.driverInfo['phone']?.toString();
                            if (phone == null || phone.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Numéro du chauffeur indisponible')),
                              );
                              return;
                            }
                            final uri = Uri(scheme: 'tel', path: phone);
                            if (await canLaunchUrl(uri)) {
                              await launchUrl(uri);
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Impossible de lancer l\'appel')),
                              );
                            }
                          },
                          icon: const Icon(Icons.phone),
                          iconSize: 32,
                          color: const Color(0xFF00A651),
                        ),
                      ],
                    ),
                    SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () {
                          SocketService().startVoipCall(widget.rideId);
                        },
                        icon: const Icon(Icons.wifi_calling_3),
                        label: const Text('Appel VOIP (BETA)'),
                      ),
                    ),
                    SizedBox(height: 8),
                    OutlinedButton.icon(
                      onPressed: _openSafetyShare,
                      icon: const Icon(Icons.shield_outlined),
                      label: const Text('Rappel : partager le trajet (sécurité)'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
