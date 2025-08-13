import 'package:flutter/material.dart';

// Paleta de colores principal de la aplicación.
class AppColors {
  static const Color primaryRed = Color(0xFF780000);
  static const Color secondaryRed = Color(0xFFC1121F);
  static const Color lightCream = Color(0xFFFDF0D5);
  static const Color darkBlue = Color(0xFF003049);
  static const Color lightBlue = Color(0xFF669BBC);

  // Colores semánticos para temas
  static const Color backgroundLight = Color(0xFFFFFFFF);
  static const Color backgroundDark = Color(0xFF121212);
  static const Color surfaceLight = Color(0xFFFDF0D5);
  static const Color surfaceDark = Color(0xFF1E1E1E);
}

// Rutas de la aplicación para GoRouter
class AppRoutes {
  static const String splash = '/';
  static const String offlineSplashScreen = '/offline-splash-screen';
  static const String splashScreen = '/splash-screen';
  static const String login = '/login';
  static const String register = '/register';
  static const String guestLogin = '/guest-login';
  static const String home = '/home';
  static const String affiliates = '/affiliates';
  static const String affiliateDetail = '/affiliates/:id';
  static const String contributions = '/contributions';
  static const String fines = '/fines';
  static const String attendance = '/attendance';
  static const String settings = '/settings';
  static const String pendingOperations = '/pending-operations';
  static const String guestDetail = '/guest-detail';
}

