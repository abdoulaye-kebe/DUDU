import 'package:flutter/material.dart';
import '../services/api_service.dart';

class DriverRegistrationScreen extends StatefulWidget {
  const DriverRegistrationScreen({super.key});

  @override
  State<DriverRegistrationScreen> createState() => _DriverRegistrationScreenState();
}

class _DriverRegistrationScreenState extends State<DriverRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();

  // Contrôleurs simplifiés - uniquement les données essentielles
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _nationalIdController = TextEditingController();
  final _licenseNumberController = TextEditingController();
  final _vehicleMakeController = TextEditingController();
  final _vehicleModelController = TextEditingController();
  final _vehicleYearController = TextEditingController();
  final _vehicleColorController = TextEditingController();
  final _vehiclePlateController = TextEditingController();
  final _insuranceController = TextEditingController();
  final _technicalInspectionController = TextEditingController();

  DateTime? _dateOfBirth;
  DateTime? _licenseExpiry;
  DateTime? _insuranceExpiry;
  DateTime? _technicalInspectionExpiry;

  bool _isSubmitting = false;
  String? _errorMessage;
  String _gender = 'male';
  bool _acceptTerms = false;
  bool _isMotoCourier = false;

  void _setProfileType(bool isMotoCourier) {
    setState(() {
      _isMotoCourier = isMotoCourier;

      // Reset fields that depend on the selected profile type
      _licenseNumberController.clear();
      _licenseExpiry = null;

      _vehicleMakeController.clear();
      _vehicleModelController.clear();
      _vehicleYearController.clear();
      _vehicleColorController.clear();
      _vehiclePlateController.clear();

      _insuranceController.clear();
      _insuranceExpiry = null;
      _technicalInspectionController.clear();
      _technicalInspectionExpiry = null;

      _errorMessage = null;
    });
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _nationalIdController.dispose();
    _licenseNumberController.dispose();
    _vehicleMakeController.dispose();
    _vehicleModelController.dispose();
    _vehicleYearController.dispose();
    _vehicleColorController.dispose();
    _vehiclePlateController.dispose();
    _insuranceController.dispose();
    _technicalInspectionController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context, {required String field}) async {
    final isBirthDate = field == 'birth';
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isBirthDate
          ? DateTime(2000, 1, 1)
          : DateTime.now().add(const Duration(days: 365)),
      firstDate: isBirthDate ? DateTime(1950) : DateTime.now(),
      lastDate: isBirthDate ? DateTime.now() : DateTime(2050),
      locale: const Locale('fr', 'FR'),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF0d5d36),
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        switch (field) {
          case 'birth':
            _dateOfBirth = picked;
            break;
          case 'licenseExpiry':
            _licenseExpiry = picked;
            break;
          case 'insuranceExpiry':
            _insuranceExpiry = picked;
            break;
          case 'technicalInspectionExpiry':
            _technicalInspectionExpiry = picked;
            break;
        }
      });
    }
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
      'dateOfBirth': _dateOfBirth?.toIso8601String().split('T')[0],
      'gender': _gender,
      'nationalId': _nationalIdController.text.trim(),
      'address': {
        'city': 'Dakar',
        'region': 'Dakar',
        'country': 'Sénégal',
      },
      'driverLicense': {
        'number': _licenseNumberController.text.trim(),
        'expiryDate': _licenseExpiry?.toIso8601String().split('T')[0],
        'category': _isMotoCourier ? 'A' : 'B',
      },
      'documents': {
        'insurance': _insuranceController.text.trim(),
        'insuranceExpiryDate': _insuranceExpiry?.toIso8601String().split('T')[0],
        'technicalInspection': _technicalInspectionController.text.trim(),
        'technicalInspectionExpiryDate':
            _technicalInspectionExpiry?.toIso8601String().split('T')[0],
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
      'preferences': {
        'maxDistance': _isMotoCourier ? 20 : 10,
        'minPrice': _isMotoCourier ? 500 : 1000,
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
        final msg = response['message']?.toString();
        final errors = response['errors'];
        String details = '';
        final lines = <String>[];
        if (errors is List) {
          for (final e in errors) {
            if (e is Map) {
              final path = e['path']?.toString();
              final emsg = e['msg']?.toString();
              if (path != null && emsg != null) {
                lines.add('- $path: $emsg');
              } else if (emsg != null) {
                lines.add('- $emsg');
              }
            } else if (e != null) {
              lines.add('- $e');
            }
          }
        } else if (errors is Map) {
          errors.forEach((k, v) {
            if (v == null) return;
            lines.add('- $k: $v');
          });
        }
        if (lines.isNotEmpty) {
          details = '\n\nDétails:\n${lines.join('\n')}';
        }
        setState(() {
          _errorMessage = (msg == null || msg.isEmpty)
              ? 'Données invalides$details'
              : '$msg$details';
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

  Widget _buildTextField(
    TextEditingController controller, {
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    bool obscureText = false,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        obscureText: obscureText,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: const Color(0xFF0d5d36)),
          filled: true,
          fillColor: const Color(0xFFF5F5F5),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF0d5d36), width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.red, width: 1),
          ),
        ),
        validator: validator ?? (value) {
          if (value == null || value.isEmpty) {
            return 'Ce champ est requis';
          }
          return null;
        },
      ),
    );
  }

  Widget _buildDateField({
    required String label,
    required IconData icon,
    required DateTime? selectedDate,
    required String field,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: () => _selectDate(context, field: field),
        child: InputDecorator(
          decoration: InputDecoration(
            labelText: label,
            prefixIcon: Icon(icon, color: const Color(0xFF0d5d36)),
            suffixIcon: const Icon(Icons.calendar_today, color: Color(0xFF0d5d36)),
            filled: true,
            fillColor: const Color(0xFFF5F5F5),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF0d5d36), width: 2),
            ),
          ),
          child: Text(
            selectedDate != null
                ? '${selectedDate.day.toString().padLeft(2, '0')}/${selectedDate.month.toString().padLeft(2, '0')}/${selectedDate.year}'
                : 'Sélectionner une date',
            style: TextStyle(
              color: selectedDate != null ? Colors.black : Colors.grey,
              fontSize: 16,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileTypeCard({
    required IconData icon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF0d5d36) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? const Color(0xFF0d5d36) : Colors.grey.shade300,
            width: 2,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 20,
              color: isSelected ? Colors.white : const Color(0xFF0d5d36),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: isSelected ? Colors.white : Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Inscription'),
        backgroundColor: const Color(0xFF0d5d36),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Type de profil
                const Text(
                  'Type de profil',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0d5d36),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildProfileTypeCard(
                        icon: Icons.directions_car,
                        label: 'Chauffeur\nVoiture',
                        isSelected: !_isMotoCourier,
                        onTap: () => _setProfileType(false),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildProfileTypeCard(
                        icon: Icons.motorcycle,
                        label: 'Livreur\nMoto',
                        isSelected: _isMotoCourier,
                        onTap: () => _setProfileType(true),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),

                // Informations personnelles
                const Text(
                  'Informations personnelles',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0d5d36),
                  ),
                ),
                const SizedBox(height: 16),
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
                    final v = value?.trim() ?? '';
                    if (v.isEmpty) return null;
                    final ok = RegExp(r'^\S+@\S+\.\S+$').hasMatch(v);
                    return ok ? null : 'Email invalide';
                  },
                ),
                _buildDateField(
                  label: 'Date de naissance',
                  icon: Icons.cake_outlined,
                  selectedDate: _dateOfBirth,
                  field: 'birth',
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: DropdownButtonFormField<String>(
                    value: _gender,
                    decoration: InputDecoration(
                      labelText: 'Genre',
                      prefixIcon: const Icon(Icons.wc, color: Color(0xFF0d5d36)),
                      filled: true,
                      fillColor: const Color(0xFFF5F5F5),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'male', child: Text('Homme')),
                      DropdownMenuItem(value: 'female', child: Text('Femme')),
                      DropdownMenuItem(value: 'other', child: Text('Autre')),
                    ],
                    onChanged: (value) => setState(() => _gender = value ?? 'male'),
                  ),
                ),
                _buildTextField(
                  _nationalIdController,
                  label: 'Numéro CNI',
                  icon: Icons.badge_outlined,
                ),
                const SizedBox(height: 24),

                // Sécurité
                const Text(
                  'Sécurité du compte',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0d5d36),
                  ),
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  _passwordController,
                  label: 'Mot de passe',
                  icon: Icons.lock_outline,
                  obscureText: true,
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Ce champ est requis';
                    if (value.length < 6) return 'Minimum 6 caractères';
                    return null;
                  },
                ),
                _buildTextField(
                  _confirmPasswordController,
                  label: 'Confirmer le mot de passe',
                  icon: Icons.lock,
                  obscureText: true,
                  validator: (value) {
                    if (value != _passwordController.text) {
                      return 'Les mots de passe ne correspondent pas';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),

                // Permis de conduire
                const Text(
                  'Permis de conduire',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0d5d36),
                  ),
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  _licenseNumberController,
                  label: 'Numéro de permis',
                  icon: Icons.credit_card,
                ),
                _buildDateField(
                  label: 'Date d\'expiration du permis',
                  icon: Icons.event,
                  selectedDate: _licenseExpiry,
                  field: 'licenseExpiry',
                ),
                const SizedBox(height: 24),

                // Documents
                const Text(
                  'Documents',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0d5d36),
                  ),
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  _insuranceController,
                  label: 'Assurance',
                  icon: Icons.verified_user_outlined,
                ),
                _buildDateField(
                  label: 'Date de validité de l\'assurance',
                  icon: Icons.event,
                  selectedDate: _insuranceExpiry,
                  field: 'insuranceExpiry',
                ),
                _buildTextField(
                  _technicalInspectionController,
                  label: 'Contrôle technique',
                  icon: Icons.build_circle_outlined,
                ),
                _buildDateField(
                  label: 'Date d\'expiration du contrôle technique',
                  icon: Icons.event,
                  selectedDate: _technicalInspectionExpiry,
                  field: 'technicalInspectionExpiry',
                ),
                const SizedBox(height: 24),

                // Véhicule
                Text(
                  _isMotoCourier ? 'Informations moto' : 'Informations véhicule',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0d5d36),
                  ),
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  _vehicleMakeController,
                  label: 'Marque',
                  icon: Icons.directions_car_outlined,
                ),
                _buildTextField(
                  _vehicleModelController,
                  label: 'Modèle',
                  icon: Icons.car_rental,
                ),
                _buildTextField(
                  _vehicleYearController,
                  label: 'Année',
                  icon: Icons.calendar_today,
                  keyboardType: TextInputType.number,
                ),
                _buildTextField(
                  _vehicleColorController,
                  label: 'Couleur',
                  icon: Icons.palette_outlined,
                ),
                _buildTextField(
                  _vehiclePlateController,
                  label: 'Plaque d\'immatriculation',
                  icon: Icons.pin,
                ),
                const SizedBox(height: 24),

                // Conditions
                CheckboxListTile(
                  value: _acceptTerms,
                  onChanged: (value) => setState(() => _acceptTerms = value ?? false),
                  title: const Text(
                    'J\'accepte les conditions d\'utilisation',
                    style: TextStyle(fontSize: 14),
                  ),
                  activeColor: const Color(0xFF0d5d36),
                  controlAffinity: ListTileControlAffinity.leading,
                  contentPadding: EdgeInsets.zero,
                ),

                // Message d'erreur
                if (_errorMessage != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline, color: Colors.red, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: const TextStyle(color: Colors.red, fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 24),

                // Bouton de soumission
                ElevatedButton(
                  onPressed: _isSubmitting ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0d5d36),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
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
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
