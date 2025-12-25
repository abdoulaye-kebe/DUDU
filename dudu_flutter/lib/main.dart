import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'services/notification_service.dart';
import 'providers/auth_provider.dart';
import 'themes/app_theme.dart';
import 'screens/login_screen.dart';
import 'screens/dashboard_screen.dart';
import 'config/app_config.dart';

final GlobalKey<NavigatorState> appNavigatorKey = GlobalKey<NavigatorState>();

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
}

Future<void> main() async {
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

  // Initialiser les notifications (avec protection)
  try {
    await NotificationService().initialize();
    debugPrint('✅ Notifications initialisées');
  } catch (e) {
    debugPrint('⚠️ Erreur notifications: $e');
    // Continue sans notifications
  }

  // Gestionnaire d'erreurs global
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    debugPrint('❌ Flutter Error: ${details.exception}');
    debugPrint('📍 Stack trace: ${details.stack}');
  };

  debugPrint('🚀 Démarrage DUDU Client...');
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
      ],
      child: MaterialApp(
        title: 'DUDU',
        theme: AppTheme.lightTheme,
        navigatorKey: appNavigatorKey,
        home: const AppWrapper(),
        debugShowCheckedModeBanner: false,
        routes: {
          '/login': (context) => const LoginScreen(),
          '/dashboard': (context) => const DashboardScreen(),
        },
      ),
    );
  }
}

class AppWrapper extends StatelessWidget {
  const AppWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        // Flux normal : Login puis Dashboard
        if (authProvider.isAuthenticated) {
          return const DashboardScreen();
        }
        return const LoginScreen();
      },
    );
  }
}