import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'services/auth_provider.dart';
import 'services/auth_service.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: 'assets/env.txt');

  // TODO: Run `flutterfire configure` to generate firebase_options.dart,
  // then replace this block with Firebase.initializeApp() + FcmService.init().
  // FCM is mobile-only; web push is handled via Supabase Edge Function.

  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL'] ?? '',
    anonKey: dotenv.env['SUPABASE_ANON_KEY'] ?? '',
  );

  final authProvider = AuthProvider();
  await authProvider.loadCurrentUser();

  // Register FCM token after auth load (mobile only, requires Firebase setup)
  if (!kIsWeb && authProvider.isLoggedIn) {
    try {
      final token = await _getFcmToken();
      if (token != null) {
        await AuthService().updateFcmToken(authProvider.user!.id, token);
      }
    } catch (e) {
      if (kDebugMode) debugPrint('FCM token registration failed: $e');
    }
  }

  runApp(
    ChangeNotifierProvider.value(
      value: authProvider,
      child: const HkApp(),
    ),
  );
}

// Stub until `flutterfire configure` is run and firebase_options.dart is generated.
Future<String?> _getFcmToken() async => null;
