import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:shared_preferences/shared_preferences.dart';

class XPResult {
  final int oldXP;
  final int newXP;
  final int oldLevel;
  final int newLevel;

  XPResult({
    required this.oldXP,
    required this.newXP,
    required this.oldLevel,
    required this.newLevel,
  });

  bool get leveledUp => newLevel > oldLevel;
}

class XPManager {
  static const String _xpKey = 'user_xp';

  static final FirebaseDatabase _db = FirebaseDatabase.instanceFor(
    app: Firebase.app(),
    databaseURL: 'https://yazimkurallari-3883f-default-rtdb.firebaseio.com/',
  );

  static String? get _uid => FirebaseAuth.instance.currentUser?.uid;

  static DatabaseReference? get _xpRef {
    final uid = _uid;
    if (uid == null) return null;
    return _db.ref('users/$uid/progress/xp');
  }

  static Future<int> getXP() async {
    final ref = _xpRef;

    if (ref == null) {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getInt(_xpKey) ?? 0;
    }

    final snapshot = await ref.get();

    if (!snapshot.exists || snapshot.value == null) {
      await ref.set(0);
      return 0;
    }

    final value = snapshot.value;

    if (value is int) return value;
    if (value is num) return value.toInt();

    return int.tryParse(value.toString()) ?? 0;
  }

  static Future<XPResult> addXP(int amount) async {
    final oldXP = await getXP();
    final oldLevel = getLevel(oldXP);

    final newXP = oldXP + amount;
    final newLevel = getLevel(newXP);

    final ref = _xpRef;

    if (ref != null) {
      await ref.set(newXP);
    } else {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_xpKey, newXP);
    }

    return XPResult(
      oldXP: oldXP,
      newXP: newXP,
      oldLevel: oldLevel,
      newLevel: newLevel,
    );
  }

  static Future<void> resetXP() async {
    final ref = _xpRef;

    if (ref != null) {
      await ref.set(0);
    } else {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_xpKey, 0);
    }
  }

  static int getLevel(int xp) {
    if (xp < 100) return 1;
    if (xp < 250) return 2;
    if (xp < 500) return 3;
    if (xp < 850) return 4;
    if (xp < 1300) return 5;
    return 6;
  }

  static int getCurrentLevelStartXP(int xp) {
    final level = getLevel(xp);

    switch (level) {
      case 1:
        return 0;
      case 2:
        return 100;
      case 3:
        return 250;
      case 4:
        return 500;
      case 5:
        return 850;
      default:
        return 1300;
    }
  }

  static int getNextLevelXP(int xp) {
    final level = getLevel(xp);

    switch (level) {
      case 1:
        return 100;
      case 2:
        return 250;
      case 3:
        return 500;
      case 4:
        return 850;
      case 5:
        return 1300;
      default:
        return xp + 500;
    }
  }
}