import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';

import '../models/lesson_model.dart';

class LessonService {
  static final FirebaseDatabase _db = FirebaseDatabase.instanceFor(
    app: Firebase.app(),
    databaseURL: 'https://yazimkurallari-3883f-default-rtdb.firebaseio.com/',
  );

  static Future<LessonModel?> getLessonById(String lessonId) async {
    final snapshot = await _db.ref('lessons/$lessonId').get();

    if (!snapshot.exists || snapshot.value == null) {
      return null;
    }

    final raw = snapshot.value;

    if (raw is! Map) {
      return null;
    }

    final map = Map<String, dynamic>.from(
      raw.map((key, value) => MapEntry(key.toString(), value)),
    );

    return LessonModel.fromMap(lessonId, map);
  }

  static Future<List<LessonModel>> getAllLessons() async {
    final snapshot = await _db.ref('lessons').get();

    if (!snapshot.exists || snapshot.value == null) {
      return [];
    }

    final raw = snapshot.value;

    if (raw is! Map) {
      return [];
    }

    final data = Map<String, dynamic>.from(
      raw.map((key, value) => MapEntry(key.toString(), value)),
    );

    final lessons = data.entries.map((entry) {
      final value = Map<String, dynamic>.from(
        (entry.value as Map).map(
              (key, value) => MapEntry(key.toString(), value),
        ),
      );

      return LessonModel.fromMap(entry.key, value);
    }).toList();

    lessons.sort((a, b) => a.title.compareTo(b.title));

    return lessons;
  }
}