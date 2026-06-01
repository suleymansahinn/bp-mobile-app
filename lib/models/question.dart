class Question {
  final String id;
  final String question;
  final String type;
  final List<String>? options;
  final dynamic answer;
  final String topic;

  Question({
    required this.id,
    required this.question,
    required this.type,
    required this.answer,
    required this.topic,
    this.options,
  });

  factory Question.fromMap(String id, Map<String, dynamic> data) {
    return Question(
      id: id,
      question: data['question'] ?? '',
      type: data['type'] ?? 'tf',
      answer: data['answer'],
      topic: data['topic'] ?? '',
      options: data['options'] != null
          ? List<String>.from(data['options'])
          : null,
    );
  }
}