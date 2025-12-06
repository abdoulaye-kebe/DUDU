import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'screens/new_driver_dashboard.dart';
import 'screens/login_screen.dart';
import 'services/notification_service.dart';
import 'config/app_config.dart';

final GlobalKey<NavigatorState> proNavigatorKey = GlobalKey<NavigatorState>();

void main() async {
  // Initialisation Flutter
  WidgetsFlutterBinding.ensureInitialized();
  
  // Afficher la config au démarrage
  AppConfig.printConfig();
  
  // Orientation portrait uniquement
  try {
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
  } catch (e) {
    debugPrint('⚠️ Erreur orientation: $e');
  }
  
  // Initialiser les notifications locales (avec protection)
  try {
    await NotificationService().initialize();
    debugPrint('✅ Notifications initialisées');
  } catch (e) {
    debugPrint('⚠️ Erreur notifications: $e');
    // Continue sans notifications
  }
  
  // Gestion des erreurs globales
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    debugPrint('❌ Flutter Error: ${details.exception}');
    debugPrint('📍 Stack: ${details.stack}');
  };
  
  debugPrint('🚀 Démarrage DUDU Pro...');
  runApp(const DUDUProApp());
}

class DUDUProApp extends StatelessWidget {
  const DUDUProApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DUDU Pro - Chauffeur',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: const Color(0xFF0d5d36), // Couleur DUDU
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0d5d36),
          primary: const Color(0xFF0d5d36),
        ),
        useMaterial3: true,
      ),
      navigatorKey: proNavigatorKey,
      home: const LoginScreen(), // Page de connexion par défaut
    );
  }
}
