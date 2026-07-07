import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app/app.dart';
import 'app/not_configured_app.dart';
import 'core/constants/app_constants.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await _seedApiKey(
    apiKey: '',
    provider: 'groq',
  );

  bool firebaseReady = false;
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    firebaseReady = true;
  } catch (_) {
    // Firebase not configured yet — show setup screen
  }

  runApp(firebaseReady ? const AiAssistantApp() : const NotConfiguredApp());
}

// Always overwrite — ensures provider/key switches take effect immediately
Future<void> _seedApiKey({
  required String apiKey,
  required String provider,
}) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString(AppConstants.apiKeyKey, apiKey);
  await prefs.setString(AppConstants.aiProviderKey, provider);
}
