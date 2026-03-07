import 'package:flutter/material.dart';
import '../themes/app_theme.dart';
import '../services/api_service.dart';
import '../models/ride.dart';

class RidesScreen extends StatefulWidget {
  const RidesScreen({super.key});

  @override
  State<RidesScreen> createState() => _RidesScreenState();
}

class _RidesScreenState extends State<RidesScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  String _selectedFilter = 'all';
  
  // Données réelles depuis l'API
  List<Ride> _ongoingRides = [];
  List<Ride> _completedRides = [];
  List<Ride> _cancelledRides = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadRides();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadRides() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Charger les courses en cours (in_progress, accepted, started)
      final ongoingResponse = await ApiService.getUserRides(status: 'in_progress', limit: 50);
      final acceptedResponse = await ApiService.getUserRides(status: 'accepted', limit: 50);
      final startedResponse = await ApiService.getUserRides(status: 'started', limit: 50);
      
      // Charger les courses terminées
      final completedResponse = await ApiService.getUserRides(status: 'completed', limit: 50);
      
      // Charger les courses annulées
      final cancelledResponse = await ApiService.getUserRides(status: 'cancelled', limit: 50);

      if (!mounted) return;
      setState(() {
        _ongoingRides = [
          ...(ongoingResponse.data?['rides'] as List<Ride>? ?? []),
          ...(acceptedResponse.data?['rides'] as List<Ride>? ?? []),
          ...(startedResponse.data?['rides'] as List<Ride>? ?? []),
        ];
        _completedRides = completedResponse.data?['rides'] as List<Ride>? ?? [];
        _cancelledRides = cancelledResponse.data?['rides'] as List<Ride>? ?? [];
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Bouton flottant Accueil
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).popUntil((route) => route.isFirst);
        },
        backgroundColor: AppTheme.primaryColor,
        child: const Icon(Icons.home, color: Colors.white),
        tooltip: 'Accueil',
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.startFloat,
      appBar: AppBar(
        title: const Text('Mes courses'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'En cours'),
            Tab(text: 'Terminées'),
            Tab(text: 'Annulées'),
          ],
        ),
      ),
      body: Container(
        color: Colors.white,
        child: SafeArea(
          child: Column(
            children: [
              // Filtres
              Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Filtres',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        _buildFilterChip('Toutes', 'all'),
                        const SizedBox(width: 8),
                        _buildFilterChip('Cette semaine', 'week'),
                        const SizedBox(width: 8),
                        _buildFilterChip('Ce mois', 'month'),
                      ],
                    ),
                  ],
                ),
              ),
              // Liste des courses
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildRidesList('ongoing'),
                    _buildRidesList('completed'),
                    _buildRidesList('cancelled'),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _selectedFilter == value;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _selectedFilter = value;
        });
      },
      selectedColor: AppTheme.primaryColor.withOpacity(0.2),
      checkmarkColor: AppTheme.primaryColor,
      labelStyle: TextStyle(
        color: isSelected ? AppTheme.primaryColor : Colors.grey[600],
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }

  Widget _buildRidesList(String status) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text('Erreur: $_error'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadRides,
              child: const Text('Réessayer'),
            ),
          ],
        ),
      );
    }
    
    final List<Ride> rides;
    switch (status) {
      case 'ongoing':
        rides = _ongoingRides;
        break;
      case 'completed':
        rides = _completedRides;
        break;
      case 'cancelled':
        rides = _cancelledRides;
        break;
      default:
        rides = [];
    }
    
    if (rides.isEmpty) {
      return Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.directions_car_outlined,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'Aucune course ${status == 'ongoing' ? 'en cours' : status == 'completed' ? 'terminée' : 'annulée'}',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              status == 'ongoing' 
                  ? 'Vos courses en cours apparaîtront ici'
                  : status == 'completed'
                      ? 'Vos courses terminées apparaîtront ici'
                      : 'Vos courses annulées apparaîtront ici',
              style: TextStyle(
                color: Colors.grey[500],
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: rides.length,
      itemBuilder: (context, index) {
        final ride = rides[index];
        return _buildRideCard(ride);
      },
    );
  }

  Widget _buildRideCard(Ride ride) {
    final statusStr = ride.status.name;
    final dateStr = _formatDate(ride.requestedAt);
    final driverName = ride.driver?.firstName ?? 'Chauffeur';
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // En-tête de la course
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _getStatusColorFromRide(ride.status).withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: _getStatusColorFromRide(ride.status),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Icon(
                    _getStatusIconFromRide(ride.status),
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        driverName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        dateStr,
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getStatusColorFromRide(ride.status),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _getStatusTextFromRide(ride.status),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Détails de la course
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Trajet
                Row(
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: const BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        ride.pickup.address,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Container(
                  margin: const EdgeInsets.only(left: 5),
                  width: 2,
                  height: 20,
                  color: Colors.grey[300],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        ride.destination.address,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Informations supplémentaires
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildInfoItem(
                      'Distance',
                      '${ride.distance.toStringAsFixed(1)} km',
                      Icons.straighten,
                    ),
                    _buildInfoItem(
                      'Durée',
                      '${ride.estimatedDuration} min',
                      Icons.access_time,
                    ),
                    _buildInfoItem(
                      'Prix',
                      '${ride.pricing.totalPrice.toStringAsFixed(0)} FCFA',
                      Icons.monetization_on,
                    ),
                  ],
                ),
                // Actions pour courses en cours
                if (ride.status == RideStatus.started || 
                    ride.status == RideStatus.accepted ||
                    ride.status == RideStatus.started) ...[
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            _showTrackRideDialogNew(ride);
                          },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppTheme.primaryColor,
                            side: BorderSide(color: AppTheme.primaryColor),
                          ),
                          child: const Text('Suivre'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            // Action pour annuler la course
                            _showCancelRideDialogNew(ride);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('Annuler'),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: AppTheme.primaryColor, size: 16),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    final months = ['Jan', 'Fév', 'Mar', 'Avr', 'Mai', 'Juin', 'Juil', 'Août', 'Sep', 'Oct', 'Nov', 'Déc'];
    return '${date.day} ${months[date.month - 1]} ${date.year}, ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  Color _getStatusColorFromRide(RideStatus status) {
    switch (status) {
      case RideStatus.accepted:
      case RideStatus.started:
      case RideStatus.arriving:
      case RideStatus.arrived:
        return Colors.blue;
      case RideStatus.completed:
        return Colors.green;
      case RideStatus.cancelled:
        return Colors.red;
      default:
        return Colors.orange;
    }
  }

  IconData _getStatusIconFromRide(RideStatus status) {
    switch (status) {
      case RideStatus.accepted:
      case RideStatus.started:
      case RideStatus.arriving:
      case RideStatus.arrived:
        return Icons.directions_car;
      case RideStatus.completed:
        return Icons.check_circle;
      case RideStatus.cancelled:
        return Icons.cancel;
      default:
        return Icons.schedule;
    }
  }

  String _getStatusTextFromRide(RideStatus status) {
    switch (status) {
      case RideStatus.requested:
        return 'Demandée';
      case RideStatus.accepted:
        return 'Acceptée';
      case RideStatus.started:
        return 'En cours';
      case RideStatus.completed:
        return 'Terminée';
      case RideStatus.cancelled:
        return 'Annulée';
      default:
        return 'Inconnue';
    }
  }

  void _showTrackRideDialogNew(Ride ride) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Suivi de course'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Course ${ride.rideId}'),
            const SizedBox(height: 16),
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            const Text('Recherche de votre chauffeur...'),
          ],
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

  void _showCancelRideDialogNew(Ride ride) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Annuler la course'),
        content: const Text('Êtes-vous sûr de vouloir annuler cette course ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Non'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                final result = await ApiService.cancelRide(ride.id, 'Annulé par le client');
                if (result.success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Course annulée avec succès'),
                      backgroundColor: Colors.green,
                    ),
                  );
                  _loadRides(); // Recharger les courses
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(result.message),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Erreur: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Oui, annuler'),
          ),
        ],
      ),
    );
  }
}



