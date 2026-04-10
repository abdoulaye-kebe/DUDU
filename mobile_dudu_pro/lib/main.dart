import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'screens/pro_startup_screen.dart';
import 'screens/login_screen.dart';
import 'screens/pro_app_gate.dart';
import 'services/notification_service.dart';
import 'config/app_config.dart';
import 'theme/theme_controller.dart';

final GlobalKey<NavigatorState> proNavigatorKey = GlobalKey<NavigatorState>();

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
}

void main() async {
  // Initialisation Flutter
  WidgetsFlutterBinding.ensureInitialized();

  // Firebase (FCM)
  try {
    await Firebase.initializeApp();
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  } catch (e) {
    debugPrint('⚠️ Firebase init error: $e');
  }
  
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
  final themeController = ThemeController();
  await themeController.loadFromPrefs();
  runApp(DUDUProApp(themeController: themeController));
}

class DUDUProApp extends StatelessWidget {
  final ThemeController themeController;

  const DUDUProApp({Key? key, required this.themeController}) : super(key: key);

  static final ThemeData _lightTheme = ThemeData(
    primaryColor: const Color(0xFF0d5d36),
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFF0d5d36),
      primary: const Color(0xFF0d5d36),
      brightness: Brightness.light,
    ),
    useMaterial3: true,
  );

  static final ThemeData _darkTheme = ThemeData(
    primaryColor: const Color(0xFF0d5d36),
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFF0d5d36),
      primary: const Color(0xFF10b981),
      brightness: Brightness.dark,
    ),
    useMaterial3: true,
    scaffoldBackgroundColor: const Color(0xFF121212),
  );

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<ThemeController>.value(
      value: themeController,
      child: Consumer<ThemeController>(
        builder: (context, tc, _) {
          return MaterialApp(
            title: 'DUDU Pro - Chauffeur',
            debugShowCheckedModeBanner: false,
            themeMode: tc.mode,
            theme: _lightTheme,
            darkTheme: _darkTheme,
            locale: const Locale('fr', 'FR'),
            supportedLocales: const [
              Locale('fr', 'FR'),
              Locale('en', 'US'),
            ],
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            navigatorKey: proNavigatorKey,
            routes: {
              '/login': (_) => const LoginScreen(),
              '/dashboard': (_) => const ProAppGate(),
            },
            home: const ProStartupScreen(),
          );
        },
      ),
    );
  }
}
