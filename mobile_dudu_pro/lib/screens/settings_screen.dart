import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/driver_profile.dart';
import '../services/api_service.dart';
import '../theme/theme_controller.dart';
import 'login_screen.dart';
import 'pro_app_gate.dart';

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

  static const Color primaryGreen = Color(0xFF0d5d36);
  static const Color lightGreen = Color(0xFF10b981);

  static final Uri _urlPrivacy =
      Uri.parse('https://dudugroup.sn/privacy.html');
  static final Uri _urlTerms = Uri.parse('https://dudugroup.sn/terms.html');
  static final Uri _urlFaq = Uri.parse('https://dudugroup.sn/faq.html');
  static final Uri _urlContact = Uri.parse('https://dudugroup.sn/contact.html');

  Future<void> _openExternal(Uri uri) async {
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Impossible d\'ouvrir : $uri')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur : $e')),
        );
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _loadLanguagePreference();
  }

  Future<void> _loadLanguagePreference() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedLanguage = prefs.getString('app_language') ?? 'fr';
      if (mounted) {
        setState(() => _language = savedLanguage);
      }
    } catch (e) {
      print('Erreur chargement langue: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
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
            
            // Paramètres de langue
            _buildLanguageSettings(),
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
            const Divider(height: 24),
            ListTile(
              leading: const Icon(Icons.lock_outline, color: Color(0xFF00A651)),
              title: const Text('Changer le mot de passe'),
              trailing: const Icon(Icons.chevron_right),
              onTap: _changePassword,
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
            Consumer<ThemeController>(
              builder: (context, tc, _) => _buildSettingItem(
                icon: Icons.palette_outlined,
                title: 'Apparence',
                subtitle: tc.modeLabel,
                onTap: () => _showThemeSelector(tc),
              ),
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
              onTap: () => _showNotificationTypes(),
            ),
            _buildSettingItem(
              icon: Icons.schedule,
              title: 'Heures silencieuses',
              subtitle: 'Désactiver les notifications',
              onTap: () => _showQuietHours(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLanguageSettings() {
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
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF00A651).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.language,
                    color: Color(0xFF00A651),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Langue / Language / اللغة',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildLanguageOption('fr', 'Français', '🇫🇷'),
            const Divider(height: 1),
            _buildLanguageOption('en', 'English', '🇬🇧'),
            const Divider(height: 1),
            _buildLanguageOption('ar', 'العربية', '🇸🇦'),
          ],
        ),
      ),
    );
  }

  Widget _buildLogoutSection() {
    return Column(
      children: [
        // Carte pour supprimer le compte
        Card(
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
                  'Zone Dangereuse',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                ),
                const SizedBox(height: 16),
                _buildSettingItem(
                  icon: Icons.delete_forever,
                  title: 'Supprimer le compte',
                  subtitle: 'Action irréversible',
                  onTap: _deleteAccount,
                  textColor: Colors.red,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        
        // Bouton de déconnexion moderne
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.red.shade600, Colors.red.shade800],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.red.withOpacity(0.3),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _logout,
              borderRadius: BorderRadius.circular(16),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 24),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.logout_rounded,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Text(
                      'Se déconnecter',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
      ],
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
      case 'ar':
        return 'العربية';
      default:
        return 'Français';
    }
  }

  void _editProfile() {
    final v = widget.driverProfile.vehicle;
    final makeCtrl = TextEditingController(text: v.make);
    final modelCtrl = TextEditingController(text: v.model);
    final yearCtrl = TextEditingController(text: v.year.toString());
    final colorCtrl = TextEditingController(text: v.color);

    void disposeCtrls() {
      makeCtrl.dispose();
      modelCtrl.dispose();
      yearCtrl.dispose();
      colorCtrl.dispose();
    }

    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Modifier le véhicule'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: makeCtrl,
                decoration: const InputDecoration(labelText: 'Marque'),
              ),
              TextField(
                controller: modelCtrl,
                decoration: const InputDecoration(labelText: 'Modèle'),
              ),
              TextField(
                controller: yearCtrl,
                decoration: const InputDecoration(labelText: 'Année'),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: colorCtrl,
                decoration: const InputDecoration(labelText: 'Couleur'),
              ),
              const SizedBox(height: 8),
              Text(
                'Immatriculation : ${v.plateNumber} (modif. via support si besoin)',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () async {
              final y = int.tryParse(yearCtrl.text.trim());
              if (y == null || y < 1990 || y > DateTime.now().year + 1) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Année invalide')),
                );
                return;
              }
              try {
                await ApiService.updateDriverVehicle(
                  make: makeCtrl.text.trim(),
                  model: modelCtrl.text.trim(),
                  year: y,
                  color: colorCtrl.text.trim(),
                );
                if (ctx.mounted) Navigator.pop(ctx);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Véhicule mis à jour'),
                      backgroundColor: Color(0xFF00A651),
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('$e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text('Enregistrer'),
          ),
        ],
      ),
    ).whenComplete(disposeCtrls);
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
            Text('Version : 1.0.0'),
            SizedBox(height: 8),
            Text('Application chauffeur DUDU — Sénégal.'),
            SizedBox(height: 8),
            Text('© 2026 DUDU Group'),
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
      builder: (ctx) => AlertDialog(
        title: const Text('Aide et support'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.help_outline),
                title: const Text('FAQ'),
                subtitle: const Text('Questions fréquentes'),
                onTap: () {
                  Navigator.pop(ctx);
                  _openExternal(_urlFaq);
                },
              ),
              ListTile(
                leading: const Icon(Icons.mail_outline),
                title: const Text('Contact'),
                subtitle: const Text('Formulaire sur dudugroup.sn'),
                onTap: () {
                  Navigator.pop(ctx);
                  _openExternal(_urlContact);
                },
              ),
              ListTile(
                leading: const Icon(Icons.email),
                title: const Text('Email'),
                subtitle: const Text('support@dudugroup.sn'),
                onTap: () => _openExternal(
                  Uri.parse('mailto:support@dudugroup.sn'),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }

  void _showPrivacy() {
    _openExternal(_urlPrivacy);
  }

  void _showTerms() {
    _openExternal(_urlTerms);
  }

  void _showDeliverySettings() {
    showDialog(
      context: context,
      builder: (ctx) => FutureBuilder<SharedPreferences>(
        future: SharedPreferences.getInstance(),
        builder: (context, snap) {
          final prefs = snap.data;
          bool priority = prefs?.getBool('pro_delivery_priority') ?? true;
          return StatefulBuilder(
            builder: (context, setSt) => AlertDialog(
              title: const Text('Livraisons'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Indiquez si vous souhaitez être prioritaire sur les courses livraison (préférence enregistrée sur cet appareil).',
                    style: TextStyle(fontSize: 14),
                  ),
                  const SizedBox(height: 12),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Livraisons prioritaires'),
                    value: priority,
                    activeColor: const Color(0xFF00A651),
                    onChanged: prefs == null
                        ? null
                        : (v) async {
                            await prefs.setBool('pro_delivery_priority', v);
                            setSt(() => priority = v);
                          },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Fermer'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _showNotificationTypes() async {
    final prefs = await SharedPreferences.getInstance();
    bool rides = prefs.getBool('pro_notify_rides') ?? true;
    bool promos = prefs.getBool('pro_notify_promos') ?? true;
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setSt) => AlertDialog(
          title: const Text('Types de notifications'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SwitchListTile(
                title: const Text('Nouvelles courses'),
                value: rides,
                activeColor: const Color(0xFF00A651),
                onChanged: (v) async {
                  await prefs.setBool('pro_notify_rides', v);
                  setSt(() => rides = v);
                },
              ),
              SwitchListTile(
                title: const Text('Promotions et infos'),
                value: promos,
                activeColor: const Color(0xFF00A651),
                onChanged: (v) async {
                  await prefs.setBool('pro_notify_promos', v);
                  setSt(() => promos = v);
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Fermer'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showQuietHours() async {
    final prefs = await SharedPreferences.getInstance();
    bool enabled = prefs.getBool('pro_quiet_hours') ?? false;
    int startH = prefs.getInt('pro_quiet_start') ?? 22;
    int endH = prefs.getInt('pro_quiet_end') ?? 7;
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setSt) => AlertDialog(
          title: const Text('Heures silencieuses'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Plage horaire enregistrée localement. Les notifications système dépendent aussi des réglages Android/iOS.',
                  style: TextStyle(fontSize: 13),
                ),
                const SizedBox(height: 12),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Activer'),
                  value: enabled,
                  activeColor: const Color(0xFF00A651),
                  onChanged: (v) async {
                    await prefs.setBool('pro_quiet_hours', v);
                    setSt(() => enabled = v);
                  },
                ),
                if (enabled) ...[
                  Row(
                    children: [
                      const Text('Début : '),
                      DropdownButton<int>(
                        value: startH,
                        items: List.generate(
                          24,
                          (h) => DropdownMenuItem(value: h, child: Text('$h h')),
                        ),
                        onChanged: (v) async {
                          if (v == null) return;
                          await prefs.setInt('pro_quiet_start', v);
                          setSt(() => startH = v);
                        },
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      const Text('Fin : '),
                      DropdownButton<int>(
                        value: endH,
                        items: List.generate(
                          24,
                          (h) => DropdownMenuItem(value: h, child: Text('$h h')),
                        ),
                        onChanged: (v) async {
                          if (v == null) return;
                          await prefs.setInt('pro_quiet_end', v);
                          setSt(() => endH = v);
                        },
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Fermer'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveLanguagePreference(String languageCode) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('app_language', languageCode);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              languageCode == 'fr' 
                ? 'Langue changée en Français'
                : languageCode == 'en'
                  ? 'Language changed to English'
                  : 'تم تغيير اللغة إلى العربية',
            ),
            backgroundColor: const Color(0xFF00A651),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      print('Erreur sauvegarde langue: $e');
    }
  }

  Widget _buildLanguageOption(String code, String name, String flag) {
    final isSelected = _language == code;
    
    return InkWell(
      onTap: () async {
        setState(() => _language = code);
        await _saveLanguagePreference(code);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF00A651).withOpacity(0.1) : null,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Text(
              flag,
              style: const TextStyle(fontSize: 32),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                name,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? const Color(0xFF00A651) : Colors.black87,
                ),
              ),
            ),
            if (isSelected)
              Container(
                padding: const EdgeInsets.all(6),
                decoration: const BoxDecoration(
                  color: Color(0xFF00A651),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check,
                  color: Colors.white,
                  size: 18,
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _showThemeSelector(ThemeController tc) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Thème de l\'application'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.light_mode),
              title: const Text('Clair'),
              trailing: tc.mode == ThemeMode.light
                  ? const Icon(Icons.check, color: Color(0xFF00A651))
                  : null,
              onTap: () async {
                await tc.setTheme(ThemeMode.light);
                if (dialogContext.mounted) Navigator.pop(dialogContext);
              },
            ),
            ListTile(
              leading: const Icon(Icons.dark_mode),
              title: const Text('Sombre'),
              trailing: tc.mode == ThemeMode.dark
                  ? const Icon(Icons.check, color: Color(0xFF00A651))
                  : null,
              onTap: () async {
                await tc.setTheme(ThemeMode.dark);
                if (dialogContext.mounted) Navigator.pop(dialogContext);
              },
            ),
            ListTile(
              leading: const Icon(Icons.brightness_auto),
              title: const Text('Système'),
              trailing: tc.mode == ThemeMode.system
                  ? const Icon(Icons.check, color: Color(0xFF00A651))
                  : null,
              onTap: () async {
                await tc.setTheme(ThemeMode.system);
                if (dialogContext.mounted) Navigator.pop(dialogContext);
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }

  void _changePassword() {
    final cur = TextEditingController();
    final neu = TextEditingController();
    final conf = TextEditingController();

    void disposePw() {
      cur.dispose();
      neu.dispose();
      conf.dispose();
    }

    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Changer le mot de passe'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: cur,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Mot de passe actuel',
                ),
              ),
              TextField(
                controller: neu,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Nouveau (min. 6 caractères)',
                ),
              ),
              TextField(
                controller: conf,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Confirmer le nouveau',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () async {
              if (neu.text.length < 6) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Le nouveau mot de passe doit faire au moins 6 caractères'),
                  ),
                );
                return;
              }
              if (neu.text != conf.text) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Les mots de passe ne correspondent pas')),
                );
                return;
              }
              try {
                await ApiService.changePassword(cur.text, neu.text);
                if (ctx.mounted) Navigator.pop(ctx);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Mot de passe modifié'),
                      backgroundColor: Color(0xFF00A651),
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('$e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text('Valider'),
          ),
        ],
      ),
    ).whenComplete(disposePw);
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
            onPressed: () async {
              Navigator.pop(context);

              final result = await ApiService.deleteAccount();
              final success = result['success'] == true;
              final message = result['message']?.toString() ??
                  (success ? 'Compte supprimé' : 'Erreur de suppression');

              if (!mounted) return;

              if (success) {
                ApiService.setAuthToken('');
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                  (route) => false,
                );
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(message),
                    backgroundColor: Colors.green,
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(message),
                    backgroundColor: Colors.red,
                  ),
                );
              }
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
              () async {
                try {
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.remove('pro_auth_token');
                } catch (_) {}
                ApiService.clearAuthToken();
              }();
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const ProAppGate()),
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
