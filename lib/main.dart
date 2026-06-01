import 'package:bp/services/notification_service.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'services/settings_service.dart';
import 'screens/splash_screen.dart';
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp();

  // 🔔 Bildirim sistemi başlat
  await NotificationService.initialize();

  // ⚙️ Kullanıcı ayarlarını yükle
  await SettingsService.getSettings();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: const Color(0xFF6D4AFF),
      scaffoldBackgroundColor: const Color(0xFFF5F7FB),
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF6D4AFF),
        brightness: Brightness.light,
      ),
    );
  }

  ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,

      scaffoldBackgroundColor: const Color(0xFF0F172A),

      cardColor: const Color(0xFF1E293B),

      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF111827),
        foregroundColor: Colors.white,
      ),

      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF6D4AFF),
        brightness: Brightness.dark,
      ),

      textTheme: const TextTheme(
        bodyLarge: TextStyle(color: Colors.white),
        bodyMedium: TextStyle(color: Colors.white70),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AppSettings>(
      valueListenable: SettingsService.notifier,
      builder: (context, settings, _) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Yazım Kuralları',
          theme: lightTheme,
          darkTheme: darkTheme,
          themeMode: settings.flutterThemeMode,
          home: const SplashScreen(),
        );
      },
    );
  }
}