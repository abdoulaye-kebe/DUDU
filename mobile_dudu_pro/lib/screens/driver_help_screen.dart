import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class DriverHelpScreen extends StatelessWidget {
  const DriverHelpScreen({Key? key}) : super(key: key);

  static const Color primaryGreen = Color(0xFF0d5d36);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: primaryGreen,
        foregroundColor: Colors.white,
        title: const Text('Aide & Support', style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
      ),
      body: ListView(
        children: [
          // Contact rapide
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Besoin d\'aide ?',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Notre équipe est disponible 24/7 pour vous assister',
                  style: TextStyle(color: Colors.grey[600]),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildContactButton(
                        icon: Icons.phone,
                        label: 'Appeler',
                        onTap: () => _makePhoneCall('+221338601234'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildContactButton(
                        icon: Icons.message,
                        label: 'WhatsApp',
                        onTap: () => _openWhatsApp('+221778601234'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          
          // FAQ
          _buildSectionHeader('QUESTIONS FRÉQUENTES'),
          _buildFaqItem(
            'Comment recevoir des courses ?',
            'Assurez-vous d\'être en ligne et d\'avoir un abonnement actif. Les demandes de courses vous seront envoyées automatiquement selon votre position.',
          ),
          _buildFaqItem(
            'Comment gérer mon abonnement ?',
            'Accédez à la section "Abonnement" sur le dashboard pour voir votre plan actuel, le renouveler ou le modifier.',
          ),
          _buildFaqItem(
            'Que faire en cas de problème avec un passager ?',
            'Contactez immédiatement notre support via le bouton d\'appel ou WhatsApp. Nous sommes disponibles 24/7.',
          ),
          _buildFaqItem(
            'Comment sont calculés mes gains ?',
            'Vos gains sont calculés en fonction du prix de la course moins la commission DUDU. Consultez votre historique pour plus de détails.',
          ),
          _buildFaqItem(
            'Comment retirer mes gains ?',
            'Les retraits sont disponibles via Orange Money, Wave ou Free Money. Rendez-vous dans la section "Gains" pour effectuer un retrait.',
          ),
          
          const SizedBox(height: 16),
          
          // Informations de contact
          _buildSectionHeader('NOUS CONTACTER'),
          _buildContactInfoTile(
            icon: Icons.email_outlined,
            title: 'Email',
            subtitle: 'support@dudugroup.sn',
            onTap: () => _sendEmail('support@dudugroup.sn'),
          ),
          _buildContactInfoTile(
            icon: Icons.phone_outlined,
            title: 'Téléphone',
            subtitle: '+221 33 860 12 34',
            onTap: () => _makePhoneCall('+221338601234'),
          ),
          _buildContactInfoTile(
            icon: Icons.location_on_outlined,
            title: 'Adresse',
            subtitle: 'Dakar, Sénégal',
            onTap: null,
          ),
          
          const SizedBox(height: 16),
          
          // Liens utiles
          _buildSectionHeader('LIENS UTILES'),
          _buildLinkTile(
            icon: Icons.description_outlined,
            title: 'Guide du chauffeur',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Fonctionnalité à venir')),
              );
            },
          ),
          _buildLinkTile(
            icon: Icons.video_library_outlined,
            title: 'Tutoriels vidéo',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Fonctionnalité à venir')),
              );
            },
          ),
          _buildLinkTile(
            icon: Icons.article_outlined,
            title: 'Conditions générales',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Fonctionnalité à venir')),
              );
            },
          ),
          
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildContactButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return ElevatedButton.icon(
      onPressed: onTap,
      icon: Icon(icon),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryGreen,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: TextStyle(
          color: Colors.grey[600],
          fontSize: 12,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildFaqItem(String question, String answer) {
    return Container(
      color: Colors.white,
      margin: const EdgeInsets.only(bottom: 1),
      child: ExpansionTile(
        title: Text(
          question,
          style: const TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 15,
          ),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Text(
              answer,
              style: TextStyle(
                color: Colors.grey[700],
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactInfoTile({
    required IconData icon,
    required String title,
    required String subtitle,
    VoidCallback? onTap,
  }) {
    return Container(
      color: Colors.white,
      margin: const EdgeInsets.only(bottom: 1),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: primaryGreen.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: primaryGreen, size: 20),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        subtitle: Text(subtitle),
        trailing: onTap != null ? const Icon(Icons.chevron_right, color: Colors.grey) : null,
        onTap: onTap,
      ),
    );
  }

  Widget _buildLinkTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return Container(
      color: Colors.white,
      margin: const EdgeInsets.only(bottom: 1),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: primaryGreen.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: primaryGreen, size: 20),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        trailing: const Icon(Icons.chevron_right, color: Colors.grey),
        onTap: onTap,
      ),
    );
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    final Uri phoneUri = Uri(scheme: 'tel', path: phoneNumber);
    if (await canLaunchUrl(phoneUri)) {
      await launchUrl(phoneUri);
    }
  }

  Future<void> _openWhatsApp(String phoneNumber) async {
    final Uri whatsappUri = Uri.parse('https://wa.me/$phoneNumber');
    if (await canLaunchUrl(whatsappUri)) {
      await launchUrl(whatsappUri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _sendEmail(String email) async {
    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: email,
      query: 'subject=Support DUDU Pro',
    );
    if (await canLaunchUrl(emailUri)) {
      await launchUrl(emailUri);
    }
  }
}
