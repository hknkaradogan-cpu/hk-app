import '../core/supabase_client.dart';
import 'dart:convert';

class FcmService {
  static Future<void> init() async {
    // FCM init: requires flutterfire configure on mobile.
    // Web does not support FCM via this package.
  }

  static Future<String?> getToken() async => null;

  static Future<void> sendPushToUser({
    required String userId,
    required String title,
    required String body,
  }) async {
    try {
      await supabase.functions.invoke(
        'send-push',
        body: jsonEncode({'user_id': userId, 'title': title, 'body': body}),
      );
    } catch (_) {}
  }
}
