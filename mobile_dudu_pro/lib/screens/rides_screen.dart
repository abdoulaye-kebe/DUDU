import 'package:flutter/material.dart';
import '../models/ride.dart';
import '../services/api_service.dart';

class RidesScreen extends StatefulWidget {
  const RidesScreen({Key? key}) : super(key: key);

  @override
  State<RidesScreen> createState() => _RidesScreenState();
}

class _RidesScreenState extends State<RidesScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  List<Ride> _activeRides = [];
  List<Ride> _completedRides = [];
  List<Ride> _cancelledRides = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadRides();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
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
      final activeRides = [
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
          status: RideStatus.accepted,
          rideType: RideType.standard,
          vehicleCategory: VehicleCategory.car,
          timing: RideTiming(
            requestedAt: DateTime.now().subtract(const Duration(minutes: 10)),
            acceptedAt: DateTime.now().subtract(const Duration(minutes: 5)),
          ),
          payment: const RidePayment(
            method: 'orange_money',
            status: 'pending',
          ),
        ),
      ];

      final completedRides = [
        Ride(
          id: '2',
          rideId: 'DUDU123455',
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
          status: RideStatus.completed,
          rideType: RideType.standard,
          vehicleCategory: VehicleCategory.car,
          timing: RideTiming(
            requestedAt: DateTime.now().subtract(const Duration(hours: 2)),
            acceptedAt: DateTime.now().subtract(const Duration(hours: 2, minutes: -5)),
            startedAt: DateTime.now().subtract(const Duration(hours: 1, minutes: 45)),
            completedAt: DateTime.now().subtract(const Duration(hours: 1)),
          ),
          payment: RidePayment(
            method: 'wave',
            status: 'completed',
            paidAt: DateTime.now().subtract(const Duration(hours: 1)),
          ),
          rating: RideRating(
            passengerRating: 5,
            driverRating: 4,
          ),
        ),
      ];

      setState(() {
        _activeRides = activeRides;
        _completedRides = completedRides;
        _cancelledRides = [];
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Erreur de chargement: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mes Courses'),
        backgroundColor: Colors.blue[600],
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'En cours', icon: Icon(Icons.directions_car)),
            Tab(text: 'Terminées', icon: Icon(Icons.check_circle)),
            Tab(text: 'Annulées', icon: Icon(Icons.cancel)),
          ],
        ),
      ),
      body: _isLoading
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
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildActiveRidesTab(),
                    _buildCompletedRidesTab(),
                    _buildCancelledRidesTab(),
                  ],
                ),
    );
  }

  Widget _buildActiveRidesTab() {
    if (_activeRides.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.directions_car, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'Aucune course en cours',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
            SizedBox(height: 8),
            Text(
              'Les nouvelles demandes de course apparaîtront ici',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _activeRides.length,
      itemBuilder: (context, index) {
        final ride = _activeRides[index];
        return _buildRideCard(ride, isActive: true);
      },
    );
  }

  Widget _buildCompletedRidesTab() {
    if (_completedRides.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'Aucune course terminée',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
            SizedBox(height: 8),
            Text(
              'Vos courses terminées apparaîtront ici',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _completedRides.length,
      itemBuilder: (context, index) {
        final ride = _completedRides[index];
        return _buildRideCard(ride, isActive: false);
      },
    );
  }

  Widget _buildCancelledRidesTab() {
    if (_cancelledRides.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.cancel, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'Aucune course annulée',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
            SizedBox(height: 8),
            Text(
              'Les courses annulées apparaîtront ici',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _cancelledRides.length,
      itemBuilder: (context, index) {
        final ride = _cancelledRides[index];
        return _buildRideCard(ride, isActive: false);
      },
    );
  }

  Widget _buildRideCard(Ride ride, {required bool isActive}) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // En-tête avec ID de course et statut
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
            
            // Informations de prix et paiement
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
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
                if (ride.passengers > 1)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.people, size: 16, color: Colors.blue),
                        const SizedBox(width: 4),
                        Text(
                          '${ride.passengers} passagers',
                          style: const TextStyle(
                            color: Colors.blue,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            
            // Actions selon le statut
            if (isActive) ...[
              const SizedBox(height: 16),
              _buildActiveRideActions(ride),
            ],
            
            // Informations de timing
            const SizedBox(height: 12),
            _buildTimingInfo(ride),
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

  Widget _buildActiveRideActions(Ride ride) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () => _handleRideAction(ride, 'arrive'),
            icon: const Icon(Icons.location_on, size: 18),
            label: const Text('Arrivé'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () => _handleRideAction(ride, 'start'),
            icon: const Icon(Icons.play_arrow, size: 18),
            label: const Text('Commencer'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () => _handleRideAction(ride, 'complete'),
            icon: const Icon(Icons.check, size: 18),
            label: const Text('Terminer'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTimingInfo(Ride ride) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          if (ride.timing.requestedAt != null)
            _buildTimingRow('Demandé', ride.timing.requestedAt!),
          if (ride.timing.acceptedAt != null)
            _buildTimingRow('Accepté', ride.timing.acceptedAt!),
          if (ride.timing.arrivedAt != null)
            _buildTimingRow('Arrivé', ride.timing.arrivedAt!),
          if (ride.timing.startedAt != null)
            _buildTimingRow('Commencer', ride.timing.startedAt!),
          if (ride.timing.completedAt != null)
            _buildTimingRow('Terminé', ride.timing.completedAt!),
        ],
      ),
    );
  }

  Widget _buildTimingRow(String label, DateTime time) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 12,
            ),
          ),
          Text(
            '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}',
            style: const TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(RideStatus status) {
    switch (status) {
      case RideStatus.requested:
      case RideStatus.searching:
        return Colors.orange;
      case RideStatus.accepted:
      case RideStatus.arriving:
        return Colors.blue;
      case RideStatus.arrived:
        return Colors.purple;
      case RideStatus.started:
        return Colors.green;
      case RideStatus.completed:
        return Colors.green[700]!;
      case RideStatus.cancelled:
        return Colors.red;
      case RideStatus.noDriver:
      case RideStatus.expired:
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
      case 'orange_money':
        return 'Orange Money';
      case 'wave':
        return 'Wave';
      case 'free_money':
        return 'Free Money';
      case 'cash':
        return 'Espèces';
      default:
        return method;
    }
  }

  Future<void> _handleRideAction(Ride ride, String action) async {
    try {
      // Ici, vous appelleriez l'API pour effectuer l'action
      // await ApiService.updateRideStatus(ride.id, action);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Action "$action" effectuée pour la course ${ride.rideId}'),
          backgroundColor: Colors.green,
        ),
      );
      
      // Recharger les courses
      await _loadRides();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
