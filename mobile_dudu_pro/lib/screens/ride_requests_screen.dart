import 'package:flutter/material.dart';
import 'dart:async';
import 'package:url_launcher/url_launcher.dart';
import '../services/api_service.dart';
import '../services/socket_service.dart';
import '../widgets/driver_counter_offer_section.dart';
import 'active_ride_screen.dart';
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
  StreamSubscription<Map<String, dynamic>>? _counterOfferSub;
  Timer? _countdownTimer;
  /// Demandes où une contre-proposition vient d’être envoyée (attente client).
  final Set<String> _pendingCounterOfferRideIds = {};

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
    _counterOfferSub =
        SocketService().counterOfferPassengerResponseStream.listen(_onCounterOfferResponse);
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _rideRequestSub?.cancel();
    _rideClosedSub?.cancel();
    _counterOfferSub?.cancel();
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
        _pendingCounterOfferRideIds.remove(rideId);
      });
    });
  }

  void _onCounterOfferResponse(Map<String, dynamic> data) {
    final rideId = data['rideId']?.toString();
    if (rideId == null || rideId.isEmpty) return;

    final accepted = data['accepted'] == true;
    final idx = _pendingRequests.indexWhere((r) => r.id == rideId);
    if (idx < 0) return;

    final pricing = data['pricing'];
    if (accepted && pricing is Map) {
      final total = (pricing['totalPrice'] as num?)?.round();
      if (total != null) {
        final prev = _pendingRequests[idx];
        _pendingRequests[idx] = prev.copyWith(customPrice: total);
        SocketService().patchRideRequestPricing(rideId, total);
      }
    }

    setState(() {
      _pendingCounterOfferRideIds.remove(rideId);
    });

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          accepted
              ? 'Le client a accepté le nouveau prix (${data['pricing']?['totalPrice'] ?? ''} FCFA). Vous pouvez accepter la course.'
              : 'Le client a refusé la proposition — le prix initial reste affiché.',
        ),
        duration: const Duration(seconds: 5),
      ),
    );
  }

  Future<void> _submitCounterOffer(RideRequest request, int additionalAmount) async {
    try {
      await ApiService.submitCounterOffer(request.id, additionalAmount);
      if (!mounted) return;
      setState(() {
        _pendingCounterOfferRideIds.add(request.id);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Proposition envoyée au client. En attente de sa réponse…'),
          duration: Duration(seconds: 4),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      final msg = e.toString().replaceFirst('Exception: ', '');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg)),
      );
    }
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
      'comfort': Colors.orange,
      'women_only': Colors.pink,
      'delivery': Colors.deepOrange,
      'luxe': Colors.black,
      'moto': Colors.blueGrey,
      // Alias / rétrocompat
      'express': Colors.orange,
    };

    final rideTypeLabels = {
      'standard': 'Standard',
      'comfort': 'Confort',
      'women_only': 'Femme',
      'delivery': 'Livraison',
      'luxe': 'Luxe',
      'moto': 'Moto',
      'express': 'Confort',
    };

    final rawType = request.rideType;
    final normalizedType = rawType == 'express' ? 'comfort' : rawType;
    final color = rideTypeColors[normalizedType] ??
        rideTypeColors[rawType] ??
        Colors.grey;
    final label = rideTypeLabels[normalizedType] ??
        rideTypeLabels[rawType] ??
        'Course';

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
              child: Column(
                children: [
                  Row(
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
                      if (request.isUrgentDelivery &&
                          (normalizedType == 'delivery' || rawType == 'delivery')) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.red.shade700,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text(
                            'URGENT',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                            ),
                          ),
                        ),
                      ],
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
                  if (request.scheduledFor != null) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.orange, width: 1),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.schedule, color: Colors.orange, size: 16),
                          const SizedBox(width: 6),
                          Text(
                            request.scheduledTimeText,
                            style: const TextStyle(
                              color: Colors.orange,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
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
                                if (request.customPricePerKm != null)
                                  Text(
                                    '${request.customPricePerKm!.toStringAsFixed(0)} FCFA/km',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.grey[700],
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

                  DriverCounterOfferSection(
                    isBusy: _pendingCounterOfferRideIds.contains(request.id),
                    onDeltaPressed: (d) => _submitCounterOffer(request, d),
                  ),
                  const SizedBox(height: 12),

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
                            'Refuser la course',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton(
                          onPressed: _pendingCounterOfferRideIds.contains(request.id)
                              ? null
                              : () => _acceptRide(request.id),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0d5d36),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 2,
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.check_circle_outline, size: 20),
                              SizedBox(width: 8),
                              Text(
                                'Accepter la course',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ],
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
      final request = _pendingRequests.firstWhere((r) => r.id == rideId);
      final socketSnapshot = SocketService().currentRideRequests.firstWhere(
        (r) => (r['id']?.toString() ?? r['rideId']?.toString()) == rideId,
        orElse: () => <String, dynamic>{},
      );

      await SocketService().acceptRide(rideId);

      Map<String, dynamic> rideData =
          Map<String, dynamic>.from(socketSnapshot);
      final details = await ApiService.getRideDetails(rideId);
      final data = details?['data'];
      final rideObj = data is Map ? data['ride'] : null;
      if (rideObj is Map<String, dynamic>) {
        rideData = ActiveRideScreen.ridePayloadFromApiRide(rideObj);
      }

      setState(() {
        _pendingRequests.removeWhere((r) => r.id == rideId);
        SocketService().removeRideRequest(rideId);
      });

      if (!mounted) return;

      final route = MaterialPageRoute<void>(
        builder: (context) => ActiveRideScreen(
          rideId: rideId,
          rideData: rideData,
        ),
      );
      // Livraison : empiler les écrans pour pouvoir gérer 2 courses (comme Yango)
      final isDelivery = request.rideType == 'delivery';
      if (isDelivery) {
        Navigator.push(context, route);
      } else {
        Navigator.pushReplacement(context, route);
      }
    } catch (e) {
      if (!mounted) return;
      final msg = e.toString().replaceFirst('Exception: ', '');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg)),
      );
    }
  }

  void _refuseRide(String rideId) {
    SocketService().refuseRide(rideId);
    setState(() {
      _pendingRequests.removeWhere((r) => r.id == rideId);
      SocketService().removeRideRequest(rideId);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Course refusée — le client est informé')),
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
  final double? customPricePerKm;
  final String rideType;
  final int estimatedDuration;
  final DateTime requestedAt;
  final int expiresInSeconds;
  final DateTime? scheduledFor;
  final String scheduledTimeText;
  final bool isUrgentDelivery;

  RideRequest({
    required this.id,
    required this.passengerName,
    this.passengerPhone,
    required this.pickup,
    required this.destination,
    required this.distance,
    required this.customPrice,
    this.customPricePerKm,
    required this.rideType,
    required this.estimatedDuration,
    required this.requestedAt,
    required this.expiresInSeconds,
    this.scheduledFor,
    this.scheduledTimeText = '',
    this.isUrgentDelivery = false,
  });

  int get timeLeft {
    final expiry = requestedAt.add(Duration(seconds: expiresInSeconds));
    final remaining = expiry.difference(DateTime.now());
    return remaining.isNegative ? 0 : remaining.inSeconds;
  }

  RideRequest copyWith({int? customPrice}) {
    return RideRequest(
      id: id,
      passengerName: passengerName,
      passengerPhone: passengerPhone,
      pickup: pickup,
      destination: destination,
      distance: distance,
      customPrice: customPrice ?? this.customPrice,
      customPricePerKm: customPricePerKm,
      rideType: rideType,
      estimatedDuration: estimatedDuration,
      requestedAt: requestedAt,
      expiresInSeconds: expiresInSeconds,
      scheduledFor: scheduledFor,
      scheduledTimeText: scheduledTimeText,
      isUrgentDelivery: isUrgentDelivery,
    );
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

    // Parse scheduled ride data
    DateTime? scheduledFor;
    String scheduledTimeText = '';
    
    if (data['scheduledFor'] != null) {
      try {
        scheduledFor = DateTime.parse(data['scheduledFor'].toString());
        final now = DateTime.now();
        final difference = scheduledFor.difference(now);
        
        if (difference.inMinutes < 60) {
          scheduledTimeText = 'Dans ${difference.inMinutes} min';
        } else if (difference.inHours < 24) {
          scheduledTimeText = 'Dans ${difference.inHours}h';
        } else {
          scheduledTimeText = 'Le ${scheduledFor.day}/${scheduledFor.month} à ${scheduledFor.hour}:${scheduledFor.minute.toString().padLeft(2, '0')}';
        }
      } catch (e) {
        scheduledTimeText = 'Planifiée';
      }
    }

    int toInt(dynamic v, int fallback) {
      if (v == null) return fallback;
      if (v is int) return v;
      if (v is num) return v.toInt();
      if (v is String) return int.tryParse(v) ?? fallback;
      return fallback;
    }
    double toDoubleSafe(dynamic v) {
      if (v == null) return 0;
      if (v is num) return v.toDouble();
      if (v is String) return double.tryParse(v) ?? 0;
      return 0;
    }

    bool parseBool(dynamic v) {
      if (v == true) return true;
      if (v == false || v == null) return false;
      if (v is String) return v == 'true' || v == '1';
      return false;
    }

    return RideRequest(
      id: requestId,
      passengerName: (data['passengerName']?.toString() ?? passenger['name']?.toString()) ?? 'Client DuDu',
      passengerPhone: data['passengerPhone']?.toString() ?? passenger['phone']?.toString(),
      pickup: pickupText.toString(),
      destination: destinationText.toString(),
      distance: toDoubleSafe(pricing['distance'] ?? data['distance']),
      customPrice: toInt(pricing['customPrice'], toInt(pricing['totalPrice'], toInt(data['customPrice'], 0))),
      customPricePerKm: (pricing is Map && pricing['customPricePerKm'] != null)
          ? toDoubleSafe(pricing['customPricePerKm'])
          : (data['customPricePerKm'] != null ? toDoubleSafe(data['customPricePerKm']) : null),
      rideType: data['rideType']?.toString() ?? 'standard',
      estimatedDuration: toInt(pricing['estimatedDuration'], toInt(data['estimatedDuration'], 5)),
      requestedAt: requestedAt,
      expiresInSeconds: 180,
      scheduledFor: scheduledFor,
      scheduledTimeText: scheduledTimeText,
      isUrgentDelivery: parseBool(data['isUrgentDelivery']),
    );
  }
}
