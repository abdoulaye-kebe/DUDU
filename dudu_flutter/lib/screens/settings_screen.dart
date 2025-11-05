import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'login_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  static const Color primaryGreen = Color(0xFF0d5d36);
  static const Color lightGreen = Color(0xFF10b981);

  bool _notificationsEnabled = true;
  bool _locationEnabled = true;
  String _language = 'fr';
  String _theme = 'light';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Paramètres',
          style: TextStyle(color: Colors.white, fontSize: 18),
        ),
        backgroundColor: primaryGreen,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section Notifications
            _buildSection(
              title: 'Notifications',
              icon: Icons.notifications_outlined,
              children: [
                _buildSwitchTile(
                  title: 'Activer les notifications',
                  subtitle: 'Recevoir des alertes pour vos courses',
                  value: _notificationsEnabled,
                  onChanged: (value) {
                    setState(() => _notificationsEnabled = value);
                  },
                ),
              ],
            ),
            
            const SizedBox(height: 20),
            
            // Section Localisation
            _buildSection(
              title: 'Localisation',
              icon: Icons.location_on_outlined,
              children: [
                _buildSwitchTile(
                  title: 'Partager ma position',
                  subtitle: 'Permettre au chauffeur de vous localiser',
                  value: _locationEnabled,
                  onChanged: (value) {
                    setState(() => _locationEnabled = value);
                  },
                ),
              ],
            ),
            
            const SizedBox(height: 20),
            
            // Section Langue
            _buildSection(
              title: 'Langue',
              icon: Icons.language_outlined,
              children: [
                _buildRadioTile(
                  title: 'Français',
                  value: 'fr',
                  groupValue: _language,
                  onChanged: (value) {
                    setState(() => _language = value!);
                  },
                ),
                _buildRadioTile(
                  title: 'English',
                  value: 'en',
                  groupValue: _language,
                  onChanged: (value) {
                    setState(() => _language = value!);
                  },
                ),
                _buildRadioTile(
                  title: 'Wolof',
                  value: 'wo',
                  groupValue: _language,
                  onChanged: (value) {
                    setState(() => _language = value!);
                  },
                ),
              ],
            ),
            
            const SizedBox(height: 20),
            
            // Section Thème
            _buildSection(
              title: 'Apparence',
              icon: Icons.palette_outlined,
              children: [
                _buildRadioTile(
                  title: 'Clair',
                  value: 'light',
                  groupValue: _theme,
                  onChanged: (value) {
                    setState(() => _theme = value!);
                  },
                ),
                _buildRadioTile(
                  title: 'Sombre',
                  value: 'dark',
                  groupValue: _theme,
                  onChanged: (value) {
                    setState(() => _theme = value!);
                  },
                ),
              ],
            ),
            
            const SizedBox(height: 20),
            
            // Section À propos
            _buildSection(
              title: 'À propos',
              icon: Icons.info_outline,
              children: [
                _buildListTile(
                  title: 'Version de l\'application',
                  trailing: const Text('1.0.0'),
                  onTap: () {},
                ),
                _buildListTile(
                  title: 'Conditions d\'utilisation',
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {},
                ),
                _buildListTile(
                  title: 'Politique de confidentialité',
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {},
                ),
              ],
            ),
            
            const SizedBox(height: 32),
            
            // Bouton Déconnexion
            _buildLogoutButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: primaryGreen, size: 24),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1a1a1a),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return SwitchListTile(
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontSize: 14,
          color: Colors.grey[600],
        ),
      ),
      value: value,
      onChanged: onChanged,
      activeColor: lightGreen,
      contentPadding: EdgeInsets.zero,
    );
  }

  Widget _buildRadioTile({
    required String title,
    required String value,
    required String groupValue,
    required ValueChanged<String?> onChanged,
  }) {
    return RadioListTile<String>(
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
      value: value,
      groupValue: groupValue,
      onChanged: onChanged,
      activeColor: lightGreen,
      contentPadding: EdgeInsets.zero,
    );
  }

  Widget _buildListTile({
    required String title,
    required Widget trailing,
    required VoidCallback onTap,
  }) {
    return ListTile(
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
      trailing: trailing,
      onTap: onTap,
      contentPadding: EdgeInsets.zero,
    );
  }

  Widget _buildLogoutButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _logout,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.red,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 2,
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.logout, size: 20),
            SizedBox(width: 8),
            Text(
              'Se déconnecter',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Déconnexion'),
        content: const Text('Voulez-vous vraiment vous déconnecter ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Déconnecter'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      // Supprimer le token
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('auth_token');
      await prefs.remove('user_id');

      // Retour à l'écran de connexion
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const LoginScreen()),
          (route) => false,
        );
      }
    }
  }
}
