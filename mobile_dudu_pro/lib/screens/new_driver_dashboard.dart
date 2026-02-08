import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import '../services/socket_service.dart';
import '../models/driver_profile.dart';
import 'ride_requests_screen.dart';
import 'driver_profile_screen.dart';
import 'driver_rides_screen.dart';
import 'driver_history_screen.dart';
import 'driver_settings_screen.dart';
import 'driver_help_screen.dart';
import 'settings_screen.dart';
import 'login_screen.dart';
import 'subscription_widget.dart';
import 'subscription_screen.dart';

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

  // Profil complet du chauffeur/livreur
  DriverProfile? _driverProfile;

  @override
  void initState() {
    super.initState();
    _loadDriverData();
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
            final rawRideType = data['rideType']?.toString() ?? 'standard';
            final normalizedRideType = rawRideType == 'express' ? 'comfort' : rawRideType;
            final rideTypeLabels = {
              'standard': 'Standard',
              'comfort': 'Confort',
              'women_only': 'Femme',
              'delivery': 'Livraison',
              'luxe': 'Luxe',
              'moto': 'Moto',
            };
            final rideTypeLabel = rideTypeLabels[normalizedRideType] ?? 'Standard';
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
            final perKmValue = pricing?['customPricePerKm'] ?? data['customPricePerKm'];
            final perKmText = perKmValue != null ? perKmValue.toString() : null;
            
            // Vérifier si c'est une course planifiée
            final scheduledFor = data['scheduledFor'];
            final isScheduled = scheduledFor != null;
            String scheduledTimeText = '';
            if (isScheduled) {
              try {
                final scheduledDate = DateTime.parse(scheduledFor.toString());
                final now = DateTime.now();
                final difference = scheduledDate.difference(now);
                
                if (difference.inMinutes < 60) {
                  scheduledTimeText = 'Dans ${difference.inMinutes} min';
                } else if (difference.inHours < 24) {
                  scheduledTimeText = 'Dans ${difference.inHours}h';
                } else {
                  scheduledTimeText = 'Le ${scheduledDate.day}/${scheduledDate.month} à ${scheduledDate.hour}:${scheduledDate.minute.toString().padLeft(2, '0')}';
                }
              } catch (e) {
                scheduledTimeText = 'Planifiée';
              }
            }

            return AlertDialog(
              title: Row(
                children: [
                  Expanded(
                    child: Text(
                      isScheduled ? 'COURSE PLANIFIÉE' : 'NOUVELLE DEMANDE',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: isScheduled ? Colors.orange : Colors.black,
                      ),
                    ),
                  ),
                  if (isScheduled)
                    Icon(Icons.schedule, color: Colors.orange, size: 28),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: primaryGreen.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          rideTypeLabel,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            color: primaryGreen,
                          ),
                        ),
                      ),
                      if (isScheduled) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.orange.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.access_time, size: 14, color: Colors.orange),
                              const SizedBox(width: 4),
                              Text(
                                scheduledTimeText,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: Colors.orange,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 10),
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
                  if (perKmText != null && perKmText.isNotEmpty)
                    Text(
                      'Prix / km : $perKmText FCFA/km',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[700],
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

      if (!mounted) return;
      
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
      if (!mounted) return;
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
      if (!mounted) return;
      setState(() {
        _driverProfile = profile;
        _todayRides = profile.stats.todayRides;
        _todayEarnings = profile.stats.todayEarnings;
        _rating = profile.stats.averageRating;
        _isOnline = profile.isOnline;
        _driverTypeLabel = profile.isCourier ? 'Livreur (moto)' : 'Chauffeur';
        
        // Charger les préférences du chauffeur depuis le profil
        if (profile.rideTypes != null) {
          _womenOnlyEnabled = profile.rideTypes!['women_only'] ?? false;
        }

        // Charger l'abonnement courant à partir du profil si disponible
        if (profile.subscription != null) {
          _currentPlan = profile.subscription!.type;
          _subscriptionExpiry = profile.subscription!.endDate;
        } else {
          _currentPlan = 'free';
          _subscriptionExpiry = null;
        }
      });
    } catch (e) {
      print('Erreur chargement stats: $e');
    }
  }

  void _loadDriverData() {
    _loadTodayStats();
    _getCurrentLocation();
    _loadCurrentSubscription();
  }

  Future<void> _loadCurrentSubscription() async {
    try {
      final subscription = await ApiService.getCurrentSubscription();
      if (!mounted) return;

      if (subscription != null && subscription.isActive) {
        setState(() {
          _currentPlan = subscription.type;
          _subscriptionExpiry = subscription.endDate;
        });
      }
    } catch (_) {
      // On ignore les erreurs ici pour ne pas bloquer le dashboard
    }
  }

  /// Affiche le menu utilisateur en bottom sheet (comme l'app client)
  void _showDriverMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            _buildMenuOption(
              icon: Icons.person_outline,
              title: 'Mon profil',
              color: primaryGreen,
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const DriverProfileScreen()),
                );
              },
            ),
            _buildMenuOption(
              icon: Icons.history,
              title: 'Mon historique',
              color: lightGreen,
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const DriverHistoryScreen()),
                );
              },
            ),
            _buildMenuOption(
              icon: Icons.settings_outlined,
              title: 'Paramètres',
              color: Colors.grey[700]!,
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const DriverSettingsScreen()),
                );
              },
            ),
            _buildMenuOption(
              icon: Icons.help_outline,
              title: 'Aide & Support',
              color: Colors.blue,
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const DriverHelpScreen()),
                );
              },
            ),
            const Divider(),
            _buildMenuOption(
              icon: Icons.logout,
              title: 'Se déconnecter',
              color: Colors.red,
              onTap: () {
                Navigator.pop(context);
                _logout();
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  /// Construit une option de menu
  Widget _buildMenuOption({
    required IconData icon,
    required String title,
    required Color color,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: color, size: 24),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
      trailing: Icon(Icons.chevron_right, color: Colors.grey[400]),
      onTap: onTap,
    );
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
          _loadTodayStats();
        },
        backgroundColor: primaryGreen,
        child: const Icon(Icons.home, color: Colors.white),
        tooltip: 'Accueil',
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.startFloat,
      appBar: AppBar(
        toolbarHeight: 70,
        title: Row(
          children: [
            // Logo DUDU avec badge Pro
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'DUDU',
                style: TextStyle(
                  color: primaryGreen,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ),
            const SizedBox(width: 8),
            // Informations du chauffeur
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _driverProfile?.firstName != null && _driverProfile?.lastName != null
                        ? '${_driverProfile!.firstName} ${_driverProfile!.lastName}'
                        : 'Chauffeur DUDU',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on,
                        size: 14,
                        color: Colors.white70,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          'Dakar, Sénégal',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                            color: Colors.white70,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: primaryGreen,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          // Bouton Menu - Ouvre un bottom sheet comme l'app client
          IconButton(
            icon: const Icon(Icons.menu, color: Colors.white, size: 28),
            onPressed: _showDriverMenu,
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
                // Vérifier si le compte est vérifié avant d'accéder aux abonnements
                // Lire depuis SharedPreferences pour avoir la valeur immédiatement
                final prefs = await SharedPreferences.getInstance();
                final isVerified = prefs.getBool('driver_is_verified') ?? 
                                   _driverProfile?.isVerified ?? 
                                   false;
                
                if (!isVerified) {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.orange.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.warning_amber_rounded,
                              color: Colors.orange,
                              size: 28,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Text(
                              'Compte en attente',
                              style: TextStyle(fontSize: 18),
                            ),
                          ),
                        ],
                      ),
                      content: const Text(
                        'Votre compte est en cours de vérification.\n\n'
                        'Vous devez attendre la validation de votre compte par notre équipe avant de pouvoir souscrire à un abonnement.\n\n'
                        'Vous serez notifié dès que votre compte sera validé.',
                        style: TextStyle(fontSize: 15, height: 1.5),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          style: TextButton.styleFrom(
                            foregroundColor: primaryGreen,
                          ),
                          child: const Text('Compris', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  );
                  return;
                }

                try {
                  if (_driverProfile == null) {
                    // Construire le profil à partir des données du login si disponibles
                    final driverJson = ApiService.lastDriverData;

                    if (driverJson != null) {
                      final dynamic rawVehicle = driverJson['vehicle'];
                      final Map<String, dynamic> vehicle =
                          rawVehicle is Map<String, dynamic> ? rawVehicle : <String, dynamic>{};

                      final String firstName = driverJson['firstName']?.toString() ?? '';
                      final String lastName = driverJson['lastName']?.toString() ?? '';
                      final String phone = driverJson['phone']?.toString() ?? '';
                      final String email = driverJson['email']?.toString() ?? '';

                      final String vehicleTypeStr = vehicle['type']?.toString() ?? 'car';
                      final vehicleType = VehicleType.fromString(vehicleTypeStr);
                      final bool isMoto =
                          (vehicle['category']?.toString() == 'moto' || vehicleTypeStr == 'moto_delivery');

                      final String driverType = driverJson['driverType']?.toString() ??
                          (isMoto ? 'courier' : 'driver');

                      final fallbackProfile = DriverProfile(
                        id: driverJson['id']?.toString() ?? driverJson['_id']?.toString() ?? '',
                        firstName: firstName,
                        lastName: lastName,
                        phone: phone,
                        email: email,
                        vehicleType: vehicleType,
                        vehicle: VehicleInfo(
                          make: vehicle['make']?.toString() ?? '',
                          model: vehicle['model']?.toString() ?? '',
                          year: int.tryParse(vehicle['year']?.toString() ?? '') ?? 2020,
                          color: vehicle['color']?.toString() ?? '',
                          plateNumber: vehicle['plateNumber']?.toString() ?? '',
                          type: vehicleTypeStr,
                          capacity: int.tryParse(vehicle['capacity']?.toString() ?? '') ?? 4,
                          features: vehicle['features'] is List
                              ? (vehicle['features'] as List).map((e) => e.toString()).toList()
                              : const <String>[],
                        ),
                        subscription: null,
                        stats: DriverStats(
                          totalRides: 0,
                          completedRides: 0,
                          cancelledRides: 0,
                          averageRating: 0.0,
                          totalEarnings: 0.0,
                          totalDistance: 0.0,
                          todayRides: 0,
                          todayEarnings: 0.0,
                          weeklyRides: 0,
                          weeklyEarnings: 0.0,
                          bonusEarned: 0.0,
                          acceptanceRate: 0.0,
                        ),
                        earnings: EarningsInfo.empty(),
                        isOnline: _isOnline,
                        isAvailable: true,
                        currentLocation: null,
                        rideTypes: null,
                        preferences: null,
                        driverType: driverType,
                      );

                      setState(() {
                        _driverProfile = fallbackProfile;
                      });
                    }
                  }

                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => SubscriptionScreen(
                        driverProfile: _driverProfile!,
                      ),
                    ),
                  );

                  // Après retour, recharger les infos d'abonnement réelles (ignore les erreurs)
                  _loadTodayStats();
                  _loadCurrentSubscription();
                } catch (e) {
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Erreur lors de l\'ouverture des abonnements. Veuillez réessayer.'),
                      backgroundColor: Colors.red,
                    ),
                  );
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
                    // Vérifier si le compte est vérifié avant de permettre la mise en ligne
                    final prefs = await SharedPreferences.getInstance();
                    final isVerified = prefs.getBool('driver_is_verified') ?? 
                                       _driverProfile?.isVerified ?? 
                                       false;
                    
                    if (value && !isVerified) {
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.orange.withOpacity(0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.warning_amber_rounded,
                                  color: Colors.orange,
                                  size: 28,
                                ),
                              ),
                              const SizedBox(width: 12),
                              const Expanded(
                                child: Text(
                                  'Compte en attente',
                                  style: TextStyle(fontSize: 18),
                                ),
                              ),
                            ],
                          ),
                          content: const Text(
                            'Votre compte est en cours de vérification.\n\n'
                            'Notre équipe examine vos documents et validera votre compte prochainement.\n\n'
                            'Vous pourrez recevoir des courses une fois votre compte validé.',
                            style: TextStyle(fontSize: 15, height: 1.5),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              style: TextButton.styleFrom(
                                foregroundColor: primaryGreen,
                              ),
                              child: const Text('Compris', style: TextStyle(fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ),
                      );
                      return;
                    }

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

          // Bouton Femmes uniquement
          // Masqué pour les livreurs (courier/moto)
          if (!(_driverProfile?.isCourier ?? false))
            Row(
              children: [
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
