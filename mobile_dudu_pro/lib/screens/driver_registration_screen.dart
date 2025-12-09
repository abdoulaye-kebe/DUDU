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
            title: const Text('Demande envoyée'),
            content: const Text(
              'Votre candidature a été envoyée.\n'
              'Notre équipe l\'examinera prochainement et vous serez notifié(e) par SMS ou email.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
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
      appBar: AppBar(
        title: const Text('Inscription chauffeur / livreur'),
        backgroundColor: const Color(0xFF0d5d36),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 8),
              const Text(
                'Complétez les informations ci-dessous.\nNous validerons votre profil sous 24h.',
                style: TextStyle(fontSize: 14, color: Colors.black54),
              ),
              const SizedBox(height: 12),
              // Sélection du type de profil
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Type de profil',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0d5d36),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: ChoiceChip(
                            label: const Text('Chauffeur voiture'),
                            selected: !_isMotoCourier,
                            onSelected: (selected) {
                              if (selected) {
                                setState(() {
                                  _isMotoCourier = false;
                                });
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ChoiceChip(
                            label: const Text('Livreur moto'),
                            selected: _isMotoCourier,
                            onSelected: (selected) {
                              if (selected) {
                                setState(() {
                                  _isMotoCourier = true;
                                });
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _isMotoCourier
                          ? 'Profil livreur moto : accès au forfait journalier 500 FCFA et livraisons.'
                          : 'Profil chauffeur voiture : accès à tous les forfaits et types de courses.',
                      style: const TextStyle(fontSize: 12, color: Colors.black54),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _buildSectionTitle('Informations personnelles'),
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
                keyboardType: TextInputType.text,
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
              const SizedBox(height: 16),
              _buildSectionTitle('Sécurité du compte'),
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
              const SizedBox(height: 16),
              _buildSectionTitle('Permis de conduire'),
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
              const SizedBox(height: 16),
              _buildSectionTitle(_isMotoCourier ? 'Moto de livraison' : 'Véhicule'),
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
              const SizedBox(height: 16),
              _buildSectionTitle('Assurance et contrôle technique'),
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
              SwitchListTile(
                title: const Text('Accepter les trajets partagés'),
                value: _acceptSharedRides,
                onChanged: (value) => setState(() => _acceptSharedRides = value),
              ),
              CheckboxListTile(
                value: _acceptTerms,
                onChanged: (value) => setState(() => _acceptTerms = value ?? false),
                title: const Text('J\'accepte les conditions d\'utilisation DUDU Chauffeur'),
              ),
              if (_errorMessage != null) ...[
                const SizedBox(height: 8),
                Text(
                  _errorMessage!,
                  style: const TextStyle(color: Colors.red, fontWeight: FontWeight.w600),
                ),
              ],
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _isSubmitting ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0d5d36),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text(
                        'Envoyer ma candidature',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Text(
        title,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0d5d36)),
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
          prefixIcon: icon != null ? Icon(icon) : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
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


