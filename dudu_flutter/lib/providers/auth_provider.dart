import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/user.dart';
import '../services/api_service.dart';

class AuthProvider extends ChangeNotifier {
  User? _user;
  String? _authToken;
  bool _isLoading = false;
  String? _errorMessage;
  bool _isAuthenticated = false;

  // Getters
  User? get user => _user;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _isAuthenticated;
  String get userDisplayName => _user != null ? '${_user!.firstName} ${_user!.lastName}' : '';
  String get userPhone => _user?.phone ?? '';

  // Connexion
  Future<bool> login(String phone, String password) async {
    _setLoading(true);
    _clearError();

    try {
      final response = await ApiService.login(phone, password);
      
      if (response.success && response.data != null) {
        _user = response.data!.user;
        _authToken = response.data!.token;
        _isAuthenticated = true;
        
        await _saveUserData(_user!);
        await _saveToken(_authToken!);
        
        _setLoading(false);
        notifyListeners();
        return true;
      } else {
        _setError(response.message);
        _setLoading(false);
        return false;
      }
    } catch (e) {
      _setError('Erreur de connexion: $e');
      _setLoading(false);
      return false;
    }
  }

  // Inscription
  Future<bool> register({
    required String firstName,
    required String lastName,
    required String phone,
    required String password,
    String language = 'fr',
    String? referralCode,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      final response = await ApiService.register(
        firstName: firstName,
        lastName: lastName,
        phone: phone,
        password: password,
        language: language,
        referralCode: referralCode,
      );
      
      if (response.success && response.data != null) {
        _user = response.data!.user;
        _authToken = response.data!.token;
        _isAuthenticated = true;
        
        await _saveUserData(_user!);
        await _saveToken(_authToken!);
        
        _setLoading(false);
        return true;
      } else {
        _setError(response.message);
        _setLoading(false);
        return false;
      }
    } catch (e) {
      _setError('Erreur d\'inscription: $e');
      _setLoading(false);
      return false;
    }
  }

  // Vérification du code SMS
  Future<bool> verifyPhone(String phone, String code) async {
    _setLoading(true);
    _clearError();

    try {
      final response = await ApiService.verifyPhone(phone, code);
      
      if (response.success && response.data != null) {
        _user = response.data!.user;
        _authToken = response.data!.token;
        _isAuthenticated = true;
        
        await _saveUserData(_user!);
        await _saveToken(_authToken!);
        
        _setLoading(false);
        return true;
      } else {
        _setError(response.message);
        _setLoading(false);
        return false;
      }
    } catch (e) {
      _setError('Erreur de vérification: $e');
      _setLoading(false);
      return false;
    }
  }

  // Déconnexion
  Future<void> logout() async {
    try {
      await ApiService.logout();
    } catch (e) {
      // Ignorer les erreurs de déconnexion
    }
    
    await _clearUserData();
    _user = null;
    _authToken = null;
    _isAuthenticated = false;
    _clearError();
    notifyListeners();
  }

  // Méthodes privées
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _errorMessage = error;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
  }

  Future<void> _saveUserData(User user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_data', json.encode(user.toJson()));
  }

  Future<void> _saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
  }

  Future<void> _clearUserData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user_data');
    await prefs.remove('auth_token');
  }
}