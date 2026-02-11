import 'package:flutter/material.dart';
import '../services/places_service.dart' as places;

/// Écran de debug pour tester le chargement des positions GPS
class DebugLocationScreen extends StatefulWidget {
  const DebugLocationScreen({Key? key}) : super(key: key);

  @override
  State<DebugLocationScreen> createState() => _DebugLocationScreenState();
}

class _DebugLocationScreenState extends State<DebugLocationScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<places.PlaceSuggestion> _suggestions = [];
  bool _isLoading = false;
  String _debugInfo = '';
  places.PlaceSuggestion? _selectedPlace;

  Future<void> _search(String query) async {
    if (query.length < 2) {
      setState(() {
        _suggestions = [];
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _debugInfo = 'Recherche en cours...';
    });

    try {
      final results = await places.PlacesService.getPlaceSuggestions(query);
      
      setState(() {
        _suggestions = results;
        _isLoading = false;
        _debugInfo = '''
✅ ${results.length} résultats trouvés

Détails du premier résultat:
${results.isNotEmpty ? '''
- Description: ${results[0].description}
- MainText: ${results[0].mainText}
- SecondaryText: ${results[0].secondaryText}
- PlaceId: ${results[0].placeId}
- LocalLat: ${results[0].localLat}
- LocalLng: ${results[0].localLng}
- IsLocal: ${results[0].isLocal}
''' : 'Aucun résultat'}
''';
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _debugInfo = '❌ Erreur: $e';
      });
    }
  }

  void _selectPlace(places.PlaceSuggestion place) {
    setState(() {
      _selectedPlace = place;
      _debugInfo = '''
🎯 PLACE SÉLECTIONNÉE:

Description: ${place.description}
MainText: ${place.mainText}
SecondaryText: ${place.secondaryText}
PlaceId: ${place.placeId}

📍 COORDONNÉES GPS:
LocalLat: ${place.localLat}
LocalLng: ${place.localLng}
IsLocal: ${place.isLocal}

${place.localLat != null && place.localLng != null 
  ? '✅ COORDONNÉES DISPONIBLES !' 
  : '❌ COORDONNÉES MANQUANTES !'}
''';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Debug Position GPS'),
        backgroundColor: const Color(0xFF00A651),
      ),
      body: Column(
        children: [
          // Champ de recherche
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Rechercher un lieu',
                hintText: 'Ex: Plateau, Almadies, Thierno...',
                border: const OutlineInputBorder(),
                suffixIcon: _isLoading
                    ? const Padding(
                        padding: EdgeInsets.all(12),
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    : const Icon(Icons.search),
              ),
              onChanged: _search,
            ),
          ),

          // Liste des suggestions
          if (_suggestions.isNotEmpty)
            Expanded(
              child: ListView.builder(
                itemCount: _suggestions.length,
                itemBuilder: (context, index) {
                  final suggestion = _suggestions[index];
                  final hasCoords = suggestion.localLat != null && suggestion.localLng != null;
                  
                  return ListTile(
                    leading: Icon(
                      hasCoords ? Icons.check_circle : Icons.error,
                      color: hasCoords ? Colors.green : Colors.red,
                    ),
                    title: Text(suggestion.mainText),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(suggestion.secondaryText),
                        const SizedBox(height: 4),
                        Text(
                          hasCoords 
                            ? '✅ GPS: ${suggestion.localLat}, ${suggestion.localLng}'
                            : '❌ Pas de coordonnées GPS',
                          style: TextStyle(
                            fontSize: 11,
                            color: hasCoords ? Colors.green : Colors.red,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    onTap: () => _selectPlace(suggestion),
                  );
                },
              ),
            ),

          // Informations de debug
          if (_debugInfo.isNotEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _selectedPlace != null ? Colors.green[50] : Colors.blue[50],
                border: Border(
                  top: BorderSide(
                    color: _selectedPlace != null ? Colors.green : Colors.blue,
                    width: 2,
                  ),
                ),
              ),
              child: SingleChildScrollView(
                child: Text(
                  _debugInfo,
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 12,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
