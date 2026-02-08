import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';

class ShareRideScreen extends StatefulWidget {
  final String rideId;
  final String driverName;
  final String vehicleInfo;
  final String pickupAddress;
  final String destinationAddress;
  final double? currentLat;
  final double? currentLng;

  const ShareRideScreen({
    Key? key,
    required this.rideId,
    required this.driverName,
    required this.vehicleInfo,
    required this.pickupAddress,
    required this.destinationAddress,
    this.currentLat,
    this.currentLng,
  }) : super(key: key);

  @override
  State<ShareRideScreen> createState() => _ShareRideScreenState();
}

class _ShareRideScreenState extends State<ShareRideScreen> {
  bool _isGeneratingLink = false;
  String? _trackingLink;

  @override
  void initState() {
    super.initState();
    _generateTrackingLink();
  }

  void _generateTrackingLink() {
    setState(() {
      _isGeneratingLink = true;
    });

    // Générer un lien de suivi (à adapter selon votre backend)
    final baseUrl = 'https://dudu.sn/track';
    _trackingLink = '$baseUrl/${widget.rideId}';

    setState(() {
      _isGeneratingLink = false;
    });
  }

  String _generateShareMessage() {
    final position = widget.currentLat != null && widget.currentLng != null
        ? 'Position actuelle: https://maps.google.com/?q=${widget.currentLat},${widget.currentLng}'
        : '';

    return '''
🚗 Je partage mon trajet DUDU avec toi

👤 Chauffeur: ${widget.driverName}
🚙 Véhicule: ${widget.vehicleInfo}

📍 Départ: ${widget.pickupAddress}
🎯 Destination: ${widget.destinationAddress}

$position

🔗 Suivre mon trajet en temps réel:
$_trackingLink

En cas d'urgence, contacte:
🚨 Police: 17
🚑 Pompiers: 18
''';
  }

  Future<void> _shareViaWhatsApp() async {
    final message = Uri.encodeComponent(_generateShareMessage());
    final url = 'whatsapp://send?text=$message';
    
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        throw Exception('WhatsApp non installé');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _shareViaSMS() async {
    final message = Uri.encodeComponent(_generateShareMessage());
    final url = 'sms:?body=$message';
    
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        throw Exception('Impossible d\'ouvrir l\'application SMS');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _shareViaOtherApps() async {
    try {
      await Share.share(
        _generateShareMessage(),
        subject: 'Mon trajet DUDU - Suivi en temps réel',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur de partage: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _copyLink() async {
    if (_trackingLink != null) {
      await Clipboard.setData(ClipboardData(text: _trackingLink!));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Lien copié dans le presse-papiers'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Partager mon trajet',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color(0xFF00A651),
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: _isGeneratingLink
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // En-tête de sécurité
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.green.shade200),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.shield_outlined,
                          size: 48,
                          color: Colors.green.shade700,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Partagez votre trajet pour plus de sécurité',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.green.shade900,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Vos proches pourront suivre votre position en temps réel',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.green.shade700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Informations du trajet
                  _buildInfoCard(),
                  
                  const SizedBox(height: 24),
                  
                  // Options de partage
                  Text(
                    'Choisissez comment partager',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[800],
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  _buildShareOption(
                    icon: Icons.whatsapp,
                    title: 'WhatsApp',
                    subtitle: 'Partager via WhatsApp',
                    color: const Color(0xFF25D366),
                    onTap: _shareViaWhatsApp,
                  ),
                  
                  const SizedBox(height: 12),
                  
                  _buildShareOption(
                    icon: Icons.message,
                    title: 'SMS',
                    subtitle: 'Envoyer par message',
                    color: Colors.blue,
                    onTap: _shareViaSMS,
                  ),
                  
                  const SizedBox(height: 12),
                  
                  _buildShareOption(
                    icon: Icons.share,
                    title: 'Autres applications',
                    subtitle: 'Email, Telegram, etc.',
                    color: Colors.orange,
                    onTap: _shareViaOtherApps,
                  ),
                  
                  const SizedBox(height: 12),
                  
                  _buildShareOption(
                    icon: Icons.link,
                    title: 'Copier le lien',
                    subtitle: 'Copier dans le presse-papiers',
                    color: Colors.grey,
                    onTap: _copyLink,
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Note de sécurité
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.blue.shade700),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Le lien de suivi sera actif pendant toute la durée de votre course',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.blue.shade900,
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

  Widget _buildInfoCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Informations du trajet',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 12),
          _buildInfoRow(Icons.person, 'Chauffeur', widget.driverName),
          const SizedBox(height: 8),
          _buildInfoRow(Icons.directions_car, 'Véhicule', widget.vehicleInfo),
          const SizedBox(height: 8),
          _buildInfoRow(Icons.location_on, 'Départ', widget.pickupAddress),
          const SizedBox(height: 8),
          _buildInfoRow(Icons.flag, 'Destination', widget.destinationAddress),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: Colors.grey[600]),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey[600],
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildShareOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[200]!),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey[400]),
          ],
        ),
      ),
    );
  }
}
