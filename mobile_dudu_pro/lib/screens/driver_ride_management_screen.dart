import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import '../constants/senegal_map.dart';
import '../models/ride.dart';
import '../services/api_service.dart';
import '../services/tracking_service.dart';
import '../services/notification_service.dart';
import '../services/map_style_service.dart';
import 'ride_tracking_screen.dart';

class DriverRideManagementScreen extends StatefulWidget {
  const DriverRideManagementScreen({Key? key}) : super(key: key);

  @override
  State<DriverRideManagementScreen> createState() => _DriverRideManagementScreenState();
}

class _DriverRideManagementScreenState extends State<DriverRideManagementScreen> {
  GoogleMapController? _mapController;
  List<Ride> _availableRides = [];
  List<Ride> _myRides = [];
  bool _isLoading = true;
  String? _error;
  bool _isOnline = false;
  Position? _currentPosition;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
    _loadRides();
  }

  Future<void> _getCurrentLocation() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        return;
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        _currentPosition = position;
      });

      // Mettre à jour la position du chauffeur
      if (_isOnline) {
        await _updateDriverLocation();
      }
    } catch (e) {
      print('Erreur localisation: $e');
    }
  }

  Future<void> _loadRides() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      // Simuler le chargement des courses
      await Future.delayed(const Duration(seconds: 1));
      
      // Données de test
      final availableRides = [
        Ride(
          id: '1',
          rideId: 'DUDU123456',
          passengerId: 'passenger1',
          driverId: 'driver1',
          pickup: const RideLocation(
            address: 'Place de l\'Indépendance, Dakar',
            latitude: 14.6928,
            longitude: -17.4467,
          ),
          destination: const RideLocation(
            address: 'Aéroport Léopold Sédar Senghor',
            latitude: 14.6708,
            longitude: -17.0731,
          ),
          pricing: const RidePricing(
            basePrice: 1000,
            distancePrice: 2500,
            timePrice: 500,
            totalPrice: 4000,
          ),
          status: RideStatus.requested,
          rideType: RideType.standard,
          vehicleCategory: VehicleCategory.car,
          timing: RideTiming(
            requestedAt: DateTime.now().subtract(const Duration(minutes: 5)),
          ),
          payment: const RidePayment(
            method: 'wave',
            status: 'pending',
          ),
        ),
        Ride(
          id: '2',
          rideId: 'DUDU123457',
          passengerId: 'passenger2',
          driverId: 'driver1',
          pickup: const RideLocation(
            address: 'Université Cheikh Anta Diop',
            latitude: 14.6928,
            longitude: -17.4467,
          ),
          destination: const RideLocation(
            address: 'Plateau, Dakar',
            latitude: 14.6708,
            longitude: -17.0731,
          ),
          pricing: const RidePricing(
            basePrice: 1000,
            distancePrice: 1500,
            timePrice: 300,
            totalPrice: 2800,
          ),
          status: RideStatus.requested,
          rideType: RideType.comfort,
          vehicleCategory: VehicleCategory.car,
          timing: RideTiming(
            requestedAt: DateTime.now().subtract(const Duration(minutes: 2)),
          ),
          payment: const RidePayment(
            method: 'wave',
            status: 'pending',
          ),
        ),
      ];

      setState(() {
        _availableRides = availableRides;
        _myRides = [];
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Erreur de chargement: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  Future<void> _toggleOnlineStatus() async {
    setState(() {
      _isOnline = !_isOnline;
    });

    if (_isOnline) {
      await _updateDriverLocation();
      _loadRides(); // Recharger les courses disponibles
    }
  }

  Future<void> _updateDriverLocation() async {
    if (_currentPosition != null) {
      try {
        // Mettre à jour la position du chauffeur via l'API
        // await ApiService.updateDriverLocation(
        //   _currentPosition!.latitude,
        //   _currentPosition!.longitude,
        // );
        print('Position mise à jour: ${_currentPosition!.latitude}, ${_currentPosition!.longitude}');
      } catch (e) {
        print('Erreur mise à jour position: $e');
      }
    }
  }

  Future<void> _acceptRide(Ride ride) async {
    try {
      // Accepter la course via l'API
      // final updatedRide = await ApiService.acceptRide(ride.id);
      
      setState(() {
        _availableRides.removeWhere((r) => r.id == ride.id);
        _myRides.add(ride.copyWith(status: RideStatus.accepted));
      });

      // Envoyer une notification
      await NotificationService().showRideAcceptedNotification(
        rideId: ride.rideId,
        driverName: 'Vous',
        vehicleInfo: 'Votre véhicule',
        estimatedArrival: 5,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Course ${ride.rideId} acceptée'),
          backgroundColor: Colors.green,
        ),
      );

      // Naviguer vers l'écran de suivi
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => RideTrackingScreen(ride: ride),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestion des Courses'),
        backgroundColor: Colors.blue[600],
        foregroundColor: Colors.white,
        actions: [
          Switch(
            value: _isOnline,
            onChanged: (value) => _toggleOnlineStatus(),
            activeColor: Colors.green,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          // Statut en ligne
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: _isOnline ? Colors.green[50] : Colors.red[50],
            child: Row(
              children: [
                Icon(
                  _isOnline ? Icons.circle : Icons.circle_outlined,
                  color: _isOnline ? Colors.green : Colors.red,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Text(
                  _isOnline ? 'En ligne - Prêt à recevoir des courses' : 'Hors ligne',
                  style: TextStyle(
                    color: _isOnline ? Colors.green[700] : Colors.red[700],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          
          // Carte
          Expanded(
            flex: 2,
            child: GoogleMap(
              cameraTargetBounds: MapStyleService.senegalBounds,
              minMaxZoomPreference: MapStyleService.zoomPreference,
              onMapCreated: (GoogleMapController controller) async {
                _mapController = controller;
                await MapStyleService.apply(controller);
              },
              initialCameraPosition: CameraPosition(
                target: _currentPosition != null
                    ? LatLng(_currentPosition!.latitude, _currentPosition!.longitude)
                    : SenegalMap.countryOverviewCenter,
                zoom: _currentPosition != null ? 15 : SenegalMap.countryOverviewZoom,
              ),
              mapType: MapType.normal,
              markers: _buildMarkers(),
            ),
          ),
          
          // Liste des courses
          Expanded(
            flex: 3,
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.error, size: 64, color: Colors.red[300]),
                            const SizedBox(height: 16),
                            Text(
                              _error!,
                              style: const TextStyle(fontSize: 16),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: _loadRides,
                              child: const Text('Réessayer'),
                            ),
                          ],
                        ),
                      )
                    : _buildRidesList(),
          ),
        ],
      ),
    );
  }

  Widget _buildRidesList() {
    if (_availableRides.isEmpty && _myRides.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.directions_car, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'Aucune course disponible',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
            SizedBox(height: 8),
            Text(
              'Les nouvelles demandes apparaîtront ici',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (_myRides.isNotEmpty) ...[
          const Text(
            'Mes courses',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          ..._myRides.map((ride) => _buildRideCard(ride, isMyRide: true)),
          const SizedBox(height: 16),
        ],
        
        if (_availableRides.isNotEmpty) ...[
          const Text(
            'Courses disponibles',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          ..._availableRides.map((ride) => _buildRideCard(ride, isMyRide: false)),
        ],
      ],
    );
  }

  Widget _buildRideCard(Ride ride, {required bool isMyRide}) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // En-tête
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Course ${ride.rideId}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getStatusColor(ride.status),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    ride.status.displayName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            // Type de course
            Row(
              children: [
                Icon(
                  _getRideTypeIcon(ride.rideType),
                  size: 16,
                  color: Colors.blue[600],
                ),
                const SizedBox(width: 4),
                Text(
                  ride.rideType.displayName,
                  style: TextStyle(
                    color: Colors.blue[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(width: 16),
                Icon(
                  _getVehicleIcon(ride.vehicleCategory),
                  size: 16,
                  color: Colors.grey[600],
                ),
                const SizedBox(width: 4),
                Text(
                  ride.vehicleCategory.displayName,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            // Adresses
            _buildLocationRow(
              Icons.location_on,
              'Départ',
              ride.pickup.address,
              Colors.green,
            ),
            const SizedBox(height: 8),
            _buildLocationRow(
              Icons.location_on,
              'Arrivée',
              ride.destination.address,
              Colors.red,
            ),
            const SizedBox(height: 12),
            
            // Prix
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Prix: ${ride.pricing.totalPrice.toStringAsFixed(0)} FCFA',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
                Text(
                  'Paiement: ${_getPaymentMethodName(ride.payment.method)}',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            
            // Actions
            if (!isMyRide) ...[
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => _acceptRide(ride),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Accepter cette course'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildLocationRow(IconData icon, String label, String address, Color color) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                address,
                style: const TextStyle(fontSize: 14),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Set<Marker> _buildMarkers() {
    Set<Marker> markers = {};
    
    // Marqueur de position actuelle
    if (_currentPosition != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('current_position'),
          position: LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
          infoWindow: const InfoWindow(
            title: 'Ma position',
            snippet: 'Position actuelle',
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
        ),
      );
    }
    
    // Marqueurs des courses disponibles
    for (int i = 0; i < _availableRides.length; i++) {
      final ride = _availableRides[i];
      markers.add(
        Marker(
          markerId: MarkerId('ride_${ride.id}'),
          position: LatLng(ride.pickup.latitude, ride.pickup.longitude),
          infoWindow: InfoWindow(
            title: 'Course ${ride.rideId}',
            snippet: '${ride.pricing.totalPrice.toStringAsFixed(0)} FCFA',
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
        ),
      );
    }
    
    return markers;
  }

  Color _getStatusColor(RideStatus status) {
    switch (status) {
      case RideStatus.requested:
        return Colors.orange;
      case RideStatus.accepted:
        return Colors.blue;
      case RideStatus.arrived:
        return Colors.purple;
      case RideStatus.started:
        return Colors.green;
      case RideStatus.completed:
        return Colors.green[700]!;
      case RideStatus.cancelled:
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getRideTypeIcon(RideType type) {
    switch (type) {
      case RideType.standard:
        return Icons.directions_car;
      case RideType.comfort:
        return Icons.chair;
      case RideType.womenOnly:
        return Icons.female;
      case RideType.delivery:
        return Icons.motorcycle;
      case RideType.luxe:
        return Icons.star;
      case RideType.moto:
        return Icons.motorcycle;
    }
  }

  IconData _getVehicleIcon(VehicleCategory category) {
    switch (category) {
      case VehicleCategory.car:
        return Icons.directions_car;
      case VehicleCategory.moto:
        return Icons.motorcycle;
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
}
