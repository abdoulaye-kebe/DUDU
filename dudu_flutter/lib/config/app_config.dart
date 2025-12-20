import 'package:flutter/foundation.dart' show kIsWeb, kDebugMode, defaultTargetPlatform, TargetPlatform;

/// Configuration centralisée de l'application DUDU Client
class AppConfig {
  // Empêcher l'instanciation
  AppConfig._();

  /// Nom de l'application
  static const String appName = 'DUDU';
  
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
    if (kDebugMode) {
      // En mode DEBUG, utiliser le serveur local
      if (defaultTargetPlatform == TargetPlatform.android) {
        // Émulateur Android: 10.0.2.2 = localhost de la machine hôte
        return '$androidEmulatorUrl/api/$apiVersion';
      } else if (defaultTargetPlatform == TargetPlatform.iOS) {
        // Simulateur iOS: localhost fonctionne
        return '$localServerUrl/api/$apiVersion';
      } else {
        // Web ou autre: localhost
        return '$localServerUrl/api/$apiVersion';
      }
    } else {
      // En mode RELEASE, toujours utiliser la production
      return '$productionServerUrl/api/$apiVersion';
    }
  }

  /// Obtenir l'URL du serveur Socket.io
  static String get socketUrl {
    if (kDebugMode) {
      // En mode DEBUG, utiliser le serveur local
      if (defaultTargetPlatform == TargetPlatform.android) {
        // Émulateur Android: 10.0.2.2 = localhost de la machine hôte
        return androidEmulatorUrl;
      } else if (defaultTargetPlatform == TargetPlatform.iOS) {
        // Simulateur iOS: localhost fonctionne
        return localServerUrl;
      } else {
        // Web ou autre: localhost
        return localServerUrl;
      }
    } else {
      // En mode RELEASE, toujours utiliser la production avec le port
      return '$productionServerUrl:$serverPort';
    }
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
  
  /// Timeout pour la recherche de chauffeur (en secondes)
  static const int driverSearchTimeout = 120;

  // ============================================
  // DEBUG
  // ============================================
  
  /// Afficher les logs de debug
  static bool get showDebugLogs => kDebugMode;
  
  /// Afficher les infos de configuration
  static void printConfig() {
    if (showDebugLogs) {
      print('╔══════════════════════════════════════════╗');
      print('║         DUDU CLIENT CONFIG               ║');
      print('╠══════════════════════════════════════════╣');
      print('║ Mode: ${kDebugMode ? "DEBUG" : "RELEASE"}');
      print('║ Platform: ${kIsWeb ? "WEB" : defaultTargetPlatform.toString()}');
      print('║ API URL: $apiUrl');
      print('║ Socket URL: $socketUrl');
      print('╚══════════════════════════════════════════╝');
    }
  }
}
