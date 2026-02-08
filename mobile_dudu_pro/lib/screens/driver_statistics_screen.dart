import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/driver_profile.dart';

/// Écran de statistiques détaillées pour le chauffeur
class DriverStatisticsScreen extends StatefulWidget {
  const DriverStatisticsScreen({Key? key}) : super(key: key);

  @override
  State<DriverStatisticsScreen> createState() => _DriverStatisticsScreenState();
}

class _DriverStatisticsScreenState extends State<DriverStatisticsScreen> {
  static const Color primaryGreen = Color(0xFF0d5d36);
  bool _isLoading = true;
  DriverStats? _stats;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final stats = await ApiService.getDriverStats();
      setState(() {
        _stats = stats;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Mes Statistiques'),
        backgroundColor: primaryGreen,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadStats,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildErrorState()
              : _buildStatsContent(),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'Erreur de chargement',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _error ?? 'Une erreur est survenue',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadStats,
              icon: const Icon(Icons.refresh),
              label: const Text('Réessayer'),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryGreen,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsContent() {
    if (_stats == null) {
      return const Center(child: Text('Aucune statistique disponible'));
    }

    return RefreshIndicator(
      onRefresh: _loadStats,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Statistiques du jour
            _buildSectionTitle('Aujourd\'hui'),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    icon: Icons.directions_car,
                    label: 'Courses',
                    value: '${_stats!.todayRides}',
                    color: primaryGreen,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    icon: Icons.payments,
                    label: 'Gains',
                    value: '${_stats!.todayEarnings.toInt()} F',
                    color: Colors.orange,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Statistiques de la semaine
            _buildSectionTitle('Cette semaine'),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    icon: Icons.directions_car,
                    label: 'Courses',
                    value: '${_stats!.weeklyRides}',
                    color: Colors.blue,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    icon: Icons.payments,
                    label: 'Gains',
                    value: '${_stats!.weeklyEarnings.toInt()} F',
                    color: Colors.purple,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Statistiques globales
            _buildSectionTitle('Statistiques globales'),
            const SizedBox(height: 12),
            _buildStatCard(
              icon: Icons.star,
              label: 'Note moyenne',
              value: _stats!.averageRating > 0 
                  ? '${_stats!.averageRating.toStringAsFixed(1)} ⭐'
                  : 'Nouveau',
              color: Colors.amber,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    icon: Icons.check_circle,
                    label: 'Courses terminées',
                    value: '${_stats!.completedRides}',
                    color: Colors.green,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    icon: Icons.cancel,
                    label: 'Annulées',
                    value: '${_stats!.cancelledRides}',
                    color: Colors.red,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    icon: Icons.route,
                    label: 'Distance totale',
                    value: '${_stats!.totalDistance.toStringAsFixed(0)} km',
                    color: Colors.indigo,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    icon: Icons.trending_up,
                    label: 'Taux d\'acceptation',
                    value: '${_stats!.acceptanceRate.toStringAsFixed(0)}%',
                    color: Colors.teal,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Revenus
            _buildSectionTitle('Revenus'),
            const SizedBox(height: 12),
            _buildStatCard(
              icon: Icons.account_balance_wallet,
              label: 'Revenus totaux',
              value: '${_stats!.totalEarnings.toInt()} FCFA',
              color: primaryGreen,
              isLarge: true,
            ),
            const SizedBox(height: 12),
            if (_stats!.bonusEarned > 0)
              _buildStatCard(
                icon: Icons.card_giftcard,
                label: 'Bonus gagnés',
                value: '${_stats!.bonusEarned.toInt()} FCFA',
                color: Colors.pink,
              ),
            const SizedBox(height: 24),

            // Conseils
            _buildTipsSection(),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Colors.black87,
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    bool isLarge = false,
  }) {
    return Container(
      padding: EdgeInsets.all(isLarge ? 20 : 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(isLarge ? 14 : 10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: color,
              size: isLarge ? 32 : 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: isLarge ? 14 : 12,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: isLarge ? 24 : 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTipsSection() {
    final tips = <Map<String, dynamic>>[];

    if (_stats!.averageRating < 4.5) {
      tips.add({
        'icon': Icons.star,
        'color': Colors.amber,
        'text': 'Améliorez votre note en offrant un excellent service',
      });
    }

    if (_stats!.acceptanceRate < 80) {
      tips.add({
        'icon': Icons.trending_up,
        'color': Colors.blue,
        'text': 'Augmentez votre taux d\'acceptation pour plus de courses',
      });
    }

    if (_stats!.todayRides == 0) {
      tips.add({
        'icon': Icons.directions_car,
        'color': primaryGreen,
        'text': 'Mettez-vous en ligne pour commencer à recevoir des courses',
      });
    }

    if (tips.isEmpty) {
      tips.add({
        'icon': Icons.celebration,
        'color': Colors.green,
        'text': 'Excellent travail ! Continuez comme ça ! 🎉',
      });
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.blue[100]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.lightbulb, color: Colors.blue[700]),
              const SizedBox(width: 8),
              const Text(
                'Conseils',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...tips.map((tip) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      tip['icon'] as IconData,
                      color: tip['color'] as Color,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        tip['text'] as String,
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}
