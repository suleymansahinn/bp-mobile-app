import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../xp_manager.dart';

class DailyQuestResult {
  final int bonusXP;
  final List<String> completedQuests;

  DailyQuestResult({
    required this.bonusXP,
    required this.completedQuests,
  });
}

class DailyQuestService {
  static const String _dateKey = 'daily_quest_date';
  static const String _solvedKey = 'daily_solved_count';
  static const String _correctKey = 'daily_correct_count';
  static const String _quest1ClaimedKey = 'daily_quest_1_claimed';
  static const String _quest2ClaimedKey = 'daily_quest_2_claimed';

  static final FirebaseDatabase _db = FirebaseDatabase.instanceFor(
    app: Firebase.app(),
    databaseURL: 'https://yazimkurallari-3883f-default-rtdb.firebaseio.com/',
  );

  static String? get _uid => FirebaseAuth.instance.currentUser?.uid;

  static DatabaseReference? get _questRef {
    final uid = _uid;
    if (uid == null) return null;
    return _db.ref('users/$uid/dailyQuest');
  }

  static String _todayKey() {
    final now = DateTime.now();
    return '${now.year}-${now.month}-${now.day}';
  }

  static Future<void> _resetIfNewDay() async {
    final today = _todayKey();
    final ref = _questRef;

    if (ref == null) {
      final prefs = await SharedPreferences.getInstance();
      final savedDate = prefs.getString(_dateKey);

      if (savedDate != today) {
        await prefs.setString(_dateKey, today);
        await prefs.setInt(_solvedKey, 0);
        await prefs.setInt(_correctKey, 0);
        await prefs.setBool(_quest1ClaimedKey, false);
        await prefs.setBool(_quest2ClaimedKey, false);
      }

      return;
    }

    final snapshot = await ref.get();

    String savedDate = '';

    if (snapshot.exists && snapshot.value is Map) {
      final raw = Map<String, dynamic>.from(
        (snapshot.value as Map).map(
              (key, value) => MapEntry(key.toString(), value),
        ),
      );

      savedDate = raw['date']?.toString() ?? '';
    }

    if (savedDate != today) {
      await ref.set({
        'date': today,
        'solved': 0,
        'correct': 0,
        'quest1Claimed': false,
        'quest2Claimed': false,
        'updatedAt': DateTime.now().toIso8601String(),
      });
    }
  }

  static Future<Map<String, dynamic>> _getQuestData() async {
    await _resetIfNewDay();

    final ref = _questRef;

    if (ref == null) {
      final prefs = await SharedPreferences.getInstance();

      return {
        'solved': prefs.getInt(_solvedKey) ?? 0,
        'correct': prefs.getInt(_correctKey) ?? 0,
        'quest1Claimed': prefs.getBool(_quest1ClaimedKey) ?? false,
        'quest2Claimed': prefs.getBool(_quest2ClaimedKey) ?? false,
      };
    }

    final snapshot = await ref.get();

    if (!snapshot.exists || snapshot.value == null || snapshot.value is! Map) {
      return {
        'solved': 0,
        'correct': 0,
        'quest1Claimed': false,
        'quest2Claimed': false,
      };
    }

    final raw = Map<String, dynamic>.from(
      (snapshot.value as Map).map(
            (key, value) => MapEntry(key.toString(), value),
      ),
    );

    return {
      'solved': int.tryParse(raw['solved']?.toString() ?? '0') ?? 0,
      'correct': int.tryParse(raw['correct']?.toString() ?? '0') ?? 0,
      'quest1Claimed': raw['quest1Claimed'] == true,
      'quest2Claimed': raw['quest2Claimed'] == true,
    };
  }

  static Future<void> recordAnswer(bool isCorrect) async {
    await _resetIfNewDay();

    final ref = _questRef;

    if (ref == null) {
      final prefs = await SharedPreferences.getInstance();

      final solved = prefs.getInt(_solvedKey) ?? 0;
      final correct = prefs.getInt(_correctKey) ?? 0;

      await prefs.setInt(_solvedKey, solved + 1);

      if (isCorrect) {
        await prefs.setInt(_correctKey, correct + 1);
      }

      return;
    }

    final data = await _getQuestData();

    final solved = data['solved'] as int;
    final correct = data['correct'] as int;

    await ref.update({
      'solved': solved + 1,
      'correct': isCorrect ? correct + 1 : correct,
      'updatedAt': DateTime.now().toIso8601String(),
    });
  }

  static Future<int> getSolvedCount() async {
    final data = await _getQuestData();
    return data['solved'] as int;
  }

  static Future<int> getCorrectCount() async {
    final data = await _getQuestData();
    return data['correct'] as int;
  }

  static Future<DailyQuestResult> checkAndClaimRewards() async {
    await _resetIfNewDay();

    final data = await _getQuestData();

    final solved = data['solved'] as int;
    final correct = data['correct'] as int;
    final quest1Claimed = data['quest1Claimed'] as bool;
    final quest2Claimed = data['quest2Claimed'] as bool;

    int bonusXP = 0;
    final List<String> completed = [];

    bool updatedQuest1 = quest1Claimed;
    bool updatedQuest2 = quest2Claimed;

    if (solved >= 10 && !quest1Claimed) {
      bonusXP += 50;
      completed.add('Günlük görev: 10 soru çöz');
      updatedQuest1 = true;
    }

    if (correct >= 5 && !quest2Claimed) {
      bonusXP += 30;
      completed.add('Günlük görev: 5 doğru cevap');
      updatedQuest2 = true;
    }

    if (bonusXP > 0) {
      await XPManager.addXP(bonusXP);
    }

    final ref = _questRef;

    if (ref != null) {
      await ref.update({
        'quest1Claimed': updatedQuest1,
        'quest2Claimed': updatedQuest2,
        'updatedAt': DateTime.now().toIso8601String(),
      });
    } else {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_quest1ClaimedKey, updatedQuest1);
      await prefs.setBool(_quest2ClaimedKey, updatedQuest2);
    }

    return DailyQuestResult(
      bonusXP: bonusXP,
      completedQuests: completed,
    );
  }
}