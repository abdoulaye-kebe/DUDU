import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/auth_provider.dart';
import '../themes/app_theme.dart';
import '../services/search_history_service.dart';
import '../services/places_service.dart';
import 'unified_ride_screen.dart';
import 'delivery_request_screen.dart';
import 'scheduled_rides_screen.dart';
import 'rides_screen.dart';
import 'profile_screen.dart';
import 'login_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  GoogleMapController? _mapController;
  Position? _currentPosition;
  final Set<Marker> _vehicleMarkers = {};
  List<SearchHistoryItem> _searchHistory = [];

  // Couleurs DUDU
  static const Color primaryGreen = Color(0xFF0d5d36);
  static const Color darkGreen = Color(0xFF094d2a);
  static const Color lightGreen = Color(0xFF10b981);
  static const Color accentBlack = Color(0xFF1A1A1A);

  List<Map<String, String>> _getPopularPlaces() {
    return [
      {
        'name': 'Aéroport Blaise Diagne',
        'address': 'AIBD, Diass',
        'lat': '14.6700',
        'lng': '-17.0728',
      },
      {
        'name': 'Place de l\'Indépendance',
        'address': 'Plateau, Dakar',
        'lat': '14.6697',
        'lng': '-17.4389',
      },
      {
        'name': 'UCAD',
        'address': 'Université Cheikh Anta Diop, Dakar',
        'lat': '14.6937',
        'lng': '-17.4441',
      },
      {
        'name': 'Marché Sandaga',
        'address': 'Sandaga, Dakar',
        'lat': '14.6667',
        'lng': '-17.4333',
      },
    ];
  }

  Future<void> _openDestinationSearch() async {
    final controller = TextEditingController();
    Timer? debounce;
    var isSearching = false;
    var suggestions = <PlaceSuggestion>[];

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, modalSetState) {
            Future<void> search(String query) async {
              modalSetState(() {
                isSearching = true;
              });

              final userLat = _currentPosition?.latitude;
              final userLng = _currentPosition?.longitude;

              final results = await PlacesService.getPlaceSuggestions(
                query,
                userLat: userLat,
                userLng: userLng,
              );

              modalSetState(() {
                suggestions = results;
                isSearching = false;
              });
            }

            return Container(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: SafeArea(
                top: false,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      margin: const EdgeInsets.only(top: 10),
                      width: 44,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
                      child: TextField(
                        controller: controller,
                        autofocus: true,
                        decoration: InputDecoration(
                          hintText: 'Où allez-vous ?',
                          prefixIcon: const Icon(Icons.search),
                          suffixIcon: isSearching
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: Padding(
                                    padding: EdgeInsets.all(12),
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  ),
                                )
                              : (controller.text.isNotEmpty
                                  ? IconButton(
                                      onPressed: () {
                                        controller.clear();
                                        modalSetState(() {
                                          suggestions = [];
                                          isSearching = false;
                                        });
                                      },
                                      icon: const Icon(Icons.clear),
                                    )
                                  : null),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        onChanged: (value) {
                          final q = value.trim();
                          debounce?.cancel();

                          if (q.length < 2) {
                            modalSetState(() {
                              suggestions = [];
                              isSearching = false;
                            });
                            return;
                          }

                          debounce = Timer(const Duration(milliseconds: 200), () {
                            if (!mounted) return;
                            final current = controller.text.trim();
                            if (current.length < 2) return;
                            search(current);
                          });
                        },
                      ),
                    ),
                    Flexible(
                      child: ListView(
                        shrinkWrap: true,
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                        children: [
                          if (controller.text.trim().length < 2 && suggestions.isEmpty) ...[
                            if (_searchHistory.isNotEmpty) ...[
                              const SizedBox(height: 6),
                              const Text(
                                'Recherches récentes',
                                style: TextStyle(fontWeight: FontWeight.w700),
                              ),
                              const SizedBox(height: 8),
                              ..._searchHistory.take(3).map(
                                    (item) => ListTile(
                                      leading: const Icon(Icons.history),
                                      title: Text(item.title),
                                      subtitle: Text(item.subtitle),
                                      onTap: () async {
                                        Navigator.pop(context);
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(builder: (context) => const UnifiedRideScreen()),
                                        );
                                      },
                                    ),
                                  ),
                              const SizedBox(height: 10),
                            ],
                            const Text(
                              'Lieux populaires',
                              style: TextStyle(fontWeight: FontWeight.w700),
                            ),
                            const SizedBox(height: 8),
                            ..._getPopularPlaces().take(3).map(
                                  (place) => ListTile(
                                    leading: const Icon(Icons.star, color: Colors.amber),
                                    title: Text(place['name'] ?? ''),
                                    subtitle: Text(place['address'] ?? ''),
                                    onTap: () async {
                                      await SearchHistoryService.addToHistory(
                                        SearchHistoryItem(
                                          title: place['name'] ?? '',
                                          subtitle: place['address'] ?? '',
                                          latitude: double.tryParse(place['lat'] ?? ''),
                                          longitude: double.tryParse(place['lng'] ?? ''),
                                        ),
                                      );
                                      if (!mounted) return;
                                      await _loadSearchHistory();
                                      if (!mounted) return;
                                      Navigator.pop(context);
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(builder: (context) => const UnifiedRideScreen()),
                                      );
                                    },
                                  ),
                                ),
                          ] else ...[
                            ...suggestions.take(10).map(
                                  (s) => ListTile(
                                    leading: Icon(
                                      s.isLocal ? Icons.star : Icons.location_on,
                                      color: s.isLocal ? Colors.amber : null,
                                    ),
                                    title: Text(s.mainText),
                                    subtitle: Text(s.secondaryText),
                                    onTap: () async {
                                      await SearchHistoryService.addToHistory(
                                        SearchHistoryItem(
                                          title: s.mainText,
                                          subtitle: s.description,
                                          latitude: s.localLat,
                                          longitude: s.localLng,
                                        ),
                                      );
                                      if (!mounted) return;
                                      await _loadSearchHistory();
                                      if (!mounted) return;
                                      Navigator.pop(context);
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(builder: (context) => const UnifiedRideScreen()),
                                      );
                                    },
                                  ),
                                ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    debounce?.cancel();
    controller.dispose();
  }

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _getCurrentLocation();
    _loadSearchHistory();
  }

  Future<void> _loadSearchHistory() async {
    final history = await SearchHistoryService.getHistory();
    if (mounted) {
      setState(() {
        _searchHistory = history;
      });
    }
  }

  void _generateNearbyVehicles() {
    if (_currentPosition == null) return;

    final baseLat = _currentPosition!.latitude;
    final baseLng = _currentPosition!.longitude;

    final List<LatLng> positions = [
      LatLng(baseLat + 0.002, baseLng + 0.0025),
      LatLng(baseLat - 0.0015, baseLng + 0.002),
      LatLng(baseLat + 0.001, baseLng - 0.002),
      LatLng(baseLat - 0.0025, baseLng - 0.0015),
      LatLng(baseLat + 0.0005, baseLng + 0.0015),
    ];

    final markers = <Marker>{};
    for (var i = 0; i < positions.length; i++) {
      markers.add(
        Marker(
          markerId: MarkerId('vehicle_$i'),
          position: positions[i],
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
          infoWindow: const InfoWindow(title: 'Chauffeur à proximité'),
        ),
      );
    }

    setState(() {
      _vehicleMarkers
        ..clear()
        ..addAll(markers);
    });
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));

    _animationController.forward();
  }

  Future<void> _getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _useDakarAsDefault();
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _useDakarAsDefault();
          return;
        }
      }

      Position position = await Geolocator.getCurrentPosition();

      bool isInSenegal = position.latitude >= 12.0 &&
          position.latitude <= 17.0 &&
          position.longitude >= -18.0 &&
          position.longitude <= -11.0;

      if (!isInSenegal) {
        _useDakarAsDefault();
        return;
      }

      if (!mounted) return;
      
      setState(() {
        _currentPosition = position;
      });

      _generateNearbyVehicles();

      _mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(
          LatLng(position.latitude, position.longitude),
          14.0,
        ),
      );
    } catch (e) {
      if (mounted) _useDakarAsDefault();
    }
  }

  void _useDakarAsDefault() {
    if (!mounted) return;
    
    final dakarPosition = Position(
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

    setState(() {
      _currentPosition = dakarPosition;
    });

    _generateNearbyVehicles();

    _mapController?.animateCamera(
      CameraUpdate.newLatLngZoom(
        const LatLng(14.6928, -17.4467),
        13.0,
      ),
    );
  }

  Widget _buildMapBackground() {
    final target = _currentPosition != null
        ? LatLng(_currentPosition!.latitude, _currentPosition!.longitude)
        : const LatLng(14.6928, -17.4467);

    return GoogleMap(
      initialCameraPosition: CameraPosition(
        target: target,
        zoom: 14.0,
      ),
      onMapCreated: (controller) => _mapController = controller,
      myLocationEnabled: true,
      myLocationButtonEnabled: true,
      zoomControlsEnabled: false,
      mapType: MapType.normal,
      markers: _vehicleMarkers,
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _showUserMenu() {
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
                  MaterialPageRoute(builder: (context) => const ProfileScreen()),
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
                  MaterialPageRoute(builder: (context) => const RidesScreen()),
                );
              },
            ),
            _buildMenuOption(
              icon: Icons.settings_outlined,
              title: 'Paramètres',
              color: Colors.grey[700]!,
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Paramètres - Bientôt disponible')),
                );
              },
            ),
            _buildMenuOption(
              icon: Icons.help_outline,
              title: 'Aide & Support',
              color: Colors.blue,
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Support - Bientôt disponible')),
                );
              },
            ),
            _buildMenuOption(
              icon: Icons.local_taxi,
              title: 'Devenir chauffeur (DUDU Pro)',
              color: primaryGreen,
              highlight: true,
              onTap: () async {
                Navigator.pop(context);
                const url = 'https://dudugroup.sn/downloads/dudu-driver.apk';
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Téléchargement de DUDU Pro...'),
                    backgroundColor: primaryGreen,
                    duration: const Duration(seconds: 3),
                    action: SnackBarAction(
                      label: 'Ouvrir',
                      textColor: Colors.white,
                      onPressed: () async {
                        try {
                          final uri = Uri.parse(url);
                          if (await canLaunchUrl(uri)) {
                            await launchUrl(uri, mode: LaunchMode.externalApplication);
                          }
                        } catch (e) {
                          print('Erreur ouverture lien: $e');
                        }
                      },
                    ),
                  ),
                );
                try {
                  final uri = Uri.parse(url);
                  if (await canLaunchUrl(uri)) {
                    await launchUrl(uri, mode: LaunchMode.externalApplication);
                  }
                } catch (e) {
                  print('Erreur ouverture lien: $e');
                }
              },
            ),
            const Divider(),
            _buildMenuOption(
              icon: Icons.logout,
              title: 'Se déconnecter',
              color: Colors.red,
              onTap: () async {
                Navigator.pop(context);
                final authProvider = Provider.of<AuthProvider>(context, listen: false);
                await authProvider.logout();
                if (mounted) {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (context) => const LoginScreen()),
                    (route) => false,
                  );
                }
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuOption({
    required IconData icon,
    required String title,
    required Color color,
    required VoidCallback onTap,
    bool highlight = false,
  }) {
    final Color highlightColor = Colors.green.shade700;
    final Color effectiveColor = highlight ? highlightColor : color;
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: effectiveColor.withOpacity(highlight ? 0.16 : 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: effectiveColor, size: 24),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: highlight ? FontWeight.w800 : FontWeight.w500,
          color: highlight ? highlightColor : null,
        ),
      ),
      trailing: Icon(
        Icons.arrow_forward_ios,
        size: 16,
        color: highlight ? highlightColor : null,
      ),
      onTap: onTap,
    );
  }

  Widget _buildHeader() {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.user;

    final bool isFemale = (user?.gender ?? '').toLowerCase() == 'female';
    final IconData genderIcon = isFemale ? Icons.woman : Icons.man;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Logo et adresse
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: primaryGreen,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Center(
                          child: Text(
                            'DUDU',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Icon(genderIcon, color: accentBlack, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              user?.fullName ?? 'Client',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: accentBlack,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                Icon(Icons.location_on, size: 14, color: Colors.grey[600]),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    'Dakar, Sénégal',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
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
                ],
              ),
            ),
            // Menu hamburger
            IconButton(
              onPressed: _showUserMenu,
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.menu,
                  color: accentBlack,
                  size: 24,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRideTypes() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          // Bouton Courses (regroupe les 4 types)
          Expanded(
            child: _buildMainRideTypeCard(
              iconBuilder: (color) => Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.directions_car, color: Colors.white, size: 28),
                  const SizedBox(width: 6),
                  Icon(Icons.local_taxi, color: Colors.white.withOpacity(0.85), size: 22),
                ],
              ),
              title: 'Courses',
              subtitle: '4 types disponibles',
              color: primaryGreen,
              iconBackgroundColor: primaryGreen.withOpacity(0.25),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const UnifiedRideScreen()),
                );
              },
            ),
          ),
          const SizedBox(width: 14),
          // Bouton Livraison
          Expanded(
            child: _buildMainRideTypeCard(
              iconBuilder: (color) => Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.directions_car, color: Colors.white, size: 26),
                  const SizedBox(width: 6),
                  Icon(Icons.motorcycle, color: Colors.white, size: 26),
                ],
              ),
              title: 'Livraison',
              subtitle: 'Colis & documents',
              color: const Color(0xFFFF6B00),
              iconBackgroundColor: const Color(0xFFFF6B00).withOpacity(0.25),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const DeliveryRequestScreen(
                      pickupAddress: '',
                      destinationAddress: '',
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainRideTypeCard({
    required Widget Function(Color color) iconBuilder,
    required String title,
    required String subtitle,
    required Color color,
    Color? iconBackgroundColor,
    double verticalPadding = 16,
    double iconPadding = 14,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 18, vertical: verticalPadding),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [color, color.withOpacity(0.8)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: EdgeInsets.all(iconPadding),
              decoration: BoxDecoration(
                color: iconBackgroundColor ?? Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: iconBuilder(color),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                color: Colors.white.withOpacity(0.9),
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.1),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
          border: Border.all(
            color: color.withOpacity(0.2),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color: color,
                size: 22,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: accentBlack,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentLocations() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.directions_car_filled_outlined, size: 22, color: primaryGreen),
              const SizedBox(width: 8),
              Text(
                'On vous emmène !',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: accentBlack,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildActionCard(
                  icon: Icons.directions_car,
                  title: 'Trajets',
                  subtitle: 'Allons-y',
                  color: primaryGreen,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const UnifiedRideScreen()),
                    );
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildActionCard(
                  icon: Icons.calendar_today,
                  title: 'Trajets planifiés',
                  subtitle: 'Réserver à l’avance',
                  color: Colors.grey[800]!,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ScheduledRidesScreen(),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          InkWell(
            onTap: () {
              _openDestinationSearch();
            },
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(Icons.search, color: Colors.grey[700], size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Où allez-vous ?',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[700],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey[500]),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          // Afficher l'historique des recherches ou un message si vide
          if (_searchHistory.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Column(
                  children: [
                    Icon(
                      Icons.history,
                      size: 48,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Aucune recherche récente',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            ..._searchHistory.map((item) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _buildLocationItem(
                icon: Icons.location_on,
                title: item.title,
                subtitle: item.subtitle,
                time: _calculateTime(item),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const UnifiedRideScreen(),
                    ),
                  );
                },
              ),
            )).toList(),
        ],
      ),
    );
  }

  String _calculateTime(SearchHistoryItem item) {
    final now = DateTime.now();
    final difference = now.difference(item.timestamp);
    
    if (difference.inMinutes < 60) {
      return '${difference.inMinutes} min';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h';
    } else {
      return '${difference.inDays}j';
    }
  }

  Widget _buildLocationItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required String time,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap ?? () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const UnifiedRideScreen()),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color: Colors.grey[600],
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: accentBlack,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[600],
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Text(
              time,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[500],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required String time,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              color: color,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: accentBlack,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Text(
            time,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
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
          _getCurrentLocation();
        },
        backgroundColor: primaryGreen,
        child: const Icon(Icons.home, color: Colors.white),
        tooltip: 'Accueil',
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.startFloat,
      body: Stack(
        children: [
          _buildMapBackground(),
          FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: Column(
                children: [
                  _buildHeader(),
                  Expanded(
                    child: Align(
                      alignment: Alignment.bottomCenter,
                      child: SingleChildScrollView(
                        child: Container(
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(24),
                              topRight: Radius.circular(24),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black26,
                                blurRadius: 12,
                                offset: Offset(0, -4),
                              ),
                            ],
                          ),
                          padding: const EdgeInsets.only(
                            top: 20,
                            left: 0,
                            right: 0,
                            bottom: 24,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Slogan
                              Center(
                                child: ShaderMask(
                                  shaderCallback: (bounds) => LinearGradient(
                                    colors: [primaryGreen, darkGreen],
                                  ).createShader(bounds),
                                  child: const Text(
                                    'Yobalé sii sama prix',
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w700,
                                      fontStyle: FontStyle.italic,
                                      color: Colors.white,
                                      letterSpacing: 1.5,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 6),
                              const Center(
                                child: Text(
                                  'la mobilité à mon prix',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.black54,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 24),
                              _buildRecentLocations(),
                              const SizedBox(height: 24),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
