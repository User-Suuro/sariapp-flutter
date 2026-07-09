import 'notifications_impl.dart'
    if (dart.library.js) 'notifications_web.dart'
    if (dart.library.io) 'notifications_mobile.dart';

class NotificationsHelper {
  static Future<void> init() async {
    await initNotificationsPlatform();
  }

  static Future<void> requestPermission() async {
    await requestNotificationsPermissionPlatform();
  }

  static Future<void> showNotification({
    required String title,
    required String body,
  }) async {
    await showNotificationPlatform(title: title, body: body);
  }
}
