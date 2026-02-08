import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../services/api_service.dart';

/// Écran d'évaluation du passager par le chauffeur
class RatePassengerScreen extends StatefulWidget {
  final String rideId;
  final String passengerName;

  const RatePassengerScreen({
    Key? key,
    required this.rideId,
    required this.passengerName,
  }) : super(key: key);

  @override
  State<RatePassengerScreen> createState() => _RatePassengerScreenState();
}

class _RatePassengerScreenState extends State<RatePassengerScreen> {
  int _rating = 0;
  final TextEditingController _commentController = TextEditingController();
  bool _isSubmitting = false;

  final List<String> _quickComments = [
    'Client ponctuel',
    'Très respectueux',
    'Agréable',
    'Bonne communication',
    'Destination claire',
    'Pourboire généreux',
  ];

  final List<String> _negativeComments = [
    'En retard',
    'Impoli',
    'Mauvaise communication',
    'Destination incorrecte',
  ];

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _submitRating() async {
    if (_rating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez sélectionner une note'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final response = await http.post(
        Uri.parse('${ApiService.baseUrl}/rides/${widget.rideId}/rate-passenger'),
        headers: {
          'Content-Type': 'application/json',
          if (ApiService.authToken != null) 
            'Authorization': 'Bearer ${ApiService.authToken}',
        },
        body: jsonEncode({
          'rating': _rating,
          'comment': _commentController.text.trim(),
        }),
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Évaluation envoyée avec succès'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['message'] ?? 'Erreur lors de l\'évaluation');
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _addQuickComment(String comment) {
    final currentText = _commentController.text.trim();
    if (currentText.isEmpty) {
      _commentController.text = comment;
    } else if (!currentText.contains(comment)) {
      _commentController.text = '$currentText. $comment';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Évaluer le client'),
        backgroundColor: const Color(0xFF0d5d36),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Avatar et nom du passager
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: const Color(0xFF0d5d36).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.person,
                size: 40,
                color: Color(0xFF0d5d36),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              widget.passengerName,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Comment s\'est passée la course ?',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 32),

            // Étoiles de notation
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (index) {
                final starValue = index + 1;
                return GestureDetector(
                  onTap: () => setState(() => _rating = starValue),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Icon(
                      _rating >= starValue ? Icons.star : Icons.star_border,
                      size: 48,
                      color: _rating >= starValue
                          ? Colors.amber
                          : Colors.grey[300],
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 16),
            if (_rating > 0)
              Text(
                _getRatingText(),
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: _getRatingColor(),
                ),
              ),
            const SizedBox(height: 32),

            // Commentaires rapides
            if (_rating >= 4) ...[
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Commentaires rapides (optionnel)',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _quickComments.map((comment) {
                  return ActionChip(
                    label: Text(comment),
                    onPressed: () => _addQuickComment(comment),
                    backgroundColor: Colors.green[50],
                    labelStyle: const TextStyle(color: Color(0xFF0d5d36)),
                  );
                }).toList(),
              ),
            ] else if (_rating > 0 && _rating < 4) ...[
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Que s\'est-il passé ?',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _negativeComments.map((comment) {
                  return ActionChip(
                    label: Text(comment),
                    onPressed: () => _addQuickComment(comment),
                    backgroundColor: Colors.orange[50],
                    labelStyle: const TextStyle(color: Colors.orange),
                  );
                }).toList(),
              ),
            ],
            const SizedBox(height: 24),

            // Champ de commentaire
            TextField(
              controller: _commentController,
              maxLines: 4,
              maxLength: 200,
              decoration: InputDecoration(
                hintText: 'Ajoutez un commentaire (optionnel)...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF0d5d36), width: 2),
                ),
                filled: true,
                fillColor: Colors.grey[50],
              ),
            ),
            const SizedBox(height: 32),

            // Bouton de soumission
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submitRating,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0d5d36),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        'ENVOYER L\'ÉVALUATION',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: _isSubmitting ? null : () => Navigator.pop(context),
              child: const Text(
                'Passer',
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

  String _getRatingText() {
    switch (_rating) {
      case 5:
        return 'Excellent ! ⭐⭐⭐⭐⭐';
      case 4:
        return 'Très bien ! ⭐⭐⭐⭐';
      case 3:
        return 'Correct ⭐⭐⭐';
      case 2:
        return 'Peut mieux faire ⭐⭐';
      case 1:
        return 'Mauvaise expérience ⭐';
      default:
        return '';
    }
  }

  Color _getRatingColor() {
    if (_rating >= 4) return Colors.green;
    if (_rating == 3) return Colors.orange;
    return Colors.red;
  }
}
