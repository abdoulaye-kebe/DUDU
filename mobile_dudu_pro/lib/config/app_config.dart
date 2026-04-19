import 'package:flutter/foundation.dart' show kIsWeb, kDebugMode, defaultTargetPlatform, TargetPlatform;
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Configuration centralisée de l'application DuDu Pro (Chauffeur)
class AppConfig {
  // Empêcher l'instanciation
  AppConfig._();

  /// Nom de l'application
  static const String appName = 'DuDu Pro';
  
  /// Version de l'API
  static const String apiVersion = 'v1';

  // ============================================
  // CONFIGURATION DES URLS
  // ============================================

  /// Repli si `app.env` absent et `ENV` ≠ local (aligné sur la prod HTTPS).
  static const String productionServerUrl = 'https://www.dudugroup.sn';
  
  /// URL du serveur local
  static const String localServerUrl = 'http://localhost:3000';
  
  /// URL pour l'émulateur Android (10.0.2.2 = localhost de la machine hôte)
  static const String androidEmulatorUrl = 'http://10.0.2.2:3000';

  /// Port du serveur
  static const int serverPort = 3000;

  static const String _env = String.fromEnvironment('ENV', defaultValue: 'prod');
  static const String _serverOriginOverride = String.fromEnvironment('SERVER_ORIGIN', defaultValue: '');

  /// Origine API lue depuis `assets/config/app.env` (`DUDU_API_ORIGIN`), après [loadFromDotenv].
  static String? _dotenvOrigin;

  /// À appeler depuis [main] après [dotenv.load], si le fichier `.env` est présent.
  static void loadFromDotenv() {
    if (!dotenv.isInitialized) return;
    final v = dotenv.maybeGet('DUDU_API_ORIGIN')?.trim();
    if (v != null && v.isNotEmpty) {
      _dotenvOrigin = v.endsWith('/') ? v.substring(0, v.length - 1) : v;
    }
  }

  static String get _serverOrigin {
    if (_serverOriginOverride.isNotEmpty) {
      return _serverOriginOverride;
    }
    if (_dotenvOrigin != null && _dotenvOrigin!.isNotEmpty) {
      return _dotenvOrigin!;
    }
    if (_env == 'local') {
      if (defaultTargetPlatform == TargetPlatform.android) {
        return androidEmulatorUrl;
      }
      return localServerUrl;
    }
    return productionServerUrl;
  }

  /// Évite `…:0/socket.io` : forcer `hôte:port` explicite (voir client dudu_flutter).
  static String normalizeOriginForSocket(String origin) {
    final o = origin.trim();
    if (o.isEmpty) return o;
    final u = Uri.tryParse(o);
    if (u == null || u.host.isEmpty) return o;
    var port = u.port;
    if (port == 0) {
      if (u.scheme == 'https' || u.scheme == 'wss') {
        port = 443;
      } else if (u.scheme == 'http' || u.scheme == 'ws') {
        port = 80;
      } else {
        return o;
      }
    }
    final host = u.host.contains(':') ? '[${u.host}]' : u.host;
    return '${u.scheme}://$host:$port';
  }

  /// Obtenir l'URL de base selon la plateforme et le mode
  static String get baseUrl {
    return '$_serverOrigin/api/$apiVersion';
  }

  /// Obtenir l'URL du serveur Socket.io
  static String get socketUrl {
    return normalizeOriginForSocket(_serverOrigin);
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
  
  /// Prix abonnement journalier voiture (FCFA)
  static const int dailySubscriptionPrice = 1000;

  /// Prix abonnement journalier livreur moto / livraison (FCFA)
  static const int dailyMotoSubscriptionPrice = 500;
  
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
      final dotenvLine = dotenv.maybeGet('DUDU_API_ORIGIN');
      final override = _serverOriginOverride;
      print('╔══════════════════════════════════════════╗');
      print('║         DuDu PRO (CHAUFFEUR) CONFIG      ║');
      print('╠══════════════════════════════════════════╣');
      print('║ Mode: ${kDebugMode ? "DEBUG" : "RELEASE"}');
      print('║ Platform: ${kIsWeb ? "WEB" : defaultTargetPlatform.toString()}');
      print('║ ENV (dart-define): $_env');
      print('║ DUDU_API_ORIGIN (fichier): ${dotenvLine ?? "(vide / non chargé)"}');
      print('║ SERVER_ORIGIN (dart-define): ${override.isEmpty ? "(aucun)" : override}');
      print('║ API URL effective: $apiUrl');
      print('║ Socket URL: $socketUrl');
      print('╚══════════════════════════════════════════╝');
    }
  }
}
