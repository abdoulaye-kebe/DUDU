import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
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

  static const Map<String, String> _paymentLogos = {
    'orange_money': 'assets/images/payments/orange_money.png',
    'wave': 'assets/images/payments/wave.png',
    'free_money': 'assets/images/payments/free_money.png',
  };

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

      // Charger les plans disponibles depuis le backend
      _availablePlans = await ApiService.getAvailablePlans(widget.driverProfile.vehicleType);

      // Si c'est un livreur moto, ne garder que le forfait journalier
      if (widget.driverProfile.isMoto || widget.driverProfile.isCourier) {
        _availablePlans = _availablePlans
            .where((plan) => plan.type == 'daily' && plan.isAvailable)
            .toList();
      }

      // Charger l'abonnement actuel s'il existe
      _currentSubscription = await ApiService.getCurrentSubscription();

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
              '1000 FCFA/jour',
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
        if (_availablePlans.isEmpty)
          Text(
            widget.driverProfile.isMoto || widget.driverProfile.isCourier
                ? 'Aucun forfait journalier disponible pour le moment.'
                : 'Aucun plan disponible pour le moment.',
            style: TextStyle(color: Colors.grey[600]),
          )
        else
          ..._availablePlans
              .where((plan) => plan.type != 'yearly')
              .map((plan) => _buildPlanCard(plan)),
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
    final paymentMethod = await _showPaymentMethodDialog(plan);
    if (paymentMethod == null) return;

    // Si c'est Orange Money ou Wave, ouvrir l'application avec deep link
    if (paymentMethod == 'orange_money' || paymentMethod == 'wave') {
      await _openPaymentApp(paymentMethod, plan);
      return;
    }

    // Pour les autres méthodes, procéder normalement
    try {
      await ApiService.purchaseSubscription(
        planType: plan.type,
        paymentMethod: paymentMethod,
        phone: (widget.driverProfile.phone.isNotEmpty
                ? widget.driverProfile.phone
                : null),
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

  Future<void> _openPaymentApp(String paymentMethod, SubscriptionPlan plan) async {
    try {
      final amount = plan.price.toInt();
      final phone = widget.driverProfile.phone;
      
      // Essayer d'ouvrir l'application directement
      String packageName;
      String appName;
      
      if (paymentMethod == 'orange_money') {
        packageName = 'com.orange.orangemoney';
        appName = 'Orange Money';
      } else {
        packageName = 'com.wave.personal';
        appName = 'Wave';
      }
      
      // Essayer avec le package name Android
      final uri = Uri.parse('market://details?id=$packageName');
      
      // Message pour l'utilisateur
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('Paiement $appName'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Montant: ${amount.toStringAsFixed(0)} FCFA'),
                const SizedBox(height: 8),
                Text('Abonnement: ${plan.name}'),
                const SizedBox(height: 16),
                const Text(
                  'Veuillez ouvrir votre application de paiement et effectuer le transfert.',
                  style: TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 8),
                Text(
                  'Numéro: $phone',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Annuler'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  // Procéder avec l'achat
                  _completePurchase(plan, paymentMethod);
                },
                child: const Text('J\'ai payé'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        _showErrorDialog(
          'Information',
          'Veuillez ouvrir votre application ${paymentMethod == 'orange_money' ? 'Orange Money' : 'Wave'} et effectuer le paiement de ${plan.price.toInt()} FCFA.',
        );
      }
    }
  }
  
  Future<void> _completePurchase(SubscriptionPlan plan, String paymentMethod) async {
    try {
      await ApiService.purchaseSubscription(
        planType: plan.type,
        paymentMethod: paymentMethod,
        phone: widget.driverProfile.phone.isNotEmpty ? widget.driverProfile.phone : null,
        autoRenew: false,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Abonnement ${plan.name} enregistré avec succès !'),
            backgroundColor: Colors.green,
          ),
        );
        _loadData();
      }
    } catch (e) {
      if (mounted) {
        _showErrorDialog('Erreur', e.toString());
      }
    }
  }

  Future<String?> _showPaymentMethodDialog(SubscriptionPlan plan) async {
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Méthode de Paiement'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Montant: ${plan.price.toInt()} FCFA',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF00A651),
              ),
            ),
            const SizedBox(height: 16),
            _buildPaymentOption('orange_money', 'Orange Money'),
            _buildPaymentOption('wave', 'Wave'),
            _buildPaymentOption('free_money', 'Free Money'),
            _buildPaymentOption('cash', 'Espèces'),
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

  Widget _buildPaymentOption(String value, String label) {
    final logoPath = _paymentLogos[value];
    return ListTile(
      leading: logoPath != null
          ? Image.asset(
              logoPath,
              width: 28,
              height: 28,
              errorBuilder: (_, __, ___) => const Icon(Icons.account_balance_wallet),
            )
          : const Icon(Icons.payments),
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
