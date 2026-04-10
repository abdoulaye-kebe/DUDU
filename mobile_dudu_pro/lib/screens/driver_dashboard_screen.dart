import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import '../models/driver_profile.dart';
import '../services/api_service.dart';
import 'subscription_screen.dart';
import 'statistics_screen.dart';
import 'settings_screen.dart';
import 'login_screen.dart';

class DriverDashboardScreen extends StatefulWidget {
  const DriverDashboardScreen({Key? key}) : super(key: key);

  @override
  State<DriverDashboardScreen> createState() => _DriverDashboardScreenState();
}

class _DriverDashboardScreenState extends State<DriverDashboardScreen> {
  GoogleMapController? _mapController;
  DriverProfile? _driverProfile;
  bool _isLoading = true;
  String? _error;
  
  // État du chauffeur
  bool _isOnline = false;
  bool _acceptDeliveries = false;
  bool _acceptLuggage = false;
  Position? _currentPosition;

  // Position par défaut : Dakar, Sénégal
  final LatLng _defaultLocation = const LatLng(14.6928, -17.4467); // Dakar - Place de l'Indépendance
  final LatLng _senegalCenter = const LatLng(14.4974, -14.4524); // Centre du Sénégal

  @override
  void initState() {
    super.initState();
    _loadDriverProfile();
    _getCurrentLocation();
  }

  Future<void> _loadDriverProfile() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      // Créer un profil de test basique sans délai
      final profile = DriverProfile(
        id: 'test_driver',
        firstName: 'Test',
        lastName: 'User',
        phone: '221771234567',
        email: 'test@dudu.sn',
        vehicleType: VehicleType.car,
        vehicle: VehicleInfo(
          make: 'Toyota',
          model: 'Corolla',
          year: 2020,
          color: 'Blanc',
          plateNumber: 'DK-1234-AB',
          type: 'standard',
          capacity: 4,
        ),
        stats: DriverStats(
          totalRides: 100,
          completedRides: 95,
          cancelledRides: 5,
          averageRating: 4.8,
          totalEarnings: 500000,
          totalDistance: 5000,
          todayRides: 5,
          todayEarnings: 25000,
          weeklyRides: 20,
          weeklyEarnings: 100000,
          bonusEarned: 0,
          acceptanceRate: 0.95,
        ),
        earnings: EarningsInfo(
          today: 25000,
          thisWeek: 100000,
          thisMonth: 400000,
          total: 500000,
        ),
        isOnline: false,
        isAvailable: false,
        driverType: 'driver',
      );
      
      setState(() {
        _driverProfile = profile;
        _isOnline = false;
        _isLoading = false;
      });
    } catch (e) {
      print('Erreur chargement profil: $e');
      setState(() {
        _error = 'Erreur de chargement du profil: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return;
      }

      Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 10,
        ),
      );

      setState(() {
        _currentPosition = position;
      });

      _mapController?.animateCamera(
        CameraUpdate.newLatLng(
          LatLng(position.latitude, position.longitude),
        ),
      );
    } catch (e) {
      print('Erreur de géolocalisation: $e');
    }
  }

  void _toggleOnlineStatus() {
    setState(() {
      _isOnline = !_isOnline;
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_isOnline ? 'Vous êtes maintenant en ligne' : 'Vous êtes hors ligne'),
        backgroundColor: _isOnline ? Colors.green : Colors.grey,
      ),
    );
  }

  void _toggleDeliveries() {
    if (_driverProfile == null || !_driverProfile!.isMoto) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Les livraisons sont réservées aux motos'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    
    setState(() {
      _acceptDeliveries = !_acceptDeliveries;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_acceptDeliveries ? 'Livraisons activées (Moto)' : 'Livraisons désactivées'),
      ),
    );
  }

  void _toggleLuggage() {
    if (_driverProfile == null || !_driverProfile!.canAcceptLuggage) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Le transport de bagages est réservé aux voitures cargo'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    
    setState(() {
      _acceptLuggage = !_acceptLuggage;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_acceptLuggage ? 'Transport de bagages activé' : 'Transport de bagages désactivé'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_error != null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('DUDU Pro', style: TextStyle(color: Colors.white)),
          backgroundColor: const Color(0xFF00A651),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text('Erreur de chargement', style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 8),
              Text(_error!, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadDriverProfile,
                child: const Text('Réessayer'),
              ),
            ],
          ),
        ),
      );
    }

    if (_driverProfile == null) {
      return const Scaffold(
        body: Center(
          child: Text('Profil non trouvé'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'DUDU Pro - ${_driverProfile!.vehicleType.displayName}',
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color(0xFF00A651),
        actions: [
          IconButton(
            icon: const Icon(Icons.subscriptions, color: Colors.white),
            onPressed: () => _navigateToSubscriptions(),
          ),
          IconButton(
            icon: const Icon(Icons.person, color: Colors.white),
            onPressed: () => _showProfileMenu(),
          ),
        ],
      ),
      body: Stack(
        children: [
          // Google Map - Sénégal
          GoogleMap(
            onMapCreated: (controller) {
              _mapController = controller;
              // Centrer sur le Sénégal
              _mapController?.animateCamera(
                CameraUpdate.newLatLngZoom(_senegalCenter, 7.0),
              );
            },
            initialCameraPosition: CameraPosition(
              target: _currentPosition != null
                  ? LatLng(_currentPosition!.latitude, _currentPosition!.longitude)
                  : _defaultLocation,
              zoom: _currentPosition != null ? 14.0 : 7.0,
            ),
            myLocationEnabled: true,
            myLocationButtonEnabled: true,
            zoomControlsEnabled: false,
            mapType: MapType.normal,
            markers: _buildMarkers(),
            polylines: _buildPolylines(),
          ),

          // Status Card
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Statut',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Container(
                                  width: 12,
                                  height: 12,
                                  decoration: BoxDecoration(
                                    color: _isOnline ? Colors.green : Colors.grey,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  _isOnline ? 'En ligne' : 'Hors ligne',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        ElevatedButton(
                          onPressed: _toggleOnlineStatus,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _isOnline ? Colors.grey : const Color(0xFF00A651),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(_isOnline ? 'Se déconnecter' : 'Se connecter'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Divider(),
                    const SizedBox(height: 16),
                    // Options selon le type de véhicule
                    _buildOptionsRow(),
                  ],
                ),
              ),
            ),
          ),

          // Stats Card
          Positioned(
            bottom: 16,
            left: 16,
            right: 16,
            child: Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    const Text(
                      'Statistiques du jour',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildStat('🚗', '12', 'Courses'),
                        _buildStat('💰', '48k', 'FCFA'),
                        _buildStat('⭐', '4.8', 'Note'),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOptionsRow() {
    if (_driverProfile == null) return const SizedBox.shrink();

    // Options pour MOTO
    if (_driverProfile!.isMoto) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildOptionButton(
            icon: Icons.delivery_dining,
            label: 'Livraisons',
            isActive: _acceptDeliveries,
            onTap: _toggleDeliveries,
          ),
        ],
      );
    }
    
    // Options pour VOITURE
    List<Widget> options = [];
    
    // Ajouter option bagages si voiture cargo
    if (_driverProfile!.canAcceptLuggage) {
      options.add(
        _buildOptionButton(
          icon: Icons.luggage,
          label: 'Bagages',
          isActive: _acceptLuggage,
          onTap: _toggleLuggage,
        ),
      );
    }
    
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: options,
    );
  }

  Widget _buildOptionButton({
    required IconData icon,
    required String label,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFF00A651) : Colors.grey[200],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isActive ? Colors.white : Colors.grey[600],
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: isActive ? Colors.white : Colors.grey[600],
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStat(String icon, String value, String label) {
    return Column(
      children: [
        Text(icon, style: const TextStyle(fontSize: 24)),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
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
    );
  }

  void _navigateToSubscriptions() {
    if (_driverProfile != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => SubscriptionScreen(
            driverProfile: _driverProfile!,
          ),
        ),
      );
    }
  }

  // Marqueurs pour la carte
  Set<Marker> _buildMarkers() {
    Set<Marker> markers = {};
    
    // Marqueur de position actuelle
    if (_currentPosition != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('current_position'),
          position: LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
          infoWindow: const InfoWindow(
            title: 'Ma position',
            snippet: 'Position actuelle',
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
        ),
      );
    }
    
    // Marqueurs de villes principales du Sénégal
    final cities = [
      {'name': 'Dakar', 'lat': 14.6928, 'lng': -17.4467, 'color': BitmapDescriptor.hueGreen},
      {'name': 'Thiès', 'lat': 14.7896, 'lng': -16.9260, 'color': BitmapDescriptor.hueOrange},
      {'name': 'Kaolack', 'lat': 14.1510, 'lng': -16.0755, 'color': BitmapDescriptor.hueRed},
      {'name': 'Ziguinchor', 'lat': 12.5641, 'lng': -16.2630, 'color': BitmapDescriptor.hueViolet},
      {'name': 'Saint-Louis', 'lat': 16.0179, 'lng': -16.4896, 'color': BitmapDescriptor.hueCyan},
    ];
    
    for (int i = 0; i < cities.length; i++) {
      final city = cities[i];
      markers.add(
        Marker(
          markerId: MarkerId('city_$i'),
          position: LatLng(city['lat'] as double, city['lng'] as double),
          infoWindow: InfoWindow(
            title: city['name'] as String,
            snippet: 'Ville du Sénégal',
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(city['color'] as double),
        ),
      );
    }
    
    return markers;
  }
  
  // Polylines pour la carte
  Set<Polyline> _buildPolylines() {
    Set<Polyline> polylines = {};
    
    // Route principale Dakar-Thiès
    polylines.add(
      Polyline(
        polylineId: const PolylineId('route_dakar_thies'),
        points: [
          const LatLng(14.6928, -17.4467), // Dakar
          const LatLng(14.7896, -16.9260), // Thiès
        ],
        color: const Color(0xFF00A651),
        width: 3,
      ),
    );
    
    return polylines;
  }

  void _showProfileMenu() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_driverProfile != null) ...[
              ListTile(
                leading: CircleAvatar(
                  backgroundColor: const Color(0xFF00A651),
                  child: Text(
                    _driverProfile!.fullName.substring(0, 1).toUpperCase(),
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
                title: Text(_driverProfile!.fullName),
                subtitle: Text('${_driverProfile!.vehicleType.displayName} - ${_driverProfile!.vehicle.plateNumber}'),
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.subscriptions),
                title: const Text('Abonnements'),
                onTap: () {
                  Navigator.pop(context);
                  _navigateToSubscriptions();
                },
              ),
              ListTile(
                leading: const Icon(Icons.analytics),
                title: const Text('Statistiques'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => StatisticsScreen(
                        driverProfile: _driverProfile!,
                      ),
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.settings),
                title: const Text('Paramètres'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => SettingsScreen(
                        driverProfile: _driverProfile!,
                      ),
                    ),
                  ).then((_) {
                    if (mounted) _loadDriverProfile();
                  });
                },
              ),
              ListTile(
                leading: const Icon(Icons.logout, color: Colors.red),
                title: const Text('Déconnexion', style: TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.pop(context);
                  _showLogoutDialog();
                },
              ),
            ],
          ],
        ),
      ),
    );
  }
  
  void _showLogoutDialog() {
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
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const LoginScreen()),
                (route) => false,
              );
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Déconnexion'),
          ),
        ],
      ),
    );
  }
}
