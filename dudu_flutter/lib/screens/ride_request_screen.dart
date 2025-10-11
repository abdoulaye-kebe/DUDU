import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../themes/app_theme.dart';
// import 'simple_map_screen.dart'; // Plus utilisé

class RideRequestScreen extends StatefulWidget {
  const RideRequestScreen({super.key});

  @override
  State<RideRequestScreen> createState() => _RideRequestScreenState();
}

class _RideRequestScreenState extends State<RideRequestScreen> {
  LatLng? _pickupLocation;
  LatLng? _destinationLocation;
  String _pickupAddress = '';
  String _destinationAddress = '';
  bool _isRequesting = false;

  static const LatLng _dakarCenter = LatLng(14.6928, -17.4467);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Demander une course'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Zone de sélection des points
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Point de départ
                _buildLocationSelector(
                  title: 'Départ',
                  address: _pickupAddress.isEmpty ? 'Sélectionner le point de départ' : _pickupAddress,
                  icon: Icons.radio_button_checked,
                  iconColor: Colors.green,
                  onTap: () => _selectPickupLocation(),
                ),
                
                const SizedBox(height: 16),
                
                // Ligne de connexion
                Container(
                  height: 20,
                  width: 2,
                  color: Colors.grey[300],
                  margin: const EdgeInsets.only(left: 8),
                ),
                
                const SizedBox(height: 16),
                
                // Destination
                _buildLocationSelector(
                  title: 'Destination',
                  address: _destinationAddress.isEmpty ? 'Sélectionner la destination' : _destinationAddress,
                  icon: Icons.place,
                  iconColor: Colors.red,
                  onTap: () => _selectDestinationLocation(),
                ),
              ],
            ),
          ),
          
          // Carte
          Expanded(
            child: Container(
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: GoogleMap(
                  initialCameraPosition: const CameraPosition(
                    target: _dakarCenter,
                    zoom: 12.0,
                  ),
                  markers: _buildMarkers(),
                  myLocationEnabled: true,
                  myLocationButtonEnabled: true,
                  zoomControlsEnabled: true,
                  mapType: MapType.normal,
                ),
              ),
            ),
          ),
          
          // Bouton de demande de course
          Container(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _canRequestRide() ? _requestRide : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isRequesting
                    ? const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          ),
                          SizedBox(width: 12),
                          Text('Recherche de chauffeur...'),
                        ],
                      )
                    : const Text(
                        'Demander une course',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationSelector({
    required String title,
    required String address,
    required IconData icon,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                icon,
                color: iconColor,
                size: 20,
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
                      fontSize: 12,
                      color: Colors.grey,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    address,
                    style: TextStyle(
                      fontSize: 16,
                      color: address.contains('Sélectionner') ? Colors.grey : Colors.black,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: Colors.grey,
            ),
          ],
        ),
      ),
    );
  }

  Set<Marker> _buildMarkers() {
    Set<Marker> markers = {};

    if (_pickupLocation != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('pickup'),
          position: _pickupLocation!,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
          infoWindow: const InfoWindow(title: 'Point de départ'),
        ),
      );
    }

    if (_destinationLocation != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('destination'),
          position: _destinationLocation!,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
          infoWindow: const InfoWindow(title: 'Destination'),
        ),
      );
    }

    return markers;
  }

  Future<void> _selectPickupLocation() async {
    final String? selectedAddress = await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Sélectionner le point de départ'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.location_city),
                title: const Text('Centre de Dakar'),
                subtitle: const Text('Place de l\'Indépendance'),
                onTap: () => Navigator.pop(context, 'Centre de Dakar'),
              ),
              ListTile(
                leading: const Icon(Icons.flight),
                title: const Text('Aéroport Léopold Sédar Senghor'),
                subtitle: const Text('Aéroport international'),
                onTap: () => Navigator.pop(context, 'Aéroport Léopold Sédar Senghor'),
              ),
              ListTile(
                leading: const Icon(Icons.business),
                title: const Text('SICAP'),
                subtitle: const Text('Zone commerciale'),
                onTap: () => Navigator.pop(context, 'SICAP'),
              ),
              ListTile(
                leading: const Icon(Icons.beach_access),
                title: const Text('Plage de Yoff'),
                subtitle: const Text('Zone touristique'),
                onTap: () => Navigator.pop(context, 'Plage de Yoff'),
              ),
            ],
          ),
        );
      },
    );

    if (selectedAddress != null) {
      setState(() {
        _pickupAddress = selectedAddress;
        _pickupLocation = _getLocationForAddress(selectedAddress);
      });
    }
  }

  Future<void> _selectDestinationLocation() async {
    final String? selectedAddress = await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Sélectionner la destination'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.location_city),
                title: const Text('Centre de Dakar'),
                subtitle: const Text('Place de l\'Indépendance'),
                onTap: () => Navigator.pop(context, 'Centre de Dakar'),
              ),
              ListTile(
                leading: const Icon(Icons.flight),
                title: const Text('Aéroport Léopold Sédar Senghor'),
                subtitle: const Text('Aéroport international'),
                onTap: () => Navigator.pop(context, 'Aéroport Léopold Sédar Senghor'),
              ),
              ListTile(
                leading: const Icon(Icons.business),
                title: const Text('SICAP'),
                subtitle: const Text('Zone commerciale'),
                onTap: () => Navigator.pop(context, 'SICAP'),
              ),
              ListTile(
                leading: const Icon(Icons.beach_access),
                title: const Text('Plage de Yoff'),
                subtitle: const Text('Zone touristique'),
                onTap: () => Navigator.pop(context, 'Plage de Yoff'),
              ),
            ],
          ),
        );
      },
    );

    if (selectedAddress != null) {
      setState(() {
        _destinationAddress = selectedAddress;
        _destinationLocation = _getLocationForAddress(selectedAddress);
      });
    }
  }

  LatLng _getLocationForAddress(String address) {
    // Coordonnées approximatives pour chaque adresse
    switch (address) {
      case 'Centre de Dakar':
        return const LatLng(14.6928, -17.4467);
      case 'Aéroport Léopold Sédar Senghor':
        return const LatLng(14.6708, -17.4731);
      case 'SICAP':
        return const LatLng(14.7167, -17.4677);
      case 'Plage de Yoff':
        return const LatLng(14.7500, -17.4833);
      default:
        return const LatLng(14.6928, -17.4467); // Centre de Dakar par défaut
    }
  }

  bool _canRequestRide() {
    return _pickupLocation != null && 
           _destinationLocation != null && 
           !_isRequesting;
  }

  Future<void> _requestRide() async {
    setState(() {
      _isRequesting = true;
    });

    try {
      // TODO: Implémenter la demande de course via l'API
      await Future.delayed(const Duration(seconds: 2)); // Simulation
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Demande de course envoyée !'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isRequesting = false;
        });
      }
    }
  }
}
