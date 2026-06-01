import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/app_badge.dart';

class BadgeService {
  static const String _badgeKey = 'unlocked_badges';

  static final FirebaseDatabase _db = FirebaseDatabase.instanceFor(
    app: Firebase.app(),
    databaseURL: 'https://yazimkurallari-3883f-default-rtdb.firebaseio.com/',
  );

  static String? get _uid => FirebaseAuth.instance.currentUser?.uid;

  static DatabaseReference? get _badgeRef {
    final uid = _uid;
    if (uid == null) return null;
    return _db.ref('users/$uid/badges/unlocked');
  }

  static const List<AppBadge> allBadges = [
    AppBadge(
      id: 'xp_50',
      title: 'İlk Adım',
      description: '50 XP kazandın.',
      requiredXP: 50,
    ),
    AppBadge(
      id: 'xp_100',
      title: 'Çalışkan Öğrenci',
      description: '100 XP kazandın.',
      requiredXP: 100,
    ),
    AppBadge(
      id: 'xp_250',
      title: 'Yazım Ustası',
      description: '250 XP kazandın.',
      requiredXP: 250,
    ),
  ];

  static Future<List<String>> getUnlockedBadgeIds() async {
    final ref = _badgeRef;

    if (ref == null) {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getStringList(_badgeKey) ?? [];
    }

    final snapshot = await ref.get();

    if (!snapshot.exists || snapshot.value == null) {
      await ref.set([]);
      return [];
    }

    final raw = snapshot.value;

    if (raw is List) {
      return raw.whereType<String>().toList();
    }

    if (raw is Map) {
      return raw.values.map((e) => e.toString()).toList();
    }

    return [];
  }

  static Future<List<String>> getUnlockedBadges() async {
    return getUnlockedBadgeIds();
  }

  static Future<void> _saveUnlockedIds(List<String> ids) async {
    final ref = _badgeRef;

    if (ref != null) {
      await ref.set(ids);
    } else {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_badgeKey, ids);
    }
  }

  static Future<List<AppBadge>> checkAndUnlockBadges({
    required int xp,
    required int level,
  }) async {
    final unlockedIds = await getUnlockedBadgeIds();
    final List<AppBadge> newlyUnlocked = [];

    void unlock(AppBadge badge) {
      if (!unlockedIds.contains(badge.id)) {
        unlockedIds.add(badge.id);
        newlyUnlocked.add(badge);
      }
    }

    for (final badge in allBadges) {
      if (xp >= badge.requiredXP) {
        unlock(badge);
      }
    }

    await _saveUnlockedIds(unlockedIds);

    return newlyUnlocked;
  }
}