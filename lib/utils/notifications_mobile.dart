import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

final FlutterLocalNotificationsPlugin _localNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

Future<void> initNotificationsPlatform() async {
  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');

  const DarwinInitializationSettings initializationSettingsDarwin =
      DarwinInitializationSettings(
    requestAlertPermission: false,
    requestBadgePermission: false,
    requestSoundPermission: false,
  );

  const InitializationSettings initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
    iOS: initializationSettingsDarwin,
  );

  try {
    await _localNotificationsPlugin.initialize(initializationSettings);
  } catch (e) {
    debugPrint('Error initializing local notifications: $e');
  }
}

Future<void> requestNotificationsPermissionPlatform() async {
  try {
    final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
        _localNotificationsPlugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    if (androidImplementation != null) {
      await androidImplementation.requestNotificationsPermission();
    }

    final IOSFlutterLocalNotificationsPlugin? iosImplementation =
        _localNotificationsPlugin.resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>();
    if (iosImplementation != null) {
      await iosImplementation.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
    }
  } catch (e) {
    debugPrint('Mobile Notifications permission request failed: $e');
  }
}

Future<void> showNotificationPlatform({required String title, required String body}) async {
  const AndroidNotificationDetails androidNotificationDetails =
      AndroidNotificationDetails(
    'low_stock_channel_id',
    'Low Stock Alerts',
    channelDescription: 'Notifications for items low in stock',
    importance: Importance.max,
    priority: Priority.high,
    ticker: 'ticker',
  );

  const NotificationDetails notificationDetails =
      NotificationDetails(android: androidNotificationDetails);

  try {
    await _localNotificationsPlugin.show(
      0,
      title,
      body,
      notificationDetails,
    );
  } catch (e) {
    debugPrint('Failed to show mobile notification: $e');
  }
}
