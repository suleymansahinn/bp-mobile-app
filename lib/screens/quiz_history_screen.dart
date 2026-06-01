import 'package:flutter/material.dart';
import '../services/progress_service.dart';

class QuizHistoryScreen extends StatelessWidget {
  const QuizHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Quiz Geçmişi")),
      body: FutureBuilder(
        future: ProgressService.getQuizHistory(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final history = snapshot.data!;
          if (history.isEmpty) {
            return const Center(child: Text("Henüz quiz yok"));
          }

          return ListView.builder(
            itemCount: history.length,
            itemBuilder: (_, i) {
              final q = history[i];
              return ListTile(
                title: Text(q["topic"]),
                subtitle: Text(
                  "Doğru: ${q["correct"]}/${q["total"]}",
                ),
                trailing: Text(
                  q["date"].toString().substring(0, 10),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
