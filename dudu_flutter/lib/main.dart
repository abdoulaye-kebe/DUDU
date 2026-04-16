import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'services/notification_service.dart';
import 'providers/auth_provider.dart';
import 'themes/app_theme.dart';
import 'screens/login_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/app_gate.dart';
import 'screens/splash_screen.dart';
import 'config/app_config.dart';
import 'firebase_options.dart';

final GlobalKey<NavigatorState> appNavigatorKey = GlobalKey<NavigatorState>();

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Sur iOS, enregistrer le handler FCM *avant* Firebase.initializeApp, sinon erreur
  // [firebase_core/not-initialized] fréquente (voir doc FlutterFire / firebase_messaging).
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  try {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
    debugPrint('✅ Firebase initialisé');
  } catch (e, st) {
    debugPrint('⚠️ Firebase init error: $e');
    debugPrint('$st');
  }

  // Afficher la config au démarrage
  AppConfig.printConfig();

  // FCM / notifs locales : seulement si le noyau Firebase est prêt
  if (Firebase.apps.isNotEmpty) {
    try {
      await NotificationService().initialize();
      NotificationService.setNavigatorKey(appNavigatorKey);
      debugPrint('✅ Notifications initialisées');
    } catch (e) {
      debugPrint('⚠️ Erreur notifications: $e');
    }
  } else {
    debugPrint('⚠️ Notifications ignorées : Firebase non initialisé');
  }

  // Gestionnaire d'erreurs global
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    debugPrint('❌ Flutter Error: ${details.exception}');
    debugPrint('📍 Stack trace: ${details.stack}');
  };

  debugPrint('🚀 Démarrage DuDu...');
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
        title: 'DuDu',
        theme: AppTheme.lightTheme,
        navigatorKey: appNavigatorKey,
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [
          Locale('fr'),
          Locale('wo'),
          Locale('en'),
        ],
        home: const SplashScreen(),
        debugShowCheckedModeBanner: false,
        routes: {
          '/splash': (context) => const SplashScreen(),
          '/login': (context) => const LoginScreen(),
          '/dashboard': (context) => const DashboardScreen(),
          '/app': (context) => const AppGate(),
        },
      ),
    );
  }
}