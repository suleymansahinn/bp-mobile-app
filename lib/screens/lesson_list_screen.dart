import 'package:flutter/material.dart';

import '../models/lesson_model.dart';
import '../services/lesson_service.dart';
import 'lesson_screen.dart';

class LessonListScreen extends StatefulWidget {
  const LessonListScreen({super.key});

  @override
  State<LessonListScreen> createState() => _LessonListScreenState();
}

class _LessonListScreenState extends State<LessonListScreen> {
  late Future<List<LessonModel>> _lessonsFuture;

  @override
  void initState() {
    super.initState();
    _lessonsFuture = LessonService.getAllLessons();
  }

  IconData _iconForLesson(String id) {
    if (id.contains('buyuk')) return Icons.text_fields_rounded;
    if (id.contains('de_da')) return Icons.compare_arrows_rounded;
    if (id.contains('ki')) return Icons.link_rounded;
    if (id.contains('noktalama')) return Icons.format_quote_rounded;
    if (id.contains('sayi')) return Icons.pin_rounded;
    if (id.contains('kisaltma')) return Icons.short_text_rounded;
    if (id.contains('birlesik')) return Icons.join_full_rounded;
    if (id.contains('ek')) return Icons.extension_rounded;
    return Icons.menu_book_rounded;
  }

  Color _colorForIndex(int index) {
    final colors = [
      const Color(0xFF1FA2FF),
      const Color(0xFF00BFA5),
      const Color(0xFFFFB300),
      const Color(0xFFFF5252),
      const Color(0xFF7E57C2),
      const Color(0xFF26C6DA),
    ];

    return colors[index % colors.length];
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: dark ? const Color(0xFF0F172A) : const Color(0xFFF5F7FB),
      appBar: AppBar(
        title: const Text("Dersler"),
        centerTitle: true,
        backgroundColor: dark ? const Color(0xFF111827) : const Color(0xFF1FA2FF),
        foregroundColor: Colors.white,
      ),
      body: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: dark
                ? [
              const Color(0xFF0F172A),
              const Color(0xFF111827),
            ]
                : [
              const Color(0xFFF8FBFC),
              const Color(0xFFE0F7FA),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: FutureBuilder<List<LessonModel>>(
          future: _lessonsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    "Dersler okunamadı.\n${snapshot.error}",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: dark ? Colors.white70 : Colors.black87,
                    ),
                  ),
                ),
              );
            }

            final lessons = snapshot.data ?? [];

            if (lessons.isEmpty) {
              return Center(
                child: Text(
                  "Henüz ders bulunamadı.",
                  style: TextStyle(
                    color: dark ? Colors.white : Colors.black87,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              );
            }

            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _HeaderCard(total: lessons.length),
                const SizedBox(height: 18),
                ...lessons.asMap().entries.map((entry) {
                  final index = entry.key;
                  final lesson = entry.value;
                  final color = _colorForIndex(index);

                  return _LessonListCard(
                    lesson: lesson,
                    color: color,
                    icon: _iconForLesson(lesson.id),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => LessonScreen(
                            lessonId: lesson.id,
                          ),
                        ),
                      );
                    },
                  );
                }),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _HeaderCard extends StatelessWidget {
  final int total;

  const _HeaderCard({
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        gradient: LinearGradient(
          colors: dark
              ? [
            const Color(0xFF1E3A8A),
            const Color(0xFF312E81),
          ]
              : [
            const Color(0xFF1FA2FF),
            const Color(0xFF12D8FA),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1FA2FF).withOpacity(dark ? 0.15 : 0.25),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 31,
            backgroundColor: Colors.white,
            child: Icon(
              Icons.school_rounded,
              color: Color(0xFF1FA2FF),
              size: 34,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Yazım Kuralları Dersleri",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 21,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  "$total kapsamlı ders seni bekliyor.",
                  style: const TextStyle(
                    color: Colors.white70,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LessonListCard extends StatelessWidget {
  final LessonModel lesson;
  final Color color;
  final IconData icon;
  final VoidCallback onTap;

  const _LessonListCard({
    required this.lesson,
    required this.color,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final sectionCount = lesson.sections.length;

    return InkWell(
      borderRadius: BorderRadius.circular(22),
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: dark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: dark ? Border.all(color: Colors.white10) : null,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(dark ? 0.26 : 0.08),
              blurRadius: 12,
              offset: const Offset(0, 7),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                color: color.withOpacity(dark ? 0.20 : 0.12),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Icon(
                icon,
                color: color,
                size: 31,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    lesson.title,
                    style: TextStyle(
                      color: dark ? Colors.white : Colors.black87,
                      fontSize: 17.5,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    lesson.description.isEmpty
                        ? "$sectionCount bölüm"
                        : lesson.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: dark ? Colors.white60 : Colors.black54,
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "$sectionCount bölüm",
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              size: 17,
              color: dark ? Colors.white38 : Colors.black38,
            ),
          ],
        ),
      ),
    );
  }
}