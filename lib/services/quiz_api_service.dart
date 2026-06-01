import '../models/quiz_question.dart';

class QuizApiService {
  static Future<List<QuizQuestion>> fetchQuestions({
    required String topic,
    int limit = 10,
  }) async {
    final List<QuizQuestion> all = List.generate(
      100,
          (i) => QuizQuestion(
        id: "$topic-$i",
        topic: topic,
        question: "Soru $i",
        type: i % 2 == 0 ? "tf" : "fill",
        answer: i % 2 == 0 ? true : "cevap",
      ),
    );

    return all.take(limit).toList();
  }
}
