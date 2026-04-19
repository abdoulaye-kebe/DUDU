import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;

/// Canal Android dédié aux demandes de course (son + vibration forts).
/// Changer l’id si les réglages canal ne s’appliquent plus (canal figé après 1ʳᵉ création).
const String _rideRequestAndroidChannelId = 'dudu_ride_request_alert_v5';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;

  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Configuration des notifications locales
      const AndroidInitializationSettings androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
      const DarwinInitializationSettings iosSettings = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );
      
      const InitializationSettings settings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      await _localNotifications.initialize(
        settings,
        onDidReceiveNotificationResponse: _onNotificationTapped,
      );

      if (Platform.isAndroid) {
        final androidImpl = _localNotifications
            .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin>();
        await androidImpl?.createNotificationChannel(
          AndroidNotificationChannel(
            _rideRequestAndroidChannelId,
            'Demandes de course — alerte',
            description:
                'Sonnerie et vibration pour ne pas manquer une demande',
            importance: Importance.max,
            playSound: true,
            enableVibration: true,
            vibrationPattern: Int64List.fromList([
              0, 500, 200, 500, 200, 500, 200, 800,
            ]),
            audioAttributesUsage: AudioAttributesUsage.notificationRingtone,
          ),
        );
        await androidImpl?.requestNotificationsPermission();
      }

      // Configuration Firebase Messaging
      await _setupFirebaseMessaging();

      _isInitialized = true;
    } catch (e) {
      print('Erreur initialisation notifications: $e');
    }
  }

  Future<void> registerToken(String apiUrl, String authToken) async {
    try {
      final token = await _firebaseMessaging.getToken();
      if (token == null || token.isEmpty) return;

      final platform = Platform.isIOS
          ? 'ios'
          : Platform.isAndroid
              ? 'android'
              : 'mobile';

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
        print('✅ Token FCM Pro enregistré');
      } else {
        print('⚠️ Enregistrement token FCM Pro échoué (${response.statusCode})');
      }
    } catch (e) {
      print('❌ Erreur enregistrement token FCM Pro: $e');
    }
  }

  Future<void> _setupFirebaseMessaging() async {
    try {
      // Demander les permissions (iOS)
      final settings = await _firebaseMessaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        print('Notifications autorisées');
      } else {
        print('Notifications refusées');
      }

      // Promos
      await _firebaseMessaging.subscribeToTopic('promos');

      // Écouter les messages au premier plan
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

      // Écouter les clics sur les notifications (quand l'app est ouverte depuis notif)
      FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);

      // Token FCM
      final token = await _firebaseMessaging.getToken();
      print('Token FCM: $token');
    } catch (e) {
      print('Erreur setup Firebase Messaging: $e');
    }
  }

  Future<void> _onNotificationTapped(NotificationResponse response) async {
    // Gérer le clic sur une notification locale
    print('Notification locale tapée: ${response.payload}');
    _handleNotificationData(response.payload);
  }

  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    print('Message reçu au premier plan: ${message.notification?.title}');

    await showLocalNotification(
      title: message.notification?.title ?? 'DuDu',
      body: message.notification?.body ?? '',
      payload: message.data.isNotEmpty ? message.data.toString() : null,
      id: message.messageId?.hashCode ?? 0,
    );
  }

  Future<void> _handleNotificationTap(RemoteMessage message) async {
    print('Notification Firebase tapée: ${message.data}');
    _handleNotificationData(message.data.toString());
  }

  void _handleNotificationData(String? data) {
    // Gérer les données de la notification
    // Rediriger vers l'écran approprié selon le type de notification
    print('Données notification: $data');
  }

  Future<void> showLocalNotification({
    required String title,
    required String body,
    String? payload,
    int id = 0,
  }) async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'dudu_channel',
      'DuDu Notifications',
      channelDescription: 'Notifications de la plateforme DuDu',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      id,
      title,
      body,
      details,
      payload: payload,
    );
  }

  Future<void> showRideRequestNotification({
    required String rideId,
    required String passengerName,
    required String pickupAddress,
    required String destinationAddress,
    required double price,
  }) async {
    final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      _rideRequestAndroidChannelId,
      'Demandes de course — alerte',
      channelDescription:
          'Sonnerie type alarme et vibration pour les nouvelles demandes',
      importance: Importance.max,
      priority: Priority.max,
      icon: '@mipmap/ic_launcher',
      enableVibration: true,
      playSound: true,
      showWhen: true,
      onlyAlertOnce: false,
      ticker: 'Nouvelle demande de course DuDu',
      vibrationPattern: Int64List.fromList([
        0, 500, 200, 500, 200, 500, 200, 800, 200, 600,
      ]),
      category: AndroidNotificationCategory.call,
      audioAttributesUsage: AudioAttributesUsage.notificationRingtone,
      visibility: NotificationVisibility.public,
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      presentBanner: true,
      presentList: true,
      interruptionLevel: InterruptionLevel.active,
    );

    final NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      rideId.hashCode,
      'NOUVELLE DEMANDE DE COURSE',
      '$passengerName • $pickupAddress → $destinationAddress • ${price.toStringAsFixed(0)} FCFA',
      details,
      payload: 'ride_request:$rideId',
    );
  }

  Future<void> showRideAcceptedNotification({
    required String rideId,
    required String driverName,
    required String vehicleInfo,
    required int estimatedArrival,
  }) async {
    await showLocalNotification(
      title: 'Course acceptée',
      body: '$driverName avec $vehicleInfo arrive dans $estimatedArrival minutes',
      payload: 'ride_accepted:$rideId',
      id: rideId.hashCode,
    );
  }

  Future<void> showRideStartedNotification({
    required String rideId,
    required String driverName,
  }) async {
    await showLocalNotification(
      title: 'Course commencée',
      body: '$driverName a commencé votre course',
      payload: 'ride_started:$rideId',
      id: rideId.hashCode,
    );
  }

  Future<void> showRideCompletedNotification({
    required String rideId,
    required double amount,
    required String paymentMethod,
  }) async {
    await showLocalNotification(
      title: 'Course terminée',
      body: 'Course terminée. Montant: ${amount.toStringAsFixed(0)} FCFA via $paymentMethod',
      payload: 'ride_completed:$rideId',
      id: rideId.hashCode,
    );
  }

  Future<void> showPaymentNotification({
    required String title,
    required String body,
    required String paymentId,
  }) async {
    await showLocalNotification(
      title: title,
      body: body,
      payload: 'payment:$paymentId',
      id: paymentId.hashCode,
    );
  }

  Future<void> showSubscriptionNotification({
    required String title,
    required String body,
    required String subscriptionId,
  }) async {
    await showLocalNotification(
      title: title,
      body: body,
      payload: 'subscription:$subscriptionId',
      id: subscriptionId.hashCode,
    );
  }

  Future<void> showDriverStatusNotification({
    required String title,
    required String body,
  }) async {
    await showLocalNotification(
      title: title,
      body: body,
      payload: 'driver_status',
    );
  }

  Future<void> showEarningsNotification({
    required double amount,
    required String period,
  }) async {
    await showLocalNotification(
      title: 'Nouveaux gains',
      body: 'Vous avez gagné ${amount.toStringAsFixed(0)} FCFA cette $period',
      payload: 'earnings',
    );
  }

  Future<void> showBonusNotification({
    required String type,
    required double amount,
    required String description,
  }) async {
    await showLocalNotification(
      title: 'Bonus reçu !',
      body: '$type: ${amount.toStringAsFixed(0)} FCFA - $description',
      payload: 'bonus',
    );
  }

  Future<void> showSystemNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    await showLocalNotification(
      title: title,
      body: body,
      payload: payload,
    );
  }

  Future<void> cancelNotification(int id) async {
    await _localNotifications.cancel(id);
  }

  Future<void> cancelAllNotifications() async {
    await _localNotifications.cancelAll();
  }

  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    return await _localNotifications.pendingNotificationRequests();
  }

  // Future<String?> getFCMToken() async {
  //   return await _firebaseMessaging.getToken();
  // }

  // Future<void> subscribeToTopic(String topic) async {
  //   await _firebaseMessaging.subscribeToTopic(topic);
  // }

  // Future<void> unsubscribeFromTopic(String topic) async {
  //   await _firebaseMessaging.unsubscribeFromTopic(topic);
  // }

  // Méthodes pour les différents types d'utilisateurs (désactivées temporairement)
  // Future<void> setupDriverNotifications() async {
  //   await subscribeToTopic('drivers');
  //   await subscribeToTopic('ride_requests');
  //   await subscribeToTopic('earnings');
  //   await subscribeToTopic('subscriptions');
  // }

  // Future<void> setupPassengerNotifications() async {
  //   await subscribeToTopic('passengers');
  //   await subscribeToTopic('ride_updates');
  //   await subscribeToTopic('payments');
  // }

  // Future<void> setupAdminNotifications() async {
  //   await subscribeToTopic('admin');
  //   await subscribeToTopic('system_alerts');
  //   await subscribeToTopic('reports');
  // }
}

// Handler pour les messages en arrière-plan (désactivé temporairement)
// @pragma('vm:entry-point')
// Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
//   print('Message en arrière-plan: ${message.messageId}');
//   // Traiter le message en arrière-plan
// }
