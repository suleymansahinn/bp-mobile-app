class LessonModel {
  final String id;
  final String title;
  final String description;
  final List<LessonSection> sections;

  LessonModel({
    required this.id,
    required this.title,
    required this.description,
    required this.sections,
  });

  factory LessonModel.fromMap(String id, Map<String, dynamic> map) {
    final rawSections = map['sections'];
    final List<LessonSection> parsedSections = [];

    if (rawSections is List) {
      for (final item in rawSections) {
        if (item is Map) {
          parsedSections.add(
            LessonSection.fromMap(
              Map<String, dynamic>.from(
                item.map((key, value) => MapEntry(key.toString(), value)),
              ),
            ),
          );
        }
      }
    } else if (rawSections is Map) {
      final sortedKeys = rawSections.keys.toList()
        ..sort((a, b) => a.toString().compareTo(b.toString()));

      for (final key in sortedKeys) {
        final item = rawSections[key];
        if (item is Map) {
          parsedSections.add(
            LessonSection.fromMap(
              Map<String, dynamic>.from(
                item.map((k, v) => MapEntry(k.toString(), v)),
              ),
            ),
          );
        }
      }
    }

    return LessonModel(
      id: id,
      title: map['title']?.toString() ?? 'Ders',
      description: map['description']?.toString() ?? '',
      sections: parsedSections,
    );
  }
}

class LessonSection {
  final String title;
  final String content;
  final List<String> examples;

  LessonSection({
    required this.title,
    required this.content,
    required this.examples,
  });

  factory LessonSection.fromMap(Map<String, dynamic> map) {
    final rawExamples = map['examples'];
    final List<String> parsedExamples = [];

    if (rawExamples is List) {
      parsedExamples.addAll(rawExamples.map((e) => e.toString()));
    } else if (rawExamples is Map) {
      final sortedKeys = rawExamples.keys.toList()
        ..sort((a, b) => a.toString().compareTo(b.toString()));

      for (final key in sortedKeys) {
        parsedExamples.add(rawExamples[key].toString());
      }
    }

    return LessonSection(
      title: map['title']?.toString() ?? 'Başlık',
      content: map['content']?.toString() ?? '',
      examples: parsedExamples,
    );
  }
}