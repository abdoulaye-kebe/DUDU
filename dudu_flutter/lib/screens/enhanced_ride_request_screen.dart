import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import '../services/geocoding_service.dart';
import '../services/places_service.dart' as places;
import '../widgets/address_autocomplete.dart';

class EnhancedRideRequestScreen extends StatefulWidget {
  const EnhancedRideRequestScreen({Key? key}) : super(key: key);

  @override
  State<EnhancedRideRequestScreen> createState() => _EnhancedRideRequestScreenState();
}

class _EnhancedRideRequestScreenState extends State<EnhancedRideRequestScreen> {
  GoogleMapController? _mapController;
  places.PlaceSuggestion? _pickupPlace;
  places.PlaceSuggestion? _destinationPlace;
  
  String _selectedRideType = 'standard';
  String _selectedVehicleCategory = 'car';
  int _passengers = 1;
  bool _acceptLuggage = false;
  List<String> _specialRequests = [];
  
  bool _isCalculatingPrice = false;
  double _estimatedPrice = 0.0;
  double _estimatedDistance = 0.0;
  int _estimatedDuration = 0;
  
  bool _isRequesting = false;
  bool _showMap = true;

  // Position par défaut : Centre du Sénégal
  final LatLng _senegalCenter = const LatLng(14.4974, -14.4524);

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

      if (mounted) {
        setState(() {
          _pickupPlace = PlaceSuggestion(
            name: 'Ma position',
            address: 'Position actuelle',
            latitude: position.latitude,
            longitude: position.longitude,
            type: 'current',
          );
        });

        _mapController?.animateCamera(
          CameraUpdate.newLatLng(LatLng(position.latitude, position.longitude)),
        );
      }
    } catch (e) {
      print('Erreur localisation: $e');
    }
  }

  void _onPickupSelected(places.PlaceSuggestion place) {
    print('🔍 Pickup sélectionné: ${place.description}');
    print('📍 Coordonnées: ${place.localLat}, ${place.localLng}');
    
    setState(() {
      _pickupPlace = place;
    });
    
    if (place.localLat != null && place.localLng != null) {
      _mapController?.animateCamera(
        CameraUpdate.newLatLng(LatLng(place.localLat!, place.localLng!)),
      );
    }
    
    if (_destinationPlace != null) {
      _calculatePrice();
    }
  }

  void _onDestinationSelected(places.PlaceSuggestion place) {
    print('🔍 Destination sélectionnée: ${place.description}');
    print('📍 Coordonnées: ${place.localLat}, ${place.localLng}');
    
    setState(() {
      _destinationPlace = place;
    });
    
    if (place.localLat != null && place.localLng != null) {
      _mapController?.animateCamera(
        CameraUpdate.newLatLng(LatLng(place.localLat!, place.localLng!)),
      );
    }
    
    if (_pickupPlace != null) {
      _calculatePrice();
    }
  }

  Future<void> _calculatePrice() async {
    if (_pickupPlace == null || _destinationPlace == null) return;

    setState(() {
      _isCalculatingPrice = true;
    });

    try {
      // Simuler le calcul de prix
      await Future.delayed(const Duration(seconds: 1));
      
      // Calculer la distance
      double distance = GeocodingService.calculateDistance(
        _pickupPlace!.localLat ?? 0.0,
        _pickupPlace!.localLng ?? 0.0,
        _destinationPlace!.localLat ?? 0.0,
        _destinationPlace!.localLng ?? 0.0,
      );

      // Calculer le prix basé sur la distance et le type de course
      double basePrice = 1000;
      double distancePrice = distance * 500; // 500 FCFA par km
      double timePrice = 300; // Prix fixe pour le temps
      
      // Multiplicateur selon le type de course
      double multiplier = 1.0;
      switch (_selectedRideType) {
        case 'standard':
          multiplier = 1.0;
          break;
        case 'express':
          multiplier = 1.5;
          break;
        case 'premium':
          multiplier = 2.0;
          break;
        case 'cargo':
          multiplier = 1.8;
          break;
        case 'delivery':
          multiplier = 1.3;
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
    if (_pickupPlace == null || _destinationPlace == null) {
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
          'address': _pickupPlace!.address,
          'coordinates': {
            'latitude': _pickupPlace!.latitude,
            'longitude': _pickupPlace!.longitude,
          },
        },
        'destination': {
          'address': _destinationPlace!.address,
          'coordinates': {
            'latitude': _destinationPlace!.latitude,
            'longitude': _destinationPlace!.longitude,
          },
        },
        'pricing': {
          'basePrice': 1000,
          'distancePrice': _estimatedDistance * 500,
          'timePrice': 300,
          'totalPrice': _estimatedPrice,
        },
        'rideType': _selectedRideType,
        'vehicleCategory': _selectedVehicleCategory,
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
          IconButton(
            icon: Icon(_showMap ? Icons.list : Icons.map),
            onPressed: () {
              setState(() {
                _showMap = !_showMap;
              });
            },
            tooltip: _showMap ? 'Voir la liste' : 'Voir la carte',
          ),
        ],
      ),
      body: _showMap ? _buildMapView() : _buildListView(),
    );
  }

  Widget _buildMapView() {
    return Column(
      children: [
        // Carte
        Expanded(
          flex: 3,
          child: GoogleMap(
            onMapCreated: (GoogleMapController controller) {
              _mapController = controller;
            },
            initialCameraPosition: CameraPosition(
              target: _pickupPlace != null 
                  ? LatLng(_pickupPlace!.latitude, _pickupPlace!.longitude)
                  : _senegalCenter,
              zoom: 15,
            ),
            markers: _buildMarkers(),
            polylines: _buildPolylines(),
            onTap: (LatLng position) {
              // Optionnel: permettre de cliquer sur la carte pour sélectionner
            },
          ),
        ),
        
        // Formulaire
        Expanded(
          flex: 2,
          child: _buildForm(),
        ),
      ],
    );
  }

  Widget _buildListView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildForm(),
          const SizedBox(height: 16),
          _buildMapPreview(),
        ],
      ),
    );
  }

  Widget _buildForm() {
    return Container(
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
          // Sélection des adresses
          AddressAutocomplete(
            label: 'Départ',
            hint: 'Où voulez-vous être pris en charge ?',
            icon: Icons.location_on,
            onPlaceSelected: _onPickupSelected,
            initialValue: _pickupPlace?.description,
          ),
          const SizedBox(height: 16),
          
          AddressAutocomplete(
            label: 'Destination',
            hint: 'Où voulez-vous aller ?',
            icon: Icons.flag,
            onPlaceSelected: _onDestinationSelected,
            initialValue: _destinationPlace?.description,
          ),
          const SizedBox(height: 16),
          
          // Sélection du type de course
          _buildRideTypeSelector(),
          const SizedBox(height: 16),
          
          // Prix et informations
          if (_estimatedPrice > 0) _buildPriceSection(),
          
          // Bouton de demande
          if (_pickupPlace != null && _destinationPlace != null)
            _buildRequestButton(),
        ],
      ),
    );
  }

  Widget _buildMapPreview() {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: GoogleMap(
          onMapCreated: (GoogleMapController controller) {
            _mapController = controller;
          },
          initialCameraPosition: CameraPosition(
            target: _pickupPlace != null 
                ? LatLng(_pickupPlace!.latitude, _pickupPlace!.longitude)
                : _senegalCenter,
            zoom: 15,
          ),
          markers: _buildMarkers(),
          polylines: _buildPolylines(),
        ),
      ),
    );
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
            children: [
              _buildRideTypeChip('standard', 'Standard', Icons.directions_car),
              const SizedBox(width: 8),
              _buildRideTypeChip('express', 'Express', Icons.flash_on),
              const SizedBox(width: 8),
              _buildRideTypeChip('delivery', 'Livraison', Icons.motorcycle),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRideTypeChip(String type, String label, IconData icon) {
    final isSelected = _selectedRideType == type;
    return FilterChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16),
          const SizedBox(width: 4),
          Text(label),
        ],
      ),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _selectedRideType = type;
        });
        if (_pickupPlace != null && _destinationPlace != null) {
          _calculatePrice();
        }
      },
      selectedColor: Colors.blue[100],
      checkmarkColor: Colors.blue[600],
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

  Set<Marker> _buildMarkers() {
    Set<Marker> markers = {};
    
    if (_pickupPlace != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('pickup'),
          position: LatLng(_pickupPlace!.latitude, _pickupPlace!.longitude),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
          infoWindow: InfoWindow(
            title: 'Départ',
            snippet: _pickupPlace!.name,
          ),
        ),
      );
    }
    
    if (_destinationPlace != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('destination'),
          position: LatLng(_destinationPlace!.latitude, _destinationPlace!.longitude),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
          infoWindow: InfoWindow(
            title: 'Destination',
            snippet: _destinationPlace!.name,
          ),
        ),
      );
    }
    
    return markers;
  }

  Set<Polyline> _buildPolylines() {
    if (_pickupPlace == null || _destinationPlace == null) {
      return {};
    }
    
    return {
      Polyline(
        polylineId: const PolylineId('route'),
        points: [
          LatLng(_pickupPlace!.latitude, _pickupPlace!.longitude),
          LatLng(_destinationPlace!.latitude, _destinationPlace!.longitude),
        ],
        color: Colors.blue,
        width: 4,
      ),
    };
  }
}















