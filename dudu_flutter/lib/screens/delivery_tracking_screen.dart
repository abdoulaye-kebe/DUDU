import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class DeliveryTrackingScreen extends StatefulWidget {
  final String deliveryId;
  final String confirmationCode;

  const DeliveryTrackingScreen({
    Key? key,
    required this.deliveryId,
    required this.confirmationCode,
  }) : super(key: key);

  @override
  State<DeliveryTrackingScreen> createState() => _DeliveryTrackingScreenState();
}

class _DeliveryTrackingScreenState extends State<DeliveryTrackingScreen> {
  String _currentStatus = 'searching'; // searching, accepted, picked_up, in_transit, delivered
  String _driverName = 'Moussa Ndiaye';
  String _driverPhone = '+221 77 123 45 67';
  String _driverVehicle = 'Yamaha DT - SN 1234 AB';
  double _driverRating = 4.9;
  
  // Photos
  String? _pickupPhoto;
  String? _deliveryPhoto;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Suivi de livraison 📦'),
        backgroundColor: const Color(0xFFFF6B00),
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Carte avec position du livreur
          Expanded(
            flex: 2,
            child: GoogleMap(
              initialCameraPosition: const CameraPosition(
                target: LatLng(14.6937, -17.4441),
                zoom: 14,
              ),
              myLocationEnabled: true,
              zoomControlsEnabled: false,
            ),
          ),
          
          // Informations de livraison
          Expanded(
            flex: 3,
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  // Handle
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Statut de la livraison
                  _buildStatusTimeline(),
                  
                  const SizedBox(height: 24),
                  
                  // Code de confirmation
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF6B00).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFFF6B00)),
                    ),
                    child: Column(
                      children: [
                        const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.key, color: Color(0xFFFF6B00)),
                            SizedBox(width: 8),
                            Text(
                              'Code de confirmation',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          widget.confirmationCode,
                          style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFFF6B00),
                            letterSpacing: 4,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Communiquez ce code au destinataire',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Informations du livreur
                  if (_currentStatus != 'searching') ...[
                    const Text(
                      'Votre livreur',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Card(
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: const Color(0xFFFF6B00),
                          child: Text(
                            _driverName[0],
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                        title: Text(_driverName),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(_driverVehicle),
                            Row(
                              children: [
                                const Icon(Icons.star, size: 16, color: Colors.amber),
                                Text(' $_driverRating'),
                              ],
                            ),
                          ],
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.phone, color: Color(0xFF00A651)),
                          onPressed: () {
                            // TODO: Appeler le livreur
                          },
                        ),
                      ),
                    ),
                  ],
                  
                  const SizedBox(height: 24),
                  
                  // Photos de livraison
                  if (_currentStatus == 'picked_up' || _currentStatus == 'in_transit' || _currentStatus == 'delivered') ...[
                    const Text(
                      'Photos de livraison',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _buildPhotoCard(
                            'Récupération',
                            _pickupPhoto,
                            Icons.check_circle,
                            Colors.green,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildPhotoCard(
                            'Livraison',
                            _deliveryPhoto,
                            Icons.check_circle,
                            _currentStatus == 'delivered' ? Colors.green : Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ],
                  
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusTimeline() {
    final statuses = [
      {'key': 'searching', 'label': 'Recherche livreur', 'icon': Icons.search},
      {'key': 'accepted', 'label': 'Livreur trouvé', 'icon': Icons.person_check},
      {'key': 'picked_up', 'label': 'Colis récupéré', 'icon': Icons.inventory},
      {'key': 'in_transit', 'label': 'En cours de livraison', 'icon': Icons.two_wheeler},
      {'key': 'delivered', 'label': 'Livré', 'icon': Icons.done_all},
    ];

    return Column(
      children: statuses.asMap().entries.map((entry) {
        final index = entry.key;
        final status = entry.value;
        final isActive = _getStatusIndex(_currentStatus) >= index;
        final isCurrent = status['key'] == _currentStatus;

        return Row(
          children: [
            Column(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: isActive ? const Color(0xFFFF6B00) : Colors.grey[300],
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    status['icon'] as IconData,
                    color: isActive ? Colors.white : Colors.grey,
                    size: 20,
                  ),
                ),
                if (index < statuses.length - 1)
                  Container(
                    width: 2,
                    height: 30,
                    color: isActive ? const Color(0xFFFF6B00) : Colors.grey[300],
                  ),
              ],
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    status['label'] as String,
                    style: TextStyle(
                      fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                      color: isActive ? Colors.black87 : Colors.grey,
                      fontSize: isCurrent ? 16 : 14,
                    ),
                  ),
                  if (isCurrent)
                    const Text(
                      'En cours...',
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFFFF6B00),
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ],
        );
      }).toList(),
    );
  }

  int _getStatusIndex(String status) {
    const statusOrder = ['searching', 'accepted', 'picked_up', 'in_transit', 'delivered'];
    return statusOrder.indexOf(status);
  }

  Widget _buildPhotoCard(String label, String? photoUrl, IconData icon, Color color) {
    return Card(
      child: Container(
        height: 120,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: Colors.grey[100],
        ),
        child: photoUrl != null
            ? Image.network(photoUrl, fit: BoxFit.cover)
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, color: color, size: 32),
                  const SizedBox(height: 8),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 12,
                      color: color,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

