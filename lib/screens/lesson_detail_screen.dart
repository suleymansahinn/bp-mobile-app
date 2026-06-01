import 'package:flutter/material.dart';
import 'quiz_screen.dart';

class LessonDetailScreen extends StatelessWidget {
  final String lessonId;
  final String title;
  final String content;

  const LessonDetailScreen({
    super.key,
    required this.lessonId,
    required this.title,
    required this.content,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            Text(
              content,
              style: const TextStyle(
                fontSize: 16,
                height: 1.6,
              ),
            ),

            const Spacer(),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.quiz),
                label: const Text("Teste Başla"),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => QuizScreen(topic: lessonId),
                    ),
                  );
                },
              ),
            )
          ],
        ),
      ),
    );
  }
}
