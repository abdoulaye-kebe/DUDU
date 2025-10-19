import 'package:flutter/material.dart';
import '../models/driver_profile.dart';
import '../services/api_service.dart';

class SubscriptionScreen extends StatefulWidget {
  final DriverProfile driverProfile;

  const SubscriptionScreen({
    Key? key,
    required this.driverProfile,
  }) : super(key: key);

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {
  List<SubscriptionPlan> _availablePlans = [];
  SubscriptionInfo? _currentSubscription;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      // Simuler un délai de chargement
      await Future.delayed(const Duration(seconds: 1));

      // Créer des plans de test simples
      _availablePlans = [
        SubscriptionPlan(
          type: 'daily',
          name: 'Forfait Journalier',
          price: 2000,
          currency: 'FCFA',
          duration: 1,
          features: ['Courses illimitées', 'Support 24/7'],
          isAvailable: true,
        ),
        SubscriptionPlan(
          type: 'weekly',
          name: 'Forfait Hebdomadaire',
          price: 12000,
          currency: 'FCFA',
          duration: 7,
          features: ['Courses illimitées', 'Support prioritaire', 'Statistiques avancées'],
          isAvailable: widget.driverProfile.isCar,
        ),
        SubscriptionPlan(
          type: 'monthly',
          name: 'Forfait Mensuel',
          price: 45000,
          currency: 'FCFA',
          duration: 30,
          features: ['Courses illimitées', 'Support prioritaire', 'Statistiques avancées', 'Formation gratuite'],
          isAvailable: widget.driverProfile.isCar,
        ),
      ];

      // Créer un abonnement actuel de test
      _currentSubscription = SubscriptionInfo(
        id: 'sub_test',
        type: 'daily',
        name: 'Forfait Journalier',
        price: 2000,
        currency: 'FCFA',
        duration: 1,
        features: ['Courses illimitées', 'Support 24/7'],
        status: 'active',
        startDate: DateTime.now(),
        endDate: DateTime.now().add(const Duration(days: 1)),
        isActive: true,
        isExpiringSoon: false,
      );

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Abonnements ${widget.driverProfile.vehicleType.displayName}',
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color(0xFF00A651),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildErrorWidget()
              : _buildContent(),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline,
            size: 64,
            color: Colors.red,
          ),
          const SizedBox(height: 16),
          Text(
            'Erreur de chargement',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            _error!,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadData,
            child: const Text('Réessayer'),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Abonnement actuel
          if (_currentSubscription != null) ...[
            _buildCurrentSubscriptionCard(),
            const SizedBox(height: 24),
          ],

          // Restrictions pour moto
          if (widget.driverProfile.isMoto) ...[
            _buildMotoRestrictionsCard(),
            const SizedBox(height: 24),
          ],

          // Plans disponibles
          _buildPlansSection(),

          // Bonus pour moto
          if (widget.driverProfile.isMoto && _currentSubscription != null) ...[
            const SizedBox(height: 24),
            _buildBonusSection(),
          ],
        ],
      ),
    );
  }

  Widget _buildCurrentSubscriptionCard() {
    if (_currentSubscription == null) return const SizedBox.shrink();

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: _currentSubscription!.isActive 
              ? Colors.green 
              : Colors.orange,
          width: 2,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  _currentSubscription!.isActive 
                      ? Icons.check_circle 
                      : Icons.warning,
                  color: _currentSubscription!.isActive 
                      ? Colors.green 
                      : Colors.orange,
                ),
                const SizedBox(width: 8),
                Text(
                  'Abonnement Actuel',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildInfoRow('Plan', _currentSubscription!.name),
            _buildInfoRow('Prix', _currentSubscription!.priceFormatted),
            _buildInfoRow('Durée', _currentSubscription!.durationFormatted),
            _buildInfoRow('Statut', _currentSubscription!.isActive ? 'Actif' : 'Expiré'),
            if (_currentSubscription!.isExpiringSoon)
              Container(
                margin: const EdgeInsets.only(top: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning, color: Colors.orange),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Votre abonnement expire bientôt !',
                        style: TextStyle(
                          color: Colors.orange.shade800,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMotoRestrictionsCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Colors.blue, width: 2),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.info, color: Colors.blue),
                const SizedBox(width: 8),
                Text(
                  'Restrictions Livreur Moto',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildRestrictionItem(
              '🏍️',
              'Forfait journalier uniquement',
              '2,000 FCFA/jour',
            ),
            _buildRestrictionItem(
              '📦',
              'Maximum 20 livraisons/jour',
              'Pour votre sécurité',
            ),
            _buildRestrictionItem(
              '🎁',
              'Bonus hebdomadaires',
              'Performance récompensée',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRestrictionItem(String icon, String title, String subtitle) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(icon, style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlansSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Plans Disponibles',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        ..._availablePlans.map((plan) => _buildPlanCard(plan)),
      ],
    );
  }

  Widget _buildPlanCard(SubscriptionPlan plan) {
    final isCurrentPlan = _currentSubscription?.type == plan.type;
    final hasSavings = plan.savings != null && 
        plan.savings!['amount'] != null && 
        plan.savings!['amount'] > 0;

    return Card(
      elevation: isCurrentPlan ? 6 : 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isCurrentPlan 
            ? const BorderSide(color: Color(0xFF00A651), width: 2)
            : BorderSide.none,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        plan.name,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        plan.durationFormatted,
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      plan.priceFormatted,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF00A651),
                      ),
                    ),
                    if (hasSavings)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.green.shade100,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'Économisez ${plan.savings!['percentage']}%',
                          style: TextStyle(
                            color: Colors.green.shade800,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Fonctionnalités
            ...plan.features.map((feature) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                children: [
                  const Icon(
                    Icons.check,
                    color: Color(0xFF00A651),
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      feature,
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
            )),
            const SizedBox(height: 16),
            // Bouton d'action
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isCurrentPlan ? null : () => _purchasePlan(plan),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isCurrentPlan 
                      ? Colors.grey 
                      : const Color(0xFF00A651),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  isCurrentPlan 
                      ? 'Plan Actuel' 
                      : 'Souscrire',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBonusSection() {
    if (_currentSubscription?.weeklyBonus == null) {
      return const SizedBox.shrink();
    }

    final bonus = _currentSubscription!.weeklyBonus!;

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Colors.orange, width: 2),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.card_giftcard, color: Colors.orange),
                const SizedBox(width: 8),
                Text(
                  'Bonus Hebdomadaire',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.orange,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (bonus.hasBonus) ...[
              _buildBonusInfo('Type', bonus.bonusDescription),
              _buildBonusInfo('Total gagné', bonus.amount.toStringAsFixed(0) + ' FCFA'),
              if (bonus.lastBonusDate != null)
                _buildBonusInfo('Dernier bonus', _formatDate(bonus.lastBonusDate!)),
            ] else ...[
              const Text(
                'Aucun bonus cette semaine',
                style: TextStyle(
                  color: Colors.grey,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
            const SizedBox(height: 12),
            TextButton.icon(
              onPressed: () => _showBonusHistory(),
              icon: const Icon(Icons.history),
              label: const Text('Voir l\'historique'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          Text(value),
        ],
      ),
    );
  }

  Widget _buildBonusInfo(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: const TextStyle(fontSize: 12),
            ),
          ),
          const Text(': '),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  Future<void> _purchasePlan(SubscriptionPlan plan) async {
    // Vérifier les restrictions pour moto
    if (widget.driverProfile.isMoto && plan.type != 'daily') {
      _showErrorDialog(
        'Restriction Moto',
        'Les livreurs moto ne peuvent souscrire qu\'au forfait journalier.',
      );
      return;
    }

    // Afficher dialogue de paiement
    final paymentMethod = await _showPaymentMethodDialog();
    if (paymentMethod == null) return;

    try {
      await ApiService.purchaseSubscription(
        planType: plan.type,
        paymentMethod: paymentMethod,
        phone: widget.driverProfile.phone,
        autoRenew: false,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Abonnement ${plan.name} acheté avec succès !'),
            backgroundColor: Colors.green,
          ),
        );
        _loadData(); // Recharger les données
      }
    } catch (e) {
      if (mounted) {
        _showErrorDialog('Erreur d\'achat', e.toString());
      }
    }
  }

  Future<String?> _showPaymentMethodDialog() async {
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Méthode de Paiement'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildPaymentOption('orange_money', 'Orange Money', '🟠'),
            _buildPaymentOption('wave', 'Wave', '🌊'),
            _buildPaymentOption('free_money', 'Free Money', '🆓'),
            _buildPaymentOption('cash', 'Espèces', '💵'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentOption(String value, String label, String icon) {
    return ListTile(
      leading: Text(icon, style: const TextStyle(fontSize: 24)),
      title: Text(label),
      onTap: () => Navigator.pop(context, value),
    );
  }

  void _showErrorDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _showBonusHistory() async {
    if (_currentSubscription == null) return;

    try {
      final history = await ApiService.getBonusHistory(_currentSubscription!.id);
      
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Historique des Bonus'),
            content: SizedBox(
              width: double.maxFinite,
              height: 300,
              child: ListView.builder(
                itemCount: history['data']['bonusHistory'].length,
                itemBuilder: (context, index) {
                  final bonus = history['data']['bonusHistory'][index];
                  return ListTile(
                    leading: Icon(
                      bonus['type'] == 'free_subscription' 
                          ? Icons.card_giftcard 
                          : Icons.monetization_on,
                      color: Colors.orange,
                    ),
                    title: Text(bonus['description']),
                    subtitle: Text(_formatDate(DateTime.parse(bonus['date']))),
                    trailing: Text(
                      bonus['type'] == 'free_subscription' 
                          ? '24h gratuites' 
                          : '${bonus['amount']} FCFA',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  );
                },
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Fermer'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        _showErrorDialog('Erreur', 'Impossible de charger l\'historique des bonus');
      }
    }
  }
}
