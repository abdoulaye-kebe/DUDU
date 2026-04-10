import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/user.dart';
import '../services/api_service.dart';
import '../services/socket_service.dart';
import '../services/notification_service.dart';
import '../config/app_config.dart';

class AuthProvider extends ChangeNotifier {
  User? _user;
  String? _authToken;
  bool _isLoading = false;
  String? _errorMessage;
  bool _isAuthenticated = false;

  Future<void> bootstrapFromStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      final userRaw = prefs.getString('user_data');

      if (token != null && token.isNotEmpty && userRaw != null && userRaw.isNotEmpty) {
        final decoded = json.decode(userRaw);
        if (decoded is Map<String, dynamic>) {
          _user = User.fromJson(decoded);
          _authToken = token;
          _isAuthenticated = true;
          try {
            SocketService().connect(_authToken!);
          } catch (_) {}
          try {
            await NotificationService().registerToken(AppConfig.apiUrl, _authToken!);
          } catch (_) {}
        }
      }
    } catch (_) {
      // ignore
    }
    notifyListeners();
  }

  // Getters
  User? get user => _user;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _isAuthenticated;
  String get userDisplayName => _user != null ? '${_user!.firstName} ${_user!.lastName}' : '';
  String get userPhone => _user?.phone ?? '';

  void setUser(User? user) {
    _user = user;
    if (user != null) {
      _saveUserData(user);
    }
    notifyListeners();
  }

  Future<bool> refreshProfile() async {
    try {
      final response = await ApiService.getProfile();
      if (response.success && response.data != null) {
        setUser(response.data);
        return true;
      }
      _setError(response.message);
      return false;
    } catch (e) {
      _setError('Erreur de récupération du profil: $e');
      return false;
    }
  }

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
        SocketService().connect(_authToken!);

        try {
          await NotificationService().registerToken(AppConfig.apiUrl, _authToken!);
        } catch (_) {}
        
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
    String? email,
    required String phone,
    required String password,
    String? gender,
    String language = 'fr',
  }) async {
    _setLoading(true);
    _clearError();

    try {
      final response = await ApiService.register(
        firstName: firstName,
        lastName: lastName,
        email: email,
        phone: phone,
        password: password,
        gender: gender,
        language: language,
      );
      
      if (response.success && response.data != null) {
        _user = response.data!.user;
        _authToken = response.data!.token;
        _isAuthenticated = true;
        
        await _saveUserData(_user!);
        await _saveToken(_authToken!);

        try {
          await NotificationService().registerToken(AppConfig.apiUrl, _authToken!);
        } catch (_) {}
        
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

        try {
          await NotificationService().registerToken(AppConfig.apiUrl, _authToken!);
        } catch (_) {}
        
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

  /// Après un 401 : aligner la mémoire avec le stockage (déjà effacé par l’API client).
  Future<void> clearLocalSession({String? message}) async {
    await _clearUserData();
    _user = null;
    _authToken = null;
    _isAuthenticated = false;
    if (message != null && message.isNotEmpty) {
      _setError(message);
    } else {
      _clearError();
    }
    try {
      SocketService().disconnect();
    } catch (_) {}
    notifyListeners();
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
    SocketService().disconnect();
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