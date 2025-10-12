import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'api_service.dart';

/// Service pour surveiller la disponibilité des chauffeurs en covoiturage
class CarpoolMonitorService {
  static final CarpoolMonitorService _instance = CarpoolMonitorService._internal();
  factory CarpoolMonitorService() => _instance;
  CarpoolMonitorService._internal();

  Timer? _monitorTimer;
  int _lastDriversCount = 0;
  bool _isMonitoring = false;
  Position? _lastPosition;
  
  BuildContext? _context;

  /// Démarrer la surveillance
  void startMonitoring(BuildContext context, Position? currentPosition) {
    if (_isMonitoring) return;
    
    _context = context;
    _lastPosition = currentPosition;
    _isMonitoring = true;
    
    print('🔍 Surveillance covoiturage démarrée');
    
    // Vérifier toutes les 10 secondes (pour test)
    _monitorTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      _checkCarpoolAvailability();
    });
    
    // Première vérification immédiate
    _checkCarpoolAvailability();
  }

  /// Arrêter la surveillance
  void stopMonitoring() {
    _monitorTimer?.cancel();
    _monitorTimer = null;
    _isMonitoring = false;
    print('⏹️ Surveillance covoiturage arrêtée');
  }

  /// Mettre à jour la position
  void updatePosition(Position position) {
    _lastPosition = position;
  }

  /// Vérifier la disponibilité des chauffeurs en covoiturage
  Future<void> _checkCarpoolAvailability() async {
    print('🔍 Vérification covoiturage démarrée...');
    
    if (_lastPosition == null) {
      print('⚠️ Position non disponible');
      return;
    }
    
    if (_context == null) {
      print('⚠️ Context non disponible');
      return;
    }

    try {
      // Simuler l'appel API pour obtenir les chauffeurs disponibles
      final response = await _getCarpoolDriversCount();
      
      final int currentCount = response['count'] ?? 0;
      final int totalSeats = response['totalSeats'] ?? 0;

      print('📊 Résultat: $currentCount chauffeurs, $totalSeats places');
      print('📊 Dernier count: $_lastDriversCount');

      // Si le nombre de chauffeurs a augmenté significativement
      if (currentCount > _lastDriversCount && currentCount >= 3) {
        print('🔔 Affichage de la notification !');
        _showNotification(currentCount, totalSeats);
      } else {
        print('ℹ️ Pas de notification (count: $currentCount, last: $_lastDriversCount)');
      }

      _lastDriversCount = currentCount;
    } catch (e) {
      print('❌ Erreur surveillance covoiturage: $e');
    }
  }

  /// Obtenir le nombre de chauffeurs en covoiturage depuis l'API
  Future<Map<String, dynamic>> _getCarpoolDriversCount() async {
    print('🌐 Récupération des chauffeurs...');
    
    if (_lastPosition == null) {
      print('⚠️ Position non disponible pour requête API');
      return {'count': 0, 'totalSeats': 0, 'drivers': []};
    }
    
    try {
      // Appel API réel
      final url = 'http://127.0.0.1:8000/api/v1/carpool/drivers/available'
          '?latitude=${_lastPosition!.latitude}'
          '&longitude=${_lastPosition!.longitude}'
          '&radius=1'; // 1km de rayon
      
      print('📡 Appel API: $url');
      
      final response = await http.get(Uri.parse(url));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data['success'] == true) {
          final drivers = data['data']['drivers'] as List;
          final count = data['data']['count'] as int;
          final totalSeats = data['data']['totalSeats'] as int;
          
          print('✅ API: $count chauffeurs, $totalSeats places');
          
          return {
            'count': count,
            'totalSeats': totalSeats,
            'drivers': drivers,
          };
        }
      }
      
      print('⚠️ API erreur, utilisation simulation');
      // Fallback sur simulation si API échoue
      return {'count': 0, 'totalSeats': 0, 'drivers': []};
      
    } catch (e) {
      print('❌ Erreur appel API: $e');
      return {'count': 0, 'totalSeats': 0, 'drivers': []};
    }
  }

  /// Afficher notification locale
  void _showNotification(int driversCount, int totalSeats) {
    if (_context == null || !_context!.mounted) return;

    final savings = 600; // Économie moyenne

    ScaffoldMessenger.of(_context!).showSnackBar(
      SnackBar(
        backgroundColor: const Color(0xFF00A651),
        duration: const Duration(seconds: 8),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text(
                  '🤝',
                  style: TextStyle(fontSize: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$driversCount chauffeurs en covoiturage !',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$totalSeats places disponibles • Économisez $savings FCFA',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
        action: SnackBarAction(
          label: 'VOIR',
          textColor: Colors.white,
          onPressed: () {
            print('👆 Voir covoiturage');
            _showCarpoolDrivers(driversCount, totalSeats);
          },
        ),
      ),
    );

    // Afficher aussi une notification système (si permissions)
    _showSystemNotification(driversCount, totalSeats, savings);
  }

  /// Afficher notification système (locale)
  void _showSystemNotification(int driversCount, int totalSeats, int savings) {
    // TODO: Utiliser flutter_local_notifications
    print('🔔 Notification: $driversCount chauffeurs • $totalSeats places • $savings FCFA');
  }

  /// Afficher les chauffeurs en covoiturage disponibles
  void _showCarpoolDrivers(int driversCount, int totalSeats) {
    if (_context == null || !_context!.mounted) return;
    
    // Récupérer les derniers drivers depuis la dernière vérification
    _getCarpoolDriversCount().then((data) {
      final drivers = data['drivers'] as List? ?? [];
      _showCarpoolDriversModal(drivers, driversCount, totalSeats);
    });
  }
  
  void _showCarpoolDriversModal(List drivers, int driversCount, int totalSeats) {
    if (_context == null || !_context!.mounted) return;

    showModalBottomSheet(
      context: _context!,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              // Poignée
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              
              // En-tête
              Row(
                children: [
                  const Text(
                    '🤝',
                    style: TextStyle(fontSize: 32),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Covoiturage Disponible',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '$driversCount chauffeurs • $totalSeats places',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 20),
              
              // Avantages
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF00A651).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    _buildBenefit('💰', 'Économisez jusqu\'à 20%', 'Sur le prix normal'),
                    const SizedBox(height: 12),
                    _buildBenefit('🌍', 'Écologique', 'Réduisez votre empreinte carbone'),
                    const SizedBox(height: 12),
                    _buildBenefit('👥', 'Convivial', 'Partagez votre trajet'),
                  ],
                ),
              ),
              
              const SizedBox(height: 20),
              
              // Liste des chauffeurs réels
              Expanded(
                child: drivers.isEmpty
                    ? const Center(
                        child: Text(
                          'Aucun chauffeur disponible pour le moment',
                          style: TextStyle(color: Colors.grey),
                        ),
                      )
                    : ListView.builder(
                        controller: scrollController,
                        itemCount: drivers.length,
                        itemBuilder: (context, index) => _buildDriverCardFromData(drivers[index]),
                      ),
              ),
              
              const SizedBox(height: 16),
              
              // Bouton de demande
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Demande de covoiturage envoyée !'),
                        backgroundColor: Color(0xFF00A651),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00A651),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Demander un covoiturage',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBenefit(String icon, String title, String subtitle) {
    return Row(
      children: [
        Text(icon, style: const TextStyle(fontSize: 24)),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDriverCardFromData(dynamic driverData) {
    final driver = {
      'name': driverData['name'] ?? 'Chauffeur',
      'car': '${driverData['vehicle']?['make'] ?? ''} ${driverData['vehicle']?['model'] ?? ''}'.trim(),
      'rating': (driverData['rating'] ?? 0).toDouble(),
      'seats': driverData['carpoolSeats'] ?? 0,
      'distance': '${driverData['distance']?.toStringAsFixed(1) ?? '0.0'} km',
      'time': _calculateETA(driverData['distance'] ?? 0),
      'plateNumber': driverData['vehicle']?['plateNumber'] ?? '',
      'color': driverData['vehicle']?['color'] ?? '',
    };
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // Avatar
            CircleAvatar(
              radius: 25,
              backgroundColor: const Color(0xFF00A651),
              child: Text(
                driver['name'].toString().substring(0, 1),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 12),
            
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    driver['name'].toString(),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    driver['car'].toString(),
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.star, size: 14, color: Colors.amber),
                      const SizedBox(width: 4),
                      Text(
                        driver['rating'].toString(),
                        style: const TextStyle(fontSize: 12),
                      ),
                      const SizedBox(width: 12),
                      const Icon(Icons.event_seat, size: 14, color: Color(0xFF00A651)),
                      const SizedBox(width: 4),
                      Text(
                        '${driver['seats']} places',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            // Distance
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  driver['distance'].toString(),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  driver['time'].toString(),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Forcer une vérification manuelle
  Future<Map<String, dynamic>> checkNow() async {
    return await _getCarpoolDriversCount();
  }

  /// Calculer le temps d'arrivée estimé selon la distance
  String _calculateETA(double distanceKm) {
    // Vitesse moyenne en ville: 30 km/h
    final minutes = (distanceKm / 30 * 60).ceil();
    return '$minutes min';
  }

  /// Obtenir l'état actuel
  bool get isMonitoring => _isMonitoring;
  int get lastDriversCount => _lastDriversCount;
}

