import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/api_service.dart';
import '../theme/theme_controller.dart';

class DriverSettingsScreen extends StatefulWidget {
  const DriverSettingsScreen({Key? key}) : super(key: key);

  @override
  State<DriverSettingsScreen> createState() => _DriverSettingsScreenState();
}

class _DriverSettingsScreenState extends State<DriverSettingsScreen> {
  static const Color primaryGreen = Color(0xFF0d5d36);
  
  bool _notificationsEnabled = true;
  bool _soundEnabled = true;

  void _showChangePasswordDialog() {
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
                decoration: const InputDecoration(labelText: 'Mot de passe actuel'),
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
                decoration: const InputDecoration(labelText: 'Confirmer'),
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
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Mot de passe modifié'),
                      backgroundColor: Color(0xFF00A651),
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('$e'), backgroundColor: Colors.red),
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

  void _showThemeSelector(ThemeController tc) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Apparence'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.light_mode),
              title: const Text('Clair'),
              trailing: tc.mode == ThemeMode.light
                  ? const Icon(Icons.check, color: primaryGreen)
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
                  ? const Icon(Icons.check, color: primaryGreen)
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
                  ? const Icon(Icons.check, color: primaryGreen)
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

  @override
  Widget build(BuildContext context) {
    final surface = Theme.of(context).colorScheme.surface;
    return Scaffold(
      backgroundColor: surface,
      appBar: AppBar(
        backgroundColor: primaryGreen,
        foregroundColor: Colors.white,
        title: const Text('Paramètres', style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
      ),
      body: ListView(
        children: [
          _buildSectionHeader('NOTIFICATIONS'),
          _buildSettingTile(
            icon: Icons.notifications_active,
            title: 'Notifications de courses',
            subtitle: 'Recevoir les nouvelles demandes',
            trailing: Switch(
              value: _notificationsEnabled,
              onChanged: (value) {
                setState(() => _notificationsEnabled = value);
              },
              activeColor: primaryGreen,
            ),
          ),
          _buildSettingTile(
            icon: Icons.volume_up,
            title: 'Sons et vibrations',
            subtitle: 'Activer les sons',
            trailing: Switch(
              value: _soundEnabled,
              onChanged: (value) {
                setState(() => _soundEnabled = value);
              },
              activeColor: primaryGreen,
            ),
          ),
          
          const Divider(height: 32),
          
          _buildSectionHeader('PRÉFÉRENCES'),
          Consumer<ThemeController>(
            builder: (context, tc, _) => _buildSettingTile(
              icon: Icons.palette_outlined,
              title: 'Apparence',
              subtitle: tc.modeLabel,
              onTap: () => _showThemeSelector(tc),
            ),
          ),
          _buildSettingTile(
            icon: Icons.language,
            title: 'Langue & aide',
            subtitle: 'FAQ sur dudugroup.sn',
            onTap: () async {
              final uri = Uri.parse('https://dudugroup.sn/faq.html');
              if (await canLaunchUrl(uri)) {
                await launchUrl(uri, mode: LaunchMode.externalApplication);
              } else if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Impossible d\'ouvrir la FAQ')),
                );
              }
            },
          ),
          
          const Divider(height: 32),
          
          _buildSectionHeader('COMPTE'),
          _buildSettingTile(
            icon: Icons.lock_outline,
            title: 'Changer le mot de passe',
            onTap: _showChangePasswordDialog,
          ),
          
          const SizedBox(height: 32),
          
          Center(
            child: Text(
              'Version 1.0.0',
              style: TextStyle(color: Colors.grey[500], fontSize: 12),
            ),
          ),
          
          const SizedBox(height: 24),
        ],
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

  Widget _buildSettingTile({
    required IconData icon,
    required String title,
    String? subtitle,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return Container(
      color: Theme.of(context).colorScheme.surface,
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
        subtitle: subtitle != null 
            ? Text(subtitle, style: TextStyle(color: Colors.grey[600], fontSize: 12))
            : null,
        trailing: trailing ?? const Icon(Icons.chevron_right, color: Colors.grey),
        onTap: onTap,
      ),
    );
  }
}
