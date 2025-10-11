import 'package:flutter/material.dart';
import '../themes/app_theme.dart';

class SimpleMapScreen extends StatelessWidget {
  final String? title;
  final bool allowLocationSelection;

  const SimpleMapScreen({
    super.key,
    this.title = 'Carte',
    this.allowLocationSelection = true,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title ?? 'Carte'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: Container(
        color: Colors.grey[200],
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.map,
                size: 80,
                color: Colors.grey,
              ),
              const SizedBox(height: 20),
              const Text(
                'Carte Google Maps',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Carte temporaire - Sélectionnez une destination',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 30),
              Column(
                children: [
                  ElevatedButton(
                    onPressed: () {
                      // Simulation d'une localisation sélectionnée (Dakar)
                      Navigator.pop(context, {
                        'location': {'lat': 14.7167, 'lng': -17.4677},
                        'address': 'Dakar, Sénégal'
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                    ),
                    child: const Text('Continuer avec Dakar'),
                  ),
                  const SizedBox(height: 15),
                  ElevatedButton(
                    onPressed: () {
                      // Simulation d'une localisation sélectionnée (Aéroport)
                      Navigator.pop(context, {
                        'location': {'lat': 14.6708, 'lng': -17.4731},
                        'address': 'Aéroport Léopold Sédar Senghor'
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                    ),
                    child: const Text('Continuer avec Aéroport'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
