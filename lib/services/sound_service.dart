import 'package:audioplayers/audioplayers.dart';

import 'settings_service.dart';

class SoundService {
  static final AudioPlayer _player = AudioPlayer();

  static Future<void> playCorrect() async {
    final settings = await SettingsService.getSettings();

    if (!settings.sound) return;

    await _player.play(
      AssetSource('sounds/correct.mp3'),
    );
  }

  static Future<void> playWrong() async {
    final settings = await SettingsService.getSettings();

    if (!settings.sound) return;

    await _player.play(
      AssetSource('sounds/wrong.mp3'),
    );
  }

  static Future<void> playLevelUp() async {
    final settings = await SettingsService.getSettings();

    if (!settings.sound) return;

    await _player.play(
      AssetSource('sounds/levelup.mp3'),
    );
  }

  static Future<void> playBadge() async {
    final settings = await SettingsService.getSettings();

    if (!settings.sound) return;

    await _player.play(
      AssetSource('sounds/badge.mp3'),
    );
  }
}