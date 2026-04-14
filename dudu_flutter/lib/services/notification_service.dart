import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:firebase_messaging/firebase_messaging.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  /// Clé de navigation pour ouvrir des écrans au tap sur une notification
  static GlobalKey<NavigatorState>? _navigatorKey;
  static void setNavigatorKey(GlobalKey<NavigatorState>? key) {
    _navigatorKey = key;
  }

  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  String? _fcmToken;
  bool _initialized = false;

  /// Initialiser les notifications
  Future<void> initialize() async {
    if (_initialized) return;

    // Sur le Web, les notifications locales ne sont pas supportées de la même façon
    if (kIsWeb) {
      _initialized = true;
      print('✅ Notifications initialisées (Web - mode limité)');
      return;
    }

    // Configuration Android
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    // Configuration iOS
    final DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
      onDidReceiveLocalNotification: _onDidReceiveLocalNotification,
    );

    final InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await _flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Demander permissions
    await _requestPermissions();

    // Initialiser FCM (promos)
    await initFCMPromos();

    _initialized = true;
    print('✅ Notifications initialisées');
  }

  /// Demander les permissions
  Future<void> _requestPermissions() async {
    // Sur le Web, pas de permissions à demander via ce plugin
    if (kIsWeb) return;

    // Essayer iOS d'abord
    final iosPlugin = _flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>();
    if (iosPlugin != null) {
      await iosPlugin.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
      return;
    }

    // Sinon essayer Android
    final androidPlugin = _flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    if (androidPlugin != null) {
      await androidPlugin.requestNotificationsPermission();
    }
  }

  /// Obtenir le token FCM (Firebase)
  Future<String?> getFCMToken() async {
    if (kIsWeb) return null;
    try {
      final messaging = FirebaseMessaging.instance;
      _fcmToken = await messaging.getToken();
      return _fcmToken;
    } catch (e) {
      print('❌ Erreur getToken FCM: $e');
      return null;
    }
  }

  Future<void> initFCMPromos() async {
    if (kIsWeb) return;
    try {
      final messaging = FirebaseMessaging.instance;

      await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      await messaging.subscribeToTopic('promos');

      FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
        final title = message.notification?.title ?? 'DUDU';
        final body = message.notification?.body ?? '';
        await showNotification(
          title: title,
          body: body,
          payload: message.data.isNotEmpty ? jsonEncode(message.data) : null,
        );
      });
    } catch (e) {
      print('❌ Erreur initFCM promos: $e');
    }
  }

  /// Enregistrer le token sur le serveur
  Future<void> registerToken(String apiUrl, String authToken) async {
    try {
      final token = await getFCMToken();
      if (token == null) return;

      // Déterminer la plateforme
      String platform = 'web';
      if (!kIsWeb) {
        // On ne peut pas utiliser Platform.isIOS sur le web
        // Donc on utilise une approche différente
        platform = 'mobile'; // Le backend peut différencier plus tard si besoin
      }

      final response = await http.post(
        Uri.parse('$apiUrl/notifications/register-token'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $authToken',
        },
        body: jsonEncode({
          'fcmToken': token,
          'platform': platform,
        }),
      );

      if (response.statusCode == 200) {
        print('✅ Token FCM enregistré');
      }
    } catch (e) {
      print('❌ Erreur enregistrement token: $e');
    }
  }

  /// Afficher notification locale
  Future<void> showNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    // Sur le Web, afficher dans la console (les notifications locales ne sont pas supportées)
    if (kIsWeb) {
      print('🔔 [Web Notification] $title: $body');
      return;
    }

    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'dudu_channel',
      'DUDU Notifications',
      channelDescription: 'Notifications de courses DUDU',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: true,
      icon: '@mipmap/ic_launcher',
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _flutterLocalNotificationsPlugin.show(
      DateTime.now().millisecond,
      title,
      body,
      notificationDetails,
      payload: payload,
    );
  }

  /// Notification chauffeur trouvé
  Future<void> showDriverFoundNotification({
    required String driverName,
    required int eta,
  }) async {
    await showNotification(
      title: '✅ Chauffeur trouvé !',
      body: '$driverName arrive dans $eta minutes',
      payload: 'driver_found',
    );
  }

  /// Notification chauffeur en approche (course normale)
  Future<void> showDriverApproachingNotification({
    required String driverName,
    required int etaMinutes,
  }) async {
    await showNotification(
      title: '🚗 Votre chauffeur approche',
      body: '$driverName arrive dans $etaMinutes minutes',
      payload: 'driver_approaching',
    );
  }

  /// Notification chauffeur arrivé au point de prise en charge
  Future<void> showDriverArrivedNotification({
    required String driverName,
  }) async {
    await showNotification(
      title: '📍 Votre chauffeur est arrivé',
      body: '$driverName vous attend au point de prise en charge',
      payload: 'driver_arrived',
    );
  }

  /// Notification début de course
  Future<void> showRideStartedNotification() async {
    await showNotification(
      title: '🚕 Course démarrée',
      body: 'Votre trajet DUDU est en cours.',
      payload: 'ride_started',
    );
  }

  /// Notification fin de course avec invitation à noter
  Future<void> showRideCompletedNotification() async {
    await showNotification(
      title: '✅ Course terminée',
      body: 'Merci d’avoir voyagé avec DUDU. Donnez une note à votre chauffeur.',
      payload: 'ride_completed',
    );
  }

  /// Rappel 2h avant pour une course planifiée
  Future<void> showScheduledRideReminder2h({
    required DateTime scheduledAt,
  }) async {
    await showNotification(
      title: '⏰ Votre course est dans 2 heures',
      body: 'Tenez-vous prêt, votre trajet DUDU est prévu à ${scheduledAt.hour.toString().padLeft(2, '0')}:${scheduledAt.minute.toString().padLeft(2, '0')}.',
      payload: 'scheduled_reminder_2h',
    );
  }

  /// Rappel 1h avant pour une course planifiée
  Future<void> showScheduledRideReminder1h({
    required DateTime scheduledAt,
  }) async {
    await showNotification(
      title: '⏰ Votre course est dans 1 heure',
      body: 'Votre chauffeur arrivera bientôt. Course prévue à ${scheduledAt.hour.toString().padLeft(2, '0')}:${scheduledAt.minute.toString().padLeft(2, '0')}.',
      payload: 'scheduled_reminder_1h',
    );
  }

  /// Notification chauffeur en route pour une course planifiée
  Future<void> showScheduledDriverOnTheWayNotification({
    required String driverName,
    required int etaMinutes,
  }) async {
    await showNotification(
      title: '🚗 Votre chauffeur est en route',
      body: '$driverName arrivera dans environ $etaMinutes minutes.',
      payload: 'scheduled_driver_on_way',
    );
  }

  /// Notification chauffeur arrivé pour une course planifiée
  Future<void> showScheduledDriverArrivedNotification({
    required String driverName,
  }) async {
    await showNotification(
      title: '📍 Votre chauffeur pour le trajet planifié est arrivé',
      body: '$driverName vous attend au point de prise en charge.',
      payload: 'scheduled_driver_arrived',
    );
  }

  /// Notification promotion
  Future<void> showPromotionNotification({
    required String title,
    required String message,
  }) async {
    await showNotification(
      title: '🎉 $title',
      body: message,
      payload: 'promotion',
    );
  }

  /// Callback quand notification reçue (iOS uniquement)
  void _onDidReceiveLocalNotification(
    int id,
    String? title,
    String? body,
    String? payload,
  ) {
    print('📱 Notification reçue (iOS): $title');
  }

  /// Callback quand notification tapée
  void _onNotificationTapped(NotificationResponse response) {
    final payload = response.payload;
    print('👆 Notification tapée: $payload');

    final navigator = _navigatorKey?.currentState;
    if (navigator == null) {
      print('📱 NavigatorKey non configurée, impossible de naviguer');
      return;
    }
    switch (payload) {
      case 'driver_found':
      case 'driver_approaching':
      case 'ride_started':
      case 'driver_arrived':
      case 'ride_completed':
        navigator.pushNamedAndRemoveUntil('/dashboard', (route) => false);
        break;
      case 'scheduled_reminder_2h':
      case 'scheduled_reminder_1h':
      case 'scheduled_driver_on_way':
      case 'scheduled_driver_arrived':
        navigator.pushNamedAndRemoveUntil('/dashboard', (route) => false);
        break;
      case 'promotion':
        navigator.pushNamedAndRemoveUntil('/dashboard', (route) => false);
        break;
      default:
        navigator.pushNamedAndRemoveUntil('/dashboard', (route) => false);
    }
  }

  /// Annuler toutes les notifications
  Future<void> cancelAll() async {
    await _flutterLocalNotificationsPlugin.cancelAll();
  }

  /// Annuler une notification spécifique
  Future<void> cancel(int id) async {
    await _flutterLocalNotificationsPlugin.cancel(id);
  }

}

