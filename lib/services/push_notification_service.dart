import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'fixxi_api.dart';

// Top-level handler required for background FCM (must be top-level)
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  if (kDebugMode) print('[FCM] Background: ${message.notification?.title}');
}

class PushNotificationService {
  PushNotificationService(this._api);

  final FixxiApi _api;
  bool _initialized = false;

  static const _channelId = 'fixxi_channel';
  static const _channelName = 'Fixxi Notifications';

  /// Call ONCE at app startup to create Android notification channel
  static Future<void> setupLocalNotifications() async {
    final plugin = FlutterLocalNotificationsPlugin();

    // Init with app icon
    const initSettings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
    );
    await plugin.initialize(settings: initSettings);

    // Create high-importance channel for heads-up banners
    const channel = AndroidNotificationChannel(
      _channelId,
      _channelName,
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
    );
    await plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  Future<void> initialize() async {
    if (_initialized) return;

    try {
      final messaging = FirebaseMessaging.instance;

      // 1. Request permission
      final settings = await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
      if (kDebugMode) {
        print('[FCM] Permission: ${settings.authorizationStatus}');
      }

      // 2. Register background message handler
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

      // 3. Make foreground FCM messages show as banners (iOS + Android)
      await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );

      // 4. Save FCM token
      await registerToken();

      // 5. Refresh token listener
      messaging.onTokenRefresh.listen((token) async {
        try {
          await _api.updateFcmToken(token);
          if (kDebugMode) print('[FCM] Token refreshed: $token');
        } catch (e) {
          if (kDebugMode) print('[FCM] Token refresh error: $e');
        }
      });

      // 6. Show local notification on foreground messages (Android heads-up)
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        if (kDebugMode) {
          print('[FCM] Foreground: ${message.notification?.title}');
        }
        final notif = message.notification;
        if (notif != null) {
          _showForegroundNotification(
            id: message.hashCode,
            title: notif.title ?? 'Fixxi',
            body: notif.body ?? '',
          );
        }
      });

      _initialized = true;
    } catch (e) {
      if (kDebugMode) print('[FCM] Init error: $e');
    }
  }

  static Future<void> _showForegroundNotification({
    required int id,
    required String title,
    required String body,
  }) async {
    try {
      final plugin = FlutterLocalNotificationsPlugin();
      const androidDetails = AndroidNotificationDetails(
        _channelId,
        _channelName,
        importance: Importance.high,
        priority: Priority.high,
        playSound: true,
        enableVibration: true,
      );
      const details = NotificationDetails(android: androidDetails);

      await plugin.show(
        id: id,
        title: title,
        body: body,
        notificationDetails: details,
      );
    } catch (e) {
      if (kDebugMode) print('[FCM] Local notif error: $e');
    }
  }

  Future<void> registerToken() async {
    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token != null) {
        if (kDebugMode) print('[FCM] Token: $token');
        await _api.updateFcmToken(token);
      }
    } catch (e) {
      if (kDebugMode) print('[FCM] Token error: $e');
    }
  }

  Future<void> clearToken() async {
    try {
      await _api.updateFcmToken('');
    } catch (e) {
      if (kDebugMode) print('[FCM] Clear error: $e');
    }
  }
}
