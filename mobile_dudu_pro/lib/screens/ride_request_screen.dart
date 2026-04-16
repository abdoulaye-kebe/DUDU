import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import '../constants/senegal_map.dart';
import '../models/ride.dart';
import '../services/api_service.dart';
import '../services/map_style_service.dart';

class RideRequestScreen extends StatefulWidget {
  const RideRequestScreen({Key? key}) : super(key: key);

  @override
  State<RideRequestScreen> createState() => _RideRequestScreenState();
}

class _RideRequestScreenState extends State<RideRequestScreen> {
  GoogleMapController? _mapController;
  LatLng? _pickupLocation;
  LatLng? _destinationLocation;
  String _pickupAddress = '';
  String _destinationAddress = '';
  
  RideType _selectedRideType = RideType.standard;
  VehicleCategory _selectedVehicleCategory = VehicleCategory.car;
  int _passengers = 1;
  bool _acceptLuggage = false;
  List<String> _specialRequests = [];
  
  bool _isCalculatingPrice = false;
  double _estimatedPrice = 0.0;
  double _estimatedDistance = 0.0;
  int _estimatedDuration = 0;
  
  bool _isRequesting = false;

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
        if (permission == LocationPermission.denied) {
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        return;
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        _pickupLocation = LatLng(position.latitude, position.longitude);
      });

      // Obtenir l'adresse
      await _getAddressFromCoordinates(_pickupLocation!);
    } catch (e) {
      print('Erreur localisation: $e');
    }
  }

  Future<void> _getAddressFromCoordinates(LatLng coordinates) async {
    try {
      // Ici, vous utiliseriez un service de géocodage inverse
      // Pour l'instant, on utilise une adresse simulée
      setState(() {
        if (coordinates == _pickupLocation) {
          _pickupAddress = 'Position actuelle';
        } else {
          _destinationAddress = 'Adresse sélectionnée';
        }
      });
    } catch (e) {
      print('Erreur géocodage: $e');
    }
  }

  void _onMapTap(LatLng location) {
    setState(() {
      if (_pickupLocation == null) {
        _pickupLocation = location;
        _getAddressFromCoordinates(location);
      } else if (_destinationLocation == null) {
        _destinationLocation = location;
        _getAddressFromCoordinates(location);
        _calculatePrice();
      } else {
        // Réinitialiser la sélection
        _pickupLocation = location;
        _destinationLocation = null;
        _destinationAddress = '';
        _estimatedPrice = 0.0;
      }
    });
  }

  Future<void> _calculatePrice() async {
    if (_pickupLocation == null || _destinationLocation == null) return;

    setState(() {
      _isCalculatingPrice = true;
    });

    try {
      // Simuler le calcul de prix
      await Future.delayed(const Duration(seconds: 1));
      
      // Calculer la distance approximative
      double distance = Geolocator.distanceBetween(
        _pickupLocation!.latitude,
        _pickupLocation!.longitude,
        _destinationLocation!.latitude,
        _destinationLocation!.longitude,
      ) / 1000; // en km

      // Calculer le prix basé sur la distance et le type de course
      double basePrice = 1000;
      double distancePrice = distance * 500; // 500 FCFA par km
      double timePrice = 300; // Prix fixe pour le temps
      
      // Multiplicateur selon le type de course
      double multiplier = 1.0;
      switch (_selectedRideType) {
        case RideType.standard:
          multiplier = 1.0;
          break;
        case RideType.comfort:
          multiplier = 1.3;
          break;
        case RideType.womenOnly:
          multiplier = 1.2;
          break;
        case RideType.delivery:
          multiplier = 1.3;
          break;
        case RideType.luxe:
          multiplier = 2.0;
          break;
        case RideType.moto:
          multiplier = 0.8;
          break;
      }

      setState(() {
        _estimatedDistance = distance;
        _estimatedDuration = (distance * 2).round(); // Estimation: 2 min par km
        _estimatedPrice = (basePrice + distancePrice + timePrice) * multiplier;
        _isCalculatingPrice = false;
      });
    } catch (e) {
      setState(() {
        _isCalculatingPrice = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur calcul prix: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _requestRide() async {
    if (_pickupLocation == null || _destinationLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez sélectionner le départ et la destination'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isRequesting = true;
    });

    try {
      // Créer la demande de course
      final rideRequest = {
        'pickup': {
          'address': _pickupAddress,
          'coordinates': {
            'latitude': _pickupLocation!.latitude,
            'longitude': _pickupLocation!.longitude,
          },
        },
        'destination': {
          'address': _destinationAddress,
          'coordinates': {
            'latitude': _destinationLocation!.latitude,
            'longitude': _destinationLocation!.longitude,
          },
        },
        'pricing': {
          'basePrice': 1000,
          'distancePrice': _estimatedDistance * 500,
          'timePrice': 300,
          'totalPrice': _estimatedPrice,
        },
        'rideType': _selectedRideType.value,
        'vehicleCategory': _selectedVehicleCategory.value,
        'passengers': _passengers,
        'specialRequests': _specialRequests,
      };

      // Ici, vous appelleriez l'API pour créer la course
      // final ride = await ApiService.requestRide(rideRequest);
      
      // Simuler la demande
      await Future.delayed(const Duration(seconds: 2));
      
      setState(() {
        _isRequesting = false;
      });

      // Afficher le succès
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Demande de course envoyée !'),
          backgroundColor: Colors.green,
        ),
      );

      // Retourner au dashboard
      Navigator.of(context).pop();
    } catch (e) {
      setState(() {
        _isRequesting = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Demander une course'),
        backgroundColor: Colors.blue[600],
        foregroundColor: Colors.white,
        actions: [
          if (_pickupLocation != null && _destinationLocation != null)
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _calculatePrice,
              tooltip: 'Recalculer le prix',
            ),
        ],
      ),
      body: Column(
        children: [
          // Carte
          Expanded(
            flex: 3,
            child: GoogleMap(
              cameraTargetBounds: MapStyleService.senegalBounds,
              minMaxZoomPreference: MapStyleService.zoomPreference,
              onMapCreated: (GoogleMapController controller) async {
                _mapController = controller;
                await MapStyleService.apply(controller);
              },
              onTap: _onMapTap,
              initialCameraPosition: CameraPosition(
                target: _pickupLocation ?? SenegalMap.dakar,
                zoom: 15,
              ),
              markers: _buildMarkers(),
              polylines: _buildPolylines(),
            ),
          ),
          
          // Informations de la course
          Expanded(
            flex: 2,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Sélection du type de course
                  _buildRideTypeSelector(),
                  const SizedBox(height: 16),
                  
                  // Adresses
                  _buildAddressSection(),
                  const SizedBox(height: 16),
                  
                  // Prix et informations
                  if (_estimatedPrice > 0) _buildPriceSection(),
                  
                  // Bouton de demande
                  if (_pickupLocation != null && _destinationLocation != null)
                    _buildRequestButton(),
                ],
              ),
            ),
          ),
        ],
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
          infoWindow: InfoWindow(
            title: 'Départ',
            snippet: _pickupAddress,
          ),
        ),
      );
    }
    
    if (_destinationLocation != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('destination'),
          position: _destinationLocation!,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
          infoWindow: InfoWindow(
            title: 'Destination',
            snippet: _destinationAddress,
          ),
        ),
      );
    }
    
    return markers;
  }

  Set<Polyline> _buildPolylines() {
    if (_pickupLocation == null || _destinationLocation == null) {
      return {};
    }
    
    return {
      Polyline(
        polylineId: const PolylineId('route'),
        points: [_pickupLocation!, _destinationLocation!],
        color: Colors.blue,
        width: 4,
      ),
    };
  }

  Widget _buildRideTypeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Type de course',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: RideType.values.map((type) {
              final isSelected = _selectedRideType == type;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilterChip(
                  label: Text(type.displayName),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      _selectedRideType = type;
                    });
                    if (_pickupLocation != null && _destinationLocation != null) {
                      _calculatePrice();
                    }
                  },
                  selectedColor: Colors.blue[100],
                  checkmarkColor: Colors.blue[600],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildAddressSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Itinéraire',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        
        // Départ
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.green[50],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.green[200]!),
          ),
          child: Row(
            children: [
              Icon(Icons.location_on, color: Colors.green[600]),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _pickupAddress.isEmpty ? 'Appuyez sur la carte pour sélectionner le départ' : _pickupAddress,
                  style: TextStyle(
                    color: _pickupAddress.isEmpty ? Colors.grey : Colors.black,
                  ),
                ),
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 8),
        
        // Destination
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.red[50],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.red[200]!),
          ),
          child: Row(
            children: [
              Icon(Icons.location_on, color: Colors.red[600]),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _destinationAddress.isEmpty ? 'Appuyez sur la carte pour sélectionner la destination' : _destinationAddress,
                  style: TextStyle(
                    color: _destinationAddress.isEmpty ? Colors.grey : Colors.black,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPriceSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue[200]!),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Prix estimé',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              if (_isCalculatingPrice)
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else
                Text(
                  '${_estimatedPrice.toStringAsFixed(0)} FCFA',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue[600],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Distance: ${_estimatedDistance.toStringAsFixed(1)} km'),
              Text('Durée: ${_estimatedDuration} min'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRequestButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isRequesting ? null : _requestRide,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue[600],
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
                  Text('Demande en cours...'),
                ],
              )
            : const Text(
                'Demander une course',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
      ),
    );
  }
}
















