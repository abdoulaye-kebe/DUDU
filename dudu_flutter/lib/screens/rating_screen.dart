import 'package:flutter/material.dart';
import '../services/api_service.dart';

/// Écran de notation du chauffeur après une course
/// Permet de donner une note de 1 à 5 étoiles et des feedbacks spécifiques
class RatingScreen extends StatefulWidget {
  final String rideId;
  final String driverName;
  final String driverPhoto;
  final String vehicleType;

  const RatingScreen({
    Key? key,
    required this.rideId,
    required this.driverName,
    this.driverPhoto = '',
    this.vehicleType = 'car',
  }) : super(key: key);

  @override
  State<RatingScreen> createState() => _RatingScreenState();
}

class _RatingScreenState extends State<RatingScreen> {
  int _selectedRating = 0;
  final Set<String> _selectedFeedbacks = {};
  final TextEditingController _commentController = TextEditingController();
  bool _isSubmitting = false;

  // Catégories de feedback
  final List<Map<String, dynamic>> _feedbackCategories = [
    {
      'id': 'clean_interior',
      'label': 'Intérieur\npropre',
      'icon': '🧹',
    },
    {
      'id': 'pleasant_driving',
      'label': 'Conduite\nagréable',
      'icon': '💝',
    },
    {
      'id': 'polite_driver',
      'label': 'Conducteur\npoli',
      'icon': '🏮',
    },
    {
      'id': 'good_conversation',
      'label': 'Qualité\nconversationnel',
      'icon': '🫖',
    },
  ];

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _submitRating() async {
    if (_selectedRating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez sélectionner une note'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      await ApiService.rateRide(
        widget.rideId,
        _selectedRating,
        feedbacks: _selectedFeedbacks.toList(),
        comment: _commentController.text.trim(),
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Merci pour votre évaluation !'),
          backgroundColor: Color(0xFF00A651),
        ),
      );

      // Retourner à l'écran d'accueil
      Navigator.of(context).popUntil((route) => route.isFirst);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Évaluer la course'),
        backgroundColor: const Color(0xFF00A651),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 20),

            // Photo du chauffeur
            CircleAvatar(
              radius: 50,
              backgroundColor: const Color(0xFF00A651),
              child: Text(
                widget.driverName.isNotEmpty
                    ? widget.driverName[0].toUpperCase()
                    : 'C',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 40,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Nom du chauffeur
            Text(
              widget.driverName,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            Text(
              widget.vehicleType == 'moto'
                  ? 'Livreur'
                  : 'Chauffeur',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),

            const SizedBox(height: 32),

            // Étoiles de notation
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (index) {
                final starIndex = index + 1;
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedRating = starIndex;
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    child: Icon(
                      starIndex <= _selectedRating
                          ? Icons.star
                          : Icons.star_border,
                      color: starIndex <= _selectedRating
                          ? Colors.amber
                          : Colors.grey[400],
                      size: 48,
                    ),
                  ),
                );
              }),
            ),

            const SizedBox(height: 16),

            // Texte de feedback selon la note
            if (_selectedRating > 0)
              Text(
                _selectedRating == 5
                    ? 'Excellent !'
                    : _selectedRating == 4
                        ? 'Très bien'
                        : _selectedRating == 3
                            ? 'Correct'
                            : _selectedRating == 2
                                ? 'Peut mieux faire'
                                : 'Décevant',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: _selectedRating >= 4
                      ? const Color(0xFF00A651)
                      : _selectedRating >= 3
                          ? Colors.orange
                          : Colors.red,
                ),
              ),

            const SizedBox(height: 32),

            // Question "Qu'avez-vous aimé ?"
            const Text(
              'Qu\'avez-vous aimé ?',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 20),

            // Catégories de feedback
            Wrap(
              spacing: 16,
              runSpacing: 16,
              alignment: WrapAlignment.center,
              children: _feedbackCategories.map((category) {
                final isSelected = _selectedFeedbacks.contains(category['id']);
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      if (isSelected) {
                        _selectedFeedbacks.remove(category['id']);
                      } else {
                        _selectedFeedbacks.add(category['id']);
                      }
                    });
                  },
                  child: Container(
                    width: 80,
                    padding: const EdgeInsets.symmetric(
                      vertical: 12,
                      horizontal: 8,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xFF00A651).withOpacity(0.1)
                          : Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected
                            ? const Color(0xFF00A651)
                            : Colors.grey[300]!,
                        width: 2,
                      ),
                    ),
                    child: Column(
                      children: [
                        Text(
                          category['icon'],
                          style: const TextStyle(fontSize: 32),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          category['label'],
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 11,
                            color: isSelected
                                ? const Color(0xFF00A651)
                                : Colors.grey[700],
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 32),

            // Champ de commentaire optionnel
            TextField(
              controller: _commentController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Commentaire (optionnel)',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: Color(0xFF00A651),
                    width: 2,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 32),

            // Bouton de soumission
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submitRating,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00A651),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        'Envoyer l\'évaluation',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),

            const SizedBox(height: 16),

            // Bouton "Plus tard"
            TextButton(
              onPressed: () {
                Navigator.of(context).popUntil((route) => route.isFirst);
              },
              child: const Text(
                'Plus tard',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 16,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
