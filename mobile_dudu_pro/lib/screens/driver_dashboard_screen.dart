import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';

class DriverDashboardScreen extends StatefulWidget {
  const DriverDashboardScreen({Key? key}) : super(key: key);

  @override
  State<DriverDashboardScreen> createState() => _DriverDashboardScreenState();
}

class _DriverDashboardScreenState extends State<DriverDashboardScreen> {
  GoogleMapController? _mapController;
  bool _isOnline = false;
  bool _carpoolMode = false;
  int _availableSeats = 1; // Nombre de places disponibles pour covoiturage
  bool _acceptDeliveries = false; // Pour motos seulement
  bool _acceptLuggage = false; // Pour voitures cargo seulement
  Position? _currentPosition;
  String _vehicleCategory = 'car'; // 'car' ou 'moto'
  String _vehicleType = 'standard'; // 'standard', 'cargo', 'premium', 'moto_delivery'
  int _vehicleCapacity = 4; // Capacité totale du véhicule

  final LatLng _defaultLocation = const LatLng(14.7167, -17.4677); // Dakar

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
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

  void _toggleCarpoolMode() {
    if (!_carpoolMode) {
      // Ouvrir dialogue pour choisir le nombre de places
      _showSeatsDialog();
    } else {
      setState(() {
        _carpoolMode = false;
        _availableSeats = 1;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Mode covoiturage désactivé'),
        ),
      );
    }
  }

  void _showSeatsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Covoiturage'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Combien de places disponibles ?'),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                for (int i = 1; i <= _vehicleCapacity; i++)
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _carpoolMode = true;
                        _availableSeats = i;
                      });
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Covoiturage activé : $i place${i > 1 ? 's' : ''} disponible${i > 1 ? 's' : ''}'),
                          backgroundColor: const Color(0xFF00A651),
                        ),
                      );
                    },
                    child: Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: const Color(0xFF00A651),
                        borderRadius: BorderRadius.circular(25),
                      ),
                      child: Center(
                        child: Text(
                          '$i',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
        ],
      ),
    );
  }

  void _toggleDeliveries() {
    if (_vehicleCategory != 'moto') {
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
    if (_vehicleType != 'cargo') {
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('DUDU Pro', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF00A651),
        actions: [
          IconButton(
            icon: const Icon(Icons.person, color: Colors.white),
            onPressed: () {},
          ),
        ],
      ),
      body: Stack(
        children: [
          // Google Map
          GoogleMap(
            onMapCreated: (controller) {
              _mapController = controller;
            },
            initialCameraPosition: CameraPosition(
              target: _currentPosition != null
                  ? LatLng(_currentPosition!.latitude, _currentPosition!.longitude)
                  : _defaultLocation,
              zoom: 14.0,
            ),
            myLocationEnabled: true,
            myLocationButtonEnabled: true,
            zoomControlsEnabled: false,
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
    // Options pour MOTO
    if (_vehicleCategory == 'moto') {
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
    List<Widget> options = [
      _buildOptionButton(
        icon: Icons.group,
        label: _carpoolMode ? 'Covoiturage ($_availableSeats)' : 'Covoiturage',
        isActive: _carpoolMode,
        onTap: _toggleCarpoolMode,
      ),
    ];
    
    // Ajouter option bagages si voiture cargo
    if (_vehicleType == 'cargo') {
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
}
