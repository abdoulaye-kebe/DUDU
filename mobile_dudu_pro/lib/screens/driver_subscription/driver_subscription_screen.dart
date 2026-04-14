import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/driver_profile.dart';
import '../../services/api_service.dart';

/// Abonnement pour chauffeurs et livreurs (profil [DriverProfile]).
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
    'wave': 'assets/images/payments/wave.png',
  };

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      _availablePlans = await ApiService.getAvailablePlans(widget.driverProfile.vehicleType);

      if (widget.driverProfile.isMoto || widget.driverProfile.isCourier) {
        _availablePlans = _availablePlans
            .where((plan) => plan.type == 'daily' && plan.isAvailable)
            .toList();
      }

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
          if (_currentSubscription != null) ...[
            _buildCurrentSubscriptionCard(),
            const SizedBox(height: 24),
          ],
          if (widget.driverProfile.isMoto) ...[
            _buildMotoRestrictionsCard(),
            const SizedBox(height: 24),
          ],
          _buildPlansSection(),
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
          color: _currentSubscription!.isActive ? Colors.green : Colors.orange,
          width: 2,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_currentSubscription!.isActive)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.green,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(
                      Icons.check_circle,
                      color: Colors.white,
                      size: 20,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'ABONNEMENT ACTIF',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            if (!_currentSubscription!.isActive)
              Row(
                children: [
                  const Icon(
                    Icons.warning,
                    color: Colors.orange,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Abonnement Expiré',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.orange,
                        ),
                  ),
                ],
              ),
            const SizedBox(height: 16),
            _buildInfoRow('Plan', _currentSubscription!.name),
            _buildInfoRow('Prix', _currentSubscription!.priceFormatted),
            _buildInfoRow('Durée', _currentSubscription!.durationFormatted),
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
    final isDailyPlan = plan.type == 'daily';
    final canPurchaseAgain = isDailyPlan;
    final hasSavings = plan.savings != null &&
        plan.savings!['amount'] != null &&
        plan.savings!['amount'] > 0;

    return Card(
      elevation: (isCurrentPlan && !canPurchaseAgain) ? 6 : 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: (isCurrentPlan && !canPurchaseAgain)
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
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
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
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: (isCurrentPlan && !canPurchaseAgain)
                    ? null
                    : () => _purchasePlan(plan),
                style: ElevatedButton.styleFrom(
                  backgroundColor: (isCurrentPlan && !canPurchaseAgain)
                      ? Colors.grey
                      : const Color(0xFF00A651),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  (isCurrentPlan && !canPurchaseAgain)
                      ? 'Plan Actuel'
                      : (isCurrentPlan && canPurchaseAgain)
                          ? 'Ajouter +1 jour'
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
              _buildBonusInfo(
                  'Total gagné', '${bonus.amount.toStringAsFixed(0)} FCFA'),
              if (bonus.lastBonusDate != null)
                _buildBonusInfo(
                    'Dernier bonus', _formatDate(bonus.lastBonusDate!)),
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
    if (widget.driverProfile.isMoto && plan.type != 'daily') {
      _showErrorDialog(
        'Restriction Moto',
        'Les livreurs moto ne peuvent souscrire qu\'au forfait journalier.',
      );
      return;
    }

    final paymentMethod = await _showPaymentMethodDialog(plan);
    if (paymentMethod == null) return;

    if (paymentMethod == 'wave') {
      await _openPaymentApp(plan);
      return;
    }

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
        _loadData();
      }
    } catch (e) {
      if (mounted) {
        _showErrorDialog('Erreur d\'achat', e.toString());
      }
    }
  }

  Future<void> _openPaymentApp(SubscriptionPlan plan) async {
    try {
      final amount = plan.price.toInt();

      const String duduPaymentNumber = '221771234567';

      const appName = 'Wave';
      final deepLinkUrl =
          'wave://send?phone=$duduPaymentNumber&amount=$amount&note=Abonnement ${plan.name} - ${widget.driverProfile.phone}';
      const fallbackUrl = 'https://www.wave.com/sn';

      final uri = Uri.parse(deepLinkUrl);
      bool launched = false;

      try {
        if (await canLaunchUrl(uri)) {
          launched = await launchUrl(
            uri,
            mode: LaunchMode.externalApplication,
          );
        }
      } catch (_) {}

      if (!launched) {
        if (mounted) {
          final confirmed = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: Row(
                children: [
                  const Icon(
                    Icons.payment,
                    color: Color(0xFF00D9A5),
                  ),
                  const SizedBox(width: 8),
                  Text('Paiement $appName'),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Informations de paiement:',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Text('💰 Montant: $amount FCFA'),
                        const SizedBox(height: 4),
                        Text('📦 Abonnement: ${plan.name}'),
                        const SizedBox(height: 4),
                        Text('📞 Numéro DUDU: $duduPaymentNumber'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    '1. Ouvrez votre application de paiement',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 4),
                  Text('2. Envoyez $amount FCFA au numéro ci-dessus'),
                  const SizedBox(height: 4),
                  const Text('3. Notez le code de transaction'),
                  const SizedBox(height: 4),
                  const Text('4. Revenez ici et confirmez le paiement'),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.orange[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.orange),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.info_outline,
                            color: Colors.orange, size: 20),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Votre abonnement sera activé après vérification du paiement par notre équipe.',
                            style: TextStyle(fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Annuler'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context, true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00A651),
                  ),
                  child: Text('Ouvrir $appName'),
                ),
              ],
            ),
          );

          if (confirmed == true) {
            final fallbackUri = Uri.parse(fallbackUrl);
            await launchUrl(fallbackUri, mode: LaunchMode.externalApplication);

            if (mounted) {
              _showPaymentConfirmationDialog(plan);
            }
          }
        }
      } else {
        await Future.delayed(const Duration(seconds: 2));
        if (mounted) {
          _showPaymentConfirmationDialog(plan);
        }
      }
    } catch (e) {
      if (mounted) {
        _showErrorDialog(
          'Erreur',
          'Impossible d\'ouvrir l\'application de paiement.\n\nVeuillez effectuer le paiement manuellement et contacter le support.',
        );
      }
    }
  }

  Future<void> _showPaymentConfirmationDialog(SubscriptionPlan plan) async {
    final codeController = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Confirmer le paiement'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Avez-vous effectué le paiement ?',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: codeController,
              decoration: const InputDecoration(
                labelText: 'Code de transaction (optionnel)',
                hintText: 'Ex: WV123456789',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.receipt),
              ),
              textCapitalization: TextCapitalization.characters,
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                children: [
                  Icon(Icons.timer, color: Colors.blue, size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Votre abonnement sera activé dans quelques minutes après vérification.',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Pas encore'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00A651),
            ),
            child: const Text('J\'ai payé'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _completePurchase(plan, codeController.text.trim());
    }
  }

  Future<void> _completePurchase(
      SubscriptionPlan plan,
      [String? transactionCode]) async {
    try {
      await ApiService.purchaseSubscription(
        planType: plan.type,
        paymentMethod: 'wave',
        phone: widget.driverProfile.phone.isNotEmpty
            ? widget.driverProfile.phone
            : null,
        autoRenew: false,
        transactionCode: transactionCode,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('✅ Demande d\'abonnement ${plan.name} enregistrée !'),
                const SizedBox(height: 4),
                const Text(
                  'En attente de validation...',
                  style: TextStyle(fontSize: 12),
                ),
              ],
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 4),
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
            const Padding(
              padding: EdgeInsets.only(bottom: 8),
              child: Text(
                'Orange Money et Free Money : bientôt. Wave et espèces disponibles.',
                style: TextStyle(fontSize: 13, color: Colors.grey),
              ),
            ),
            _buildPaymentOption('wave', 'Wave', enabled: true),
            _buildPaymentOption('cash', 'Espèces', enabled: true),
            _buildPaymentOption('orange_money', 'Orange Money', enabled: false),
            _buildPaymentOption('free_money', 'Free Money', enabled: false),
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

  Widget _buildPaymentOption(String value, String label, {bool enabled = true}) {
    final logoPath = _paymentLogos[value];
    return Opacity(
      opacity: enabled ? 1 : 0.55,
      child: ListTile(
        enabled: enabled,
        leading: logoPath != null
            ? Image.asset(
                logoPath,
                width: 28,
                height: 28,
                errorBuilder: (_, __, ___) =>
                    const Icon(Icons.account_balance_wallet),
              )
            : Icon(
                value == 'cash' ? Icons.payments : Icons.account_balance_wallet,
                color: enabled ? null : Colors.grey,
              ),
        title: Text(label),
        subtitle: enabled
            ? null
            : const Text('Indisponible pour le moment'),
        trailing:
            enabled ? null : const Icon(Icons.lock_outline, color: Colors.grey),
        onTap: enabled ? () => Navigator.pop(context, value) : null,
      ),
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
        final bonusList = history['bonusHistory'];
        final bonuses = bonusList is List ? bonusList : <dynamic>[];
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Historique des Bonus'),
            content: SizedBox(
              width: double.maxFinite,
              height: 300,
              child: ListView.builder(
                itemCount: bonuses.length,
                itemBuilder: (context, index) {
                  final bonus = bonuses[index] as Map<String, dynamic>;
                  return ListTile(
                    leading: Icon(
                      bonus['type'] == 'free_subscription'
                          ? Icons.card_giftcard
                          : Icons.monetization_on,
                      color: Colors.orange,
                    ),
                    title: Text(bonus['description'] as String),
                    subtitle: Text(_formatDate(DateTime.parse(bonus['date'] as String))),
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
        _showErrorDialog(
            'Erreur', 'Impossible de charger l\'historique des bonus');
      }
    }
  }
}
