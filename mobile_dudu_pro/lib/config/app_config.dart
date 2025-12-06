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
  static const String productionServerUrl = 'http://213.154.90.11';
  
  /// URL du serveur local
  static const String localServerUrl = 'http://localhost:3000';
  
  /// URL pour l'émulateur Android (10.0.2.2 = localhost de la machine hôte)
  static const String androidEmulatorUrl = 'http://10.0.2.2:3000';

  /// Port du serveur
  static const int serverPort = 3000;

  /// Obtenir l'URL de base selon la plateforme et le mode
  static String get baseUrl {
    if (kIsWeb) {
      // Web: toujours localhost en dev
      return '$localServerUrl/api/$apiVersion';
    }
    
    if (kDebugMode) {
      // Mode debug sur mobile
      if (defaultTargetPlatform == TargetPlatform.android) {
        // Android Emulator: utiliser 10.0.2.2
        return '$androidEmulatorUrl/api/$apiVersion';
      }
      // iOS Simulator ou macOS: localhost fonctionne
      return '$localServerUrl/api/$apiVersion';
    }
    
    // Mode release: serveur de production
    return '$productionServerUrl/api/$apiVersion';
  }

  /// Obtenir l'URL du serveur Socket.io
  static String get socketUrl {
    if (kIsWeb) {
      return localServerUrl;
    }
    
    if (kDebugMode) {
      if (defaultTargetPlatform == TargetPlatform.android) {
        return androidEmulatorUrl;
      }
      return localServerUrl;
    }
    
    return productionServerUrl;
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
  static const int monthlySubscriptionPrice = 15000;

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
