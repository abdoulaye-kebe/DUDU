import 'package:flutter/material.dart';
import '../services/api_service.dart';

class DriverRegistrationScreen extends StatefulWidget {
  const DriverRegistrationScreen({super.key});

  @override
  State<DriverRegistrationScreen> createState() => _DriverRegistrationScreenState();
}

class _DriverRegistrationScreenState extends State<DriverRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();

  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _nationalIdController = TextEditingController();
  final _dateOfBirthController = TextEditingController();
  final _licenseNumberController = TextEditingController();
  final _licenseExpiryController = TextEditingController();
  final _vehicleMakeController = TextEditingController();
  final _vehicleModelController = TextEditingController();
  final _vehicleYearController = TextEditingController(text: DateTime.now().year.toString());
  final _vehicleColorController = TextEditingController();
  final _vehiclePlateController = TextEditingController();
  final _insuranceController = TextEditingController();
  final _insuranceExpiryController = TextEditingController();
  final _technicalInspectionController = TextEditingController();
  final _technicalInspectionExpiryController = TextEditingController();

  bool _isSubmitting = false;
  String? _errorMessage;
  String _gender = 'male';
  bool _acceptSharedRides = false;
  bool _acceptTerms = false;
  bool _isMotoCourier = false; // true = livreur moto, false = chauffeur voiture

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _nationalIdController.dispose();
    _dateOfBirthController.dispose();
    _licenseNumberController.dispose();
    _licenseExpiryController.dispose();
    _vehicleMakeController.dispose();
    _vehicleModelController.dispose();
    _vehicleYearController.dispose();
    _vehicleColorController.dispose();
    _vehiclePlateController.dispose();
    _insuranceController.dispose();
    _insuranceExpiryController.dispose();
    _technicalInspectionController.dispose();
    _technicalInspectionExpiryController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_acceptTerms) {
      setState(() => _errorMessage = 'Vous devez accepter les conditions d\'utilisation.');
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    final payload = {
      'firstName': _firstNameController.text.trim(),
      'lastName': _lastNameController.text.trim(),
      'phone': _phoneController.text.trim(),
      'email': _emailController.text.trim().isEmpty ? null : _emailController.text.trim(),
      'password': _passwordController.text.trim(),
      'dateOfBirth': _dateOfBirthController.text.trim().isEmpty ? null : _dateOfBirthController.text.trim(),
      'gender': _gender,
      'nationalId': _nationalIdController.text.trim().isEmpty ? null : _nationalIdController.text.trim(),
      'address': {
        'street': '',
        'city': 'Dakar',
        'region': 'Dakar',
        'country': 'Sénégal',
      },
      'driverLicense': {
        'number': _licenseNumberController.text.trim(),
        'expiryDate': _licenseExpiryController.text.trim(),
        'category': _isMotoCourier ? 'A' : 'B',
      },
      'vehicle': {
        'make': _vehicleMakeController.text.trim(),
        'model': _vehicleModelController.text.trim(),
        'year': int.tryParse(_vehicleYearController.text.trim()) ?? DateTime.now().year,
        'color': _vehicleColorController.text.trim(),
        'plateNumber': _vehiclePlateController.text.trim(),
        'category': _isMotoCourier ? 'moto' : 'car',
        'type': _isMotoCourier ? 'moto_delivery' : 'sedan',
        'capacity': _isMotoCourier ? 1 : 4,
      },
      'rideTypes': {
        'standard': !_isMotoCourier,
        'express': true,
        'shared': _isMotoCourier ? false : _acceptSharedRides,
        'womenOnly': false,
      },
      'preferences': {
        'maxDistance': _isMotoCourier ? 20 : 10,
        'minPrice': _isMotoCourier ? 500 : 1000,
        'acceptSharedRides': _isMotoCourier ? false : _acceptSharedRides,
      },
      'documents': {
        'insurance': _insuranceController.text.trim(),
        'insuranceExpiryDate': _insuranceExpiryController.text.trim(),
        'technicalInspection': _technicalInspectionController.text.trim(),
        'technicalInspectionExpiryDate': _technicalInspectionExpiryController.text.trim(),
      },
    };

    try {
      final response = await ApiService.applyAsDriver(payload);
      if (!mounted) return;

      if (response['success'] == true) {
        await showDialog<void>(
          context: context,
          builder: (context) => AlertDialog(
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0d5d36).withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_circle,
                    color: Color(0xFF0d5d36),
                    size: 28,
                  ),
                ),
                const SizedBox(width: 12),
                const Text('Demande envoyée'),
              ],
            ),
            content: const Text(
              'Votre candidature a été envoyée.\n'
              'Notre équipe l\'examinera prochainement et vous serez notifié(e) par SMS ou email.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFF0d5d36),
                ),
                child: const Text('OK', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        );
        Navigator.pop(context);
      } else {
        setState(() {
          _errorMessage = response['message']?.toString() ?? 'Erreur lors de l\'envoi de la candidature.';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Inscription Chauffeur'),
        backgroundColor: const Color(0xFF0d5d36),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // En-tête avec icône
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFF0d5d36),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.person_add,
                      size: 48,
                      color: Color(0xFF0d5d36),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Rejoignez DUDU PRO',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Complétez votre profil\nValidation sous 24h',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),
            // Formulaire
            Padding(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 8),
                    // Sélection du type de profil
                    _buildCard(
                      icon: Icons.badge,
                      title: 'Type de profil',
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: _buildProfileTypeCard(
                                  icon: Icons.directions_car,
                                  label: 'Chauffeur\nVoiture',
                                  isSelected: !_isMotoCourier,
                                  onTap: () => setState(() => _isMotoCourier = false),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildProfileTypeCard(
                                  icon: Icons.motorcycle,
                                  label: 'Livreur\nMoto',
                                  isSelected: _isMotoCourier,
                                  onTap: () => setState(() => _isMotoCourier = true),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F8F4),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.info_outline,
                                  size: 20,
                                  color: const Color(0xFF0d5d36),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _isMotoCourier
                                        ? 'Livraisons rapides et forfait journalier 500 FCFA'
                                        : 'Tous types de courses et forfaits disponibles',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFF0d5d36),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    _buildSectionHeader('Informations personnelles', Icons.person),
              _buildTextField(_firstNameController, label: 'Prénom', icon: Icons.person_outline),
              _buildTextField(_lastNameController, label: 'Nom', icon: Icons.person),
              _buildTextField(
                _phoneController,
                label: 'Téléphone',
                icon: Icons.phone,
                keyboardType: TextInputType.phone,
              ),
              _buildTextField(
                _emailController,
                label: 'Email (optionnel)',
                icon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.isEmpty) return null;
                  if (!value.contains('@') || !value.contains('.')) {
                    return 'Email invalide (ex: nom@domaine.com)';
                  }
                  return null;
                },
              ),
              _buildTextField(
                _dateOfBirthController,
                label: 'Date de naissance (YYYY-MM-DD)',
                icon: Icons.cake_outlined,
                validator: (value) {
                  if (value == null || value.isEmpty) return null;
                  final regex = RegExp(r'^\d{4}-\d{2}-\d{2}$');
                  if (!regex.hasMatch(value)) return 'Format attendu AAAA-MM-JJ';
                  return null;
                },
              ),
              DropdownButtonFormField<String>(
                value: _gender,
                decoration: const InputDecoration(
                  labelText: 'Genre',
                  prefixIcon: Icon(Icons.wc),
                ),
                items: const [
                  DropdownMenuItem(value: 'male', child: Text('Homme')),
                  DropdownMenuItem(value: 'female', child: Text('Femme')),
                  DropdownMenuItem(value: 'other', child: Text('Autre')),
                ],
                onChanged: (value) => setState(() => _gender = value ?? 'male'),
              ),
              _buildTextField(
                _nationalIdController,
                label: 'CNI',
                icon: Icons.badge_outlined,
              ),
                    const SizedBox(height: 20),
                    _buildSectionHeader('Sécurité du compte', Icons.security),
              _buildTextField(
                _passwordController,
                label: 'Mot de passe',
                icon: Icons.lock_outline,
                obscureText: true,
              ),
              _buildTextField(
                _confirmPasswordController,
                label: 'Confirmer le mot de passe',
                icon: Icons.lock,
                obscureText: true,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Confirmation requise';
                  }
                  if (value != _passwordController.text) {
                    return 'Les mots de passe ne correspondent pas';
                  }
                  return null;
                },
              ),
                    const SizedBox(height: 20),
                    _buildSectionHeader('Permis de conduire', Icons.credit_card),
              _buildTextField(_licenseNumberController, label: 'Numéro de permis', icon: Icons.credit_card),
              _buildTextField(
                _licenseExpiryController,
                label: 'Expiration (YYYY-MM-DD)',
                icon: Icons.calendar_month,
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Date d\'expiration requise';
                  final regex = RegExp(r'^\d{4}-\d{2}-\d{2}$');
                  if (!regex.hasMatch(value)) return 'Format attendu AAAA-MM-JJ';
                  return null;
                },
              ),
                    const SizedBox(height: 20),
                    _buildSectionHeader(
                      _isMotoCourier ? 'Moto de livraison' : 'Véhicule',
                      _isMotoCourier ? Icons.motorcycle : Icons.directions_car,
                    ),
              _buildTextField(
                _vehicleMakeController,
                label: _isMotoCourier ? 'Marque de la moto' : 'Marque',
                icon: Icons.directions_bike,
              ),
              _buildTextField(
                _vehicleModelController,
                label: _isMotoCourier ? 'Modèle de la moto' : 'Modèle',
                icon: _isMotoCourier ? Icons.motorcycle : Icons.directions_car_filled,
              ),
              _buildTextField(
                _vehicleYearController,
                label: 'Année',
                icon: Icons.event,
                keyboardType: TextInputType.number,
                validator: (value) {
                  final year = int.tryParse(value ?? '');
                  if (year == null) return 'Année invalide';
                  if (year < 1990 || year > DateTime.now().year + 1) {
                    return 'Année hors plage';
                  }
                  return null;
                },
              ),
              _buildTextField(_vehicleColorController, label: 'Couleur', icon: Icons.brush_outlined),
              _buildTextField(_vehiclePlateController, label: 'Immatriculation', icon: Icons.confirmation_number),
                    const SizedBox(height: 20),
                    _buildSectionHeader('Documents', Icons.description),
              _buildTextField(
                _insuranceController,
                label: 'Assurance (compagnie / numéro de police)',
                icon: Icons.description_outlined,
              ),
              _buildTextField(
                _insuranceExpiryController,
                label: 'Date de validité de l\'assurance (YYYY-MM-DD)',
                icon: Icons.calendar_today_outlined,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Date de validité requise';
                  }
                  final regex = RegExp(r'^\d{4}-\d{2}-\d{2}$');
                  if (!regex.hasMatch(value)) return 'Format attendu AAAA-MM-JJ';
                  return null;
                },
              ),
              _buildTextField(
                _technicalInspectionController,
                label: 'Contrôle technique (centre / référence)',
                icon: Icons.garage_outlined,
              ),
              _buildTextField(
                _technicalInspectionExpiryController,
                label: 'Date d\'expiration du contrôle technique (YYYY-MM-DD)',
                icon: Icons.calendar_today,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Date d\'expiration requise';
                  }
                  final regex = RegExp(r'^\d{4}-\d{2}-\d{2}$');
                  if (!regex.hasMatch(value)) return 'Format attendu AAAA-MM-JJ';
                  return null;
                },
              ),
                    const SizedBox(height: 20),
                    if (!_isMotoCourier)
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: const Color(0xFF0d5d36).withOpacity(0.3)),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: SwitchListTile(
                          title: const Text('Accepter les trajets partagés'),
                          subtitle: const Text('Augmentez vos revenus', style: TextStyle(fontSize: 12)),
                          value: _acceptSharedRides,
                          activeColor: const Color(0xFF0d5d36),
                          onChanged: (value) => setState(() => _acceptSharedRides = value),
                        ),
                      ),
                    const SizedBox(height: 12),
                    Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F8F4),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _acceptTerms ? const Color(0xFF0d5d36) : Colors.grey.shade300,
                          width: 2,
                        ),
                      ),
                      child: CheckboxListTile(
                        value: _acceptTerms,
                        activeColor: const Color(0xFF0d5d36),
                        onChanged: (value) => setState(() => _acceptTerms = value ?? false),
                        title: const Text(
                          'J\'accepte les conditions d\'utilisation',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: const Text(
                          'Conditions DUDU Chauffeur',
                          style: TextStyle(fontSize: 12),
                        ),
                      ),
                    ),
                    if (_errorMessage != null) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.red.shade200),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.error_outline, color: Colors.red.shade700),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                _errorMessage!,
                                style: TextStyle(
                                  color: Colors.red.shade700,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _isSubmitting ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0d5d36),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 4,
                      ),
                      child: _isSubmitting
                          ? const SizedBox(
                              height: 24,
                              width: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: const [
                                Icon(Icons.send, size: 20),
                                SizedBox(width: 8),
                                Text(
                                  'Envoyer ma candidature',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F8F4),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF0d5d36),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 12),
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0d5d36),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard({required IconData icon, required String title, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF0d5d36).withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF0d5d36).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: const Color(0xFF0d5d36), size: 24),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0d5d36),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Widget _buildProfileTypeCard({
    required IconData icon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF0d5d36) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? const Color(0xFF0d5d36) : Colors.grey.shade300,
            width: 2,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 40,
              color: isSelected ? Colors.white : const Color(0xFF0d5d36),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : const Color(0xFF0d5d36),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller, {
    required String label,
    IconData? icon,
    TextInputType keyboardType = TextInputType.text,
    bool obscureText = false,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        obscureText: obscureText,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: icon != null
              ? Icon(icon, color: const Color(0xFF0d5d36))
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF0d5d36), width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.red.shade300),
          ),
          filled: true,
          fillColor: Colors.grey.shade50,
        ),
        validator: validator ??
            (value) {
              if (value == null || value.trim().isEmpty) {
                return '$label requis';
              }
              return null;
            },
      ),
    );
  }
}


