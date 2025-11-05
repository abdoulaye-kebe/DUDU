import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/driver_profile.dart';

/// Profil du chauffeur - Données réelles depuis le backend
class DriverProfileScreen extends StatefulWidget {
  const DriverProfileScreen({Key? key}) : super(key: key);

  @override
  State<DriverProfileScreen> createState() => _DriverProfileScreenState();
}

class _DriverProfileScreenState extends State<DriverProfileScreen> {
  static const Color primaryGreen = Color(0xFF0d5d36);
  static const Color accentBlack = Color(0xFF1A1A1A);

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
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final profile = await ApiService.getDriverProfile();
      
      setState(() {
        _profile = profile;
        _isLoading = false;
      });
    } catch (e) {
      print('Erreur chargement profil: $e');
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Mon profil'),
        backgroundColor: primaryGreen,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadProfile,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 60, color: Colors.red),
                      const SizedBox(height: 16),
                      Text('Erreur: $_error'),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadProfile,
                        child: const Text('Réessayer'),
                      ),
                    ],
                  ),
                )
              : _profile == null
                  ? const Center(child: Text('Profil non trouvé'))
                  : SingleChildScrollView(
        child: Column(
          children: [
            // En-tête avec photo et nom
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: primaryGreen.withOpacity(0.1),
              ),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: primaryGreen,
                    child: Text(
                      '${_profile!.firstName[0]}${_profile!.lastName[0]}',
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _profile!.fullName,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: accentBlack,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _profile!.phone,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Statistiques
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStatItem('Note', '${_profile!.stats.averageRating.toStringAsFixed(1)} ⭐', Icons.star),
                      _buildStatItem('Courses', '${_profile!.stats.totalRides}', Icons.directions_car),
                      _buildStatItem('Type', _profile!.vehicleType.displayName, Icons.info),
                    ],
                  ),
                ],
              ),
            ),

            // Informations personnelles
            _buildSection(
              'Informations personnelles',
              [
                _buildInfoRow(Icons.person, 'Nom complet', _profile!.fullName),
                _buildInfoRow(Icons.phone, 'Téléphone', _profile!.phone),
                _buildInfoRow(Icons.email, 'Email', _profile!.email),
              ],
            ),

            // Informations véhicule
            _buildSection(
              'Mon véhicule',
              [
                _buildInfoRow(Icons.directions_car, 'Marque', _profile!.vehicle.make),
                _buildInfoRow(Icons.car_rental, 'Modèle', _profile!.vehicle.model),
                _buildInfoRow(Icons.calendar_today, 'Année', '${_profile!.vehicle.year}'),
                _buildInfoRow(Icons.palette, 'Couleur', _profile!.vehicle.color),
                _buildInfoRow(Icons.pin, 'Plaque', _profile!.vehicle.plateNumber),
                _buildInfoRow(Icons.category, 'Type', _profile!.vehicle.type),
              ],
            ),

            // Types de courses acceptées
            _buildSection(
              'Types de courses acceptées',
              [
                _buildRideTypeChip('Standard', true, primaryGreen),
                _buildRideTypeChip('Express', true, Colors.orange),
                _buildRideTypeChip('Covoiturage', false, Colors.blue),
                _buildRideTypeChip('Femmes uniquement', false, Colors.pink),
              ],
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: primaryGreen, size: 24),
        const SizedBox(height: 4),
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
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: accentBlack,
            ),
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, color: primaryGreen, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
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

  Widget _buildRideTypeChip(String label, bool isActive, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isActive ? color.withOpacity(0.1) : Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isActive ? color : Colors.grey[300]!,
          width: 2,
        ),
      ),
      child: Row(
        children: [
          Icon(
            isActive ? Icons.check_circle : Icons.cancel,
            color: isActive ? color : Colors.grey,
            size: 20,
          ),
          const SizedBox(width: 12),
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isActive ? color : Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

}
