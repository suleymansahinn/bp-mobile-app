import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProgressService {
  static const String _streakKey = 'daily_streak';
  static const String _lastLoginDateKey = 'last_login_date';

  static final FirebaseDatabase _db = FirebaseDatabase.instanceFor(
    app: Firebase.app(),
    databaseURL: 'https://yazimkurallari-3883f-default-rtdb.firebaseio.com/',
  );

  static String? get _uid => FirebaseAuth.instance.currentUser?.uid;

  static DatabaseReference? get _progressRef {
    final uid = _uid;
    if (uid == null) return null;
    return _db.ref('users/$uid/progress');
  }

  static String _dateKey(DateTime date) {
    return '${date.year}-${date.month}-${date.day}';
  }

  static Future<void> updateStreak() async {
    final today = DateTime.now();
    final yesterday = today.subtract(const Duration(days: 1));

    final todayKey = _dateKey(today);
    final yesterdayKey = _dateKey(yesterday);

    final ref = _progressRef;

    if (ref == null) {
      final prefs = await SharedPreferences.getInstance();

      final lastLoginDate = prefs.getString(_lastLoginDateKey);
      int streak = prefs.getInt(_streakKey) ?? 0;

      if (lastLoginDate == todayKey) return;

      if (lastLoginDate == yesterdayKey) {
        streak++;
      } else {
        streak = 1;
      }

      await prefs.setInt(_streakKey, streak);
      await prefs.setString(_lastLoginDateKey, todayKey);
      return;
    }

    final snapshot = await ref.get();

    String lastLoginDate = '';
    int streak = 0;

    if (snapshot.exists && snapshot.value is Map) {
      final raw = Map<String, dynamic>.from(
        (snapshot.value as Map).map(
              (key, value) => MapEntry(key.toString(), value),
        ),
      );

      lastLoginDate = raw['lastLoginDate']?.toString() ?? '';
      streak = int.tryParse(raw['streak']?.toString() ?? '0') ?? 0;
    }

    if (lastLoginDate == todayKey) return;

    if (lastLoginDate == yesterdayKey) {
      streak++;
    } else {
      streak = 1;
    }

    await ref.update({
      'streak': streak,
      'lastLoginDate': todayKey,
      'updatedAt': DateTime.now().toIso8601String(),
    });
  }

  static Future<int> getStreak() async {
    final ref = _progressRef;

    if (ref == null) {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getInt(_streakKey) ?? 0;
    }

    final snapshot = await ref.child('streak').get();

    if (!snapshot.exists || snapshot.value == null) {
      await ref.child('streak').set(0);
      return 0;
    }

    final value = snapshot.value;
    if (value is int) return value;
    if (value is num) return value.toInt();

    return int.tryParse(value.toString()) ?? 0;
  }

  static Future<void> resetStreak() async {
    final ref = _progressRef;

    if (ref != null) {
      await ref.update({
        'streak': 0,
        'lastLoginDate': '',
      });
    } else {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_streakKey, 0);
      await prefs.remove(_lastLoginDateKey);
    }
  }
}