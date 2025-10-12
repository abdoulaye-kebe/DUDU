import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';

class DriverDashboardScreen extends StatefulWidget {
  const DriverDashboardScreen({Key? key}) : super(key: key);

  @override
  State<DriverDashboardScreen> createState() => _DriverDashboardScreenState();
}

class _DriverDashboardScreenState extends State<DriverDashboardScreen> {
  GoogleMapController? _mapController;
  Position? _currentPosition;
  final Set<Marker> _markers = {};
  
  // État du chauffeur
  bool _isOnline = false;
  bool _isLoading = true;
  
  // Forfait
  String _currentPlanType = 'daily';
  DateTime _planEndDate = DateTime.now().add(const Duration(days: 5));
  
  // Revenus (AUCUNE COMMISSION DÉDUITE)
  double _todayEarnings = 15750;
  double _weeklyEarnings = 87500;
  double _monthlyEarnings = 342000;
  
  // Statistiques
  int _todayRides = 12;
  int _weeklyRides = 68;
  double _averageRating = 4.8;
  
  // Demandes de courses en attente
  List<Map<String, dynamic>> _pendingRides = [];

  @override
  void initState() {
    super.initState();
    _initializeScreen();
  }

  Future<void> _initializeScreen() async {
    await _getCurrentLocation();
    await _loadDriverData();
    _listenForRideRequests();
    setState(() => _isLoading = false);
  }

  Future<void> _getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception('Services de localisation désactivés');
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      Position position = await Geolocator.getCurrentPosition();
      setState(() {
        _currentPosition = position;
      });
    } catch (e) {
      print('Erreur localisation: $e');
    }
  }

  Future<void> _loadDriverData() async {
    // TODO: Charger les données depuis l'API
    // Données de démonstration
  }

  void _listenForRideRequests() {
    // TODO: Écouter les demandes via Socket.IO
    // Simulation
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted && _isOnline) {
        setState(() {
          _pendingRides.add({
            'id': '1',
            'pickup': 'Almadies',
            'destination': 'Plateau',
            'price': 3500,
            'distance': '8.5 km',
            'passenger': 'Fatou Diop',
            'timestamp': DateTime.now(),
          });
        });
        _showRideRequestNotification(_pendingRides.last);
      }
    });
  }

  void _showRideRequestNotification(Map<String, dynamic> ride) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => RideRequestDialog(
        ride: ride,
        onAccept: () {
          Navigator.pop(context);
          _acceptRide(ride);
        },
        onReject: () {
          Navigator.pop(context);
          _rejectRide(ride);
        },
      ),
    );
  }

  void _acceptRide(Map<String, dynamic> ride) {
    // TODO: Accepter la course via l'API
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Course acceptée! Prix: ${ride['price']} FCFA'),
        backgroundColor: Colors.green,
      ),
    );
    
    setState(() {
      _pendingRides.removeWhere((r) => r['id'] == ride['id']);
    });
  }

  void _rejectRide(Map<String, dynamic> ride) {
    setState(() {
      _pendingRides.removeWhere((r) => r['id'] == ride['id']);
    });
  }

  void _toggleOnlineStatus() {
    // Vérifier si le forfait est actif
    if (!_isOnline && _planEndDate.isBefore(DateTime.now())) {
      _showSubscriptionExpiredDialog();
      return;
    }

    setState(() {
      _isOnline = !_isOnline;
    });

    if (_isOnline) {
      _listenForRideRequests();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vous êtes maintenant en ligne'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vous êtes maintenant hors ligne'),
          backgroundColor: Colors.grey,
        ),
      );
    }
  }

  void _showSubscriptionExpiredDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Forfait expiré'),
        content: const Text('Votre forfait a expiré. Veuillez renouveler votre abonnement pour continuer à recevoir des courses.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Plus tard'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _showSubscriptionPlans();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00A651),
            ),
            child: const Text('Renouveler', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showSubscriptionPlans() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => SubscriptionPlansSheet(
        onPlanSelected: (planType, price) {
          Navigator.pop(context);
          _processPlanPayment(planType, price);
        },
      ),
    );
  }

  void _processPlanPayment(String planType, int price) {
    // TODO: Intégrer le paiement mobile money
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Paiement du forfait'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Forfait: ${_getPlanName(planType)}'),
            Text('Prix: $price FCFA', style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            const Text('Choisissez votre mode de paiement:'),
            const SizedBox(height: 16),
            // Options de paiement
            ..._buildPaymentOptions(),
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

  List<Widget> _buildPaymentOptions() {
    return [
      ListTile(
        leading: const Icon(Icons.payment, color: Colors.orange),
        title: const Text('Orange Money'),
        onTap: () => _processPayment('orange_money'),
      ),
      ListTile(
        leading: const Icon(Icons.payment, color: Colors.blue),
        title: const Text('Wave'),
        onTap: () => _processPayment('wave'),
      ),
      ListTile(
        leading: const Icon(Icons.payment, color: Colors.red),
        title: const Text('Free Money'),
        onTap: () => _processPayment('free_money'),
      ),
    ];
  }

  void _processPayment(String method) {
    // TODO: Traiter le paiement
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Paiement en cours de traitement...'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  String _getPlanName(String planType) {
    switch (planType) {
      case 'daily':
        return 'Journalier';
      case 'weekly':
        return 'Hebdomadaire';
      case 'monthly':
        return 'Mensuel';
      case 'yearly':
        return 'Annuel';
      default:
        return planType;
    }
  }

  int _getDaysRemaining() {
    return _planEndDate.difference(DateTime.now()).inDays;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      body: Stack(
        children: [
          // Carte Google Maps
          if (_currentPosition != null)
            GoogleMap(
              initialCameraPosition: CameraPosition(
                target: LatLng(
                  _currentPosition!.latitude,
                  _currentPosition!.longitude,
                ),
                zoom: 14,
              ),
              markers: _markers,
              myLocationEnabled: true,
              myLocationButtonEnabled: false,
              zoomControlsEnabled: false,
              onMapCreated: (controller) {
                _mapController = controller;
              },
            ),
          
          // Interface par-dessus la carte
          SafeArea(
            child: Column(
              children: [
                // En-tête avec statut
                _buildHeader(),
                
                const Spacer(),
                
                // Statistiques du jour
                _buildDailyStats(),
                
                // Bouton En ligne/Hors ligne
                _buildOnlineToggle(),
              ],
            ),
          ),
        ],
      ),
      drawer: _buildDrawer(),
    );
  }

  Widget _buildHeader() {
    final daysRemaining = _getDaysRemaining();
    final bool isExpiringSoon = daysRemaining <= 3;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Menu burger
          IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
          
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: _isOnline ? Colors.green : Colors.grey,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _isOnline ? 'En ligne' : 'Hors ligne',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                // Indicateur de forfait
                Row(
                  children: [
                    Icon(
                      Icons.calendar_today,
                      size: 14,
                      color: isExpiringSoon ? Colors.red : Colors.grey,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Forfait ${_getPlanName(_currentPlanType)}: $daysRemaining jours restants',
                      style: TextStyle(
                        fontSize: 12,
                        color: isExpiringSoon ? Colors.red : Colors.grey[600],
                        fontWeight: isExpiringSoon ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Bouton renouveler si proche de l'expiration
          if (isExpiringSoon)
            ElevatedButton(
              onPressed: _showSubscriptionPlans,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              child: const Text(
                'Renouveler',
                style: TextStyle(fontSize: 12, color: Colors.white),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDailyStats() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          const Text(
            'Aujourd\'hui',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Column(
                  children: [
                    const Icon(Icons.attach_money, color: Color(0xFF00A651), size: 32),
                    const SizedBox(height: 8),
                    Text(
                      '${NumberFormat('#,###').format(_todayEarnings)} FCFA',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF00A651),
                      ),
                    ),
                    const Text(
                      'Revenus',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    const Text(
                      '100% pour vous!',
                      style: TextStyle(
                        fontSize: 10,
                        color: Color(0xFF00A651),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 1,
                height: 60,
                color: Colors.grey[300],
              ),
              Expanded(
                child: Column(
                  children: [
                    const Icon(Icons.directions_car, color: Color(0xFF00A651), size: 32),
                    const SizedBox(height: 8),
                    Text(
                      '$_todayRides',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF00A651),
                      ),
                    ),
                    const Text(
                      'Courses',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),
              Container(
                width: 1,
                height: 60,
                color: Colors.grey[300],
              ),
              Expanded(
                child: Column(
                  children: [
                    const Icon(Icons.star, color: Colors.amber, size: 32),
                    const SizedBox(height: 8),
                    Text(
                      _averageRating.toString(),
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.amber,
                      ),
                    ),
                    const Text(
                      'Note',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOnlineToggle() {
    return Container(
      margin: const EdgeInsets.all(16),
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _toggleOnlineStatus,
        style: ElevatedButton.styleFrom(
          backgroundColor: _isOnline ? Colors.grey : const Color(0xFF00A651),
          padding: const EdgeInsets.symmetric(vertical: 20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Text(
          _isOnline ? 'SE METTRE HORS LIGNE' : 'SE METTRE EN LIGNE',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(
              color: Color(0xFF00A651),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.white,
                  child: Icon(Icons.person, size: 40, color: Color(0xFF00A651)),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Mamadou Diallo',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Forfait ${_getPlanName(_currentPlanType)}',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.dashboard),
            title: const Text('Tableau de bord'),
            onTap: () => Navigator.pop(context),
          ),
          ListTile(
            leading: const Icon(Icons.history),
            title: const Text('Historique des courses'),
            onTap: () {
              Navigator.pop(context);
              // TODO: Navigation vers l'historique
            },
          ),
          ListTile(
            leading: const Icon(Icons.attach_money),
            title: const Text('Revenus'),
            subtitle: Text('${NumberFormat('#,###').format(_monthlyEarnings)} FCFA ce mois'),
            onTap: () {
              Navigator.pop(context);
              // TODO: Navigation vers les revenus
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.card_membership, color: Color(0xFF00A651)),
            title: const Text('Gérer mon forfait'),
            onTap: () {
              Navigator.pop(context);
              _showSubscriptionPlans();
            },
          ),
          ListTile(
            leading: const Icon(Icons.settings),
            title: const Text('Paramètres'),
            onTap: () {
              Navigator.pop(context);
              // TODO: Navigation vers les paramètres
            },
          ),
          ListTile(
            leading: const Icon(Icons.help),
            title: const Text('Aide & Support'),
            onTap: () {
              Navigator.pop(context);
              // TODO: Navigation vers l'aide
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.exit_to_app, color: Colors.red),
            title: const Text('Déconnexion'),
            onTap: () {
              // TODO: Déconnexion
            },
          ),
        ],
      ),
    );
  }
}

// Dialog pour les demandes de course
class RideRequestDialog extends StatefulWidget {
  final Map<String, dynamic> ride;
  final VoidCallback onAccept;
  final VoidCallback onReject;

  const RideRequestDialog({
    Key? key,
    required this.ride,
    required this.onAccept,
    required this.onReject,
  }) : super(key: key);

  @override
  State<RideRequestDialog> createState() => _RideRequestDialogState();
}

class _RideRequestDialogState extends State<RideRequestDialog> {
  int _remainingSeconds = 30;

  @override
  void initState() {
    super.initState();
    _startCountdown();
  }

  void _startCountdown() {
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (mounted) {
        setState(() {
          _remainingSeconds--;
        });
        if (_remainingSeconds == 0) {
          widget.onReject();
          return false;
        }
        return _remainingSeconds > 0;
      }
      return false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          const Icon(Icons.notifications_active, color: Color(0xFF00A651)),
          const SizedBox(width: 8),
          const Text('Nouvelle course'),
          const Spacer(),
          Text(
            '$_remainingSeconds s',
            style: TextStyle(
              fontSize: 16,
              color: _remainingSeconds <= 10 ? Colors.red : Colors.grey,
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.person, size: 20),
              const SizedBox(width: 8),
              Text(widget.ride['passenger']),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.location_on, color: Color(0xFF00A651), size: 20),
              const SizedBox(width: 8),
              Expanded(child: Text(widget.ride['pickup'])),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.flag, color: Colors.red, size: 20),
              const SizedBox(width: 8),
              Expanded(child: Text(widget.ride['destination'])),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.straighten, size: 20),
              const SizedBox(width: 8),
              Text(widget.ride['distance']),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF00A651).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Prix proposé:',
                  style: TextStyle(fontSize: 16),
                ),
                const SizedBox(width: 8),
                Text(
                  '${widget.ride['price']} FCFA',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF00A651),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            '100% pour vous, aucune commission!',
            style: TextStyle(
              fontSize: 12,
              color: Color(0xFF00A651),
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: widget.onReject,
          child: const Text('Refuser', style: TextStyle(color: Colors.grey)),
        ),
        ElevatedButton(
          onPressed: widget.onAccept,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF00A651),
          ),
          child: const Text('Accepter', style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }
}

// Sheet pour les plans d'abonnement
class SubscriptionPlansSheet extends StatelessWidget {
  final Function(String planType, int price) onPlanSelected;

  const SubscriptionPlansSheet({
    Key? key,
    required this.onPlanSelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Choisissez votre forfait',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildPlanCard(
                  context,
                  'Journalier',
                  2000,
                  '24 heures d\'accès',
                  'daily',
                  Icons.today,
                ),
                _buildPlanCard(
                  context,
                  'Hebdomadaire',
                  12000,
                  '7 jours d\'accès',
                  'weekly',
                  Icons.view_week,
                  discount: '14% d\'économie',
                ),
                _buildPlanCard(
                  context,
                  'Mensuel',
                  40000,
                  '30 jours d\'accès',
                  'monthly',
                  Icons.calendar_month,
                  discount: '33% d\'économie',
                  isPopular: true,
                ),
                _buildPlanCard(
                  context,
                  'Annuel',
                  400000,
                  '365 jours d\'accès',
                  'yearly',
                  Icons.calendar_today,
                  discount: '45% d\'économie + 2 mois gratuits',
                  isBestValue: true,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlanCard(
    BuildContext context,
    String name,
    int price,
    String description,
    String planType,
    IconData icon, {
    String? discount,
    bool isPopular = false,
    bool isBestValue = false,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: isPopular || isBestValue ? 8 : 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isPopular || isBestValue ? const Color(0xFF00A651) : Colors.transparent,
          width: 2,
        ),
      ),
      child: InkWell(
        onTap: () => onPlanSelected(planType, price),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, color: const Color(0xFF00A651), size: 32),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              name,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (isPopular) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
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
                            ],
                            if (isBestValue) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF00A651),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Text(
                                  'MEILLEURE OFFRE',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        Text(
                          description,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${NumberFormat('#,###').format(price)} FCFA',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF00A651),
                        ),
                      ),
                      if (discount != null)
                        Text(
                          discount,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.orange,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                    ],
                  ),
                  const Icon(Icons.arrow_forward_ios, color: Color(0xFF00A651)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

