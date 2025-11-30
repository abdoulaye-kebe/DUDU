import 'package:flutter/material.dart';
import 'dart:async';
import 'package:url_launcher/url_launcher.dart';
import '../services/socket_service.dart';
/// Écran des demandes de courses en temps réel
/// Le chauffeur voit les demandes avec le PRIX LIBRE proposé par le client
class RideRequestsScreen extends StatefulWidget {
  const RideRequestsScreen({Key? key}) : super(key: key);

  @override
  State<RideRequestsScreen> createState() => _RideRequestsScreenState();
}

class _RideRequestsScreenState extends State<RideRequestsScreen> {
  final List<RideRequest> _pendingRequests = [];
  StreamSubscription<Map<String, dynamic>>? _rideRequestSub;
  StreamSubscription<String>? _rideClosedSub;
  Timer? _countdownTimer;

  @override
  void initState() {
    super.initState();
    // Charger les demandes déjà reçues mais non encore consultées
    final existingRequests = SocketService().currentRideRequests;
    for (final data in existingRequests) {
      final rideId = data['id']?.toString() ?? data['rideId']?.toString();
      if (rideId == null) continue;
      final request = RideRequest.fromSocketData(data);
      _pendingRequests.removeWhere((r) => r.id == rideId);
      _pendingRequests.add(request);
    }
    _subscribeToSocket();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _rideRequestSub?.cancel();
    _rideClosedSub?.cancel();
    _countdownTimer?.cancel();
    super.dispose();
  }

  void _subscribeToSocket() {
    final socketService = SocketService();

    _rideRequestSub = socketService.rideRequestsStream.listen((data) {
      setState(() {
        final rideId = data['id']?.toString() ?? data['rideId']?.toString();
        if (rideId == null) return;
        final existingIndex = _pendingRequests.indexWhere((r) => r.id == rideId);
        final request = RideRequest.fromSocketData(data);
        if (existingIndex >= 0) {
          _pendingRequests[existingIndex] = request;
        } else {
          _pendingRequests.add(request);
        }
      });
    });

    _rideClosedSub = socketService.rideClosedStream.listen((rideId) {
      if (rideId.isEmpty) return;
      setState(() {
        _pendingRequests.removeWhere((r) => r.id == rideId);
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Demandes de courses'),
        backgroundColor: const Color(0xFF0d5d36),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _pendingRequests.isEmpty
          ? _buildEmptyState()
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _pendingRequests.length,
              itemBuilder: (context, index) {
                return _buildRequestCard(_pendingRequests[index]);
              },
            ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inbox_outlined,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Aucune demande en attente',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Les nouvelles demandes apparaîtront ici',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRequestCard(RideRequest request) {
    final rideTypeColors = {
      'standard': const Color(0xFF0d5d36),
      'express': Colors.orange,
      'shared': Colors.blue,
      'women_only': Colors.pink,
    };

    final rideTypeLabels = {
      'standard': 'Standard',
      'express': 'Express',
      'shared': 'Covoiturage',
      'women_only': 'Femmes',
    };

    final color = rideTypeColors[request.rideType] ?? Colors.grey;
    final label = rideTypeLabels[request.rideType] ?? 'Standard';

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color, width: 2),
        ),
        child: Column(
          children: [
            // En-tête avec type et timer
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(14),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      label,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Icon(Icons.timer, color: color, size: 20),
                  const SizedBox(width: 4),
                  Text(
                    '${request.timeLeft}s',
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Nom du passager
                  Row(
                    children: [
                      const CircleAvatar(
                        radius: 20,
                        backgroundColor: Color(0xFF0d5d36),
                        child: Icon(
                          Icons.person,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          request.passengerName,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (request.passengerPhone != null && request.passengerPhone!.isNotEmpty) ...[
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.phone, color: Color(0xFF0d5d36)),
                          onPressed: () => _callPassenger(request.passengerPhone!),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Trajet
                  _buildLocationRow(
                    Icons.radio_button_checked,
                    Colors.green,
                    request.pickup,
                  ),
                  Padding(
                    padding: const EdgeInsets.only(left: 12),
                    child: Container(
                      width: 2,
                      height: 20,
                      color: Colors.grey[300],
                    ),
                  ),
                  _buildLocationRow(
                    Icons.place,
                    Colors.red,
                    request.destination,
                  ),

                  const SizedBox(height: 16),

                  // Infos course
                  Row(
                    children: [
                      _buildInfoChip(
                        Icons.route,
                        '${request.distance.toStringAsFixed(1)} km',
                      ),
                      const SizedBox(width: 8),
                      _buildInfoChip(
                        Icons.access_time,
                        '~${request.estimatedDuration} min',
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // PRIX LIBRE - Le plus important !
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10b981).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFF10b981),
                        width: 2,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.payments,
                              color: Color(0xFF0d5d36),
                              size: 28,
                            ),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Prix proposé',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                ),
                                Text(
                                  '${request.customPrice} FCFA',
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF0d5d36),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const Icon(
                          Icons.info_outline,
                          color: Colors.grey,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Bouton VOIP
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        SocketService().startVoipCall(request.id);
                      },
                      icon: const Icon(Icons.wifi_calling_3),
                      label: const Text('Appel VOIP (BETA)'),
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Boutons ACCEPTER / REFUSER
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => _refuseRide(request.id),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.grey[300],
                            foregroundColor: Colors.black87,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                          child: const Text(
                            'REFUSER',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton(
                          onPressed: () => _acceptRide(request.id),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0d5d36),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 2,
                          ),
                          child: const Text(
                            'ACCEPTER',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationRow(IconData icon, Color color, String text) {
    return Row(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoChip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Colors.grey[700]),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[700],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _callPassenger(String phone) async {
    final uri = Uri(scheme: 'tel', path: phone);
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Impossible de lancer l\'appel')), 
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors de l\'appel: $e')),
      );
    }
  }

  Future<void> _acceptRide(String rideId) async {
    try {
      await SocketService().acceptRide(rideId);
      setState(() {
        _pendingRequests.removeWhere((r) => r.id == rideId);
        SocketService().removeRideRequest(rideId);
      });
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('✅ Course acceptée'),
          content: const Text(
            'Navigation vers le client...\n\n'
            'Le client a été notifié de votre acceptation.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pop(context);
              },
              child: const Text('OK'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors de l\'acceptation: $e')),
      );
    }
  }

  void _refuseRide(String rideId) {
    setState(() {
      _pendingRequests.removeWhere((r) => r.id == rideId);
      SocketService().removeRideRequest(rideId);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Course refusée')),
    );
  }
}

class RideRequest {
  final String id;
  final String passengerName;
  final String? passengerPhone;
  final String pickup;
  final String destination;
  final double distance;
  final int customPrice;
  final String rideType;
  final int estimatedDuration;
  final DateTime requestedAt;
  final int expiresInSeconds;

  RideRequest({
    required this.id,
    required this.passengerName,
    this.passengerPhone,
    required this.pickup,
    required this.destination,
    required this.distance,
    required this.customPrice,
    required this.rideType,
    required this.estimatedDuration,
    required this.requestedAt,
    required this.expiresInSeconds,
  });

  int get timeLeft {
    final expiry = requestedAt.add(Duration(seconds: expiresInSeconds));
    final remaining = expiry.difference(DateTime.now());
    return remaining.isNegative ? 0 : remaining.inSeconds;
  }

  factory RideRequest.fromSocketData(Map<String, dynamic> data) {
    final pickupRaw = data['pickup'];
    final destinationRaw = data['destination'];
    final pricing = data['pricing'] ?? {};
    final passenger = data['passenger'] ?? {};
    final requestedAtRaw = data['requestedAt'];

    final requestId = data['id']?.toString() ?? data['rideId']?.toString() ?? '';

    DateTime requestedAt;
    if (requestedAtRaw is String) {
      requestedAt = DateTime.tryParse(requestedAtRaw)?.toUtc() ?? DateTime.now().toUtc();
    } else {
      requestedAt = DateTime.now().toUtc();
    }

    String pickupText;
    if (pickupRaw is Map) {
      pickupText = pickupRaw['address'] ??
          pickupRaw['label'] ??
          '${pickupRaw['latitude'] ?? ''}, ${pickupRaw['longitude'] ?? ''}';
    } else if (pickupRaw is String) {
      pickupText = pickupRaw;
    } else {
      pickupText = 'Point de départ';
    }

    String destinationText;
    if (destinationRaw is Map) {
      destinationText = destinationRaw['address'] ??
          destinationRaw['label'] ??
          '${destinationRaw['latitude'] ?? ''}, ${destinationRaw['longitude'] ?? ''}';
    } else if (destinationRaw is String) {
      destinationText = destinationRaw;
    } else {
      destinationText = 'Destination';
    }

    return RideRequest(
      id: requestId,
      passengerName: (data['passengerName']?.toString() ?? passenger['name']?.toString()) ?? 'Client DUDU',
      passengerPhone: data['passengerPhone']?.toString(),
      pickup: pickupText.toString(),
      destination: destinationText.toString(),
      distance: (pricing['distance'] ?? data['distance'] ?? 0).toDouble(),
      customPrice: pricing['customPrice']?.toInt() ??
          pricing['totalPrice']?.toInt() ??
          data['customPrice']?.toInt() ??
          0,
      rideType: data['rideType']?.toString() ?? 'standard',
      estimatedDuration: pricing['estimatedDuration']?.toInt() ??
          data['estimatedDuration']?.toInt() ??
          5,
      requestedAt: requestedAt,
      expiresInSeconds: 180,
    );
  }
}
