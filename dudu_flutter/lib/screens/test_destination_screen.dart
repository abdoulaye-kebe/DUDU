import 'package:flutter/material.dart';
import '../services/places_service.dart' as places;
import '../widgets/address_autocomplete.dart';

/// Écran de test pour débugger le problème du champ destination
class TestDestinationScreen extends StatefulWidget {
  const TestDestinationScreen({Key? key}) : super(key: key);

  @override
  State<TestDestinationScreen> createState() => _TestDestinationScreenState();
}

class _TestDestinationScreenState extends State<TestDestinationScreen> {
  places.PlaceSuggestion? _selectedPlace;
  String _debugInfo = '';

  void _onPlaceSelected(places.PlaceSuggestion place) {
    print('🔍 TEST - Place sélectionnée: ${place.description}');
    print('📍 TEST - Coordonnées: ${place.localLat}, ${place.localLng}');
    print('🆔 TEST - PlaceId: ${place.placeId}');
    print('📝 TEST - MainText: ${place.mainText}');
    print('📝 TEST - SecondaryText: ${place.secondaryText}');
    
    setState(() {
      _selectedPlace = place;
      _debugInfo = '''
Place sélectionnée avec succès !

Description: ${place.description}
MainText: ${place.mainText}
SecondaryText: ${place.secondaryText}
PlaceId: ${place.placeId}
Latitude: ${place.localLat}
Longitude: ${place.localLng}
IsLocal: ${place.isLocal}
''';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Test Destination'),
        backgroundColor: const Color(0xFF00A651),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Test du champ destination',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            // Widget AddressAutocomplete
            AddressAutocomplete(
              label: 'Destination',
              hint: 'Saisissez votre destination',
              icon: Icons.flag,
              onPlaceSelected: _onPlaceSelected,
              initialValue: _selectedPlace?.description,
            ),
            
            const SizedBox(height: 24),
            
            // Affichage des informations de debug
            if (_selectedPlace != null) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '✅ Place sélectionnée',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(_debugInfo),
                  ],
                ),
              ),
            ] else ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.orange[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange),
                ),
                child: const Text(
                  'Aucune place sélectionnée.\nSélectionnez une destination dans la liste.',
                  style: TextStyle(color: Colors.orange),
                ),
              ),
            ],
            
            const SizedBox(height: 24),
            
            // Bouton pour réinitialiser
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  setState(() {
                    _selectedPlace = null;
                    _debugInfo = '';
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                ),
                child: const Text('Réinitialiser'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
