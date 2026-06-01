import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';

class AppSettings {
  final bool notifications;
  final bool sound;
  final bool vibration;
  final String themeMode;

  const AppSettings({
    required this.notifications,
    required this.sound,
    required this.vibration,
    required this.themeMode,
  });

  factory AppSettings.defaults() {
    return const AppSettings(
      notifications: true,
      sound: true,
      vibration: true,
      themeMode: 'system',
    );
  }

  factory AppSettings.fromMap(Map<String, dynamic> map) {
    return AppSettings(
      notifications: map['notifications'] != false,
      sound: map['sound'] != false,
      vibration: map['vibration'] != false,
      themeMode: map['themeMode']?.toString() ?? 'system',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'notifications': notifications,
      'sound': sound,
      'vibration': vibration,
      'themeMode': themeMode,
      'updatedAt': DateTime.now().toIso8601String(),
    };
  }

  ThemeMode get flutterThemeMode {
    if (themeMode == 'light') return ThemeMode.light;
    if (themeMode == 'dark') return ThemeMode.dark;
    return ThemeMode.system;
  }

  AppSettings copyWith({
    bool? notifications,
    bool? sound,
    bool? vibration,
    String? themeMode,
  }) {
    return AppSettings(
      notifications: notifications ?? this.notifications,
      sound: sound ?? this.sound,
      vibration: vibration ?? this.vibration,
      themeMode: themeMode ?? this.themeMode,
    );
  }
}

class SettingsService {
  static final ValueNotifier<AppSettings> notifier =
  ValueNotifier<AppSettings>(AppSettings.defaults());

  static final FirebaseDatabase _db = FirebaseDatabase.instanceFor(
    app: Firebase.app(),
    databaseURL: 'https://yazimkurallari-3883f-default-rtdb.firebaseio.com/',
  );

  static String? get _uid => FirebaseAuth.instance.currentUser?.uid;

  static DatabaseReference? get _ref {
    final uid = _uid;
    if (uid == null) return null;
    return _db.ref('user_settings/$uid');
  }

  static Future<AppSettings> getSettings() async {
    final ref = _ref;

    if (ref == null) {
      return notifier.value;
    }

    final snapshot = await ref.get();

    if (!snapshot.exists || snapshot.value == null) {
      final defaults = AppSettings.defaults();
      await saveSettings(defaults);
      return defaults;
    }

    final raw = snapshot.value;

    if (raw is! Map) {
      notifier.value = AppSettings.defaults();
      return notifier.value;
    }

    final map = Map<String, dynamic>.from(
      raw.map((key, value) => MapEntry(key.toString(), value)),
    );

    final settings = AppSettings.fromMap(map);
    notifier.value = settings;
    return settings;
  }

  static Future<void> saveSettings(AppSettings settings) async {
    notifier.value = settings;

    final ref = _ref;
    if (ref == null) return;

    await ref.update(settings.toMap());
  }

  static Future<void> resetSettings() async {
    await saveSettings(AppSettings.defaults());
  }
}