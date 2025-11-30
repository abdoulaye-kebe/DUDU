import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'screens/new_driver_dashboard.dart';
import 'screens/login_screen.dart';
import 'services/notification_service.dart';

final GlobalKey<NavigatorState> proNavigatorKey = GlobalKey<NavigatorState>();

void main() async {
  // Initialisation Flutter
  WidgetsFlutterBinding.ensureInitialized();
  
  // Orientation portrait uniquement
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  
  // Initialiser les notifications locales (son + vibration)
  await NotificationService().initialize();
  
  // Gestion des erreurs globales
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    print('Flutter Error: ${details.exception}');
    print('Stack: ${details.stack}');
  };
  
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
