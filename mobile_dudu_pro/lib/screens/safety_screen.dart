import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class SafetyScreen extends StatefulWidget {
  const SafetyScreen({Key? key}) : super(key: key);

  @override
  State<SafetyScreen> createState() => _SafetyScreenState();
}

class _SafetyScreenState extends State<SafetyScreen> with SingleTickerProviderStateMixin {
  static const Color primaryGreen = Color(0xFF0d5d36);
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    final Uri launchUri = Uri(
      scheme: 'tel',
      path: phoneNumber,
    );
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Impossible de passer l\'appel')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Sécurité & Urgences'),
        backgroundColor: primaryGreen,
        foregroundColor: Colors.white,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'Police'),
            Tab(text: 'Santé'),
            Tab(text: 'Prévention'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildPoliceTab(),
          _buildHealthTab(),
          _buildPreventionTab(),
        ],
      ),
    );
  }

  Widget _buildPoliceTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildEmergencyCard(
          title: 'URGENCES POLICE',
          icon: Icons.local_police,
          color: Colors.red,
          contacts: [
            {'name': 'Police Secours', 'number': '17'},
            {'name': 'Gendarmerie', 'number': '800 00 20 20'},
          ],
        ),
        const SizedBox(height: 16),
        _buildSectionTitle('Commissariats Centraux'),
        _buildCommissariatCard(
          name: 'Commissariat central de Dakar',
          address: 'Rue Docteur Thèze X Thiong',
          phones: ['33 823 25 29', '33 841 33 42'],
        ),
        _buildCommissariatCard(
          name: 'Compagnie de la Circulation',
          address: 'Section Accidents',
          phones: ['33 889 82 00', '33 842 20 45'],
        ),
        const SizedBox(height: 16),
        _buildSectionTitle('Commissariats d\'Arrondissement'),
        _buildCommissariatCard(
          name: 'Commissariat du Plateau',
          address: '10, rue Foche X Galliéni',
          phones: ['33 822 29 76', '33 821 80 25'],
        ),
        _buildCommissariatCard(
          name: 'Commissariat de Médina',
          address: 'Avenue Cheikh Anta Diop',
          phones: ['33 821 55 18', '33 821 80 35'],
        ),
        _buildCommissariatCard(
          name: 'Commissariat du Point E',
          address: 'Rue 4 X B Point E',
          phones: ['33 824 76 73'],
        ),
        _buildCommissariatCard(
          name: 'Commissariat de Dieuppeul',
          address: 'Allées Khalifa Ababacar Sy',
          phones: ['33 824 26 27'],
        ),
        _buildCommissariatCard(
          name: 'Commissariat des Parcelles Assainies',
          address: 'Unité 22, route nationale',
          phones: ['33 879 21 33', '33 835 68 39'],
        ),
        _buildCommissariatCard(
          name: 'Commissariat de Pikine',
          address: 'Tally Boumak',
          phones: ['33 879 11 87', '33 834 00 82'],
        ),
        _buildCommissariatCard(
          name: 'Commissariat de Guédiawaye',
          address: 'Médina Gounass',
          phones: ['33 837 02 19'],
        ),
        _buildCommissariatCard(
          name: 'Commissariat de Rufisque',
          address: 'Boulevard Maurice Guèye',
          phones: ['33 839 86 75', '33 836 22 44'],
        ),
        const SizedBox(height: 16),
        _buildSectionTitle('Postes de Police'),
        _buildCommissariatCard(
          name: 'Poste de police HLM 5',
          address: 'HLM 5 n° 2562',
          phones: ['33 825 40 62'],
        ),
        _buildCommissariatCard(
          name: 'Poste de police de Grand Yoff',
          address: 'Près du marché de Grand Yoff',
          phones: ['33 869 41 83', '33 827 96 82'],
        ),
        _buildCommissariatCard(
          name: 'Poste de police de Yeumbeul',
          address: 'Route Benne Baraque',
          phones: ['33 879 37 93', '33 878 90 92'],
        ),
      ],
    );
  }

  Widget _buildHealthTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildEmergencyCard(
          title: 'URGENCES MÉDICALES',
          icon: Icons.local_hospital,
          color: Colors.red,
          contacts: [
            {'name': 'SAMU National', 'number': '1515'},
            {'name': 'Pompiers', 'number': '18'},
            {'name': 'SAMU (fixe)', 'number': '+221 33 824 24 18'},
          ],
        ),
        const SizedBox(height: 16),
        _buildSectionTitle('Hôpitaux Publics'),
        _buildHospitalCard(
          name: 'Hôpital Principal de Dakar',
          phones: ['+221 33 839 50 50'],
          type: 'Urgences générales',
        ),
        _buildHospitalCard(
          name: 'CHNU Fann',
          phones: ['+221 33 869 18 18'],
          type: 'Centre Hospitalier National',
        ),
        _buildHospitalCard(
          name: 'Hôpital Abass Ndao',
          phones: ['+221 33 821 33 37'],
          type: 'Urgences générales',
        ),
        _buildHospitalCard(
          name: 'Hôpital Albert Royer',
          phones: ['+221 33 859 47 47'],
          type: 'Pédiatrie',
        ),
        _buildHospitalCard(
          name: 'Hôpital Aristide Le Dantec',
          phones: ['+221 33 889 38 00', '+221 33 822 24 20'],
          type: 'Maternité',
        ),
        const SizedBox(height: 16),
        _buildSectionTitle('Cliniques Privées'),
        _buildHospitalCard(
          name: 'Clinique Pasteur',
          phones: ['+221 33 849 28 10', '+221 77 105 71 71'],
          type: 'Urgences 24/7',
        ),
        _buildHospitalCard(
          name: 'Clinique du Cap',
          phones: ['+221 33 889 02 02', '+221 33 821 36 27'],
          type: 'Urgences',
        ),
        _buildHospitalCard(
          name: 'Clinique de la Madeleine',
          phones: ['+221 33 889 94 70'],
          type: 'Urgences',
        ),
        _buildHospitalCard(
          name: 'Clinique Casahous',
          phones: ['+221 33 821 30 30'],
          type: 'Urgences',
        ),
        const SizedBox(height: 16),
        _buildSectionTitle('Services Spécialisés'),
        _buildHospitalCard(
          name: 'SOS Médecin Sénégal',
          phones: ['+221 33 889 15 15'],
          type: 'Médecin à domicile',
        ),
        _buildHospitalCard(
          name: 'Centre Anti-Poison',
          phones: ['+221 33 869 18 18'],
          type: 'Intoxications',
        ),
        _buildHospitalCard(
          name: 'Pharmacies de garde',
          phones: ['3636'],
          type: 'Renseignements',
        ),
      ],
    );
  }

  Widget _buildPreventionTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildPreventionCard(
          icon: Icons.phone_in_talk,
          title: 'Avant d\'appeler les secours',
          tips: [
            'Restez calme et évaluez la situation',
            'Sécurisez la zone si nécessaire',
            'Préparez les informations : lieu exact, nature du problème',
            'Restez en ligne jusqu\'à l\'arrivée des secours',
          ],
        ),
        _buildPreventionCard(
          icon: Icons.security,
          title: 'Pendant votre course',
          tips: [
            'Attachez toujours votre ceinture de sécurité',
            'Vérifiez que le conducteur correspond au profil',
            'Partagez votre position avec vos proches',
            'Signalez tout comportement suspect',
          ],
        ),
        _buildPreventionCard(
          icon: Icons.verified_user,
          title: 'Sécurité DUDU',
          tips: [
            'Tous les conducteurs sont vérifiés',
            'Contrôle automatique des courses inhabituelles',
            'Bouton SOS accessible pendant la course',
            'Partage de position en temps réel',
          ],
        ),
        _buildPreventionCard(
          icon: Icons.contact_phone,
          title: 'Contacts d\'urgence',
          tips: [
            'Enregistrez vos contacts d\'urgence dans l\'app',
            'Ils seront prévenus automatiquement si nécessaire',
            'Partagez votre trajet en un clic',
            'Accès rapide aux numéros d\'urgence',
          ],
        ),
      ],
    );
  }

  Widget _buildEmergencyCard({
    required String title,
    required IconData icon,
    required Color color,
    required List<Map<String, String>> contacts,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [color, color.withOpacity(0.8)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Icon(icon, color: Colors.white, size: 32),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...contacts.map((contact) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: ElevatedButton(
                onPressed: () => _makePhoneCall(contact['number']!),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: color,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      contact['name']!,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      contact['number']!,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: primaryGreen,
        ),
      ),
    );
  }

  Widget _buildCommissariatCard({
    required String name,
    required String address,
    required List<String> phones,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.local_police, color: Colors.blue, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.location_on, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    address,
                    style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: phones.map((phone) => InkWell(
                onTap: () => _makePhoneCall(phone),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: primaryGreen.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: primaryGreen.withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.phone, size: 16, color: primaryGreen),
                      const SizedBox(width: 4),
                      Text(
                        phone,
                        style: const TextStyle(
                          color: primaryGreen,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              )).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHospitalCard({
    required String name,
    required List<String> phones,
    required String type,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.local_hospital, color: Colors.red, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        type,
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: phones.map((phone) => InkWell(
                onTap: () => _makePhoneCall(phone),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.phone, size: 16, color: Colors.red),
                      const SizedBox(width: 4),
                      Text(
                        phone,
                        style: const TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              )).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreventionCard({
    required IconData icon,
    required String title,
    required List<String> tips,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: primaryGreen.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: primaryGreen, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: primaryGreen,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...tips.map((tip) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 6),
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: primaryGreen,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      tip,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[700],
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }
}
