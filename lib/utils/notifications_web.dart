import 'dart:js' as js;
import 'package:flutter/foundation.dart';

Future<void> initNotificationsPlatform() async {
  // Web does not require initialization for HTML5 Notifications
}

Future<void> requestNotificationsPermissionPlatform() async {
  try {
    if (js.context.hasProperty('Notification')) {
      final notificationClass = js.context['Notification'];
      js.context['Notification'].callMethod('requestPermission');
    }
  } catch (e) {
    debugPrint('Web Notifications permission request failed: $e');
  }
}

Future<void> showNotificationPlatform({required String title, required String body}) async {
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
