import 'package:shared_preferences/shared_preferences.dart';

class LevelService {
  static const String _unlockedLevelKey = "unlocked_level";

  static Future<int> getUnlockedLevel() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_unlockedLevelKey) ?? 1;
  }

  static Future<void> unlockNextLevel(int currentLevel) async {
    final prefs = await SharedPreferences.getInstance();
    final unlockedLevel = prefs.getInt(_unlockedLevelKey) ?? 1;

    if (currentLevel >= unlockedLevel && currentLevel < 5) {
      await prefs.setInt(_unlockedLevelKey, currentLevel + 1);
    }
  }
}