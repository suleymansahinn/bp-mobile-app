import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/quiz_question.dart';

class ApiService {
  static const String _baseUrl = 'http://10.0.2.2:3000';

  static Future<List<QuizQuestion>> fetchQuiz() async {
    final response = await http.get(Uri.parse('$_baseUrl/quiz'));

    if (response.statusCode == 200) {
      final List data = json.decode(utf8.decode(response.bodyBytes));
      return data.map((e) => QuizQuestion.fromJson(e)).toList();
    } else {
      throw Exception('Quiz verileri alinamadi');
    }
  }
}
