import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'api.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print('Background message: ${message.notification?.title}');
}

class FcmService {
  static Future<void> init() async {
    try {
      await Firebase.initializeApp();

      FirebaseMessaging.onBackgroundMessage(
          _firebaseMessagingBackgroundHandler);

      // Request permission
      await FirebaseMessaging.instance.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      // Get token and save
      final token = await FirebaseMessaging.instance.getToken();
      if (token != null) {
        print('✅ FCM Token ready');
        try {
          await Api.post('/auth/fcm-token', {'fcm_token': token});
        } catch (_) {}
      }

      // Token refresh
      FirebaseMessaging.instance.onTokenRefresh.listen((t) {
        Api.post('/auth/fcm-token', {'fcm_token': t});
      });

      // Foreground messages — show using Firebase's built-in
      await FirebaseMessaging.instance
          .setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );

      print('✅ FCM initialized');
    } catch (e) {
      print('⚠️ FCM error: $e');
    }
  }
}