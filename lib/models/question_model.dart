class QuestionModel {
  final String id;
  final String type; // fill | truefalse
  final String question;
  final String answer;
  final List<String> options;
  final int xp;

  QuestionModel({
    required this.id,
    required this.type,
    required this.question,
    required this.answer,
    required this.options,
    required this.xp,
  });

  factory QuestionModel.fromJson(Map<String, dynamic> json) {
    return QuestionModel(
      id: json['id'],
      type: json['type'],
      question: json['question'],
      answer: json['answer'],
      options: List<String>.from(json['options'] ?? []),
      xp: json['xp'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'question': question,
      'answer': answer,
      'options': options,
      'xp': xp,
    };
  }
}
