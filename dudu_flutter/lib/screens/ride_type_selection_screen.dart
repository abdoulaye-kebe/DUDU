import 'package:flutter/material.dart';

class RideTypeSelectionScreen extends StatelessWidget {
  final Function(String rideType) onTypeSelected;

  const RideTypeSelectionScreen({
    Key? key,
    required this.onTypeSelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
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
            padding: const EdgeInsets.all(20),
            child: Text(
              'Choisissez votre type de course',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          
          // Liste des types de course
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _buildRideTypeCard(
                  context,
                  'Standard',
                  'Course classique avec voiture',
                  Icons.directions_car,
                  'standard',
                  const Color(0xFF00A651),
                  'Idéal pour vos trajets quotidiens',
                  multiplier: 1.0,
                ),
                
                _buildRideTypeCard(
                  context,
                  'Express',
                  'Course rapide, prioritaire',
                  Icons.flash_on,
                  'express',
                  Colors.orange,
                  'Arrivée rapide, trajet direct',
                  multiplier: 1.3,
                  isPopular: true,
                ),
                
                _buildRideTypeCard(
                  context,
                  'Premium',
                  'Véhicule haut de gamme, confort',
                  Icons.star,
                  'premium',
                  Colors.purple,
                  'Climatisation, sièges en cuir',
                  multiplier: 1.5,
                ),
                
                _buildRideTypeCard(
                  context,
                  'Covoiturage',
                  'Partage avec d\'autres passagers',
                  Icons.people,
                  'shared',
                  Colors.blue,
                  'Économisez 30% sur votre trajet',
                  multiplier: 0.7,
                  discount: '-30%',
                ),
                
                _buildRideTypeCard(
                  context,
                  'Femmes uniquement',
                  'Chauffeuse femme, passagères femmes',
                  Icons.woman,
                  'women_only',
                  Colors.pink,
                  'Sécurité et confort pour les femmes',
                  multiplier: 1.0,
                ),
                
                const Divider(height: 32, thickness: 2),
                
                _buildRideTypeCard(
                  context,
                  'Livraison de colis 🏍️',
                  'Envoi rapide par moto-taxi',
                  Icons.local_shipping,
                  'delivery',
                  const Color(0xFFFF6B00),
                  'Documents, colis, nourriture',
                  multiplier: 0.8,
                  isNew: true,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRideTypeCard(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    String rideType,
    Color color, 
    String description, {
    double multiplier = 1.0,
    String? discount,
    bool isPopular = false,
    bool isNew = false,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: () {
          Navigator.pop(context);
          onTypeSelected(rideType);
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Icône
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 32),
              ),
              
              const SizedBox(width: 16),
              
              // Informations
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        if (isPopular)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.orange,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text(
                              'POPULAIRE',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        if (isNew)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.red,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text(
                              'NOUVEAU',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        if (discount != null)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.green,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              discount,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.info_outline, size: 14, color: color),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            description,
                            style: TextStyle(
                              fontSize: 12,
                              color: color,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (multiplier != 1.0)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          multiplier > 1.0
                              ? 'Prix x${multiplier.toStringAsFixed(1)}'
                              : 'Prix ${(multiplier * 100).toInt()}%',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[700],
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              
              // Flèche
              const Icon(Icons.arrow_forward_ios, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}

