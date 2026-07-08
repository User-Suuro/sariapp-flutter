import 'dart:js' as js;
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationsHelper {
  static final FlutterLocalNotificationsPlugin _localNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static bool _isInitialized = false;

  static Future<void> init() async {
    if (_isInitialized) return;

    if (kIsWeb) {
      _isInitialized = true;
      return;
    }

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
      _isInitialized = true;
    } catch (e) {
      debugPrint('Error initializing local notifications: $e');
    }
  }

  static Future<void> requestPermission() async {
    if (kIsWeb) {
      try {
        if (js.context.hasProperty('Notification')) {
          final notificationClass = js.context['Notification'];
          js.context['Notification'].callMethod('requestPermission');
        }
      } catch (e) {
        debugPrint('Web Notifications permission request failed: $e');
      }
      return;
    }

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

  static Future<void> showNotification({
    required String title,
    required String body,
  }) async {
    if (!kIsWeb) {
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
    } else {
      try {
        if (js.context.hasProperty('Notification')) {
          final notificationClass = js.context['Notification'];
          final permission = notificationClass['permission'];
          if (permission == 'granted') {
            js.JsObject(notificationClass, [
              title,
              js.JsObject.jsify({'body': body})
            ]);
          } else if (permission == 'default') {
            js.context['Notification'].callMethod('requestPermission').then((result) {
              if (result == 'granted') {
                js.JsObject(notificationClass, [
                  title,
                  js.JsObject.jsify({'body': body})
                ]);
              }
            });
          }
        }
      } catch (e) {
        debugPrint('Failed to show Web notification: $e');
      }
    }
  }
}
