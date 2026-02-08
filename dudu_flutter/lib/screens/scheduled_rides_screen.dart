import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:async';
import 'dart:math' as math;
import '../services/places_service.dart';
import '../services/api_service.dart';
import '../models/ride.dart';
import '../services/notification_service.dart';
import '../services/secure_auth_service.dart';
import '../services/socket_service.dart';
import 'package:intl/intl.dart';

class ScheduledRidesScreen extends StatefulWidget {
  const ScheduledRidesScreen({Key? key}) : super(key: key);

  @override
  State<ScheduledRidesScreen> createState() => _ScheduledRidesScreenState();
}

class _ScheduledRidesScreenState extends State<ScheduledRidesScreen>
    with SingleTickerProviderStateMixin {
  static const Color primaryGreen = Color(0xFF0d5d36);
  static const Color accentBlack = Color(0xFF1A1A1A);

  late TabController _tabController;

  final List<Ride> _scheduledRides = [];

  GoogleMapController? _mapController;
  final Set<Marker> _markers = {};

  String _mode = 'ride';
  String _from = '';
  String _to = '';
  DateTime? _dateTime;
  int _price = 0;

  final TextEditingController _fromController = TextEditingController();
  final TextEditingController _toController = TextEditingController();

  Position? _currentPosition;
  bool _isInitializingLocation = true;
  bool _isSearching = false;
  List<PlaceSuggestion> _suggestions = [];
  String _lastSearchQuery = '';
  Timer? _searchDebounce;
  int _searchToken = 0;
  LatLng? _pickupLatLng;
  LatLng? _destinationLatLng;
  double _estimatedDistanceKm = 0;
  int _estimatedDurationMin = 0;
  bool _isLoadingUpcoming = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _initLocation();
    _tabController.addListener(() {
      if (_tabController.index == 1) {
        _loadScheduledRides();
      }
    });
    _loadScheduledRides();
    _setupSocketListener();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _fromController.dispose();
    _toController.dispose();
    _searchDebounce?.cancel();
    // Nettoyer le callback Socket.IO
    SocketService().onRideAccepted = null;
    super.dispose();
  }

  void _setupSocketListener() {
    // Écouter les acceptations de courses
    SocketService().onRideAccepted = (data) {
      if (!mounted) return;
      
      final isScheduled = data['isScheduled'] == true;
      final scheduledFor = data['scheduledFor'];
      
      if (isScheduled && scheduledFor != null) {
        _showScheduledRideAcceptedDialog(data);
      }
      
      // Recharger la liste des courses planifiées
      _loadScheduledRides();
    };
  }

  void _showScheduledRideAcceptedDialog(Map<String, dynamic> data) {
    final driver = data['driver'] as Map<String, dynamic>?;
    final vehicle = driver?['vehicle'] as Map<String, dynamic>?;
    final scheduledFor = data['scheduledFor'];
    
    if (driver == null) return;
    
    DateTime? scheduledDate;
    String scheduledTimeText = '';
    
    try {
      scheduledDate = DateTime.parse(scheduledFor.toString());
      final formatter = DateFormat('EEEE d MMMM yyyy à HH:mm', 'fr_FR');
      scheduledTimeText = formatter.format(scheduledDate);
    } catch (e) {
      scheduledTimeText = 'Date à confirmer';
    }
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_circle, color: Colors.green, size: 32),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Course acceptée !',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.orange, width: 2),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.schedule, color: Colors.orange, size: 24),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Course planifiée pour :',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: Colors.orange,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            scheduledTimeText,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.orange,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Votre chauffeur :',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: primaryGreen.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 30,
                          backgroundColor: primaryGreen,
                          child: Text(
                            (driver['name']?.toString() ?? 'C')[0].toUpperCase(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                driver['name']?.toString() ?? 'Chauffeur DUDU',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  const Icon(Icons.star, color: Colors.amber, size: 16),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${driver['rating']?.toStringAsFixed(1) ?? '5.0'} (${driver['totalRides'] ?? 0} courses)',
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
                      ],
                    ),
                    if (vehicle != null) ...[
                      const SizedBox(height: 16),
                      const Divider(),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          const Icon(Icons.directions_car, color: primaryGreen, size: 24),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${vehicle['brand'] ?? ''} ${vehicle['model'] ?? ''}'.trim(),
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Text(
                                  '${vehicle['color'] ?? ''} • ${vehicle['plate'] ?? ''}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, color: Colors.blue, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Le chauffeur viendra vous chercher le jour et l\'heure prévus.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[700],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _setMode(String mode) {
    if (_mode == mode) return;
    setState(() {
      _mode = mode;
      _from = '';
      _to = '';
      _fromController.clear();
      _toController.clear();
      _dateTime = null;
      _price = 0;
      _suggestions = [];
      _isSearching = false;
      _lastSearchQuery = '';
      _pickupLatLng = null;
      _destinationLatLng = null;
      _estimatedDistanceKm = 0;
      _estimatedDurationMin = 0;
      _markers.clear();
    });
    _searchDebounce?.cancel();
    _searchToken++;
  }

  Future<void> _useCurrentLocation() async {
    if (_currentPosition == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Position non disponible')),
      );
      return;
    }

    try {
      final address = await PlacesService.reverseGeocode(
        _currentPosition!.latitude,
        _currentPosition!.longitude,
      );

      setState(() {
        _from = address;
        _fromController.text = address;
        _pickupLatLng = LatLng(
          _currentPosition!.latitude,
          _currentPosition!.longitude,
        );
      });
      _updateMarkersOnMap();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Position actuelle utilisée'),
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erreur lors de la récupération de l\'adresse')),
      );
    }
  }

  Future<void> _initLocation() async {
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

      final position = await Geolocator.getCurrentPosition();

      bool isInSenegal = position.latitude >= 12.0 &&
          position.latitude <= 17.0 &&
          position.longitude >= -18.0 &&
          position.longitude <= -11.0;

      Position finalPosition = position;
      if (!isInSenegal) {
        finalPosition = Position(
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

      final address = await PlacesService.reverseGeocode(
        finalPosition.latitude,
        finalPosition.longitude,
      );

      setState(() {
        _currentPosition = finalPosition;
        _from = address;
        _fromController.text = address;
        _pickupLatLng = LatLng(finalPosition.latitude, finalPosition.longitude);
        _isInitializingLocation = false;
      });
    } catch (e) {
      _useDakarAsDefault();
    }
  }

  void _showPlaceSearch({required bool isPickup}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, modalSetState) => DraggableScrollableSheet(
          initialChildSize: 0.9,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          builder: (_, controller) => Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              children: [
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: TextField(
                  autofocus: true,
                  decoration: InputDecoration(
                    hintText: isPickup
                        ? 'Rechercher le point de départ'
                        : 'Rechercher la destination',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _isSearching
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: Padding(
                              padding: EdgeInsets.all(12),
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onChanged: (value) {
                    final query = value.trim();
                    _lastSearchQuery = query;
                    _searchDebounce?.cancel();

                    if (query.length <= 2) {
                      setState(() {
                        _suggestions = [];
                        _isSearching = false;
                      });
                      modalSetState(() {});
                      _searchToken++;
                      return;
                    }

                    final int token = ++_searchToken;
                    setState(() => _isSearching = true);
                    modalSetState(() {});

                    _searchDebounce = Timer(const Duration(milliseconds: 220), () async {
                      if (!mounted) return;
                      if (_searchToken != token) return;

                      try {
                        final suggestions = await PlacesService.getPlaceSuggestions(
                          query,
                          userLat: _currentPosition?.latitude ?? 14.6928,
                          userLng: _currentPosition?.longitude ?? -17.4467,
                        );
                        if (!mounted) return;
                        if (_searchToken != token) return;
                        setState(() {
                          _suggestions = suggestions;
                          _isSearching = false;
                        });
                        modalSetState(() {});
                      } catch (e) {
                        if (!mounted) return;
                        if (_searchToken != token) return;
                        setState(() => _isSearching = false);
                        modalSetState(() {});
                      }
                    });
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Suggestions trouvées: ${_suggestions.length}',
                    style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                  ),
                ),
              ),
              Expanded(
                child: _suggestions.isEmpty
                    ? ListView(
                        controller: controller,
                        children: [
                          Builder(
                            builder: (context) {
                              final controllerText = (isPickup
                                      ? _fromController.text
                                      : _toController.text)
                                  .trim();
                              final fallbackText = _lastSearchQuery.isNotEmpty
                                  ? _lastSearchQuery
                                  : controllerText;

                              if (fallbackText.isEmpty) {
                                return Center(
                                  child: Padding(
                                    padding: const EdgeInsets.all(20),
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.search,
                                            size: 48, color: Colors.grey[400]),
                                        const SizedBox(height: 16),
                                        Text(
                                          'Aucun lieu trouvé pour cette recherche',
                                          style: TextStyle(color: Colors.grey[600]),
                                          textAlign: TextAlign.center,
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              }

                              return ListTile(
                                leading: const Icon(Icons.place),
                                title: Text(fallbackText),
                                subtitle: const Text('Utiliser cette adresse'),
                                onTap: () async {
                                  Navigator.pop(context);
                                  final details = await PlacesService.geocodeAddress(
                                    fallbackText,
                                  );
                                  if (details != null && mounted) {
                                    setState(() {
                                      if (isPickup) {
                                        _from = details.formattedAddress;
                                        _fromController.text = details.formattedAddress;
                                        _pickupLatLng = LatLng(
                                          details.latitude,
                                          details.longitude,
                                        );
                                      } else {
                                        _to = details.formattedAddress;
                                        _toController.text = details.formattedAddress;
                                        _destinationLatLng = LatLng(
                                          details.latitude,
                                          details.longitude,
                                        );
                                      }
                                    });
                                    _updateMarkersOnMap();
                                  }
                                },
                              );
                            },
                          ),
                        ],
                      )
                    : ListView.builder(
                        controller: controller,
                        itemCount: _suggestions.length,
                        itemBuilder: (context, index) {
                          final suggestion = _suggestions[index];
                          return ListTile(
                            leading: const Icon(Icons.location_on),
                            title: Text(suggestion.mainText),
                            subtitle: Text(suggestion.secondaryText),
                            onTap: () async {
                              Navigator.pop(context);
                              final details =
                                  await PlacesService.getPlaceDetails(suggestion.placeId);
                              if (details != null && mounted) {
                                setState(() {
                                  if (isPickup) {
                                    _from = suggestion.description;
                                    _fromController.text = suggestion.description;
                                    _pickupLatLng = LatLng(
                                      details.latitude,
                                      details.longitude,
                                    );
                                  } else {
                                    _to = suggestion.description;
                                    _toController.text = suggestion.description;
                                    _destinationLatLng = LatLng(
                                      details.latitude,
                                      details.longitude,
                                    );
                                  }
                                });
                                _updateMarkersOnMap();
                              }
                            },
                          );
                        },
                      ),
              ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _useDakarAsDefault() {
    const fallback = 'Dakar, Sénégal';
    setState(() {
      _from = fallback;
      _fromController.text = fallback;
      _pickupLatLng = const LatLng(14.6928, -17.4467);
      _isInitializingLocation = false;
    });
  }

  Future<void> _loadScheduledRides() async {
    setState(() {
      _isLoadingUpcoming = true;
    });
    final response = await ApiService.getScheduledRides();
    if (!mounted) return;
    setState(() {
      _isLoadingUpcoming = false;
      if (response.success && response.data != null) {
        _scheduledRides
          ..clear()
          ..addAll(response.data!);
      } else {
        _scheduledRides.clear();
      }
    });

    if (!mounted) return;
    if (!response.success) {
      final lowerMsg = response.message.toLowerCase();
      final isAuthExpired = lowerMsg.contains('token expir') ||
          lowerMsg.contains('jwt') ||
          lowerMsg.contains('unauthorized') ||
          lowerMsg.contains('non autoris');

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur trajets planifiés: ${response.message}'),
          backgroundColor: Colors.red,
        ),
      );

      if (isAuthExpired && mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Trajets planifiés'),
        backgroundColor: primaryGreen,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Planifier'),
            Tab(text: 'À venir'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildPlanForm(),
          _buildUpcomingList(),
        ],
      ),
    );
  }

  Widget _buildPlanForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 180,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: GoogleMap(
                initialCameraPosition: CameraPosition(
                  target: _pickupLatLng ??
                      _destinationLatLng ??
                      const LatLng(14.6928, -17.4467),
                  zoom: 18.0,
                ),
                onMapCreated: (controller) {
                  _mapController = controller;
                  _updateMarkersOnMap();
                },
                myLocationEnabled: true,
                myLocationButtonEnabled: true,
                zoomControlsEnabled: false,
                mapToolbarEnabled: false,
                compassEnabled: false,
                rotateGesturesEnabled: false,
                tiltGesturesEnabled: false,
                markers: _markers,
              ),
            ),
          ),
          if (_pickupLatLng != null && _destinationLatLng != null)
            Padding(
              padding: const EdgeInsets.only(top: 8.0, bottom: 8.0),
              child: Text(
                '≈ ${_estimatedDistanceKm.toStringAsFixed(1)} km • ${_estimatedDurationMin}–${(_estimatedDurationMin * 1.4).round()} min',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey[700],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          const SizedBox(height: 16),
          if (_isInitializingLocation)
            Row(
              children: [
                const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                const SizedBox(width: 8),
                Text(
                  'Récupération de votre position...',
                  style: TextStyle(color: Colors.grey[600], fontSize: 13),
                ),
              ],
            ),
          if (_isInitializingLocation) const SizedBox(height: 16),
          const Text(
            'Type',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: accentBlack,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildModeChip(
                  label: 'Course',
                  icon: Icons.directions_car,
                  assetPath: 'assets/images/vehicles/standard.png',
                  isSelected: _mode == 'ride',
                  onTap: () => _setMode('ride'),
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: _buildModeChip(
                  label: 'Livraison (moto)',
                  icon: Icons.delivery_dining,
                  assetPath: 'assets/images/vehicles/delivery.png',
                  isSelected: _mode == 'delivery',
                  onTap: () => _setMode('delivery'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _fromController,
                  readOnly: true,
                  decoration: const InputDecoration(
                    labelText: 'Départ',
                    border: OutlineInputBorder(),
                    suffixIcon: Icon(Icons.search),
                  ),
                  onTap: () => _showPlaceSearch(isPickup: true),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                decoration: BoxDecoration(
                  color: primaryGreen,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: IconButton(
                  icon: const Icon(Icons.my_location, color: Colors.white),
                  tooltip: 'Position actuelle',
                  onPressed: _useCurrentLocation,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _toController,
            readOnly: true,
            decoration: const InputDecoration(
              labelText: 'Destination',
              border: OutlineInputBorder(),
              suffixIcon: Icon(Icons.search),
            ),
            onTap: () => _showPlaceSearch(isPickup: false),
          ),
          const SizedBox(height: 12),
          InkWell(
            onTap: _pickDateTime,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: primaryGreen.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.calendar_today,
                      color: primaryGreen,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Date et heure',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _dateTime == null
                              ? 'Choisir la date et l\'heure'
                              : '${_dateTime!.day.toString().padLeft(2, '0')}/${_dateTime!.month.toString().padLeft(2, '0')}/${_dateTime!.year} à ${_dateTime!.hour.toString().padLeft(2, '0')}:${_dateTime!.minute.toString().padLeft(2, '0')}',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: _dateTime == null ? Colors.grey[500] : accentBlack,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: Colors.grey[400],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            keyboardType: TextInputType.number,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: primaryGreen,
            ),
            decoration: InputDecoration(
              labelText: 'Prix proposé (FCFA)',
              labelStyle: const TextStyle(
                color: primaryGreen,
                fontWeight: FontWeight.w600,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: primaryGreen, width: 2),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: primaryGreen.withOpacity(0.5), width: 1.5),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: primaryGreen, width: 2),
              ),
              filled: true,
              fillColor: primaryGreen.withOpacity(0.05),
              prefixIcon: const Icon(Icons.attach_money, color: primaryGreen),
            ),
            onChanged: (v) {
              setState(() {
                _price = int.tryParse(v) ?? 0;
              });
            },
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _canSave() ? _savePlannedRide : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryGreen,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Planifier ce trajet',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModeChip({
    required String label,
    required IconData icon,
    String? assetPath,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? primaryGreen : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? primaryGreen : Colors.grey[300]!,
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (assetPath != null)
              Image.asset(
                assetPath,
                width: 18,
                height: 18,
                errorBuilder: (_, __, ___) => Icon(
                  icon,
                  size: 18,
                  color: isSelected ? Colors.white : primaryGreen,
                ),
              )
            else
              Icon(
                icon,
                size: 18,
                color: isSelected ? Colors.white : primaryGreen,
              ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : accentBlack,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUpcomingList() {
    if (_isLoadingUpcoming) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_scheduledRides.isEmpty) {
      return Center(
        child: Text(
          'Aucun trajet planifié pour le moment',
          style: TextStyle(color: Colors.grey[600]),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _scheduledRides.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final ride = _scheduledRides[index];
        final dateTime = ride.scheduledFor ?? ride.requestedAt;
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  if (ride.rideType == 'delivery')
                    Image.asset(
                      'assets/images/vehicles/delivery.png',
                      width: 22,
                      height: 22,
                      errorBuilder: (_, __, ___) => const Icon(
                        Icons.delivery_dining,
                        color: primaryGreen,
                      ),
                    )
                  else
                    Image.asset(
                      'assets/images/vehicles/standard.png',
                      width: 22,
                      height: 22,
                      errorBuilder: (_, __, ___) => const Icon(
                        Icons.directions_car,
                        color: primaryGreen,
                      ),
                    ),
                  const SizedBox(width: 10),
                  Text(
                    ride.rideType == 'delivery'
                        ? 'Livraison (moto)'
                        : 'Course',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${dateTime.day.toString().padLeft(2, '0')}/'
                    '${dateTime.month.toString().padLeft(2, '0')} '
                    'à ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                '${ride.pickup.address} → ${ride.destination.address}',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: primaryGreen.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: primaryGreen, width: 1.5),
                ),
                child: Text(
                  '${ride.pricing.totalPrice.toInt()} FCFA',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: primaryGreen,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _pickDateTime() async {
    final now = DateTime.now();
    DateTime temp = _dateTime ?? now.add(const Duration(minutes: 10));
    if (temp.isBefore(now)) {
      temp = now.add(const Duration(minutes: 10));
    }

    DateTime roundToInterval(DateTime dt, int intervalMinutes) {
      final minute = dt.minute;
      final roundedMinute = (minute ~/ intervalMinutes) * intervalMinutes;
      return DateTime(dt.year, dt.month, dt.day, dt.hour, roundedMinute);
    }

    temp = roundToInterval(temp, 5);
    final minDate = roundToInterval(now, 5);
    if (temp.isBefore(minDate)) {
      temp = minDate;
    }

    final picked = await showModalBottomSheet<DateTime>(
      context: context,
      isScrollControlled: false,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        DateTime localTemp = temp;
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
                  child: Row(
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text('Annuler'),
                      ),
                      const Spacer(),
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, localTemp),
                        child: const Text('OK'),
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  height: 250,
                  child: CupertinoDatePicker(
                    mode: CupertinoDatePickerMode.dateAndTime,
                    initialDateTime: temp,
                    minimumDate: minDate,
                    maximumDate: now.add(const Duration(days: 30)),
                    minuteInterval: 5,
                    use24hFormat: true,
                    onDateTimeChanged: (value) {
                      localTemp = value;
                    },
                  ),
                ),
                const SizedBox(height: 10),
              ],
            ),
          ),
        );
      },
    );

    if (picked == null) return;
    if (!mounted) return;
    setState(() {
      _dateTime = picked;
    });
  }

  bool _canSave() {
    return _from.isNotEmpty &&
        _to.isNotEmpty &&
        _dateTime != null &&
        _price > 0 &&
        _pickupLatLng != null &&
        _destinationLatLng != null;
  }

  void _updateMarkersOnMap() {
    _markers.clear();

    if (_pickupLatLng != null) {
      _markers.add(
        Marker(
          markerId: const MarkerId('pickup'),
          position: _pickupLatLng!,
          infoWindow: const InfoWindow(title: 'Départ'),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
        ),
      );
    }

    if (_destinationLatLng != null) {
      _markers.add(
        Marker(
          markerId: const MarkerId('destination'),
          position: _destinationLatLng!,
          infoWindow: const InfoWindow(title: 'Destination'),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        ),
      );
    }

    if (_mapController != null) {
      if (_pickupLatLng != null && _destinationLatLng != null) {
        final southWest = LatLng(
          _pickupLatLng!.latitude < _destinationLatLng!.latitude
              ? _pickupLatLng!.latitude
              : _destinationLatLng!.latitude,
          _pickupLatLng!.longitude < _destinationLatLng!.longitude
              ? _pickupLatLng!.longitude
              : _destinationLatLng!.longitude,
        );
        final northEast = LatLng(
          _pickupLatLng!.latitude > _destinationLatLng!.latitude
              ? _pickupLatLng!.latitude
              : _destinationLatLng!.latitude,
          _pickupLatLng!.longitude > _destinationLatLng!.longitude
              ? _pickupLatLng!.longitude
              : _destinationLatLng!.longitude,
        );
        final bounds = LatLngBounds(southwest: southWest, northeast: northEast);
        _mapController!.animateCamera(
          CameraUpdate.newLatLngBounds(bounds, 50),
        );
      } else if (_pickupLatLng != null) {
        _mapController!.animateCamera(
          CameraUpdate.newLatLngZoom(_pickupLatLng!, 14),
        );
      } else if (_destinationLatLng != null) {
        _mapController!.animateCamera(
          CameraUpdate.newLatLngZoom(_destinationLatLng!, 14),
        );
      }
    }
    if (_pickupLatLng != null && _destinationLatLng != null) {
      _estimatedDistanceKm = _calculateDistance(
        _pickupLatLng!.latitude,
        _pickupLatLng!.longitude,
        _destinationLatLng!.latitude,
        _destinationLatLng!.longitude,
      );

      // Vitesse moyenne 25 km/h en ville
      final durationHours = _estimatedDistanceKm / 25.0;
      _estimatedDurationMin = (durationHours * 60).round().clamp(5, 120);
    } else {
      _estimatedDistanceKm = 0;
      _estimatedDurationMin = 0;
    }

    setState(() {});
  }

  double _calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const p = 0.017453292519943295; // pi / 180
    final a = 0.5 -
        (math.cos((lat2 - lat1) * p) / 2) +
        math.cos(lat1 * p) *
            math.cos(lat2 * p) *
            (1 - math.cos((lon2 - lon1) * p)) /
            2;
    return 12742 * math.asin(math.sqrt(a)); // 2 * R; R = 6371 km
  }

  Future<bool> _verifyPinDialog() async {
    final controller = TextEditingController();
    String? error;

    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return AlertDialog(
              title: const Text('Confirmer avec PIN'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: controller,
                    keyboardType: TextInputType.number,
                    obscureText: true,
                    maxLength: 4,
                    decoration: InputDecoration(
                      labelText: 'Code PIN',
                      counterText: '',
                      errorText: error,
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(false),
                  child: const Text('Annuler'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final pin = controller.text.trim();
                    if (pin.length != 4) {
                      setDialogState(() => error = 'PIN invalide');
                      return;
                    }
                    final ok = await SecureAuthService().verifyPin(pin);
                    if (!ctx.mounted) return;
                    if (!ok) {
                      setDialogState(() => error = 'PIN incorrect');
                      return;
                    }
                    Navigator.of(ctx).pop(true);
                  },
                  child: const Text('Confirmer'),
                ),
              ],
            );
          },
        );
      },
    );

    controller.dispose();
    return result == true;
  }

  Future<void> _savePlannedRide() async {
    if (!_canSave()) return;

    final rideType = _mode == 'delivery' ? 'delivery' : 'standard';

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Planification en cours...')),
    );

    final response = await ApiService.scheduleRide(
      pickupAddress: _from,
      pickupLatitude: _pickupLatLng!.latitude,
      pickupLongitude: _pickupLatLng!.longitude,
      destinationAddress: _to,
      destinationLatitude: _destinationLatLng!.latitude,
      destinationLongitude: _destinationLatLng!.longitude,
      rideType: rideType,
      customPrice: _price,
      scheduledFor: _dateTime!,
    );

    if (!mounted) return;

    if (response.success && response.data != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Trajet planifié avec succès')),
      );

      // Notification locale simple de rappel 1h avant si possible
      final now = DateTime.now();
      final diff = _dateTime!.difference(now);
      if (diff.inMinutes > 65 && diff.inHours <= 3) {
        NotificationService().showScheduledRideReminder1h(
          scheduledAt: _dateTime!,
        );
      }

      await _loadScheduledRides();
      _tabController.animateTo(1);
    } else {
      final lowerMsg = response.message.toLowerCase();
      final isAuthExpired = lowerMsg.contains('token expir') ||
          lowerMsg.contains('jwt') ||
          lowerMsg.contains('unauthorized') ||
          lowerMsg.contains('non autoris');

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: ${response.message}')),
      );

      if (isAuthExpired && mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
      }
    }
  }

  void _showDestinationSearch() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (_, controller) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: TextField(
                  autofocus: true,
                  decoration: InputDecoration(
                    hintText: 'Rechercher la destination',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _isSearching
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: Padding(
                              padding: EdgeInsets.all(12),
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onChanged: (value) async {
                    if (value.length > 2) {
                      setState(() => _isSearching = true);
                      try {
                        final suggestions = await PlacesService.getPlaceSuggestions(
                          value,
                          userLat: _currentPosition?.latitude ?? 14.6928,
                          userLng: _currentPosition?.longitude ?? -17.4467,
                        );
                        if (mounted) {
                          setState(() {
                            _suggestions = suggestions;
                            _isSearching = false;
                          });
                        }
                      } catch (e) {
                        if (mounted) {
                          setState(() => _isSearching = false);
                        }
                      }
                    } else {
                      setState(() {
                        _suggestions = [];
                        _isSearching = false;
                      });
                    }
                  },
                ),
              ),
              Expanded(
                child: _suggestions.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.search, size: 48, color: Colors.grey[400]),
                              const SizedBox(height: 16),
                              Text(
                                'Tapez au moins 3 caractères',
                                style: TextStyle(color: Colors.grey[600]),
                              ),
                            ],
                          ),
                        ),
                      )
                    : ListView.builder(
                        controller: controller,
                        itemCount: _suggestions.length,
                        itemBuilder: (context, index) {
                          final suggestion = _suggestions[index];
                          return ListTile(
                            leading: const Icon(Icons.location_on),
                            title: Text(suggestion.mainText),
                            subtitle: Text(suggestion.secondaryText),
                            onTap: () async {
                              Navigator.pop(context);
                              final details = await PlacesService.getPlaceDetails(suggestion.placeId);
                              if (details != null && mounted) {
                                setState(() {
                                  _to = suggestion.description;
                                  _toController.text = suggestion.description;
                                  _destinationLatLng = LatLng(
                                    details.latitude,
                                    details.longitude,
                                  );
                                });
                              }
                            },
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
