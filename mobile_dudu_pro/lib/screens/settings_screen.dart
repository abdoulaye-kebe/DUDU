import 'package:flutter/material.dart';
import '../models/driver_profile.dart';
import 'login_screen.dart';

class SettingsScreen extends StatefulWidget {
  final DriverProfile driverProfile;

  const SettingsScreen({
    Key? key,
    required this.driverProfile,
  }) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationsEnabled = true;
  bool _locationEnabled = true;
  bool _autoAcceptRides = false;
  String _language = 'fr';
  String _theme = 'light';

  static const Color primaryGreen = Color(0xFF0d5d36);
  static const Color lightGreen = Color(0xFF10b981);

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
            // Profil utilisateur
            _buildProfileSection(),
            const SizedBox(height: 20),
            
            // Paramètres de l'application
            _buildAppSettings(),
            const SizedBox(height: 20),
            
            // Paramètres de conduite
            _buildDrivingSettings(),
            const SizedBox(height: 20),
            
            // Paramètres de notification
            _buildNotificationSettings(),
            const SizedBox(height: 20),
            
            // Paramètres de langue et thème
            _buildLanguageThemeSettings(),
            const SizedBox(height: 20),
            
            // Section de déconnexion
            _buildLogoutSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileSection() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Profil',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: const Color(0xFF00A651),
                  child: Text(
                    widget.driverProfile.fullName.substring(0, 1).toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.driverProfile.fullName,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.driverProfile.phone,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                      Text(
                        '${widget.driverProfile.vehicleType.displayName} - ${widget.driverProfile.vehicle.plateNumber}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: _editProfile,
                  icon: const Icon(Icons.edit),
                  color: const Color(0xFF00A651),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppSettings() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Application',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildSettingItem(
              icon: Icons.info,
              title: 'À propos',
              subtitle: 'Version 1.0.0',
              onTap: _showAbout,
            ),
            _buildSettingItem(
              icon: Icons.help,
              title: 'Aide et Support',
              subtitle: 'FAQ et contact',
              onTap: _showHelp,
            ),
            _buildSettingItem(
              icon: Icons.privacy_tip,
              title: 'Politique de confidentialité',
              subtitle: 'Protection des données',
              onTap: _showPrivacy,
            ),
            _buildSettingItem(
              icon: Icons.description,
              title: 'Conditions d\'utilisation',
              subtitle: 'Termes et conditions',
              onTap: _showTerms,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrivingSettings() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Conduite',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Accepter automatiquement les courses'),
              subtitle: const Text('Accepter les courses sans confirmation'),
              value: _autoAcceptRides,
              onChanged: (value) => setState(() => _autoAcceptRides = value),
              activeColor: const Color(0xFF00A651),
            ),
            SwitchListTile(
              title: const Text('Géolocalisation'),
              subtitle: const Text('Partager ma position en temps réel'),
              value: _locationEnabled,
              onChanged: (value) => setState(() => _locationEnabled = value),
              activeColor: const Color(0xFF00A651),
            ),
            if (widget.driverProfile.isCar) ...[
              _buildSettingItem(
                icon: Icons.group,
                title: 'Covoiturage',
                subtitle: 'Paramètres de covoiturage',
                onTap: _showCarpoolSettings,
              ),
            ],
            if (widget.driverProfile.isMoto) ...[
              _buildSettingItem(
                icon: Icons.delivery_dining,
                title: 'Livraisons',
                subtitle: 'Paramètres de livraison',
                onTap: _showDeliverySettings,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationSettings() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Notifications',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Notifications push'),
              subtitle: const Text('Recevoir des notifications'),
              value: _notificationsEnabled,
              onChanged: (value) => setState(() => _notificationsEnabled = value),
              activeColor: const Color(0xFF00A651),
            ),
            _buildSettingItem(
              icon: Icons.notifications,
              title: 'Types de notifications',
              subtitle: 'Personnaliser les alertes',
              onTap: _showNotificationTypes,
            ),
            _buildSettingItem(
              icon: Icons.schedule,
              title: 'Heures silencieuses',
              subtitle: 'Désactiver les notifications',
              onTap: _showQuietHours,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLanguageThemeSettings() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Préférences',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildSettingItem(
              icon: Icons.language,
              title: 'Langue',
              subtitle: _getLanguageName(_language),
              onTap: _showLanguageSelector,
            ),
            _buildSettingItem(
              icon: Icons.palette,
              title: 'Thème',
              subtitle: _getThemeName(_theme),
              onTap: _showThemeSelector,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogoutSection() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Colors.red, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Compte',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildSettingItem(
              icon: Icons.security,
              title: 'Sécurité',
              subtitle: 'Changer le mot de passe',
              onTap: _changePassword,
            ),
            _buildSettingItem(
              icon: Icons.delete,
              title: 'Supprimer le compte',
              subtitle: 'Supprimer définitivement',
              onTap: _deleteAccount,
              textColor: Colors.red,
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _logout,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(Icons.logout),
                label: const Text(
                  'Se déconnecter',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Color? textColor,
  }) {
    return ListTile(
      leading: Icon(icon, color: textColor ?? const Color(0xFF00A651)),
      title: Text(
        title,
        style: TextStyle(
          color: textColor,
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: onTap,
    );
  }

  String _getLanguageName(String code) {
    switch (code) {
      case 'fr':
        return 'Français';
      case 'en':
        return 'English';
      case 'wo':
        return 'Wolof';
      default:
        return 'Français';
    }
  }

  String _getThemeName(String theme) {
    switch (theme) {
      case 'light':
        return 'Clair';
      case 'dark':
        return 'Sombre';
      case 'auto':
        return 'Automatique';
      default:
        return 'Clair';
    }
  }

  void _editProfile() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Modifier le profil'),
        content: const Text('Fonctionnalité à implémenter'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showAbout() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('À propos de DUDU Pro'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Version: 1.0.0'),
            SizedBox(height: 8),
            Text('Développé pour le marché sénégalais'),
            SizedBox(height: 8),
            Text('© 2024 DUDU Technologies'),
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

  void _showHelp() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Aide et Support'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.phone),
              title: Text('Support téléphonique'),
              subtitle: Text('+221 33 123 45 67'),
            ),
            ListTile(
              leading: Icon(Icons.email),
              title: Text('Email'),
              subtitle: Text('support@dudu.sn'),
            ),
            ListTile(
              leading: Icon(Icons.chat),
              title: Text('Chat en ligne'),
              subtitle: Text('Disponible 24/7'),
            ),
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

  void _showPrivacy() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Politique de confidentialité'),
        content: const Text('Politique de confidentialité à implémenter'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }

  void _showTerms() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Conditions d\'utilisation'),
        content: const Text('Conditions d\'utilisation à implémenter'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }

  void _showCarpoolSettings() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Paramètres Covoiturage'),
        content: const Text('Paramètres de covoiturage à implémenter'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }

  void _showDeliverySettings() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Paramètres Livraison'),
        content: const Text('Paramètres de livraison à implémenter'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }

  void _showNotificationTypes() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Types de notifications'),
        content: const Text('Types de notifications à implémenter'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }

  void _showQuietHours() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Heures silencieuses'),
        content: const Text('Heures silencieuses à implémenter'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }

  void _showLanguageSelector() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sélectionner la langue'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildLanguageOption('fr', 'Français', '🇫🇷'),
            _buildLanguageOption('en', 'English', '🇺🇸'),
            _buildLanguageOption('wo', 'Wolof', '🇸🇳'),
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

  Widget _buildLanguageOption(String code, String name, String flag) {
    return ListTile(
      leading: Text(flag, style: const TextStyle(fontSize: 24)),
      title: Text(name),
      trailing: _language == code ? const Icon(Icons.check, color: Color(0xFF00A651)) : null,
      onTap: () {
        setState(() => _language = code);
        Navigator.pop(context);
      },
    );
  }

  void _showThemeSelector() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sélectionner le thème'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildThemeOption('light', 'Clair', Icons.light_mode),
            _buildThemeOption('dark', 'Sombre', Icons.dark_mode),
            _buildThemeOption('auto', 'Automatique', Icons.brightness_auto),
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

  Widget _buildThemeOption(String theme, String name, IconData icon) {
    return ListTile(
      leading: Icon(icon),
      title: Text(name),
      trailing: _theme == theme ? const Icon(Icons.check, color: Color(0xFF00A651)) : null,
      onTap: () {
        setState(() => _theme = theme);
        Navigator.pop(context);
      },
    );
  }

  void _changePassword() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Changer le mot de passe'),
        content: const Text('Fonctionnalité à implémenter'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }

  void _deleteAccount() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer le compte'),
        content: const Text('Cette action est irréversible. Êtes-vous sûr ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: Implémenter la suppression du compte
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }

  void _logout() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Déconnexion'),
        content: const Text('Êtes-vous sûr de vouloir vous déconnecter ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const LoginScreen()),
                (route) => false,
              );
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Déconnexion'),
          ),
        ],
      ),
    );
  }
}
