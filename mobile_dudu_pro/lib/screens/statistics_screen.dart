import 'package:flutter/material.dart';
import '../models/driver_profile.dart';

class StatisticsScreen extends StatefulWidget {
  final DriverProfile driverProfile;

  const StatisticsScreen({
    Key? key,
    required this.driverProfile,
  }) : super(key: key);

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  String _selectedPeriod = 'today';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Statistiques ${widget.driverProfile.vehicleType.displayName}',
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color(0xFF00A651),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Période de sélection
            _buildPeriodSelector(),
            const SizedBox(height: 20),
            
            // Statistiques principales
            _buildMainStats(),
            const SizedBox(height: 20),
            
            // Graphiques
            _buildCharts(),
            const SizedBox(height: 20),
            
            // Détails par période
            _buildPeriodDetails(),
            const SizedBox(height: 20),
            
            // Bonus pour livreurs moto
            if (widget.driverProfile.isMoto) ...[
              _buildBonusSection(),
              const SizedBox(height: 20),
            ],
            
            // Historique des courses
            _buildRideHistory(),
          ],
        ),
      ),
    );
  }

  Widget _buildPeriodSelector() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Période',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _buildPeriodButton('today', 'Aujourd\'hui'),
                const SizedBox(width: 8),
                _buildPeriodButton('week', 'Cette semaine'),
                const SizedBox(width: 8),
                _buildPeriodButton('month', 'Ce mois'),
                const SizedBox(width: 8),
                _buildPeriodButton('year', 'Cette année'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPeriodButton(String period, String label) {
    final isSelected = _selectedPeriod == period;
    return GestureDetector(
      onTap: () => setState(() => _selectedPeriod = period),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF00A651) : Colors.grey[200],
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey[700],
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  Widget _buildMainStats() {
    final stats = widget.driverProfile.stats;
    
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Statistiques Principales',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    '🚗',
                    _getRidesCount(),
                    'Courses',
                    Colors.blue,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    '💰',
                    _getEarnings(),
                    'Revenus',
                    Colors.green,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    '⭐',
                    stats.averageRating.toStringAsFixed(1),
                    'Note',
                    Colors.orange,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    '📏',
                    '${(stats.totalDistance / 1000).toStringAsFixed(1)} km',
                    'Distance',
                    Colors.purple,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String icon, String value, String label, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(icon, style: const TextStyle(fontSize: 24)),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCharts() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Évolution des Revenus',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              height: 200,
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.show_chart,
                      size: 48,
                      color: Colors.grey,
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Graphique des revenus',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      '(À implémenter avec une librairie de graphiques)',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPeriodDetails() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Détails - ${_getPeriodLabel()}',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildDetailRow('Courses effectuées', _getRidesCount()),
            _buildDetailRow('Revenus', _getEarnings()),
            _buildDetailRow('Temps de conduite', _getDrivingTime()),
            _buildDetailRow('Distance parcourue', _getDistance()),
            if (widget.driverProfile.isMoto) ...[
              _buildDetailRow('Livraisons', _getRidesCount()),
              _buildDetailRow('Bonus gagnés', '${widget.driverProfile.stats.bonusEarned.toStringAsFixed(0)} FCFA'),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 14),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Color(0xFF00A651),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBonusSection() {
    final bonus = widget.driverProfile.subscription?.weeklyBonus;
    
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Colors.orange, width: 2),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.card_giftcard, color: Colors.orange),
                const SizedBox(width: 8),
                const Text(
                  'Bonus Hebdomadaires',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (bonus != null && bonus.hasBonus) ...[
              _buildDetailRow('Type de bonus', bonus.bonusDescription),
              _buildDetailRow('Total gagné', '${bonus.amount.toStringAsFixed(0)} FCFA'),
              if (bonus.lastBonusDate != null)
                _buildDetailRow('Dernier bonus', _formatDate(bonus.lastBonusDate!)),
              const SizedBox(height: 12),
              TextButton.icon(
                onPressed: () => _showBonusHistory(),
                icon: const Icon(Icons.history),
                label: const Text('Voir l\'historique complet'),
              ),
            ] else ...[
              const Text(
                'Aucun bonus cette semaine',
                style: TextStyle(
                  color: Colors.grey,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildRideHistory() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Historique Récent',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildRideItem('Course #001', 'Plateau → Mermoz', '1,500 FCFA', 'Aujourd\'hui 14:30'),
            _buildRideItem('Course #002', 'Ouakam → Fann', '2,200 FCFA', 'Aujourd\'hui 12:15'),
            _buildRideItem('Course #003', 'Parcelles → Liberté', '1,800 FCFA', 'Aujourd\'hui 10:45'),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => _showFullHistory(),
              child: const Text('Voir tout l\'historique'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRideItem(String id, String route, String price, String time) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: Color(0xFF00A651),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  id,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
                Text(
                  route,
                  style: const TextStyle(fontSize: 14),
                ),
                Text(
                  time,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Text(
            price,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Color(0xFF00A651),
            ),
          ),
        ],
      ),
    );
  }

  String _getPeriodLabel() {
    switch (_selectedPeriod) {
      case 'today':
        return 'Aujourd\'hui';
      case 'week':
        return 'Cette semaine';
      case 'month':
        return 'Ce mois';
      case 'year':
        return 'Cette année';
      default:
        return 'Aujourd\'hui';
    }
  }

  String _getRidesCount() {
    final stats = widget.driverProfile.stats;
    switch (_selectedPeriod) {
      case 'today':
        return '${stats.todayRides}';
      case 'week':
        return '${stats.weeklyRides}';
      case 'month':
        return '${(stats.weeklyRides * 4).toStringAsFixed(0)}';
      case 'year':
        return '${stats.totalRides}';
      default:
        return '${stats.todayRides}';
    }
  }

  String _getEarnings() {
    final stats = widget.driverProfile.stats;
    switch (_selectedPeriod) {
      case 'today':
        return stats.todayEarningsFormatted;
      case 'week':
        return stats.weeklyEarningsFormatted;
      case 'month':
        return '${(stats.weeklyEarnings * 4).toStringAsFixed(0)} FCFA';
      case 'year':
        return stats.earningsFormatted;
      default:
        return stats.todayEarningsFormatted;
    }
  }

  String _getDrivingTime() {
    switch (_selectedPeriod) {
      case 'today':
        return '6h 30min';
      case 'week':
        return '32h 15min';
      case 'month':
        return '128h 45min';
      case 'year':
        return '1,245h 30min';
      default:
        return '6h 30min';
    }
  }

  String _getDistance() {
    final stats = widget.driverProfile.stats;
    switch (_selectedPeriod) {
      case 'today':
        return '45 km';
      case 'week':
        return '180 km';
      case 'month':
        return '720 km';
      case 'year':
        return '${(stats.totalDistance / 1000).toStringAsFixed(0)} km';
      default:
        return '45 km';
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  void _showBonusHistory() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Historique des Bonus'),
        content: SizedBox(
          width: double.maxFinite,
          height: 300,
          child: ListView(
            children: [
              _buildBonusHistoryItem('24h gratuites', '2,000 FCFA', 'Il y a 2 jours'),
              _buildBonusHistoryItem('Virement Wave', '5,000 FCFA', 'Il y a 9 jours'),
              _buildBonusHistoryItem('24h gratuites', '2,000 FCFA', 'Il y a 16 jours'),
              _buildBonusHistoryItem('Virement Orange Money', '3,000 FCFA', 'Il y a 23 jours'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }

  Widget _buildBonusHistoryItem(String type, String amount, String date) {
    return ListTile(
      leading: const Icon(Icons.card_giftcard, color: Colors.orange),
      title: Text(type),
      subtitle: Text(date),
      trailing: Text(
        amount,
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
    );
  }

  void _showFullHistory() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Historique Complet'),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: ListView(
            children: List.generate(20, (index) {
              return _buildRideItem(
                'Course #${(index + 1).toString().padLeft(3, '0')}',
                'Trajet ${index + 1}',
                '${(1500 + index * 100).toStringAsFixed(0)} FCFA',
                'Il y a ${index + 1} jour${index > 0 ? 's' : ''}',
              );
            }),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }
}
