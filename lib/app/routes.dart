import 'package:flutter/material.dart';
import '../features/auth/screens/splash_screen.dart';
import '../features/auth/screens/sign_in_screen.dart';
import '../features/auth/screens/sign_up_screen.dart';
import '../features/auth/screens/forgot_password_screen.dart';
import '../features/home/screens/home_screen.dart';
import '../features/chat/screens/chat_screen.dart';
import '../features/profile/screens/profile_screen.dart';

class AppRoutes {
  AppRoutes._();

  static const String splash = '/';
  static const String signIn = '/sign-in';
  static const String signUp = '/sign-up';
  static const String forgotPassword = '/forgot-password';
  static const String home = '/home';
  static const String chat = '/chat';
  static const String profile = '/profile';

  static Map<String, WidgetBuilder> get routes => {
    splash: (_) => const SplashScreen(),
    signIn: (_) => const SignInScreen(),
    signUp: (_) => const SignUpScreen(),
    forgotPassword: (_) => const ForgotPasswordScreen(),
    home: (_) => const HomeScreen(),
    chat: (_) => const ChatScreen(),
    profile: (_) => const ProfileScreen(),
  };
}
