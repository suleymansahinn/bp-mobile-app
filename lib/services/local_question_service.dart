import 'dart:convert';
import 'package:flutter/services.dart';

class LocalQuestionService {
  static Future<List<Map<String, dynamic>>> loadQuestions(String topic) async {
    final String jsonString =
    await rootBundle.loadString('assets/data/questions.json');

    final List data = json.decode(jsonString);

    return data
        .where((q) => q['topic'] == topic)
        .map<Map<String, dynamic>>((e) => {
      "question": e['question'],
      "answer": e['answer'],
      "type": e['type'],
    })
        .toList();
  }
}