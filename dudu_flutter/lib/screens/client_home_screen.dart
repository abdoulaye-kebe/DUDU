import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../services/places_service.dart';

class ClientHomeScreen extends StatefulWidget {
  const ClientHomeScreen({Key? key}) : super(key: key);

  @override
  State<ClientHomeScreen> createState() => _ClientHomeScreenState();
}

class _ClientHomeScreenState extends State<ClientHomeScreen> {
  GoogleMapController? _mapController;
  Position? _currentPosition;
  Position? _pickupLocation;
  Position? _destinationLocation;
  final Set<Marker> _markers = {};
  
  // Prix personnalisable
  double _selectedPrice = 2000;
  double _minPrice = 500;
  double _maxPrice = 50000;
  
  // Suggestions de prix
  double? _suggestedPrice;
  double? _averagePrice;
  
  // Destinations
  String _pickupAddress = '';
  String _destinationAddress = '';
  
  // Historique
  List<Map<String, dynamic>> _recentRides = [];
  
  // États
  bool _isLoading = true;
  bool _isSearchingDrivers = false;
  
  // Controllers
  final TextEditingController _destinationController = TextEditingController();
  
  // Suggestions d'adresses
  List<PlaceSuggestion> _placeSuggestions = [];

  @override
  void initState() {
    super.initState();
    _initializeScreen();
  }

  Future<void> _initializeScreen() async {
    await _getCurrentLocation();
    await _loadRecentRides();
    await _loadPriceSuggestions();
    setState(() => _isLoading = false);
  }

  Future<void> _getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception('Services de localisation désactivés');
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Permission de localisation refusée');
        }
      }

      Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      setState(() {
        _currentPosition = position;
        _pickupLocation = position; // Définir le point de départ = position actuelle
        _markers.add(
          Marker(
            markerId: const MarkerId('current_location'),
            position: LatLng(position.latitude, position.longitude),
            infoWindow: const InfoWindow(title: 'Ma position actuelle'),
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
          ),
        );
      });

      // Obtenir l'adresse à partir de la géolocalisation
      final address = await getAddressFromCoordinates(
        position.latitude,
        position.longitude,
      );
      setState(() {
        _pickupAddress = address;
      });
    } catch (e) {
      print('Erreur localisation: $e');
      // Position par défaut : Dakar centre
      final defaultPos = Position(
        latitude: 14.6937,
        longitude: -17.4441,
        timestamp: DateTime.now(),
        accuracy: 0,
        altitude: 0,
        altitudeAccuracy: 0,
        heading: 0,
        headingAccuracy: 0,
        speed: 0,
        speedAccuracy: 0,
      );
      setState(() {
        _currentPosition = defaultPos;
        _pickupLocation = defaultPos;
        _pickupAddress = 'Place de l\'Indépendance, Dakar';
      });
    }
  }

  Future<String> getAddressFromCoordinates(double lat, double lng) async {
    try {
      // Utiliser Google Maps Geocoding API
      return await PlacesService.reverseGeocode(lat, lng);
    } catch (e) {
      print('Erreur géocodage: $e');
      return 'Dakar, Sénégal';
    }
  }
  
  Future<void> _searchPlaces(String query) async {
    if (query.isEmpty) {
      setState(() => _placeSuggestions = []);
      return;
    }
    
    try {
      final suggestions = await PlacesService.getPlaceSuggestions(query);
      setState(() => _placeSuggestions = suggestions);
    } catch (e) {
      print('Erreur recherche: $e');
    }
  }
  
  Future<void> _selectPlace(PlaceSuggestion suggestion) async {
    try {
      final details = await PlacesService.getPlaceDetails(suggestion.placeId);
      if (details != null) {
        _selectDestinationWithCoordinates(
          details.formattedAddress,
          details.latitude,
          details.longitude,
        );
      }
    } catch (e) {
      print('Erreur sélection lieu: $e');
    }
  }
  
  void _selectDestinationWithCoordinates(String address, double lat, double lng) {
    setState(() {
      _destinationAddress = address;
      _destinationLocation = Position(
        latitude: lat,
        longitude: lng,
        timestamp: DateTime.now(),
        accuracy: 0,
        altitude: 0,
        altitudeAccuracy: 0,
        heading: 0,
        headingAccuracy: 0,
        speed: 0,
        speedAccuracy: 0,
      );
    });
    _showPriceConfiguration();
  }

  Future<void> _loadRecentRides() async {
    try {
      // TODO: Appeler l'API pour obtenir l'historique
      // Données de démonstration
      setState(() {
        _recentRides = [
          {
            'pickup': 'Almadies',
            'destination': 'Plateau',
            'price': 3500,
            'date': '2024-10-10',
          },
          {
            'pickup': 'Point E',
            'destination': 'Yoff',
            'price': 2800,
            'date': '2024-10-09',
          },
          {
            'pickup': 'Parcelles Assainies',
            'destination': 'Médina',
            'price': 2200,
            'date': '2024-10-08',
          },
        ];
      });
    } catch (e) {
      print('Erreur chargement historique: $e');
    }
  }

  Future<void> _loadPriceSuggestions() async {
    // Calculer le prix moyen basé sur l'historique
    if (_recentRides.isNotEmpty) {
      double total = _recentRides
          .map((ride) => ride['price'] as int)
          .reduce((a, b) => a + b)
          .toDouble();
      setState(() {
        _averagePrice = total / _recentRides.length;
        _suggestedPrice = _averagePrice;
        _selectedPrice = _averagePrice ?? 2000;
      });
    }
  }

  void _showDestinationSearch() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildDestinationSearchSheet(),
    );
  }

  Widget _buildDestinationSearchSheet() {
    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
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
          
          // En-tête
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Où allez-vous ?',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          
          // Champ de recherche
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              controller: _destinationController,
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'Rechercher une destination...',
                prefixIcon: const Icon(Icons.search, color: Color(0xFF00A651)),
                filled: true,
                fillColor: Colors.grey[100],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (value) {
                // Autocomplétion en temps réel
                _searchPlaces(value);
              },
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Suggestions d'adresses en temps réel ou historique
          Expanded(
            child: _placeSuggestions.isNotEmpty
                ? ListView.builder(
                    itemCount: _placeSuggestions.length,
                    itemBuilder: (context, index) {
                      final suggestion = _placeSuggestions[index];
                      return ListTile(
                        leading: const Icon(Icons.location_on, color: Color(0xFF00A651)),
                        title: Text(suggestion.mainText),
                        subtitle: Text(suggestion.secondaryText),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                        onTap: () {
                          Navigator.pop(context);
                          _selectPlace(suggestion);
                        },
                      );
                    },
                  )
                : ListView.builder(
                    itemCount: _recentRides.length,
                    itemBuilder: (context, index) {
                      final ride = _recentRides[index];
                      return ListTile(
                        leading: const Icon(Icons.history, color: Color(0xFF00A651)),
                        title: Text(ride['destination']),
                        subtitle: Text('Depuis ${ride['pickup']} • ${ride['price']} FCFA'),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                        onTap: () {
                          Navigator.pop(context);
                          _selectDestination(ride['destination']);
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  void _selectDestination(String destination) {
    setState(() {
      _destinationAddress = destination;
    });
    _showPriceConfiguration();
  }

  void _showPriceConfiguration() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildPriceConfigurationSheet(),
    );
  }

  Widget _buildPriceConfigurationSheet() {
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: StatefulBuilder(
        builder: (context, setModalState) => Column(
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
            
            // En-tête
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Text(
                    'Fixez votre budget',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'De: $_pickupAddress',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  Text(
                    'Vers: $_destinationAddress',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
            
            // Prix sélectionné
            Container(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Text(
                    '${_selectedPrice.toInt()} FCFA',
                    style: const TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF00A651),
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (_suggestedPrice != null)
                    Text(
                      'Prix suggéré: ${_suggestedPrice!.toInt()} FCFA',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                ],
              ),
            ),
            
            // Slider de prix
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  Slider(
                    value: _selectedPrice,
                    min: _minPrice,
                    max: _maxPrice,
                    divisions: 100,
                    activeColor: const Color(0xFF00A651),
                    label: '${_selectedPrice.toInt()} FCFA',
                    onChanged: (value) {
                      setModalState(() {
                        _selectedPrice = value;
                      });
                      setState(() {
                        _selectedPrice = value;
                      });
                    },
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${_minPrice.toInt()} FCFA',
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      ),
                      Text(
                        '${_maxPrice.toInt()} FCFA',
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Suggestions de prix rapides
            if (_averagePrice != null) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Wrap(
                  spacing: 8,
                  children: [
                    _buildQuickPriceChip(
                      'Prix moyen',
                      _averagePrice!,
                      setModalState,
                    ),
                    _buildQuickPriceChip(
                      'Économique',
                      _averagePrice! * 0.8,
                      setModalState,
                    ),
                    _buildQuickPriceChip(
                      'Généreux',
                      _averagePrice! * 1.2,
                      setModalState,
                    ),
                  ],
                ),
              ),
            ],
            
            const Spacer(),
            
            // Bouton de confirmation
            Padding(
              padding: const EdgeInsets.all(24),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _searchForDrivers();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00A651),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Rechercher des chauffeurs',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickPriceChip(String label, double price, StateSetter setModalState) {
    final isSelected = (_selectedPrice - price).abs() < 10;
    return ActionChip(
      label: Text('$label (${price.toInt()} FCFA)'),
      backgroundColor: isSelected ? const Color(0xFF00A651) : Colors.grey[200],
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : Colors.black87,
      ),
      onPressed: () {
        setModalState(() {
          _selectedPrice = price;
        });
        setState(() {
          _selectedPrice = price;
        });
      },
    );
  }

  Future<void> _searchForDrivers() async {
    setState(() => _isSearchingDrivers = true);
    
    try {
      // TODO: Appeler l'API pour rechercher des chauffeurs dans un rayon de 2km
      await Future.delayed(const Duration(seconds: 2)); // Simulation
      
      // Afficher l'écran d'attente des chauffeurs
      _showDriverWaitingScreen();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e')),
      );
    } finally {
      setState(() => _isSearchingDrivers = false);
    }
  }

  void _showDriverWaitingScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DriverWaitingScreen(
          pickup: _pickupAddress,
          destination: _destinationAddress,
          price: _selectedPrice,
        ),
      ),
    );
  }

  void _expressCourse() {
    if (_suggestedPrice != null) {
      setState(() {
        _selectedPrice = _suggestedPrice!;
      });
      _showDestinationSearch();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      body: Stack(
        children: [
          // Carte Google Maps
          if (_currentPosition != null)
            GoogleMap(
              initialCameraPosition: CameraPosition(
                target: LatLng(
                  _currentPosition!.latitude,
                  _currentPosition!.longitude,
                ),
                zoom: 14,
              ),
              markers: _markers,
              myLocationEnabled: true,
              myLocationButtonEnabled: false,
              zoomControlsEnabled: false,
              onMapCreated: (controller) {
                _mapController = controller;
              },
            ),
          
          // Interface utilisateur par-dessus la carte
          SafeArea(
            child: Column(
              children: [
                // Barre de recherche
                _buildSearchBar(),
                
                const Spacer(),
                
                // Historique des courses
                if (_recentRides.isNotEmpty) _buildRecentRides(),
                
                // Bouton Course Express
                _buildExpressButton(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _showDestinationSearch,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Icon(Icons.search, color: Color(0xFF00A651)),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Où allez-vous ?',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 16,
                    ),
                  ),
                ),
                const Icon(Icons.arrow_forward_ios, size: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRecentRides() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.history, color: Color(0xFF00A651)),
              const SizedBox(width: 8),
              const Text(
                'Courses récentes',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...(_recentRides.take(3).map((ride) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: InkWell(
              onTap: () => _selectDestination(ride['destination']),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          ride['destination'],
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                        Text(
                          ride['pickup'],
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '${ride['price']} FCFA',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF00A651),
                    ),
                  ),
                ],
              ),
            ),
          ))),
        ],
      ),
    );
  }

  Widget _buildExpressButton() {
    return Container(
      margin: const EdgeInsets.all(16),
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _expressCourse,
        icon: const Icon(Icons.flash_on, color: Colors.white),
        label: Column(
          children: [
            const Text(
              'Course Express',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            if (_suggestedPrice != null)
              Text(
                'Prix suggéré: ${_suggestedPrice!.toInt()} FCFA',
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.white70,
                ),
              ),
          ],
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF00A651),
          padding: const EdgeInsets.symmetric(vertical: 20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _destinationController.dispose();
    super.dispose();
  }
}

// Écran d'attente des chauffeurs
class DriverWaitingScreen extends StatefulWidget {
  final String pickup;
  final String destination;
  final double price;

  const DriverWaitingScreen({
    Key? key,
    required this.pickup,
    required this.destination,
    required this.price,
  }) : super(key: key);

  @override
  State<DriverWaitingScreen> createState() => _DriverWaitingScreenState();
}

class _DriverWaitingScreenState extends State<DriverWaitingScreen> {
  int _remainingSeconds = 180; // 3 minutes
  List<Map<String, dynamic>> _acceptedDrivers = [];

  @override
  void initState() {
    super.initState();
    _startCountdown();
    _listenForDrivers();
  }

  void _startCountdown() {
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (mounted) {
        setState(() {
          _remainingSeconds--;
        });
        return _remainingSeconds > 0;
      }
      return false;
    });
  }

  void _listenForDrivers() {
    // TODO: Écouter les acceptations via Socket.IO
    // Simulation
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted) {
        setState(() {
          _acceptedDrivers.add({
            'name': 'Mamadou Diallo',
            'rating': 4.8,
            'distance': '1.2 km',
            'car': 'Toyota Corolla Blanche',
            'time': '5 min',
          });
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final minutes = _remainingSeconds ~/ 60;
    final seconds = _remainingSeconds % 60;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Recherche de chauffeurs'),
        backgroundColor: const Color(0xFF00A651),
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Compteur
          Container(
            padding: const EdgeInsets.all(24),
            color: Colors.grey[100],
            child: Column(
              children: [
                Text(
                  '$minutes:${seconds.toString().padLeft(2, '0')}',
                  style: const TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF00A651),
                  ),
                ),
                const Text('Temps restant'),
                const SizedBox(height: 16),
                LinearProgressIndicator(
                  value: _remainingSeconds / 180,
                  backgroundColor: Colors.grey[300],
                  color: const Color(0xFF00A651),
                ),
              ],
            ),
          ),
          
          // Informations de la course
          Padding(
            padding: const EdgeInsets.all(16),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.location_on, color: Color(0xFF00A651)),
                        const SizedBox(width: 8),
                        Expanded(child: Text(widget.pickup)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.flag, color: Colors.red),
                        const SizedBox(width: 8),
                        Expanded(child: Text(widget.destination)),
                      ],
                    ),
                    const Divider(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Votre offre:',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          '${widget.price.toInt()} FCFA',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF00A651),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          
          // Liste des chauffeurs qui ont accepté
          Expanded(
            child: _acceptedDrivers.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const CircularProgressIndicator(
                          color: Color(0xFF00A651),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Recherche de chauffeurs dans un rayon de 2km...',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: _acceptedDrivers.length,
                    itemBuilder: (context, index) {
                      final driver = _acceptedDrivers[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: const Color(0xFF00A651),
                            child: Text(
                              driver['name'][0],
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                          title: Text(
                            driver['name'],
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(driver['car']),
                              Row(
                                children: [
                                  const Icon(Icons.star, size: 16, color: Colors.amber),
                                  Text(' ${driver['rating']}'),
                                  Text(' • ${driver['distance']} • ${driver['time']}'),
                                ],
                              ),
                            ],
                          ),
                          trailing: ElevatedButton(
                            onPressed: () {
                              // Choisir ce chauffeur
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Chauffeur ${driver['name']} sélectionné!'),
                                ),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF00A651),
                            ),
                            child: const Text(
                              'Choisir',
                              style: TextStyle(color: Colors.white),
                            ),
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
}

