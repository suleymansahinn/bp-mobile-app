import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';

import '../models/question.dart';

class QuestionService {
  static Future<List<Question>> getQuestionsForLevel({
    required int start,
    required int end,
    required List<String> fallbackTopics,
  }) async {
    final db = FirebaseDatabase.instanceFor(
      app: Firebase.app(),
      databaseURL: 'https://yazimkurallari-3883f-default-rtdb.firebaseio.com/',
    );

    final snapshot = await db.ref('questions').get();

    if (!snapshot.exists || snapshot.value == null) {
      return [];
    }

    final raw = snapshot.value;

    if (raw is! Map) {
      return [];
    }

    final data = Map<Object?, Object?>.from(raw);

    final List<Question> rangeQuestions = [];
    final List<Question> topicQuestions = [];

    data.forEach((key, value) {
      try {
        if (value is! Map) return;

        final id = key.toString();

        final map = Map<String, dynamic>.from(
          value.map((k, v) => MapEntry(k.toString(), v)),
        );

        final question = Question.fromMap(id, map);

        // q_1, q_25, q_151 gibi id içinden sayı çek
        final numberText = id.replaceAll(RegExp(r'[^0-9]'), '');
        final number = int.tryParse(numberText);

        if (number != null && number >= start && number <= end) {
          rangeQuestions.add(question);
        }

        // yedek sistem: id aralığı çalışmazsa topic'e göre al
        if (fallbackTopics.contains(question.topic)) {
          topicQuestions.add(question);
        }
      } catch (_) {}
    });

    final result = rangeQuestions.isNotEmpty ? rangeQuestions : topicQuestions;

    result.shuffle();
    return result;
  }
}