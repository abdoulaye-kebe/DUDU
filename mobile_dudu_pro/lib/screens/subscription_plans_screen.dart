import 'package:flutter/material.dart';
import 'subscription_payment_screen.dart';

class SubscriptionPlansScreen extends StatefulWidget {
  const SubscriptionPlansScreen({Key? key}) : super(key: key);

  @override
  State<SubscriptionPlansScreen> createState() => _SubscriptionPlansScreenState();
}

class _SubscriptionPlansScreenState extends State<SubscriptionPlansScreen> {
  static const Color primaryGreen = Color(0xFF0d5d36);
  static const Color lightGreen = Color(0xFF10b981);
  static const Color accentBlack = Color(0xFF1A1A1A);

  String? _selectedPlan;

  final List<Map<String, dynamic>> _plans = [
    {
      'id': 'daily',
      'name': 'Journalier',
      'price': 1000,
      'duration': 'jour',
      'icon': Icons.today,
      'color': Colors.blue,
      'badge': null,
      'savings': null,
    },
    {
      'id': 'weekly',
      'name': 'Hebdomadaire',
      'price': 5000,
      'duration': 'semaine',
      'icon': Icons.date_range,
      'color': Color(0xFF10b981),
      'badge': 'POPULAIRE',
      'badgeColor': Color(0xFF10b981),
      'savings': 2000,
    },
    {
      'id': 'monthly',
      'name': 'Mensuel',
      'price': 21000,
      'duration': 'mois',
      'icon': Icons.calendar_month,
      'color': Colors.amber,
      'badge': 'MEILLEUR PRIX',
      'badgeColor': Colors.amber,
      'savings': 9000,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: primaryGreen,
        elevation: 0,
        title: const Text(
          'Choisir un abonnement',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          // Header - Version compacte
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              color: primaryGreen,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(24),
                bottomRight: Radius.circular(24),
              ),
            ),
            child: Column(
              children: [
                const Icon(
                  Icons.card_membership,
                  size: 40,
                  color: Colors.white,
                ),
                const SizedBox(height: 12),
                const Text(
                  'Courses illimitées',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Choisissez le plan qui vous convient',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
              ],
            ),
          ),

          // Plans
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _plans.length,
              itemBuilder: (context, index) {
                final plan = _plans[index];
                final isSelected = _selectedPlan == plan['id'];

                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedPlan = plan['id'];
                    });
                  },
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: isSelected ? plan['color'].withOpacity(0.1) : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSelected ? plan['color'] : Colors.grey[300]!,
                        width: isSelected ? 3 : 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: isSelected 
                              ? plan['color'].withOpacity(0.3)
                              : Colors.grey.withOpacity(0.1),
                          blurRadius: isSelected ? 12 : 6,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Stack(
                      children: [
                        // Badge
                        if (plan['badge'] != null)
                          Positioned(
                            top: -10,
                            right: -10,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: plan['badgeColor'],
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                plan['badge'],
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),

                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: plan['color'],
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(
                                    plan['icon'],
                                    color: Colors.white,
                                    size: 28,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        plan['name'],
                                        style: const TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                          color: accentBlack,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Valable 1 ${plan['duration']}',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (isSelected)
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: plan['color'],
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.check,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  '${plan['price']}',
                                  style: TextStyle(
                                    fontSize: 32,
                                    fontWeight: FontWeight.bold,
                                    color: plan['color'],
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 6),
                                  child: Text(
                                    'FCFA',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            if (plan['id'] == 'daily') ...[
                              const SizedBox(height: 6),
                              Text(
                                'Livreur moto / livraison : 500 FCFA / jour',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                            if (plan['savings'] != null) ...[
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: plan['color'].withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  '💰 Économisez ${plan['savings']} FCFA',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: plan['color'],
                                  ),
                                ),
                              ),
                            ],
                            const SizedBox(height: 16),
                            const Divider(),
                            const SizedBox(height: 12),
                            _buildFeature('✅ Courses illimitées'),
                            const SizedBox(height: 8),
                            _buildFeature('✅ Priorité sur les demandes'),
                            const SizedBox(height: 8),
                            _buildFeature('✅ Support 24/7'),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          // Bouton de confirmation
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.2),
                  blurRadius: 10,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: SafeArea(
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _selectedPlan == null ? null : _confirmSubscription,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryGreen,
                    disabledBackgroundColor: Colors.grey[300],
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    _selectedPlan == null
                        ? 'Choisissez un plan'
                        : 'Confirmer l\'abonnement',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeature(String text) {
    return Row(
      children: [
        Text(
          text,
          style: const TextStyle(
            fontSize: 14,
            color: accentBlack,
          ),
        ),
      ],
    );
  }

  void _confirmSubscription() {
    final selectedPlanData = _plans.firstWhere((p) => p['id'] == _selectedPlan);
    _navigateToWavePayment(selectedPlanData);
  }

  void _navigateToWavePayment(Map<String, dynamic> planData) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SubscriptionPaymentScreen(
          subscription: {
            '_id': planData['id'],
            'id': planData['id'],
            'name': planData['name'],
            'price': planData['price'],
            'duration': planData['duration'],
            'features': [
              'Courses illimitées',
              'Support prioritaire',
              'Statistiques détaillées',
              'Pas de commission',
            ],
          },
        ),
      ),
    ).then((success) {
      if (success == true && mounted) {
        Navigator.pop(context, planData['id']);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Abonnement activé avec succès !'),
            backgroundColor: lightGreen,
            duration: Duration(seconds: 3),
          ),
        );
      }
    });
  }
}
