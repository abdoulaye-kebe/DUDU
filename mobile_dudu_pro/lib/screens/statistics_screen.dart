import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/driver_period_earnings.dart';
import '../models/driver_profile.dart';
import '../services/api_service.dart';

class StatisticsScreen extends StatefulWidget {
  final DriverProfile driverProfile;

  const StatisticsScreen({
    Key? key,
    required this.driverProfile,
  }) : super(key: key);

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  String _selectedPeriod = 'today';
  bool _loading = true;
  String? _error;
  final Map<String, DriverPeriodEarnings> _byPeriod = {};
  List<Map<String, dynamic>> _recentRides = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final futures = await Future.wait([
        ApiService.getDriverEarningsSummary(period: 'today'),
        ApiService.getDriverEarningsSummary(period: 'week'),
        ApiService.getDriverEarningsSummary(period: 'month'),
        ApiService.getDriverEarningsSummary(period: 'year'),
      ]);
      _byPeriod['today'] = DriverPeriodEarnings.fromApi(futures[0]);
      _byPeriod['week'] = DriverPeriodEarnings.fromApi(futures[1]);
      _byPeriod['month'] = DriverPeriodEarnings.fromApi(futures[2]);
      _byPeriod['year'] = DriverPeriodEarnings.fromApi(futures[3]);

      final ridesPayload = await ApiService.getDriverRidesList(page: 1, limit: 8);
      final raw = ridesPayload['rides'];
      _recentRides = [];
      if (raw is List) {
        for (final e in raw) {
          if (e is Map<String, dynamic>) {
            _recentRides.add(e);
          } else if (e is Map) {
            _recentRides.add(Map<String, dynamic>.from(e));
          }
        }
      }
    } catch (e) {
      _error = e.toString();
    }
    if (mounted) setState(() => _loading = false);
  }

  DriverPeriodEarnings? get _current => _byPeriod[_selectedPeriod];

  String _rideRoute(Map<String, dynamic> ride) {
    String addr(dynamic x) {
      if (x is Map && x['address'] != null) return x['address'].toString();
      return '—';
    }

    return '${addr(ride['pickup'])} → ${addr(ride['destination'])}';
  }

  String _ridePrice(Map<String, dynamic> ride) {
    final p = ride['pricing'];
    if (p is Map && p['totalPrice'] != null) {
      return '${(p['totalPrice'] as num).toStringAsFixed(0)} FCFA';
    }
    return '—';
  }

  String _rideTimeLabel(Map<String, dynamic> ride) {
    final raw = ride['completedAt'] ?? ride['requestedAt'];
    DateTime? dt;
    if (raw is String) dt = DateTime.tryParse(raw);
    if (dt == null) return '—';
    return DateFormat('dd/MM/yyyy HH:mm', 'fr_FR').format(dt.toLocal());
  }

  String _rideIdLabel(Map<String, dynamic> ride) {
    final id = ride['rideId']?.toString() ?? ride['id']?.toString() ?? '';
    if (id.isEmpty) return 'Course';
    return id.length > 12 ? '#${id.substring(id.length - 6)}' : '#$id';
  }

  @override
  Widget build(BuildContext context) {
    final accent = const Color(0xFF00A651);
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Statistiques ${widget.driverProfile.vehicleType.displayName}',
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: accent,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Actualiser',
            onPressed: _loading ? null : _load,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_loading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(child: CircularProgressIndicator()),
                ),
              if (_error != null && !_loading)
                Card(
                  color: Colors.red.shade50,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        Icon(Icons.error_outline, color: Colors.red.shade700),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _error!,
                            style: TextStyle(color: Colors.red.shade900, fontSize: 13),
                          ),
                        ),
                        TextButton(onPressed: _load, child: const Text('Réessayer')),
                      ],
                    ),
                  ),
                ),
              _buildPeriodSelector(accent),
              const SizedBox(height: 20),
              _buildMainStats(accent),
              const SizedBox(height: 20),
              _buildCharts(accent),
              const SizedBox(height: 20),
              _buildPeriodDetails(accent),
              const SizedBox(height: 20),
              if (widget.driverProfile.isMoto) ...[
                _buildBonusSection(accent),
                const SizedBox(height: 20),
              ],
              _buildRideHistory(accent),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPeriodSelector(Color accent) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Période',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildPeriodButton('today', 'Aujourd\'hui', accent),
                _buildPeriodButton('week', 'Cette semaine', accent),
                _buildPeriodButton('month', 'Ce mois', accent),
                _buildPeriodButton('year', 'Cette année', accent),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPeriodButton(String period, String label, Color accent) {
    final isSelected = _selectedPeriod == period;
    return GestureDetector(
      onTap: () => setState(() => _selectedPeriod = period),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? accent : Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Theme.of(context).colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  Widget _buildMainStats(Color accent) {
    final stats = widget.driverProfile.stats;
    final cur = _current;

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Statistiques principales',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    '🚗',
                    cur != null ? '${cur.rides}' : (_loading ? '…' : '—'),
                    'Courses',
                    Colors.blue,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    '💰',
                    cur != null ? _formatEarningsShort(cur.total) : (_loading ? '…' : '—'),
                    'Revenus (FCFA)',
                    Colors.green,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    '⭐',
                    stats.averageRating.toStringAsFixed(1),
                    'Note',
                    Colors.orange,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    '📏',
                    cur != null ? cur.distanceFormatted : (_loading ? '…' : '—'),
                    'Distance',
                    Colors.purple,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String icon, String value, String label, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(icon, style: const TextStyle(fontSize: 24)),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  String _formatEarningsShort(double v) {
    if (v >= 1000000) return '${(v / 1000000).toStringAsFixed(1)}M';
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(1)}k';
    return v.toStringAsFixed(0);
  }

  Widget _buildCharts(Color accent) {
    final values = [
      _byPeriod['today']?.total ?? 0,
      _byPeriod['week']?.total ?? 0,
      _byPeriod['month']?.total ?? 0,
      _byPeriod['year']?.total ?? 0,
    ];
    const labels = ['Auj.', 'Sem.', 'Mois', 'Année'];
    final maxVal = values.fold<double>(1.0, (a, b) => a > b ? a : b);
    final displayMax = maxVal < 1 ? 1.0 : maxVal;

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Revenus par période',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Données issues du serveur (courses terminées).',
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 140,
              width: double.infinity,
              child: CustomPaint(
                painter: _EarningsBarChartPainter(
                  values: values,
                  maxValue: displayMax,
                  barColor: accent,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: List.generate(labels.length, (i) {
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: Column(
                      children: [
                        Text(
                          _formatEarningsShort(values[i]),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: accent,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          labels[i],
                          style: TextStyle(
                            fontSize: 10,
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPeriodDetails(Color accent) {
    final cur = _current;
    final stats = widget.driverProfile.stats;

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Détails — ${_getPeriodLabel()}',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 16),
            _buildDetailRow(
              'Courses effectuées',
              cur != null ? '${cur.rides}' : (_loading ? '…' : '—'),
              accent,
            ),
            _buildDetailRow(
              'Revenus',
              cur != null ? cur.totalFormatted : (_loading ? '…' : '—'),
              accent,
            ),
            _buildDetailRow(
              'Temps de conduite (estimé)',
              cur != null ? cur.durationFormatted : (_loading ? '…' : '—'),
              accent,
            ),
            _buildDetailRow(
              'Distance parcourue',
              cur != null ? cur.distanceFormatted : (_loading ? '…' : '—'),
              accent,
            ),
            if (widget.driverProfile.isMoto) ...[
              _buildDetailRow(
                'Bonus cumulés (profil)',
                '${stats.bonusEarned.toStringAsFixed(0)} FCFA',
                accent,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, Color accent) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(child: Text(label, style: const TextStyle(fontSize: 14))),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: accent,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBonusSection(Color accent) {
    final bonus = widget.driverProfile.subscription?.weeklyBonus;

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
                  'Bonus hebdomadaires',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange.shade800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (bonus != null && bonus.hasBonus) ...[
              _buildDetailRow('Type de bonus', bonus.bonusDescription, accent),
              _buildDetailRow('Total gagné', '${bonus.amount.toStringAsFixed(0)} FCFA', accent),
              if (bonus.lastBonusDate != null)
                _buildDetailRow(
                  'Dernier bonus',
                  _formatDate(bonus.lastBonusDate!),
                  accent,
                ),
              const SizedBox(height: 12),
              TextButton.icon(
                onPressed: _showBonusHistory,
                icon: const Icon(Icons.history),
                label: const Text('Voir l\'historique complet'),
              ),
            ] else ...[
              Text(
                'Aucun bonus en cours sur le profil',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontStyle: FontStyle.italic,
                ),
              ),
              if ((widget.driverProfile.subscription?.id ?? '').isNotEmpty)
                TextButton.icon(
                  onPressed: _showBonusHistory,
                  icon: const Icon(Icons.history),
                  label: const Text('Historique bonus'),
                ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildRideHistory(Color accent) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Historique récent',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 16),
            if (_recentRides.isEmpty && !_loading)
              Text(
                'Aucune course à afficher',
                style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
              )
            else
              ..._recentRides.map(
                (r) => _buildRideItem(
                  _rideIdLabel(r),
                  _rideRoute(r),
                  _ridePrice(r),
                  _rideTimeLabel(r),
                  accent,
                ),
              ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => _showFullHistory(accent),
              child: const Text('Voir tout l\'historique'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRideItem(
    String id,
    String route,
    String price,
    String time,
    Color accent,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 8,
            height: 8,
            margin: const EdgeInsets.only(top: 6),
            decoration: BoxDecoration(
              color: accent,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  id,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
                Text(route, style: const TextStyle(fontSize: 14)),
                Text(
                  time,
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Text(
            price,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: accent,
            ),
          ),
        ],
      ),
    );
  }

  String _getPeriodLabel() {
    switch (_selectedPeriod) {
      case 'today':
        return 'Aujourd\'hui';
      case 'week':
        return 'Cette semaine';
      case 'month':
        return 'Ce mois';
      case 'year':
        return 'Cette année';
      default:
        return 'Aujourd\'hui';
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  void _showBonusHistory() {
    final sid = widget.driverProfile.subscription?.id ?? '';
    if (sid.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Abonnement non disponible')),
      );
      return;
    }
    showDialog<void>(
      context: context,
      builder: (ctx) => _BonusHistoryDialog(subscriptionId: sid),
    );
  }

  void _showFullHistory(Color accent) {
    showDialog<void>(
      context: context,
      builder: (ctx) => _DriverRidesHistoryDialog(accent: accent),
    );
  }
}

class _BonusHistoryDialog extends StatefulWidget {
  final String subscriptionId;

  const _BonusHistoryDialog({required this.subscriptionId});

  @override
  State<_BonusHistoryDialog> createState() => _BonusHistoryDialogState();
}

class _BonusHistoryDialogState extends State<_BonusHistoryDialog> {
  late Future<Map<String, dynamic>> _future;

  @override
  void initState() {
    super.initState();
    _future = ApiService.getBonusHistory(widget.subscriptionId);
  }

  String _typeLabel(String? t) {
    switch (t) {
      case 'free_subscription':
        return 'Abonnement offert';
      case 'cash_bonus':
        return 'Bonus espèces';
      default:
        return t ?? 'Bonus';
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Historique des bonus'),
      content: SizedBox(
        width: double.maxFinite,
        height: 320,
        child: FutureBuilder<Map<String, dynamic>>(
          future: _future,
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snap.hasError) {
              return Text('${snap.error}', style: const TextStyle(color: Colors.red));
            }
            final data = snap.data!;
            final raw = data['bonusHistory'];
            if (raw is! List || raw.isEmpty) {
              return const Center(child: Text('Aucun bonus enregistré'));
            }
            return ListView.builder(
              itemCount: raw.length,
              itemBuilder: (context, i) {
                final e = raw[i];
                if (e is! Map) return const SizedBox.shrink();
                final m = Map<String, dynamic>.from(e);
                final amount = (m['amount'] as num?)?.toDouble() ?? 0;
                final desc = m['description']?.toString() ?? _typeLabel(m['type']?.toString());
                DateTime? dt;
                final d = m['date'];
                if (d is String) dt = DateTime.tryParse(d);
                final dateStr = dt != null
                    ? DateFormat('dd/MM/yyyy', 'fr_FR').format(dt.toLocal())
                    : '—';
                return ListTile(
                  leading: const Icon(Icons.card_giftcard, color: Colors.orange),
                  title: Text(desc),
                  subtitle: Text(dateStr),
                  trailing: Text(
                    '${amount.toStringAsFixed(0)} FCFA',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                );
              },
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
    );
  }
}

class _DriverRidesHistoryDialog extends StatefulWidget {
  final Color accent;

  const _DriverRidesHistoryDialog({required this.accent});

  @override
  State<_DriverRidesHistoryDialog> createState() =>
      _DriverRidesHistoryDialogState();
}

class _DriverRidesHistoryDialogState extends State<_DriverRidesHistoryDialog> {
  final List<Map<String, dynamic>> _items = [];
  int _page = 1;
  bool _loading = false;
  bool _hasNext = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadMore();
  }

  Future<void> _loadMore() async {
    if (_loading || !_hasNext) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await ApiService.getDriverRidesList(page: _page, limit: 15);
      final raw = data['rides'];
      final List<Map<String, dynamic>> batch = [];
      if (raw is List) {
        for (final e in raw) {
          if (e is Map<String, dynamic>) {
            batch.add(e);
          } else if (e is Map) {
            batch.add(Map<String, dynamic>.from(e));
          }
        }
      }
      final pag = data['pagination'];
      bool hasNext = false;
      if (pag is Map && pag['hasNext'] == true) hasNext = true;

      if (mounted) {
        setState(() {
          _items.addAll(batch);
          _hasNext = hasNext;
          _page += 1;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
    }
  }

  String _rideRoute(Map<String, dynamic> ride) {
    String addr(dynamic x) {
      if (x is Map && x['address'] != null) return x['address'].toString();
      return '—';
    }

    return '${addr(ride['pickup'])} → ${addr(ride['destination'])}';
  }

  String _ridePrice(Map<String, dynamic> ride) {
    final p = ride['pricing'];
    if (p is Map && p['totalPrice'] != null) {
      return '${(p['totalPrice'] as num).toStringAsFixed(0)} FCFA';
    }
    return '—';
  }

  String _rideTimeLabel(Map<String, dynamic> ride) {
    final raw = ride['completedAt'] ?? ride['requestedAt'];
    DateTime? dt;
    if (raw is String) dt = DateTime.tryParse(raw);
    if (dt == null) return '—';
    return DateFormat('dd/MM/yyyy HH:mm', 'fr_FR').format(dt.toLocal());
  }

  String _rideIdLabel(Map<String, dynamic> ride) {
    final id = ride['rideId']?.toString() ?? ride['id']?.toString() ?? '';
    if (id.isEmpty) return 'Course';
    return id.length > 12 ? '#${id.substring(id.length - 6)}' : '#$id';
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Historique des courses'),
      content: SizedBox(
        width: double.maxFinite,
        height: 400,
        child: Column(
          children: [
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(_error!, style: const TextStyle(color: Colors.red, fontSize: 12)),
              ),
            Expanded(
              child: ListView.builder(
                itemCount: _items.length + (_hasNext ? 1 : 0),
                itemBuilder: (context, i) {
                  if (i >= _items.length) {
                    return Padding(
                      padding: const EdgeInsets.all(16),
                      child: Center(
                        child: _loading
                            ? const CircularProgressIndicator()
                            : TextButton(
                                onPressed: _loadMore,
                                child: const Text('Charger plus'),
                              ),
                      ),
                    );
                  }
                  final r = _items[i];
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          margin: const EdgeInsets.only(top: 6),
                          decoration: BoxDecoration(
                            color: widget.accent,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _rideIdLabel(r),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                              Text(_rideRoute(r), style: const TextStyle(fontSize: 13)),
                              Text(
                                _rideTimeLabel(r),
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          _ridePrice(r),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: widget.accent,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Fermer'),
        ),
      ],
    );
  }
}

/// Histogramme simple des revenus (sans dépendance tierce).
class _EarningsBarChartPainter extends CustomPainter {
  final List<double> values;
  final double maxValue;
  final Color barColor;

  _EarningsBarChartPainter({
    required this.values,
    required this.maxValue,
    required this.barColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final n = values.length;
    if (n == 0) return;

    final paint = Paint()
      ..color = barColor
      ..style = PaintingStyle.fill;

    final gap = size.width / n;
    final barW = gap * 0.45;
    const bottomPad = 8.0;
    final chartH = size.height - bottomPad;

    for (var i = 0; i < n; i++) {
      final h = (values[i] / maxValue) * chartH;
      final left = gap * i + (gap - barW) / 2;
      final top = chartH - h;
      final r = RRect.fromRectAndRadius(
        Rect.fromLTWH(left, top, barW, h),
        const Radius.circular(6),
      );
      canvas.drawRRect(r, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _EarningsBarChartPainter oldDelegate) {
    return oldDelegate.values != values ||
        oldDelegate.maxValue != maxValue ||
        oldDelegate.barColor != barColor;
  }
}
