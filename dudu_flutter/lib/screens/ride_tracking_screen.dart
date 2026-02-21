import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:async';
import 'dart:math' as math;
import 'package:url_launcher/url_launcher.dart';
import '../services/socket_service.dart';
import '../services/api_service.dart';
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

  const RideTrackingScreen({
    Key? key,
    required this.rideId,
    required this.vehicleType,
    required this.pickupLocation,
    required this.destinationLocation,
    required this.driverInfo,
  }) : super(key: key);

  @override
  State<RideTrackingScreen> createState() => _RideTrackingScreenState();
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
  
  // Timer pour simulation
  Timer? _movementTimer;
  
  @override
  void initState() {
    super.initState();
    _initializeTracking();
    _setupSocketListeners();
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

  /// Configurer les écouteurs Socket.io pour recevoir les mises à jour en temps réel
  void _setupSocketListeners() {
    final socketService = SocketService();

    // Écouter les mises à jour de position du véhicule
    socketService.onDriverLocationUpdate = (data) {
      final latitude = (data['latitude'] as num?)?.toDouble();
      final longitude = (data['longitude'] as num?)?.toDouble();
      final heading = (data['heading'] as num?)?.toDouble() ?? 0.0;

      if (latitude != null && longitude != null && mounted) {
        setState(() {
          // Animer le mouvement vers la nouvelle position
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

    const animationDuration = 2; // 2 secondes
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
    // Récupérer le montant de la course depuis l'API ou utiliser une valeur estimée
    final amount = 2500; // TODO: Récupérer le vrai montant depuis l'API
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
                  color: const Color(0xFFFF6600).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.phone_android, color: Color(0xFFFF6600)),
              ),
              title: const Text('Orange Money'),
              subtitle: const Text('Paiement mobile Orange Money'),
              onTap: () => Navigator.pop(context, 'orange_money'),
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
    
    // Ouvrir Wave ou Orange Money
    try {
      String deepLinkUrl;
      String appName;
      
      if (paymentMethod == 'wave') {
        appName = 'Wave';
        deepLinkUrl = 'wave://send?phone=$driverPhone&amount=$amount&note=Course DUDU ${widget.rideId}';
      } else {
        appName = 'Orange Money';
        deepLinkUrl = 'orangemoney://send?phone=$driverPhone&amount=$amount&reason=Course DUDU ${widget.rideId}';
      }
      
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
                widget.vehicleType == 'moto' 
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
              widget.vehicleType == 'moto'
                  ? 'Votre colis a été livré avec succès'
                  : 'Merci d\'avoir utilisé DUDU',
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
                  icon: widget.vehicleType == 'moto'
                      ? Icons.motorcycle
                      : Icons.directions_car,
                  label: widget.vehicleType == 'moto' ? 'Moto' : 'Voiture',
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

  Future<void> _initializeTracking() async {
    // Position de départ du véhicule (simulée)
    final pickupLat = widget.pickupLocation['latitude'];
    final pickupLng = widget.pickupLocation['longitude'];
    
    setState(() {
      _vehiclePosition = LatLng(pickupLat - 0.01, pickupLng + 0.01); // 1km avant
      
      // Ajouter marqueurs
      _markers.add(
        Marker(
          markerId: const MarkerId('pickup'),
          position: LatLng(pickupLat, pickupLng),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
          infoWindow: const InfoWindow(title: 'Point de récupération'),
        ),
      );
      
      _markers.add(
        Marker(
          markerId: const MarkerId('destination'),
          position: LatLng(
            widget.destinationLocation['latitude'],
            widget.destinationLocation['longitude'],
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
          infoWindow: const InfoWindow(title: '🎯 Destination'),
        ),
      );
    });
    
    // Simuler le mouvement
    _startMovementSimulation();
  }

  /// Simuler le déplacement du véhicule
  void _startMovementSimulation() {
    final pickupLat = widget.pickupLocation['latitude'];
    final pickupLng = widget.pickupLocation['longitude'];
    final destLat = widget.destinationLocation['latitude'];
    final destLng = widget.destinationLocation['longitude'];
    
    // Phase 1 : Aller au pickup
    _animateToLocation(
      LatLng(pickupLat, pickupLng),
      duration: 10, // 10 secondes pour la démo
      onComplete: () {
        setState(() {
          _rideStatus = 'arrived';
        });
        
        // Attendre 3 secondes
        Future.delayed(const Duration(seconds: 3), () {
          setState(() {
            _rideStatus = 'in_progress';
          });
          
          // Phase 2 : Aller à la destination
          _animateToLocation(
            LatLng(destLat, destLng),
            duration: 15,
            onComplete: () {
              setState(() {
                _rideStatus = 'completed';
              });
            },
          );
        });
      },
    );
  }

  /// Animer le déplacement vers une position
  void _animateToLocation(LatLng target, {required int duration, VoidCallback? onComplete}) {
    if (_vehiclePosition == null) return;
    
    final startLat = _vehiclePosition!.latitude;
    final startLng = _vehiclePosition!.longitude;
    final endLat = target.latitude;
    final endLng = target.longitude;
    
    final totalSteps = duration * 2; // 2 updates par seconde
    int currentStep = 0;
    
    _movementTimer?.cancel();
    _movementTimer = Timer.periodic(const Duration(milliseconds: 500), (timer) {
      if (currentStep >= totalSteps) {
        timer.cancel();
        if (onComplete != null) onComplete();
        return;
      }
      
      final progress = currentStep / totalSteps;
      final newLat = startLat + (endLat - startLat) * progress;
      final newLng = startLng + (endLng - startLng) * progress;
      
      // Calculer le heading (direction)
      final heading = _calculateHeading(
        _vehiclePosition!.latitude,
        _vehiclePosition!.longitude,
        newLat,
        newLng,
      );
      
      setState(() {
        _vehiclePosition = LatLng(newLat, newLng);
        _vehicleHeading = heading;
        
        // Mettre à jour le marqueur du véhicule
        _updateVehicleMarker();
        
        // Calculer distance restante
        _distance = _calculateDistance(newLat, newLng, endLat, endLng);
        _estimatedTime = (_distance / 30 * 60).ceil(); // 30 km/h
      });
      
      // Centrer la caméra sur le véhicule
      _mapController?.animateCamera(
        CameraUpdate.newLatLng(_vehiclePosition!),
      );
      
      currentStep++;
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
    
    // Ajouter le nouveau marqueur avec rotation
    _markers.add(
      Marker(
        markerId: const MarkerId('vehicle'),
        position: _vehiclePosition!,
        rotation: _vehicleHeading,
        anchor: const Offset(0.5, 0.5),
        icon: BitmapDescriptor.defaultMarkerWithHue(
          widget.vehicleType == 'moto' 
            ? BitmapDescriptor.hueOrange 
            : BitmapDescriptor.hueYellow
        ),
        infoWindow: InfoWindow(
          title: widget.vehicleType == 'moto' ? '🏍️ $driverName' : '🚗 $driverName',
          snippet: plateNumber.isNotEmpty ? plateNumber : 'En route vers vous',
        ),
      ),
    );
  }

  /// Calculer le heading entre deux points
  double _calculateHeading(double lat1, double lon1, double lat2, double lon2) {
    final dLon = lon2 - lon1;
    final y = math.sin(dLon) * math.cos(lat2);
    final x = math.cos(lat1) * math.sin(lat2) - 
              math.sin(lat1) * math.cos(lat2) * math.cos(dLon);
    final heading = math.atan2(y, x);
    return (heading * 180 / math.pi + 360) % 360;
  }

  /// Calculer distance entre deux points (Haversine)
  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const R = 6371; // Rayon de la Terre en km
    final dLat = (lat2 - lat1) * math.pi / 180;
    final dLon = (lon2 - lon1) * math.pi / 180;
    
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
              math.cos(lat1 * math.pi / 180) * math.cos(lat2 * math.pi / 180) *
              math.sin(dLon / 2) * math.sin(dLon / 2);
    
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return R * c;
  }

  @override
  Widget build(BuildContext context) {
    final driverName = widget.driverInfo['fullName'] ?? widget.driverInfo['name'] ?? 'Chauffeur';
    final driverPhone = widget.driverInfo['phone'] ?? '';
    final vehicleInfo = widget.driverInfo['vehicle'] ?? {};
    final vehicleBrand = vehicleInfo['brand'] ?? vehicleInfo['make'] ?? '';
    final vehicleModel = vehicleInfo['model'] ?? '';
    final vehicleColor = vehicleInfo['color'] ?? '';
    final plateNumber = vehicleInfo['plateNumber'] ?? vehicleInfo['plate'] ?? '';
    final driverRating = widget.driverInfo['rating'] ?? 4.5;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.vehicleType == 'moto' 
            ? '🏍️ Suivi de livraison' 
            : '🚗 Suivi de course'
        ),
        backgroundColor: const Color(0xFF00A651),
        foregroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          // Carte Google Maps
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: _vehiclePosition ?? LatLng(
                widget.pickupLocation['latitude'],
                widget.pickupLocation['longitude'],
              ),
              zoom: 14,
            ),
            markers: _markers,
            polylines: _polylines,
            onMapCreated: (controller) {
              _mapController = controller;
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
                        const SizedBox(width: 8),
                        // Bouton partager
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.blue.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: IconButton(
                            icon: const Icon(Icons.share, color: Colors.blue),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ShareRideScreen(
                                    rideId: widget.rideId,
                                    driverName: driverName,
                                    vehicleType: widget.vehicleType,
                                    pickupAddress: 'Point de départ',
                                    destinationAddress: 'Destination',
                                  ),
                                ),
                              );
                            },
                            tooltip: 'Partager le trajet',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _shareRide,
                            icon: const Icon(Icons.share_location),
                            label: const Text('Partager'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextButton(
                            onPressed: _showCancelConfirmation,
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.red,
                            ),
                            child: const Text('Annuler'),
                          ),
                        ),
                      ],
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
                            widget.vehicleType == 'moto' ? Icons.motorcycle : Icons.directions_car,
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
                        
                        // Bouton de partage de trajet
                        IconButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ShareRideScreen(
                                  rideId: widget.rideId,
                                  driverName: driverName,
                                  vehicleType: widget.vehicleType,
                                  pickupAddress: 'Point de départ',
                                  destinationAddress: 'Destination',
                                ),
                              ),
                            );
                          },
                          icon: const Icon(Icons.share),
                          iconSize: 28,
                          color: const Color(0xFF00A651),
                          tooltip: 'Partager mon trajet',
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
                    const SizedBox(height: 12),
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
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _shareRide,
                            icon: const Icon(Icons.share_location),
                            label: const Text('Partager'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextButton(
                            onPressed: _showCancelConfirmation,
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.red,
                            ),
                            child: const Text('Annuler'),
                          ),
                        ),
                      ],
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

  Widget _buildStatusCard() {
    String statusText;
    String statusEmoji;
    Color statusColor;
    
    switch (_rideStatus) {
      case 'going_to_pickup':
        statusEmoji = '';
        statusText = widget.vehicleType == 'moto'
            ? 'Le livreur arrive pour récupérer'
            : 'Votre chauffeur arrive';
        statusColor = Colors.blue;
        break;
      case 'arrived':
        statusEmoji = '';
        statusText = widget.vehicleType == 'moto'
            ? 'Livreur arrivé - Récupération en cours'
            : 'Chauffeur arrivé';
        statusColor = Colors.orange;
        break;
      case 'in_progress':
        statusEmoji = '';
        statusText = widget.vehicleType == 'moto'
            ? 'Livraison en cours'
            : 'Course en cours';
        statusColor = const Color(0xFF00A651);
        break;
      case 'completed':
        statusEmoji = '';
        statusText = widget.vehicleType == 'moto'
            ? 'Livraison terminée !'
            : 'Course terminée !';
        statusColor = Colors.green;
        break;
      default:
        statusEmoji = '';
        statusText = 'En cours...';
        statusColor = Colors.grey;
    }
    
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [statusColor.withOpacity(0.1), Colors.white],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(statusEmoji, style: const TextStyle(fontSize: 32)),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    statusText,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                // Bouton de partage rapide
                if (_rideStatus != 'completed')
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF00A651).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: IconButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ShareRideScreen(
                              rideId: widget.rideId,
                              driverName: widget.driverInfo['name'] ?? 'Chauffeur',
                              vehicleInfo: widget.driverInfo['vehicle'] ?? 'Véhicule',
                              pickupAddress: widget.pickupLocation['address'] ?? 'Départ',
                              destinationAddress: widget.destinationLocation['address'] ?? 'Destination',
                              currentLat: _vehiclePosition?.latitude,
                              currentLng: _vehiclePosition?.longitude,
                            ),
                          ),
                        );
                      },
                      icon: const Icon(Icons.share),
                      color: const Color(0xFF00A651),
                      tooltip: 'Partager mon trajet',
                    ),
                  ),
              ],
            ),
            if (_rideStatus == 'going_to_pickup') ...[
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildInfoChipWithIcon(Icons.straighten, '${_distance.toStringAsFixed(1)} km'),
                  _buildInfoChipWithIcon(Icons.access_time, '$_estimatedTime min'),
                  _buildInfoChipWithIcon(Icons.navigation, '${_vehicleHeading.toInt()}°'),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoChip(String emoji, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 6),
          Text(
            text,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChipWithIcon(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: const Color(0xFF00A651)),
          const SizedBox(width: 6),
          Text(
            text,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                // Bouton de partage de trajet
                IconButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ShareRideScreen(
                          rideId: widget.rideId,
                          driverName: widget.driverInfo['name'] ?? 'Chauffeur',
                          vehicleInfo: widget.driverInfo['vehicle'] ?? 'Véhicule',
                          pickupAddress: widget.pickupLocation['address'] ?? 'Départ',
                          destinationAddress: widget.destinationLocation['address'] ?? 'Destination',
                          currentLat: _vehiclePosition?.latitude,
                          currentLng: _vehiclePosition?.longitude,
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.share),
                  iconSize: 28,
                  color: const Color(0xFF00A651),
                  tooltip: 'Partager mon trajet',
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
            const SizedBox(height: 12),
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
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _shareRide,
                    icon: const Icon(Icons.share_location),
                    label: const Text('Partager'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextButton(
                    onPressed: _showCancelConfirmation,
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.red,
                    ),
                    child: const Text('Annuler'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _shareRide() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ShareRideScreen(
          rideId: widget.rideId,
          driverName: widget.driverInfo['name'] ?? 'Chauffeur',
          vehicleInfo: widget.driverInfo['vehicle'] ?? 'Véhicule',
          pickupAddress: 'Point de départ', // À adapter selon vos données
          destinationAddress: 'Destination', // À adapter selon vos données
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

                // Appeler l’API d’annulation
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

                // Retourner à l'écran principal
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
}
