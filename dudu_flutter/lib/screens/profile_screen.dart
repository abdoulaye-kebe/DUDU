import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../models/user.dart';
import '../services/api_service.dart';
import '../themes/app_theme.dart';
import 'rides_screen.dart';
import 'login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  User? _user;
  bool _isLoading = true;
  String? _error;

  /// Même convention que `UnifiedRideScreen` / `RideConfirmationScreen`.
  static const Map<String, String> _paymentLogos = {
    'orange_money': 'assets/images/payments/orange_money_logo.png',
    'wave': 'assets/images/payments/wave_logo.png',
    'free_money': 'assets/images/payments/free_money_logo.png',
  };

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      final auth = Provider.of<AuthProvider>(context, listen: false);
      await auth.refreshProfile();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Bouton flottant Accueil
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).popUntil((route) => route.isFirst);
        },
        backgroundColor: AppTheme.primaryColor,
        child: const Icon(Icons.home, color: Colors.white),
        tooltip: 'Accueil',
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.startFloat,
      appBar: AppBar(
        title: const Text('Mon Profil'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: _editProfile,
          ),
        ],
      ),
      body: Container(
        color: Colors.white,
        child: SafeArea(
          child: SingleChildScrollView(
            child: Column(
              children: [
                // En-tête du profil
                Container(
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // Photo de profil
                      Stack(
                        children: [
                              Consumer<AuthProvider>(
                            builder: (context, authProvider, child) {
                              final user = authProvider.user;
                              final initials = user != null
                                  ? '${user.firstName[0]}${user.lastName[0]}'
                                  : 'U';
                              return CircleAvatar(
                                radius: 50,
                                backgroundColor: AppTheme.primaryColor,
                                child: Text(
                                  initials,
                                  style: const TextStyle(
                                    fontSize: 32,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              );
                            },
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: AppTheme.primaryColor,
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 2),
                              ),
                              child: const Icon(
                                Icons.camera_alt,
                                size: 16,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Nom et informations
                      Consumer<AuthProvider>(
                        builder: (context, authProvider, child) {
                          final user = authProvider.user;
                          return Column(
                            children: [
                              Text(
                                user?.fullName ?? 'Utilisateur',
                                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey[800],
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                user?.phone ?? '',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 16),
                      // Statistiques
                      Consumer<AuthProvider>(
                        builder: (context, authProvider, child) {
                          final user = authProvider.user;
                          final totalRides = user?.totalRides ?? 0;
                          final rating = totalRides > 0
                              ? '${(user?.averageRating ?? 0).toStringAsFixed(1)} ⭐'
                              : 'Nouveau';
                          
                          return Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _buildStatItem('Note', rating, Icons.star),
                              _buildStatItem('Courses', '$totalRides', Icons.directions_car),
                              _buildStatItem(
                                'Membre',
                                user?.createdAt != null
                                    ? '${user!.createdAt!.year}'
                                    : '—',
                                Icons.calendar_today,
                              ),
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                ),
                // Informations personnelles
                Consumer<AuthProvider>(
                  builder: (context, authProvider, child) {
                    final user = authProvider.user;
                    return _buildSection(
                      'Informations personnelles',
                      Icons.person,
                      [
                        _buildInfoItem('Prénom', user?.firstName ?? '', Icons.badge),
                        _buildInfoItem('Nom', user?.lastName ?? '', Icons.badge),
                        _buildInfoItem('Téléphone', user?.phone ?? '', Icons.phone),
                        _buildInfoItem('Email', user?.email ?? 'Non renseigné', Icons.email),
                      ],
                    );
                  },
                ),
                // Préférences
                Consumer<AuthProvider>(
                  builder: (context, authProvider, child) {
                    final user = authProvider.user;
                    final paymentMethod = user?.budgetSettings?.preferredPaymentMethod;
                    final paymentLabel = paymentMethod == null
                        ? 'Non défini'
                        : paymentMethod == 'cash'
                            ? 'Espèces'
                            : 'Wave';
                    return _buildSection(
                      'Préférences',
                      Icons.settings,
                      [
                        _buildInfoItem('Langue', user?.language ?? 'Français', Icons.language),
                        _buildInfoItem('Méthode de paiement', paymentLabel, Icons.payment),
                      ],
                    );
                  },
                ),
                // Actions
                _buildSection(
                  'Actions',
                  Icons.more_vert,
                  [
                    _buildActionItem(
                      'Moyens de paiement',
                      Icons.credit_card,
                      () => _showPaymentMethods(),
                    ),
                    _buildActionItem(
                      'Historique des courses',
                      Icons.history,
                      () => _showRideHistory(),
                    ),
                    _buildActionItem(
                      'Notifications',
                      Icons.notifications,
                      () => _showNotifications(),
                    ),
                    _buildActionItem(
                      'Aide et support',
                      Icons.help,
                      () => _showHelp(),
                    ),
                    _buildActionItem(
                      'À propos',
                      Icons.info,
                      () => _showAbout(),
                    ),
                  ],
                ),
                // Bouton de déconnexion
                Container(
                  margin: const EdgeInsets.all(16),
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
                    ),
                    child: const Text(
                      'Se déconnecter',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: AppTheme.primaryColor, size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildSection(String title, IconData icon, List<Widget> children) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Icon(icon, color: AppTheme.primaryColor),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(children: children),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(String label, String value, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppTheme.primaryColor, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionItem(String title, IconData icon, VoidCallback onTap) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: AppTheme.primaryColor, size: 20),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
          ),
        ),
        trailing: Icon(
          Icons.arrow_forward_ios,
          size: 16,
          color: Colors.grey[400],
        ),
        onTap: onTap,
      ),
    );
  }

  void _editProfile() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.user;
    
    final firstNameController = TextEditingController(text: user?.firstName ?? '');
    final lastNameController = TextEditingController(text: user?.lastName ?? '');
    final emailController = TextEditingController(text: user?.email ?? '');
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Modifier le profil'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: firstNameController,
                decoration: const InputDecoration(
                  labelText: 'Prénom',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: lastNameController,
                decoration: const InputDecoration(
                  labelText: 'Nom',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () async {
              final firstName = firstNameController.text.trim();
              final lastName = lastNameController.text.trim();
              final email = emailController.text.trim();

              if (firstName.isEmpty || lastName.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Prénom et nom requis'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }

              final response = await ApiService.updateProfile(
                firstName: firstName,
                lastName: lastName,
                email: email.isEmpty ? null : email,
              );

              if (!mounted) return;

              if (response.success && response.data != null) {
                await authProvider.refreshProfile();
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Profil mis à jour avec succès'),
                    backgroundColor: Colors.green,
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(response.message),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryColor),
            child: const Text('Enregistrer'),
          ),
        ],
      ),
    );
  }

  void _showPaymentMethods() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.user;
    final currentMethod = user?.budgetSettings?.preferredPaymentMethod ?? 'wave';
    final userPhone = user?.phone ?? '';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Moyens de paiement'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.only(bottom: 8),
              child: Text(
                'Orange Money et Free Money : bientôt. Wave et espèces disponibles.',
                style: TextStyle(fontSize: 13, color: Colors.grey),
              ),
            ),
            ListTile(
              leading: Image.asset(
                _paymentLogos['wave']!,
                width: 28,
                height: 28,
                errorBuilder: (_, __, ___) => const Icon(Icons.account_balance_wallet),
              ),
              title: const Text('Wave'),
              subtitle: Text(userPhone.isNotEmpty ? userPhone : 'Non configuré'),
              trailing: currentMethod == 'wave'
                  ? const Icon(Icons.check_circle, color: Colors.green)
                  : null,
              onTap: () => _updatePaymentMethod('wave'),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.payments, color: Colors.green),
              title: const Text('Espèces'),
              subtitle: const Text('Payer en espèces au chauffeur'),
              trailing: currentMethod == 'cash'
                  ? const Icon(Icons.check_circle, color: Colors.green)
                  : null,
              onTap: () => _updatePaymentMethod('cash'),
            ),
            const Divider(),
            Opacity(
              opacity: 0.55,
              child: ListTile(
                enabled: false,
                leading: Image.asset(
                  _paymentLogos['orange_money']!,
                  width: 28,
                  height: 28,
                  errorBuilder: (_, __, ___) => const Icon(Icons.account_balance_wallet, color: Colors.grey),
                ),
                title: const Text('Orange Money'),
                subtitle: const Text('Indisponible pour le moment'),
                trailing: const Icon(Icons.lock_outline, color: Colors.grey),
              ),
            ),
            Opacity(
              opacity: 0.55,
              child: ListTile(
                enabled: false,
                leading: Image.asset(
                  _paymentLogos['free_money']!,
                  width: 28,
                  height: 28,
                  errorBuilder: (_, __, ___) => const Icon(Icons.account_balance_wallet, color: Colors.grey),
                ),
                title: const Text('Free Money'),
                subtitle: const Text('Indisponible pour le moment'),
                trailing: const Icon(Icons.lock_outline, color: Colors.grey),
              ),
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

  Future<void> _updatePaymentMethod(String method) async {
    Navigator.pop(context);
    
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Mise à jour du moyen de paiement...')),
    );

    try {
      final response = await ApiService.updateBudgetSettings(
        preferredPaymentMethod: method,
      );

      if (response.success && mounted) {
        await authProvider.refreshProfile();
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Moyen de paiement mis à jour : ${_getPaymentLabel(method)}'),
            backgroundColor: Colors.green,
          ),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: ${response.message}'),
            backgroundColor: Colors.red,
          ),
        );
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

  String _getPaymentLabel(String method) {
    switch (method) {
      case 'wave':
        return 'Wave';
      case 'cash':
        return 'Espèces';
      case 'orange_money':
        return 'Orange Money';
      case 'free_money':
        return 'Free Money';
      default:
        return 'Non défini';
    }
  }

  void _showRideHistory() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const RidesScreen(),
      ),
    );
  }

  void _showNotifications() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Notifications'),
        content: const Text('Fonctionnalité en cours de développement'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showHelp() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Aide et support'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.phone),
              title: Text('Support client'),
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
              subtitle: Text('Disponible 24h/24'),
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

  void _showAbout() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('À propos de DuDu'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('DuDu - Votre compagnon de transport à Dakar'),
            SizedBox(height: 16),
            Text('Version: 1.0.0'),
            Text('Développé avec ❤️ au Sénégal'),
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

  void _logout() async {
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
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              final authProvider = Provider.of<AuthProvider>(context, listen: false);
              await authProvider.logout();
              if (mounted) {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                  (route) => false,
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Se déconnecter'),
          ),
        ],
      ),
    );
  }
}

