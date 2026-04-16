import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/socket_service.dart';

/// Historique des courses du chauffeur
class DriverRidesScreen extends StatefulWidget {
  const DriverRidesScreen({Key? key}) : super(key: key);

  @override
  State<DriverRidesScreen> createState() => _DriverRidesScreenState();
}

class _DriverRidesScreenState extends State<DriverRidesScreen>
    with SingleTickerProviderStateMixin {
  static const Color primaryGreen = Color(0xFF0d5d36);
  late TabController _tabController;
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      // Bouton flottant Accueil
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).popUntil((route) => route.isFirst);
        },
        backgroundColor: primaryGreen,
        child: const Icon(Icons.home, color: Colors.white),
        tooltip: 'Accueil',
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.startFloat,
      appBar: AppBar(
        title: const Text('Mon historique'),
        backgroundColor: primaryGreen,
        foregroundColor: Colors.white,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'En cours'),
            Tab(text: 'Terminées'),
            Tab(text: 'Annulées'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildRidesList('in_progress'),
          _buildRidesList('completed'),
          _buildRidesList('cancelled'),
        ],
      ),
    );
  }

  Widget _buildRidesList(String status) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: ApiService.getDriverRides(status: _mapTabStatusToApiStatus(status)),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'Erreur lors du chargement des courses\n${snapshot.error}',
                textAlign: TextAlign.center,
              ),
            ),
          );
        }

        final rides = snapshot.data ?? [];
        if (rides.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.inbox_outlined,
                  size: 80,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  'Aucune course',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: rides.length,
          itemBuilder: (context, index) {
            final mapped = _mapApiRideToUi(rides[index]);
            final rideId = rides[index]['id']?.toString() ?? '';
            return _buildRideCard(mapped, rideId);
          },
        );
      },
    );
  }

  Widget _buildRideCard(Map<String, dynamic> ride, String rideId) {
    final statusColors = {
      'in_progress': Colors.blue,
      'completed': primaryGreen,
      'cancelled': Colors.red,
    };

    final statusLabels = {
      'in_progress': 'En cours',
      'completed': 'Terminée',
      'cancelled': 'Annulée',
    };

    final color = statusColors[ride['status']] ?? Colors.grey;
    final label = statusLabels[ride['status']] ?? '';

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // En-tête avec statut et date
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: color),
                  ),
                  child: Text(
                    label,
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
                Text(
                  ride['date'],
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Client
            Row(
              children: [
                const CircleAvatar(
                  radius: 20,
                  backgroundColor: primaryGreen,
                  child: Icon(Icons.person, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 12),
                Text(
                  ride['passengerName'],
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Trajet
            _buildLocationRow(
              Icons.radio_button_checked,
              Colors.green,
              ride['pickup'],
            ),
            Padding(
              padding: const EdgeInsets.only(left: 12),
              child: Container(
                width: 2,
                height: 20,
                color: Colors.grey[300],
              ),
            ),
            _buildLocationRow(
              Icons.place,
              Colors.red,
              ride['destination'],
            ),
            const SizedBox(height: 12),

            // Infos
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildInfoChip(Icons.route, '${ride['distance']} km'),
                _buildInfoChip(Icons.access_time, '${ride['duration']} min'),
                Text(
                  '${ride['price']} FCFA',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: primaryGreen,
                  ),
                ),
              ],
            ),
            
            // Bouton Terminer pour les courses en cours
            if (_isInProgressStatus(ride['status']) && rideId.isNotEmpty) ...[
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _confirmCompleteRide(rideId),
                  icon: const Icon(Icons.check_circle, size: 20),
                  label: const Text('Terminer la course'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryGreen,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
  
  bool _isInProgressStatus(String? status) {
    return ['accepted', 'arriving', 'arrived', 'started', 'in_progress'].contains(status);
  }
  
  void _confirmCompleteRide(String rideId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Terminer la course ?'),
        content: const Text('Confirmez-vous que cette course est terminée ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _completeRide(rideId);
            },
            style: ElevatedButton.styleFrom(backgroundColor: primaryGreen),
            child: const Text('Confirmer', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
  
  Future<void> _completeRide(String rideId) async {
    try {
      // Envoyer via socket
      SocketService().completeRide(rideId);
      
      // Aussi via API pour être sûr
      final result = await ApiService.completeRide(rideId);
      
      // Vérifier si la réponse indique un succès
      final success = result['success'] == true;
      
      if (success || result['data'] != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Course terminée avec succès !'),
            backgroundColor: primaryGreen,
          ),
        );
      } else {
        // Si le message indique que la course est déjà terminée, c'est OK
        final message = result['message'] ?? '';
        if (message.contains('completed') || message.contains('terminée')) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Course déjà terminée'),
              backgroundColor: Colors.orange,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(message.isNotEmpty ? message : 'Erreur lors de la finalisation'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
      
      // Rafraîchir la liste dans tous les cas
      setState(() {});
    } catch (e) {
      // Ignorer les erreurs si le socket a déjà terminé la course
      final errorMsg = e.toString();
      if (errorMsg.contains('completed') || errorMsg.contains('terminée')) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Course terminée !'),
            backgroundColor: primaryGreen,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $errorMsg'),
            backgroundColor: Colors.red,
          ),
        );
      }
      setState(() {});
    }
  }

  Widget _buildLocationRow(IconData icon, Color color, String text) {
    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoChip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Colors.grey[700]),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[700],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  String? _mapTabStatusToApiStatus(String status) {
    switch (status) {
      case 'in_progress':
        // Inclure tous les statuts "en cours": accepted, arriving, arrived, started
        return 'in_progress';
      case 'completed':
        return 'completed';
      case 'cancelled':
        return 'cancelled';
    }
    return null;
  }

  Map<String, dynamic> _mapApiRideToUi(Map<String, dynamic> apiRide) {
    final passenger = apiRide['passenger'] is Map
        ? Map<String, dynamic>.from(apiRide['passenger'])
        : <String, dynamic>{};

    final pickup = apiRide['pickup'] is Map
        ? Map<String, dynamic>.from(apiRide['pickup'])
        : <String, dynamic>{};

    final destination = apiRide['destination'] is Map
        ? Map<String, dynamic>.from(apiRide['destination'])
        : <String, dynamic>{};

    final pricing = apiRide['pricing'] is Map
        ? Map<String, dynamic>.from(apiRide['pricing'])
        : <String, dynamic>{};

    final String pickupText =
        pickup['address']?.toString() ?? pickup['label']?.toString() ?? 'Départ';

    final String destinationText = destination['address']?.toString() ??
        destination['label']?.toString() ??
        'Destination';

    final double distanceKm = (apiRide['distance'] ?? 0).toDouble();
    final int durationMin = (apiRide['estimatedDuration'] ?? 0).toInt();

    final double price = (pricing['customPrice'] ??
            pricing['totalPrice'] ??
            apiRide['customPrice'] ??
            0)
        .toDouble();

    final String? requestedAt = apiRide['requestedAt']?.toString();
    final String? completedAt = apiRide['completedAt']?.toString();
    final String rawDate = completedAt ?? requestedAt ?? '';
    final String formattedDate = rawDate.isEmpty
        ? ''
        : rawDate
            .replaceFirst('T', ' ')
            .split('.')
            .first;

    return {
      'status': apiRide['status']?.toString() ?? '',
      'date': formattedDate,
      'passengerName': passenger['name']?.toString() ?? 'Client DuDu',
      'pickup': pickupText,
      'destination': destinationText,
      'distance': distanceKm.toStringAsFixed(1),
      'duration': durationMin.toString(),
      'price': price.toStringAsFixed(0),
    };
  }
}
