import 'package:flutter/material.dart';

class SubscriptionWidget extends StatelessWidget {
  final String currentPlan;
  final DateTime? expiryDate;
  final VoidCallback onUpgrade;

  const SubscriptionWidget({
    Key? key,
    required this.currentPlan,
    this.expiryDate,
    required this.onUpgrade,
  }) : super(key: key);

  static const Color primaryGreen = Color(0xFF0d5d36);
  static const Color lightGreen = Color(0xFF10b981);
  static const Color accentBlack = Color(0xFF1A1A1A);

  String _getPlanName(String plan) {
    switch (plan) {
      case 'daily':
        return 'Journalier';
      case 'weekly':
        return 'Hebdomadaire';
      case 'monthly':
        return 'Mensuel';
      default:
        return 'Gratuit';
    }
  }

  String _getPlanPrice(String plan) {
    switch (plan) {
      case 'daily':
        return '1 000 FCFA/jour';
      case 'weekly':
        return '5 000 FCFA/semaine';
      case 'monthly':
        return '21 000 FCFA/mois';
      default:
        return '0 FCFA';
    }
  }

  Color _getPlanColor(String plan) {
    switch (plan) {
      case 'daily':
        return Colors.blue;
      case 'weekly':
        return lightGreen;
      case 'monthly':
        return Colors.amber;
      default:
        return Colors.grey;
    }
  }

  String _getTimeRemaining() {
    if (expiryDate == null) return 'Expiré';
    
    final now = DateTime.now();
    final difference = expiryDate!.difference(now);
    
    if (difference.isNegative) return 'Expiré';
    
    if (difference.inDays > 0) {
      return '${difference.inDays} jour${difference.inDays > 1 ? 's' : ''} restant${difference.inDays > 1 ? 's' : ''}';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} heure${difference.inHours > 1 ? 's' : ''} restante${difference.inHours > 1 ? 's' : ''}';
    } else {
      return '${difference.inMinutes} minute${difference.inMinutes > 1 ? 's' : ''} restante${difference.inMinutes > 1 ? 's' : ''}';
    }
  }

  @override
  Widget build(BuildContext context) {
    final planColor = _getPlanColor(currentPlan);
    
    // Si plan gratuit, afficher un message différent
    if (currentPlan == 'free' || currentPlan == '') {
      return Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey[300]!, width: 2),
        ),
        child: Column(
          children: [
            const Icon(Icons.info_outline, size: 48, color: Colors.grey),
            const SizedBox(height: 12),
            const Text(
              'Aucun abonnement actif',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: accentBlack,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Choisissez un abonnement pour recevoir des courses illimitées',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onUpgrade,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryGreen,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Choisir un abonnement',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }
    
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [planColor.withOpacity(0.1), Colors.white],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: planColor, width: 2),
        boxShadow: [
          BoxShadow(
            color: planColor.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: planColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.card_membership,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Abonnement ${_getPlanName(currentPlan)}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: accentBlack,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _getPlanPrice(currentPlan),
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: planColor,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'ACTIF',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: Row(
              children: [
                Icon(Icons.access_time, color: planColor, size: 20),
                const SizedBox(width: 8),
                Text(
                  _getTimeRemaining(),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[700],
                  ),
                ),
                const Spacer(),
                if (expiryDate != null)
                  Text(
                    'Expire le ${expiryDate!.day}/${expiryDate!.month}/${expiryDate!.year}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.check_circle, color: lightGreen, size: 16),
              const SizedBox(width: 6),
              const Text(
                'Courses illimitées',
                style: TextStyle(fontSize: 13, color: accentBlack),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onUpgrade,
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryGreen,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: const Text(
                'Changer d\'abonnement',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
