import '../models/question_model.dart';

class QuizService {
  static Future<List<QuestionModel>> getQuestions() async {
    await Future.delayed(const Duration(milliseconds: 300)); // loading simülasyonu

    return [
      QuestionModel(
        id: "q1",
        type: "fill",
        question: "Turkiye'nin baskenti _____.",
        answer: "ankara",
        options: [],
        xp: 10,
      ),
      QuestionModel(
        id: "q2",
        type: "truefalse",
        question: "Turkce'de cumleler buyuk harf ile baslar.",
        answer: "true",
        options: [],
        xp: 10,
      ),
      QuestionModel(
        id: "q3",
        type: "fill",
        question: "Ataturk'un dogdugu sehir _____.",
        answer: "selanik",
        options: [],
        xp: 10,
      ),
    ];
  }
}
