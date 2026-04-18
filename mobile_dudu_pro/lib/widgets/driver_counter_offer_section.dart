import 'package:flutter/material.dart';

/// Bloc UI : contre-proposition tarifaire chauffeur (+300 … +2000 FCFA).
/// Utilisable pour **tous** les types de course (Standard, Confort, Luxe, Femme, Moto, livraisons).
class DriverCounterOfferSection extends StatelessWidget {
  static const List<int> deltas = [300, 500, 750, 1000, 1500, 2000];

  final bool isBusy;
  final void Function(int additionalFcfa) onDeltaPressed;

  const DriverCounterOfferSection({
    Key? key,
    required this.isBusy,
    required this.onDeltaPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: Text(
            'Si le prix ne convient pas, proposez un supplément (max +2000 FCFA)',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[700],
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: deltas.map((d) {
            return ActionChip(
              label: Text('+$d'),
              backgroundColor: isBusy ? Colors.grey[200] : Colors.green[50],
              onPressed: isBusy ? null : () => onDeltaPressed(d),
            );
          }).toList(),
        ),
        if (isBusy)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              'En attente de la réponse du client…',
              style: TextStyle(
                fontSize: 12,
                color: Colors.orange[800],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
      ],
    );
  }
}
