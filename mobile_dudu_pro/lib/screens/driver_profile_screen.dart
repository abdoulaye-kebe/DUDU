import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/driver_profile.dart';

/// Profil du chauffeur - Design moderne avec toutes les infos
class DriverProfileScreen extends StatefulWidget {
  const DriverProfileScreen({Key? key}) : super(key: key);

  @override
  State<DriverProfileScreen> createState() => _DriverProfileScreenState();
}

class _DriverProfileScreenState extends State<DriverProfileScreen> {
  static const Color primaryGreen = Color(0xFF0d5d36);
  static const Color lightGreen = Color(0xFF10b981);
  static const Color accentBlack = Color(0xFF1A1A1A);
  static const Color goldColor = Color(0xFFFFD700);

  DriverProfile? _profile;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      if (!mounted) return;
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final profile = await ApiService.getDriverProfile();
      
      if (!mounted) return;
      setState(() {
        _profile = profile;
        _isLoading = false;
      });
    } catch (e) {
      print('Erreur chargement profil: $e');
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: primaryGreen))
          : _error != null
              ? _buildErrorView()
              : _profile == null
                  ? const Center(child: Text('Profil non trouvé'))
                  : CustomScrollView(
                      slivers: [
                        _buildSliverAppBar(),
                        SliverToBoxAdapter(child: _buildProfileContent()),
                      ],
                    ),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.red[50],
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.error_outline, size: 60, color: Colors.red[400]),
            ),
            const SizedBox(height: 24),
            Text(
              'Erreur de chargement',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
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
              onPressed: _loadProfile,
              icon: const Icon(Icons.refresh),
              label: const Text('Réessayer'),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryGreen,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 280,
      pinned: true,
      backgroundColor: primaryGreen,
      foregroundColor: Colors.white,
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh),
          onPressed: _loadProfile,
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [primaryGreen, primaryGreen.withOpacity(0.8)],
            ),
          ),
          child: SafeArea(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 40),
                // Avatar avec badge de niveau
                Stack(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 3),
                      ),
                      child: CircleAvatar(
                        radius: 50,
                        backgroundColor: Colors.white,
                        child: Text(
                          _profile!.firstName.isNotEmpty && _profile!.lastName.isNotEmpty
                              ? '${_profile!.firstName[0]}${_profile!.lastName[0]}'
                              : '?',
                          style: const TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                            color: primaryGreen,
                          ),
                        ),
                      ),
                    ),
                    // Badge niveau de service
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: _getServiceLevelColor(),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: Text(
                          _getServiceLevelLabel(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  _profile!.fullName,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.phone, size: 16, color: Colors.white.withOpacity(0.8)),
                    const SizedBox(width: 6),
                    Text(
                      _profile!.phone,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _getServiceLevelColor() {
    // Vérifier le niveau de service depuis les données du profil
    final serviceLevel = _profile?.vehicle.type.toLowerCase() ?? 'standard';
    if (serviceLevel.contains('express') || serviceLevel.contains('premium')) {
      return goldColor;
    }
    return lightGreen;
  }

  String _getServiceLevelLabel() {
    final serviceLevel = _profile?.vehicle.type.toLowerCase() ?? 'standard';
    if (serviceLevel.contains('express') || serviceLevel.contains('premium')) {
      return 'EXPRESS';
    }
    return 'STANDARD';
  }

  Widget _buildProfileContent() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Statistiques principales
          _buildStatsCard(),
          const SizedBox(height: 16),
          
          // Gains
          _buildEarningsCard(),
          const SizedBox(height: 16),
          
          // Informations personnelles
          _buildInfoCard(
            'Informations personnelles',
            Icons.person,
            [
              _buildInfoTile(Icons.badge, 'Nom complet', _profile!.fullName),
              _buildInfoTile(Icons.phone_android, 'Téléphone', _profile!.phone),
              _buildInfoTile(Icons.email, 'Email', _profile!.email.isNotEmpty ? _profile!.email : 'Non renseigné'),
              _buildInfoTile(Icons.work, 'Type', _profile!.vehicleType.displayName),
            ],
          ),
          const SizedBox(height: 16),
          
          // Véhicule
          _buildVehicleCard(),
          const SizedBox(height: 16),
          
          // Abonnement
          _buildSubscriptionCard(),
          const SizedBox(height: 16),
          
          // Types de courses
          _buildRideTypesCard(),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildStatsCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatColumn(
            '${_profile!.stats.averageRating.toStringAsFixed(1)}',
            'Note',
            Icons.star,
            goldColor,
          ),
          _buildVerticalDivider(),
          _buildStatColumn(
            '${_profile!.stats.totalRides}',
            'Courses',
            Icons.directions_car,
            primaryGreen,
          ),
          _buildVerticalDivider(),
          _buildStatColumn(
            '${_profile!.stats.completedRides}',
            'Terminées',
            Icons.check_circle,
            lightGreen,
          ),
          _buildVerticalDivider(),
          _buildStatColumn(
            '${(_profile!.stats.acceptanceRate * 100).toStringAsFixed(0)}%',
            'Acceptation',
            Icons.thumb_up,
            Colors.blue,
          ),
        ],
      ),
    );
  }

  Widget _buildStatColumn(String value, String label, IconData icon, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 22),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: accentBlack,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildVerticalDivider() {
    return Container(
      height: 50,
      width: 1,
      color: Colors.grey[200],
    );
  }

  Widget _buildEarningsCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [primaryGreen, lightGreen],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: primaryGreen.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.account_balance_wallet, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 12),
              const Text(
                'Mes gains',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildEarningItem("Aujourd'hui", '${_profile!.earnings.today.toStringAsFixed(0)} F'),
              _buildEarningItem('Cette semaine', '${_profile!.earnings.thisWeek.toStringAsFixed(0)} F'),
              _buildEarningItem('Ce mois', '${_profile!.earnings.thisMonth.toStringAsFixed(0)} F'),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Total cumulé',
                  style: TextStyle(color: Colors.white, fontSize: 14),
                ),
                Text(
                  '${_profile!.earnings.total.toStringAsFixed(0)} FCFA',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEarningItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.8),
            fontSize: 11,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoCard(String title, IconData titleIcon, List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(titleIcon, color: primaryGreen, size: 22),
              const SizedBox(width: 10),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: accentBlack,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoTile(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: primaryGreen.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: primaryGreen, size: 18),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[500],
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: accentBlack,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVehicleCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _profile!.vehicle.type.toLowerCase().contains('moto') 
                      ? Icons.two_wheeler 
                      : Icons.directions_car,
                  color: Colors.blue,
                  size: 28,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${_profile!.vehicle.make} ${_profile!.vehicle.model}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: accentBlack,
                      ),
                    ),
                    Text(
                      _profile!.vehicle.plateNumber,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildVehicleDetail(Icons.calendar_today, 'Année', '${_profile!.vehicle.year}'),
              ),
              Expanded(
                child: _buildVehicleDetail(Icons.palette, 'Couleur', _profile!.vehicle.color),
              ),
              Expanded(
                child: _buildVehicleDetail(Icons.category, 'Type', _profile!.vehicle.type),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildVehicleDetail(IconData icon, String label, String value) {
    return Column(
      children: [
        Icon(icon, color: Colors.grey[400], size: 20),
        const SizedBox(height: 6),
        Text(
          value,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: accentBlack,
          ),
          textAlign: TextAlign.center,
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey[500],
          ),
        ),
      ],
    );
  }

  Widget _buildSubscriptionCard() {
    final subscription = _profile!.subscription;
    final isActive = subscription?.isActive ?? false;
    final planName = subscription?.type ?? 'Aucun';
    final endDate = subscription?.endDate;
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isActive ? lightGreen : Colors.grey[300]!,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isActive ? lightGreen.withOpacity(0.1) : Colors.grey[100],
              shape: BoxShape.circle,
            ),
            child: Icon(
              isActive ? Icons.verified : Icons.cancel,
              color: isActive ? lightGreen : Colors.grey,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Abonnement ${_capitalizeFirst(planName)}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: accentBlack,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isActive 
                      ? 'Actif jusqu\'au ${_formatDate(endDate)}'
                      : 'Aucun abonnement actif',
                  style: TextStyle(
                    fontSize: 13,
                    color: isActive ? lightGreen : Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: isActive ? lightGreen : Colors.grey[400],
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              isActive ? 'ACTIF' : 'INACTIF',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRideTypesCard() {
    final rideTypes = _profile!.rideTypes ?? {};
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.local_taxi, color: primaryGreen, size: 22),
              const SizedBox(width: 10),
              const Text(
                'Types de courses',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: accentBlack,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _buildRideTypeChip('Standard', rideTypes['standard'] ?? true, primaryGreen),
              _buildRideTypeChip('Express', rideTypes['express'] ?? false, Colors.orange),
              _buildRideTypeChip('Livraison', rideTypes['delivery'] ?? false, Colors.purple),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRideTypeChip(String label, bool isActive, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: isActive ? color.withOpacity(0.1) : Colors.grey[100],
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isActive ? color : Colors.grey[300]!,
          width: 1.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isActive ? Icons.check_circle : Icons.radio_button_unchecked,
            color: isActive ? color : Colors.grey,
            size: 16,
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isActive ? color : Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  String _capitalizeFirst(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1).toLowerCase();
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'N/A';
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
}
