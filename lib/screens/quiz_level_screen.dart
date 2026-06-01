import 'package:flutter/material.dart';

import '../services/level_service.dart';
import 'quiz_screen.dart';

class QuizLevelScreen extends StatefulWidget {
  const QuizLevelScreen({super.key});

  @override
  State<QuizLevelScreen> createState() => _QuizLevelScreenState();
}

class _QuizLevelScreenState extends State<QuizLevelScreen> {
  int unlockedLevel = 1;

  final List<Map<String, dynamic>> levels = const [
    {
      "level": 1,
      "title": "Seviye 1",
      "subtitle": "Temel yazım kuralları",
      "start": 1,
      "end": 40,
      "questionCount": 10,
      "passPercent": 60,
      "topics": ["buyuk_harf", "de_da"],
      "color": Color(0xFF1FA2FF),
    },
    {
      "level": 2,
      "title": "Seviye 2",
      "subtitle": "De / Da ve Ki yazımı",
      "start": 41,
      "end": 80,
      "questionCount": 15,
      "passPercent": 65,
      "topics": ["de_da", "ki"],
      "color": Color(0xFF12D8FA),
    },
    {
      "level": 3,
      "title": "Seviye 3",
      "subtitle": "Noktalama kuralları",
      "start": 81,
      "end": 120,
      "questionCount": 20,
      "passPercent": 70,
      "topics": ["noktalama", "sayi"],
      "color": Color(0xFF00BFA5),
    },
    {
      "level": 4,
      "title": "Seviye 4",
      "subtitle": "Karma yazım kuralları",
      "start": 121,
      "end": 160,
      "questionCount": 25,
      "passPercent": 75,
      "topics": ["buyuk_harf", "de_da", "ki", "noktalama"],
      "color": Color(0xFFFF9800),
    },
    {
      "level": 5,
      "title": "Seviye 5",
      "subtitle": "Genel tekrar",
      "start": 161,
      "end": 200,
      "questionCount": 40,
      "passPercent": 80,
      "topics": ["buyuk_harf", "de_da", "ki", "noktalama", "sayi", "yazim_kurallari"],
      "color": Color(0xFF7C4DFF),
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadUnlockedLevel();
  }

  Future<void> _loadUnlockedLevel() async {
    final level = await LevelService.getUnlockedLevel();
    if (!mounted) return;
    setState(() => unlockedLevel = level);
  }

  void _openLevel(Map<String, dynamic> level) {
    final levelNumber = level["level"] as int;
    final isLocked = levelNumber > unlockedLevel;

    if (isLocked) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Bu seviye henüz kilitli 🔒")),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => QuizScreen(
          levelNumber: levelNumber,
          levelTitle: level["title"] as String,
          startQuestion: level["start"] as int,
          endQuestion: level["end"] as int,
          questionCount: level["questionCount"] as int,
          passPercent: level["passPercent"] as int,
          fallbackTopics: List<String>.from(level["topics"] as List),
        ),
      ),
    ).then((_) => _loadUnlockedLevel());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Quiz Seviyeleri"),
        centerTitle: true,
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: levels.length,
        separatorBuilder: (_, __) => const SizedBox(height: 16),
        itemBuilder: (context, index) {
          final level = levels[index];
          final levelNumber = level["level"] as int;
          final isLocked = levelNumber > unlockedLevel;
          final color = isLocked ? Colors.grey : level["color"] as Color;

          return InkWell(
            borderRadius: BorderRadius.circular(22),
            onTap: () => _openLevel(level),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(22),
                gradient: LinearGradient(
                  colors: [color, color.withOpacity(0.75)],
                ),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: Colors.white,
                    child: Icon(
                      isLocked ? Icons.lock : Icons.school,
                      color: color,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          level["title"] as String,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 19,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          "${level["subtitle"]} • ${level["questionCount"]} soru",
                          style: const TextStyle(color: Colors.white70),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    isLocked ? Icons.lock : Icons.arrow_forward_ios,
                    color: Colors.white,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}