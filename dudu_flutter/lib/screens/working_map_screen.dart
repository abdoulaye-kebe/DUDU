import 'package:flutter/material.dart';
import '../themes/app_theme.dart';

class WorkingMapScreen extends StatelessWidget {
  final String? title;
  final Function(Map<String, dynamic>)? onLocationSelected;

  const WorkingMapScreen({
    super.key,
    this.title = 'Sélectionner un lieu',
    this.onLocationSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title!),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF2E7D32), // Vert foncé
              Color(0xFF4CAF50), // Vert moyen
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Zone de carte simulée
              Expanded(
                flex: 3,
                child: Container(
                  margin: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // En-tête de la carte
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor,
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(12),
                            topRight: Radius.circular(12),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.location_on, color: Colors.white),
                            const SizedBox(width: 8),
                            Text(
                              'Carte DUDU - Dakar',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Zone de carte
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: 80,
                                height: 80,
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryColor.withOpacity(0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.map,
                                  size: 40,
                                  color: AppTheme.primaryColor,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Carte interactive DUDU',
                                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey[800],
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Sélectionnez votre destination ci-dessous',
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: Colors.grey[600],
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Zone de sélection des lieux
              Expanded(
                flex: 2,
                child: Container(
                  margin: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.blue[50],
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(12),
                            topRight: Radius.circular(12),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.location_city, color: Colors.blue[700]),
                            const SizedBox(width: 8),
                            Text(
                              'Lieux populaires à Dakar',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                color: Colors.blue[700],
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: ListView(
                          padding: const EdgeInsets.all(16),
                          children: [
                            _buildLocationTile(
                              context,
                              Icons.location_city,
                              'Centre de Dakar',
                              'Place de l\'Indépendance',
                              const LatLng(14.6928, -17.4467),
                              'Centre historique et commercial',
                            ),
                            const SizedBox(height: 12),
                            _buildLocationTile(
                              context,
                              Icons.flight,
                              'Aéroport Léopold Sédar Senghor',
                              'Aéroport international',
                              const LatLng(14.6708, -17.4731),
                              'Aéroport principal du Sénégal',
                            ),
                            const SizedBox(height: 12),
                            _buildLocationTile(
                              context,
                              Icons.business,
                              'SICAP',
                              'Zone commerciale',
                              const LatLng(14.7167, -17.4677),
                              'Centre d\'affaires et commerces',
                            ),
                            const SizedBox(height: 12),
                            _buildLocationTile(
                              context,
                              Icons.beach_access,
                              'Plage de Yoff',
                              'Zone touristique',
                              const LatLng(14.7500, -17.4833),
                              'Plage populaire et restaurants',
                            ),
                            const SizedBox(height: 12),
                            _buildLocationTile(
                              context,
                              Icons.school,
                              'Université Cheikh Anta Diop',
                              'Campus universitaire',
                              const LatLng(14.7083, -17.4917),
                              'Principale université du pays',
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLocationTile(
    BuildContext context,
    IconData icon,
    String title,
    String subtitle,
    LatLng coordinates,
    String description,
  ) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: AppTheme.primaryColor,
            size: 20,
          ),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              subtitle,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              description,
              style: TextStyle(
                color: Colors.grey[500],
                fontSize: 10,
              ),
            ),
          ],
        ),
        trailing: Icon(
          Icons.arrow_forward_ios,
          size: 16,
          color: Colors.grey[400],
        ),
        onTap: () {
          final locationData = {
            'location': {
              'lat': coordinates.latitude,
              'lng': coordinates.longitude,
            },
            'address': title,
            'description': description,
          };
          
          if (onLocationSelected != null) {
            onLocationSelected!(locationData);
          }
          
          Navigator.pop(context, locationData);
        },
      ),
    );
  }
}

// Classe LatLng simplifiée
class LatLng {
  final double latitude;
  final double longitude;
  
  const LatLng(this.latitude, this.longitude);
}

