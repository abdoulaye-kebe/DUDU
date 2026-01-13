import 'package:flutter/foundation.dart' show kIsWeb, kDebugMode, defaultTargetPlatform, TargetPlatform;

/// Configuration centralisée de l'application DUDU Pro (Chauffeur)
class AppConfig {
  // Empêcher l'instanciation
  AppConfig._();

  /// Nom de l'application
  static const String appName = 'DUDU Pro';
  
  /// Version de l'API
  static const String apiVersion = 'v1';

  // ============================================
  // CONFIGURATION DES URLS
  // ============================================

  /// URL du serveur de production (AWS)
  static const String productionServerUrl = 'https://www.dudugroup.sn';
  
  /// URL du serveur local
  static const String localServerUrl = 'http://localhost:3000';
  
  /// URL pour l'émulateur Android (10.0.2.2 = localhost de la machine hôte)
  static const String androidEmulatorUrl = 'http://10.0.2.2:3000';

  /// Port du serveur
  static const int serverPort = 3000;

  static const String _env = String.fromEnvironment('ENV', defaultValue: 'prod');
  static const String _serverOriginOverride = String.fromEnvironment('SERVER_ORIGIN', defaultValue: '');

  static String get _serverOrigin {
    if (_serverOriginOverride.isNotEmpty) {
      return _serverOriginOverride;
    }
    if (_env == 'local') {
      if (defaultTargetPlatform == TargetPlatform.android) {
        return androidEmulatorUrl;
      }
      return localServerUrl;
    }
    return productionServerUrl;
  }

  /// Obtenir l'URL de base selon la plateforme et le mode
  static String get baseUrl {
    return '$_serverOrigin/api/$apiVersion';
  }

  /// Obtenir l'URL du serveur Socket.io
  static String get socketUrl {
    return _serverOrigin;
  }

  /// URL de l'API pour les appels HTTP
  static String get apiUrl => baseUrl;

  // ============================================
  // CONFIGURATION GOOGLE MAPS
  // ============================================
  
  /// Clé API Google Maps
  static const String googleMapsApiKey = 'AIzaSyBebPcA35Q6WKIiGxG1Xi4iW0ZErazWvZA';

  // ============================================
  // CONFIGURATION PAR DÉFAUT
  // ============================================
  
  /// Langue par défaut
  static const String defaultLanguage = 'fr';
  
  /// Devise par défaut
  static const String defaultCurrency = 'XOF';
  
  /// Pays par défaut
  static const String defaultCountry = 'Sénégal';
  
  /// Ville par défaut
  static const String defaultCity = 'Dakar';

  // ============================================
  // COORDONNÉES PAR DÉFAUT (Dakar)
  // ============================================
  
  static const double defaultLatitude = 14.6937;
  static const double defaultLongitude = -17.4441;

  // ============================================
  // TIMEOUTS
  // ============================================
  
  /// Timeout pour les requêtes HTTP (en secondes)
  static const int httpTimeout = 30;

  // ============================================
  // ABONNEMENTS
  // ============================================
  
  /// Prix abonnement journalier (FCFA)
  static const int dailySubscriptionPrice = 1000;
  
  /// Prix abonnement hebdomadaire (FCFA)
  static const int weeklySubscriptionPrice = 5000;
  
  /// Prix abonnement mensuel (FCFA)
  static const int monthlySubscriptionPrice = 21000;

  // ============================================
  // DEBUG
  // ============================================
  
  /// Afficher les logs de debug
  static bool get showDebugLogs => kDebugMode;
  
  /// Afficher les infos de configuration
  static void printConfig() {
    if (showDebugLogs) {
      print('╔══════════════════════════════════════════╗');
      print('║         DUDU PRO (CHAUFFEUR) CONFIG      ║');
      print('╠══════════════════════════════════════════╣');
      print('║ Mode: ${kDebugMode ? "DEBUG" : "RELEASE"}');
      print('║ Platform: ${kIsWeb ? "WEB" : defaultTargetPlatform.toString()}');
      print('║ API URL: $apiUrl');
      print('║ Socket URL: $socketUrl');
      print('╚══════════════════════════════════════════╝');
    }
  }
}
