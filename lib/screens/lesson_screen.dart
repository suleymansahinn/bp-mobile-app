import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/lesson_model.dart';
import '../services/lesson_service.dart';
import '../xp_manager.dart';
import 'quiz_level_screen.dart';

class LessonScreen extends StatefulWidget {
  final String lessonId;

  const LessonScreen({
    super.key,
    required this.lessonId,
  });

  @override
  State<LessonScreen> createState() => _LessonScreenState();
}

class _LessonScreenState extends State<LessonScreen> {
  LessonModel? lesson;
  bool loading = true;
  String error = '';

  int currentSectionIndex = 0;
  bool completed = false;

  String get _uid => FirebaseAuth.instance.currentUser?.uid ?? 'guest';

  String get _completedKey => 'lesson_completed_${widget.lessonId}_$_uid';

  @override
  void initState() {
    super.initState();
    _loadLesson();
  }

  Future<void> _loadLesson() async {
    try {
      final data = await LessonService.getLessonById(widget.lessonId);
      final prefs = await SharedPreferences.getInstance();
      final isCompleted = prefs.getBool(_completedKey) ?? false;

      if (!mounted) return;

      if (data == null) {
        setState(() {
          error = 'Bu derse ait içerik bulunamadı.';
          loading = false;
        });
        return;
      }

      setState(() {
        lesson = data;
        completed = isCompleted;
        loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        error = 'Ders verisi okunamadı.\n$e';
        loading = false;
      });
    }
  }

  Future<void> _completeLesson() async {
    if (completed) {
      _showCompletedDialog(alreadyCompleted: true);
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_completedKey, true);

    await XPManager.addXP(20);

    if (!mounted) return;

    setState(() {
      completed = true;
    });

    _showCompletedDialog(alreadyCompleted: false);
  }

  void _showCompletedDialog({required bool alreadyCompleted}) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        title: Text(
          alreadyCompleted ? 'Ders Zaten Tamamlandı ✅' : 'Ders Tamamlandı 🎉',
        ),
        content: Text(
          alreadyCompleted
              ? 'Bu dersi daha önce tamamladın.'
              : 'Bu dersi tamamladın ve +20 XP kazandın.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Kapat'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const QuizLevelScreen(),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1FA2FF),
              foregroundColor: Colors.white,
            ),
            child: const Text('Quize Git'),
          ),
        ],
      ),
    );
  }

  void _nextSection() {
    final total = lesson?.sections.length ?? 0;

    if (currentSectionIndex + 1 < total) {
      setState(() {
        currentSectionIndex++;
      });
    } else {
      _completeLesson();
    }
  }

  void _previousSection() {
    if (currentSectionIndex > 0) {
      setState(() {
        currentSectionIndex--;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;

    if (loading) {
      return Scaffold(
        backgroundColor:
        dark ? const Color(0xFF0F172A) : const Color(0xFFF5F7FB),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (error.isNotEmpty) {
      return Scaffold(
        backgroundColor:
        dark ? const Color(0xFF0F172A) : const Color(0xFFF5F7FB),
        appBar: AppBar(
          title: const Text("Ders"),
          centerTitle: true,
          backgroundColor:
          dark ? const Color(0xFF111827) : const Color(0xFF1FA2FF),
          foregroundColor: Colors.white,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              error,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: dark ? Colors.white70 : Colors.black87,
              ),
            ),
          ),
        ),
      );
    }

    final currentLesson = lesson!;
    final sections = currentLesson.sections;

    if (sections.isEmpty) {
      return Scaffold(
        backgroundColor:
        dark ? const Color(0xFF0F172A) : const Color(0xFFF5F7FB),
        appBar: AppBar(
          title: Text(currentLesson.title),
          centerTitle: true,
          backgroundColor:
          dark ? const Color(0xFF111827) : const Color(0xFF1FA2FF),
          foregroundColor: Colors.white,
        ),
        body: Center(
          child: Text(
            "Bu dersin bölümleri bulunamadı.",
            style: TextStyle(
              color: dark ? Colors.white70 : Colors.black87,
            ),
          ),
        ),
      );
    }

    final currentSection = sections[currentSectionIndex];
    final progress = (currentSectionIndex + 1) / sections.length;
    final isLast = currentSectionIndex == sections.length - 1;

    return Scaffold(
      backgroundColor:
      dark ? const Color(0xFF0F172A) : const Color(0xFFF5F7FB),
      appBar: AppBar(
        title: Text(currentLesson.title),
        centerTitle: true,
        backgroundColor:
        dark ? const Color(0xFF111827) : const Color(0xFF1FA2FF),
        foregroundColor: Colors.white,
        actions: [
          if (completed)
            const Padding(
              padding: EdgeInsets.only(right: 14),
              child: Icon(Icons.check_circle),
            ),
        ],
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
        child: SafeArea(
          child: Column(
            children: [
              _LessonProgressHeader(
                title: currentLesson.title,
                description: currentLesson.description,
                current: currentSectionIndex + 1,
                total: sections.length,
                progress: progress,
                completed: completed,
              ),
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: SingleChildScrollView(
                    key: ValueKey(currentSectionIndex),
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _SectionCard(
                          index: currentSectionIndex + 1,
                          section: currentSection,
                        ),
                        const SizedBox(height: 18),
                        if (currentSection.examples.isNotEmpty)
                          _ExamplesCard(
                            examples: currentSection.examples,
                          ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
              ),
              _BottomNavigationBar(
                canGoBack: currentSectionIndex > 0,
                isLast: isLast,
                completed: completed,
                onBack: _previousSection,
                onNext: _nextSection,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/* ---------------- HEADER ---------------- */

class _LessonProgressHeader extends StatelessWidget {
  final String title;
  final String description;
  final int current;
  final int total;
  final double progress;
  final bool completed;

  const _LessonProgressHeader({
    required this.title,
    required this.description,
    required this.current,
    required this.total,
    required this.progress,
    required this.completed,
  });

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.all(18),
      padding: const EdgeInsets.all(20),
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
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: Colors.white,
                child: Icon(
                  completed
                      ? Icons.check_circle_rounded
                      : Icons.menu_book_rounded,
                  color: const Color(0xFF1FA2FF),
                  size: 31,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 21,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (description.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white70,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(22),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 10,
                    backgroundColor: Colors.white.withOpacity(0.35),
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                "$current/$total",
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/* ---------------- SECTION CARD ---------------- */

class _SectionCard extends StatelessWidget {
  final int index;
  final LessonSection section;

  const _SectionCard({
    required this.index,
    required this.section,
  });

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.95, end: 1),
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOut,
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: child,
        );
      },
      child: Container(
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: dark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: BorderRadius.circular(26),
          border: dark ? Border.all(color: Colors.white10) : null,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(dark ? 0.26 : 0.08),
              blurRadius: 14,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor:
                  dark ? const Color(0xFF1E3A8A) : const Color(0xFFE3F2FD),
                  child: Text(
                    "$index",
                    style: const TextStyle(
                      color: Color(0xFF60A5FA),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    section.title,
                    style: TextStyle(
                      color: dark ? Colors.white : Colors.black87,
                      fontSize: 20,
                      height: 1.3,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Text(
              section.content,
              style: TextStyle(
                fontSize: 16,
                height: 1.65,
                color: dark ? Colors.white70 : Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/* ---------------- EXAMPLES CARD ---------------- */

class _ExamplesCard extends StatelessWidget {
  final List<String> examples;

  const _ExamplesCard({
    required this.examples,
  });

  bool _isCorrectExample(String text) {
    return text.toLowerCase().startsWith('doğru');
  }

  bool _isWrongExample(String text) {
    return text.toLowerCase().startsWith('yanlış');
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: dark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: dark ? Border.all(color: Colors.white10) : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(dark ? 0.26 : 0.08),
            blurRadius: 12,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor:
                dark ? const Color(0xFF164E63) : const Color(0xFFE0F7FA),
                child: const Icon(
                  Icons.lightbulb_rounded,
                  color: Color(0xFF00ACC1),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                "Örnekler",
                style: TextStyle(
                  color: dark ? Colors.white : Colors.black87,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...examples.map(
                (example) {
              final correct = _isCorrectExample(example);
              final wrong = _isWrongExample(example);

              Color bgColor =
              dark ? const Color(0xFF334155) : const Color(0xFFE3F2FD);
              Color textColor = dark ? Colors.white70 : Colors.black87;
              Color iconColor = const Color(0xFF1FA2FF);
              IconData icon = Icons.notes_rounded;

              if (correct) {
                bgColor =
                dark ? const Color(0xFF064E3B) : const Color(0xFFE8F5E9);
                iconColor = Colors.green;
                icon = Icons.check_circle_rounded;
              } else if (wrong) {
                bgColor =
                dark ? const Color(0xFF451A1A) : const Color(0xFFFFEBEE);
                iconColor = Colors.redAccent;
                icon = Icons.cancel_rounded;
              }

              return Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(13),
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      icon,
                      size: 21,
                      color: iconColor,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        example,
                        style: TextStyle(
                          color: textColor,
                          height: 1.4,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

/* ---------------- BOTTOM BAR ---------------- */

class _BottomNavigationBar extends StatelessWidget {
  final bool canGoBack;
  final bool isLast;
  final bool completed;
  final VoidCallback onBack;
  final VoidCallback onNext;

  const _BottomNavigationBar({
    required this.canGoBack,
    required this.isLast,
    required this.completed,
    required this.onBack,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 18),
      decoration: BoxDecoration(
        color: dark ? const Color(0xFF1E293B) : Colors.white,
        border: dark ? const Border(top: BorderSide(color: Colors.white10)) : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(dark ? 0.28 : 0.08),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        children: [
          if (canGoBack)
            SizedBox(
              height: 54,
              width: 58,
              child: OutlinedButton(
                onPressed: onBack,
                style: OutlinedButton.styleFrom(
                  foregroundColor: dark ? Colors.white : const Color(0xFF1FA2FF),
                  side: BorderSide(
                    color: dark ? Colors.white24 : const Color(0xFF1FA2FF),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
                child: const Icon(Icons.arrow_back_rounded),
              ),
            )
          else
            const SizedBox(width: 58),
          const SizedBox(width: 14),
          Expanded(
            child: SizedBox(
              height: 54,
              child: ElevatedButton.icon(
                onPressed: onNext,
                icon: Icon(
                  isLast
                      ? completed
                      ? Icons.check_circle_rounded
                      : Icons.done_all_rounded
                      : Icons.arrow_forward_rounded,
                ),
                label: Text(
                  isLast
                      ? completed
                      ? "Tamamlandı"
                      : "Dersi Tamamla"
                      : "Devam Et",
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1FA2FF),
                  foregroundColor: Colors.white,
                  elevation: 5,
                  shadowColor: const Color(0xFF1FA2FF).withOpacity(0.3),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}