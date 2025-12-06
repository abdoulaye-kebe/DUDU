import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/api_service.dart';
import '../services/socket_service.dart';
import 'ride_requests_screen.dart';
import 'driver_profile_screen.dart';
import 'driver_rides_screen.dart';
import 'settings_screen.dart';
import 'login_screen.dart';
import 'subscription_widget.dart';
import 'subscription_plans_screen.dart';

/// Dashboard chauffeur moderne avec design cohérent au client
class NewDriverDashboard extends StatefulWidget {
  const NewDriverDashboard({Key? key}) : super(key: key);

  @override
  State<NewDriverDashboard> createState() => _NewDriverDashboardState();
}

class _NewDriverDashboardState extends State<NewDriverDashboard> {
  // Couleurs DUDU
  static const Color primaryGreen = Color(0xFF0d5d36);
  static const Color lightGreen = Color(0xFF10b981);
  static const Color accentBlack = Color(0xFF1A1A1A);

  // États
  bool _isOnline = false;
  bool _carpoolEnabled = false;
  bool _womenOnlyEnabled = false;
  Position? _currentPosition;
  GoogleMapController? _mapController;
  StreamSubscription<Map<String, dynamic>>? _rideRequestSub;
  StreamSubscription<String>? _rideClosedSub;

  // Stats du jour (données réelles depuis l'API)
  int _todayRides = 0;
  double _todayEarnings = 0;
  double _rating = 0.0;
  int _pendingRequests = 0;
  
  // Abonnement
  String _currentPlan = 'free'; // free, daily, weekly, monthly
  DateTime? _subscriptionExpiry; // null si pas d'abonnement

  // Type de profil: chauffeur (voiture) ou livreur (moto)
  String _driverTypeLabel = '';

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
    _loadTodayStats();
    _subscribeToRideRequests();
  }

  @override
  void dispose() {
    _rideRequestSub?.cancel();
    _rideClosedSub?.cancel();
    super.dispose();
  }

  void _subscribeToRideRequests() {
    final socketService = SocketService();

    _rideRequestSub = socketService.rideRequestsStream.listen((data) {
      setState(() {
        _pendingRequests++;
      });

      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) {
            final passenger = (data['passenger'] ?? {}) as Map?;
            final pickup = data['pickup'];
            final destination = data['destination'];
            final pricing = (data['pricing'] ?? {}) as Map?;
            final passengerName = passenger?['name']?.toString() ?? 'Client DUDU';
            final passengerPhone = data['passengerPhone']?.toString();
            String pickupText;
            if (pickup is Map) {
              pickupText = pickup['address']?.toString() ?? pickup['label']?.toString() ?? 'Point de départ';
            } else if (pickup is String) {
              pickupText = pickup;
            } else {
              pickupText = 'Point de départ';
            }
            String destinationText;
            if (destination is Map) {
              destinationText = destination['address']?.toString() ?? destination['label']?.toString() ?? 'Destination';
            } else if (destination is String) {
              destinationText = destination;
            } else {
              destinationText = 'Destination';
            }
            final priceValue = pricing?['customPrice'] ??
                pricing?['totalPrice'] ??
                data['customPrice'] ?? 0;
            final price = priceValue.toString();

            return AlertDialog(
              title: const Text(
                'NOUVELLE DEMANDE DE COURSE',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    passengerName,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text('Départ : $pickupText'),
                  Text('Arrivée : $destinationText'),
                  const SizedBox(height: 8),
                  Text(
                    'Prix proposé : $price FCFA',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: primaryGreen,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Appuyez sur "VOIR LES DEMANDES" pour accepter ou refuser.',
                    style: TextStyle(fontSize: 13),
                  ),
                ],
              ),
              actions: [
                if (passengerPhone != null && passengerPhone.isNotEmpty)
                  TextButton.icon(
                    onPressed: () async {
                      final uri = Uri(scheme: 'tel', path: passengerPhone);
                      if (await canLaunchUrl(uri)) {
                        await launchUrl(uri);
                      }
                    },
                    icon: const Icon(Icons.phone),
                    label: const Text('APPELER LE CLIENT'),
                  ),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text('PLUS TARD'),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const RideRequestsScreen(),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryGreen,
                  ),
                  child: const Text('VOIR LES DEMANDES'),
                ),
              ],
            );
          },
        );
      }
    });

    _rideClosedSub = socketService.rideClosedStream.listen((rideId) {
      if (!mounted) return;
      setState(() {
        if (_pendingRequests > 0) {
          _pendingRequests--;
        }
      });
    });
  }

  Future<void> _getCurrentLocation() async {
    try {
      // Vérifier si le service de localisation est activé
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        print('Service de localisation désactivé');
        // Utiliser une position par défaut (Dakar)
        setState(() {
          _currentPosition = Position(
            latitude: 14.6928,
            longitude: -17.4467,
            timestamp: DateTime.now(),
            accuracy: 0,
            altitude: 0,
            heading: 0,
            speed: 0,
            speedAccuracy: 0,
            altitudeAccuracy: 0,
            headingAccuracy: 0,
          );
        });
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        print('Permission de localisation refusée');
        // Utiliser position par défaut
        setState(() {
          _currentPosition = Position(
            latitude: 14.6928,
            longitude: -17.4467,
            timestamp: DateTime.now(),
            accuracy: 0,
            altitude: 0,
            heading: 0,
            speed: 0,
            speedAccuracy: 0,
            altitudeAccuracy: 0,
            headingAccuracy: 0,
          );
        });
        return;
      }

      Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          // Position par défaut si timeout
          return Position(
            latitude: 14.6928,
            longitude: -17.4467,
            timestamp: DateTime.now(),
            accuracy: 0,
            altitude: 0,
            heading: 0,
            speed: 0,
            speedAccuracy: 0,
            altitudeAccuracy: 0,
            headingAccuracy: 0,
          );
        },
      );

      // Vérifier si la position est au Sénégal
      bool isInSenegal = position.latitude >= 12.0 &&
          position.latitude <= 17.0 &&
          position.longitude >= -18.0 &&
          position.longitude <= -11.0;

      // Si hors Sénégal (ex: émulateur aux USA), utiliser Dakar par défaut
      if (!isInSenegal) {
        print('📍 Position hors Sénégal détectée, utilisation de Dakar par défaut');
        position = Position(
          latitude: 14.6928,
          longitude: -17.4467,
          timestamp: DateTime.now(),
          accuracy: 0,
          altitude: 0,
          heading: 0,
          speed: 0,
          speedAccuracy: 0,
          altitudeAccuracy: 0,
          headingAccuracy: 0,
        );
      }

      setState(() {
        _currentPosition = position;
      });

      // Envoyer la localisation actuelle au backend pour rendre le chauffeur détectable par la recherche de courses
      try {
        await ApiService.updateLocation(position.latitude, position.longitude);
        print('✅ Position envoyée au backend: ${position.latitude}, ${position.longitude}');
      } catch (e) {
        print('Erreur envoi localisation backend: $e');
      }

      _mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(
          LatLng(position.latitude, position.longitude),
          14.0,
        ),
      );
    } catch (e) {
      print('Erreur géolocalisation: $e');
      // Position par défaut en cas d'erreur
      setState(() {
        _currentPosition = Position(
          latitude: 14.6928,
          longitude: -17.4467,
          timestamp: DateTime.now(),
          accuracy: 0,
          altitude: 0,
          heading: 0,
          speed: 0,
          speedAccuracy: 0,
          altitudeAccuracy: 0,
          headingAccuracy: 0,
        );
      });
    }
  }

  Future<void> _loadTodayStats() async {
    try {
      final profile = await ApiService.getDriverProfile();
      setState(() {
        _todayRides = profile.stats.todayRides;
        _todayEarnings = profile.stats.todayEarnings;
        _rating = profile.stats.averageRating;
        _isOnline = profile.isOnline;
        _driverTypeLabel = profile.isCourier ? 'Livreur (moto)' : 'Chauffeur';
        
        // Charger les préférences du chauffeur depuis le profil
        if (profile.rideTypes != null) {
          _carpoolEnabled = profile.rideTypes!['shared'] ?? false;
          _womenOnlyEnabled = profile.rideTypes!['women_only'] ?? false;
        }
      });
    } catch (e) {
      print('Erreur chargement stats: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      // Bouton flottant Accueil - visible partout
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Retourner au dashboard et rafraîchir
          Navigator.of(context).popUntil((route) => route.isFirst);
          _loadDriverData();
        },
        backgroundColor: primaryGreen,
        child: const Icon(Icons.home, color: Colors.white),
        tooltip: 'Accueil',
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.startFloat,
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'DUDU',
                style: TextStyle(
                  color: primaryGreen,
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Pro',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (_driverTypeLabel.isNotEmpty)
                  Text(
                    _driverTypeLabel,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      color: Colors.white70,
                    ),
                  ),
              ],
            ),
          ],
        ),
        backgroundColor: primaryGreen,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          // Bouton Menu
          PopupMenuButton<String>(
            icon: const Icon(Icons.menu, color: Colors.white),
            onSelected: (value) {
              switch (value) {
                case 'profile':
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const DriverProfileScreen(),
                    ),
                  );
                  break;
                case 'history':
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const DriverRidesScreen(),
                    ),
                  );
                  break;
                case 'settings':
                  // TODO: Passer le vrai profil
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Paramètres - En développement')),
                  );
                  break;
                case 'logout':
                  _logout();
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'profile',
                child: Row(
                  children: [
                    Icon(Icons.person, color: primaryGreen),
                    SizedBox(width: 12),
                    Text('Mon profil'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'history',
                child: Row(
                  children: [
                    Icon(Icons.history, color: primaryGreen),
                    SizedBox(width: 12),
                    Text('Mon historique'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'settings',
                child: Row(
                  children: [
                    Icon(Icons.settings, color: primaryGreen),
                    SizedBox(width: 12),
                    Text('Paramètres'),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout, color: Colors.red),
                    SizedBox(width: 12),
                    Text('Se déconnecter', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Abonnement
            SubscriptionWidget(
              currentPlan: _currentPlan,
              expiryDate: _subscriptionExpiry,
              onUpgrade: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const SubscriptionPlansScreen(),
                  ),
                );
                if (result != null) {
                  setState(() {
                    _currentPlan = result;
                    // Calculer la nouvelle date d'expiration
                    switch (result) {
                      case 'daily':
                        _subscriptionExpiry = DateTime.now().add(const Duration(days: 1));
                        break;
                      case 'weekly':
                        _subscriptionExpiry = DateTime.now().add(const Duration(days: 7));
                        break;
                      case 'monthly':
                        _subscriptionExpiry = DateTime.now().add(const Duration(days: 30));
                        break;
                    }
                  });
                }
              },
            ),
            
            // Statut Online/Offline
            _buildStatusToggle(),

            // Statistiques du jour
            _buildTodayStats(),

            // Demandes en attente
            if (_pendingRequests > 0) _buildPendingRequests(),

            // Carte de localisation
            _buildLocationMap(),

            // Actions rapides
            _buildQuickActions(),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusToggle() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        children: [
          // Bouton En ligne/Hors ligne - Plus compact
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: _isOnline ? primaryGreen.withOpacity(0.1) : Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _isOnline ? primaryGreen : Colors.grey[300]!,
                width: 2,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: _isOnline ? lightGreen : Colors.grey,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      _isOnline ? 'En ligne' : 'Hors ligne',
                      style: TextStyle(
                        color: _isOnline ? primaryGreen : Colors.grey[700],
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                Switch(
                  value: _isOnline,
                  onChanged: (value) async {
                    try {
                      await ApiService.toggleOnlineStatus(value);
                      // Lors du passage en ligne, renvoyer la localisation actuelle au backend si disponible
                      if (value && _currentPosition != null) {
                        try {
                          await ApiService.updateLocation(
                            _currentPosition!.latitude,
                            _currentPosition!.longitude,
                          );
                        } catch (e) {
                          print('Erreur mise à jour localisation lors du passage en ligne: $e');
                        }
                      }
                      setState(() => _isOnline = value);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            value ? '✅ Vous êtes en ligne' : '⏸️ Vous êtes hors ligne',
                          ),
                          backgroundColor: value ? primaryGreen : Colors.grey,
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Erreur: $e'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  },
                  activeColor: lightGreen,
                  activeTrackColor: lightGreen.withOpacity(0.3),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 12),
          
          // Boutons Convoiturage et Femmes uniquement
          Row(
            children: [
              Expanded(
                child: _buildModeButton(
                  icon: Icons.people_outline,
                  label: 'Convoiturage',
                  isEnabled: _carpoolEnabled,
                  onTap: () {
                    setState(() => _carpoolEnabled = !_carpoolEnabled);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          _carpoolEnabled 
                              ? '🚗 Mode convoiturage activé' 
                              : 'Mode convoiturage désactivé',
                        ),
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildModeButton(
                  icon: Icons.woman,
                  label: 'Femmes uniquement',
                  isEnabled: _womenOnlyEnabled,
                  onTap: () {
                    setState(() => _womenOnlyEnabled = !_womenOnlyEnabled);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          _womenOnlyEnabled 
                              ? '👩 Mode femmes uniquement activé' 
                              : 'Mode femmes uniquement désactivé',
                        ),
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildModeButton({
    required IconData icon,
    required String label,
    required bool isEnabled,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isEnabled ? primaryGreen.withOpacity(0.1) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isEnabled ? primaryGreen : Colors.grey[300]!,
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isEnabled ? primaryGreen : Colors.grey[600],
              size: 18,
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                style: TextStyle(
                  color: isEnabled ? primaryGreen : Colors.grey[700],
                  fontSize: 13,
                  fontWeight: isEnabled ? FontWeight.w600 : FontWeight.normal,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTodayStats() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Aujourd\'hui',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: accentBlack,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  icon: Icons.directions_car,
                  label: 'Courses',
                  value: '$_todayRides',
                  color: primaryGreen,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  icon: Icons.payments,
                  label: 'Gains',
                  value: '${_todayEarnings.toInt()} FCFA',
                  color: Colors.orange,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildStatCard(
            icon: Icons.star,
            label: 'Note moyenne',
            value: _rating > 0 ? '$_rating ⭐' : 'Nouveau',
            color: Colors.amber,
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: Colors.white, size: 24),
          ),
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
                    fontWeight: FontWeight.bold,
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

  Widget _buildPendingRequests() {
    return Container(
      margin: const EdgeInsets.all(20),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const RideRequestsScreen(),
            ),
          );
        },
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.red[50],
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.red, width: 2),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.notifications_active,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$_pendingRequests demande${_pendingRequests > 1 ? 's' : ''} en attente',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.red,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Appuyez pour voir les détails',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios,
                color: Colors.red,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLocationMap() {
    return Container(
      margin: const EdgeInsets.all(20),
      height: 200,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[300]!),
      ),
      clipBehavior: Clip.antiAlias,
      child: GoogleMap(
        initialCameraPosition: CameraPosition(
          target: _currentPosition != null
              ? LatLng(_currentPosition!.latitude, _currentPosition!.longitude)
              : const LatLng(14.6928, -17.4467), // Dakar
          zoom: 14.0,
        ),
        onMapCreated: (controller) => _mapController = controller,
        myLocationEnabled: true,
        myLocationButtonEnabled: true,
        zoomControlsEnabled: false,
      ),
    );
  }

  Widget _buildQuickActions() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Actions rapides',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: accentBlack,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildActionCard(
                  icon: Icons.list_alt,
                  label: 'Demandes',
                  color: primaryGreen,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const RideRequestsScreen(),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildActionCard(
                  icon: Icons.history,
                  label: 'Historique',
                  color: Colors.blue,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const DriverRidesScreen(),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _logout() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Déconnexion'),
        content: const Text('Êtes-vous sûr de vouloir vous déconnecter ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const LoginScreen()),
                (route) => false,
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Se déconnecter'),
          ),
        ],
      ),
    );
  }
}
