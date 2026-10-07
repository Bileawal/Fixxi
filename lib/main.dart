import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'app.dart';
import 'firebase_options.dart';
import 'providers/app_state.dart';
import 'services/fixxi_api.dart';
import 'services/storage_service.dart';
import 'services/push_notification_service.dart';

// ── FCM background handler (must be top-level function) ──────────────────────
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Firebase is already initialized by the time this runs,
  // but if needed: await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  debugPrint('[FCM] Background message: ${message.notification?.title}');
  // flutter_local_notifications will auto-show the notification via the data payload.
}

// ── Local notification setup ──────────────────────────────────────────────────
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

const AndroidNotificationChannel _channel = AndroidNotificationChannel(
  'fixxi_channel',        // must match AndroidManifest meta-data
  'Fixxi Notifications',
  description: 'Notifications for new messages, requests, and status updates',
  importance: Importance.high,
  playSound: true,
);
// ─────────────────────────────────────────────────────────────────────────────

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Register the background handler BEFORE runApp
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // Initialize local notifications (creates channel and initializes plugin)
  await PushNotificationService.setupLocalNotifications();

  // Request notification permission on Android 13+
  await FirebaseMessaging.instance.requestPermission(
    alert: true,
    badge: true,
    sound: true,
  );

  // Make sure foreground notifications show as heads-up banners
  await FirebaseMessaging.instance
      .setForegroundNotificationPresentationOptions(
    alert: true,
    badge: true,
    sound: true,
  );

  final storage = StorageService();
  final api = FixxiApi();
  final appState = AppState(api, storage);

  runApp(
    ChangeNotifierProvider<AppState>.value(
      value: appState,
      child: const FixxiApp(),
    ),
  );

  appState.initialize();
}
