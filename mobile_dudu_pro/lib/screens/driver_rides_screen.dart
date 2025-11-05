import 'package:flutter/material.dart';

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
    // Pas de données de test - Seulement les vraies données
    final rides = <Map<String, dynamic>>[];

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
        return _buildRideCard(rides[index]);
      },
    );
  }

  Widget _buildRideCard(Map<String, dynamic> ride) {
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
          ],
        ),
      ),
    );
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

  List<Map<String, dynamic>> _getMockRides(String status) {
    if (status == 'completed') {
      return [
        {
          'status': 'completed',
          'date': '01/11/2024 14:30',
          'passengerName': 'Abdoulaye Kebe',
          'pickup': 'King Fahd Palace',
          'destination': 'Aéroport Blaise Diagne',
          'distance': '45.2',
          'duration': '35',
          'price': '15000',
        },
        {
          'status': 'completed',
          'date': '01/11/2024 12:15',
          'passengerName': 'Fatou Diop',
          'pickup': 'Plateau',
          'destination': 'UCAD',
          'distance': '8.5',
          'duration': '15',
          'price': '2500',
        },
      ];
    }
    return [];
  }
}
