import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class LearningEngine {
  static const _key = "question_state";

  /// 📌 tüm soru durumlarını getir
  static Future<Map<String, dynamic>> _getState() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return {};
    return jsonDecode(raw);
  }

  /// 📌 state kaydet
  static Future<void> _saveState(Map<String, dynamic> data) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(data));
  }

  /// 📊 soru bilgisi getir
  static Future<Map<String, dynamic>> getQuestionMeta(String id) async {
    final state = await _getState();
    return state[id] ?? {
      "level": 0,
      "lastSeen": 0,
      "correctCount": 0,
      "wrongCount": 0,
    };
  }

  /// 🎯 soru doğru cevaplandı
  static Future<void> markCorrect(String id) async {
    final state = await _getState();
    final q = state[id] ?? {};

    int level = (q["level"] ?? 0) + 1;

    state[id] = {
      "level": level,
      "lastSeen": DateTime.now().millisecondsSinceEpoch,
      "correctCount": (q["correctCount"] ?? 0) + 1,
      "wrongCount": q["wrongCount"] ?? 0,
    };

    await _saveState(state);
  }

  /// ❌ soru yanlış cevaplandı
  static Future<void> markWrong(String id) async {
    final state = await _getState();
    final q = state[id] ?? {};

    int level = (q["level"] ?? 0);
    if (level > 0) level--;

    state[id] = {
      "level": level,
      "lastSeen": DateTime.now().millisecondsSinceEpoch,
      "correctCount": q["correctCount"] ?? 0,
      "wrongCount": (q["wrongCount"] ?? 0) + 1,
    };

    await _saveState(state);
  }

  /// ⏱ spaced repetition (TEKRAR ZAMANI MI?)
  static Future<bool> shouldShowAgain(String id) async {
    final q = await getQuestionMeta(id);

    final level = q["level"] ?? 0;
    final lastSeen = q["lastSeen"] ?? 0;

    final now = DateTime.now().millisecondsSinceEpoch;

    final hours = level == 0
        ? 0
        : level == 1
        ? 12
        : level == 2
        ? 24
        : level == 3
        ? 72
        : 168;

    return now - lastSeen > hours * 3600000;
  }
}