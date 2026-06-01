import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../xp_manager.dart';
import '../services/sound_service.dart';
import '../services/settings_service.dart';

class WrongQuestionsScreen extends StatefulWidget {
  const WrongQuestionsScreen({super.key});

  @override
  State<WrongQuestionsScreen> createState() => _WrongQuestionsScreenState();
}

class _WrongQuestionsScreenState extends State<WrongQuestionsScreen> {
  List<Map<String, dynamic>> wrongQuestions = [];
  bool loading = true;

  int currentIndex = 0;
  int score = 0;
  bool reviewMode = false;

  final TextEditingController fillController = TextEditingController();

  String get _wrongQuestionsKey {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? 'guest';
    return 'wrong_questions_$uid';
  }

  @override
  void initState() {
    super.initState();
    _loadWrongQuestions();
  }

  Future<void> _loadWrongQuestions() async {
    final prefs = await SharedPreferences.getInstance();
    final rawList = prefs.getStringList(_wrongQuestionsKey) ?? [];

    final List<Map<String, dynamic>> loaded = [];

    for (final item in rawList) {
      try {
        final decoded = jsonDecode(item);
        loaded.add(Map<String, dynamic>.from(decoded));
      } catch (_) {}
    }

    if (!mounted) return;

    setState(() {
      wrongQuestions = loaded;
      loading = false;

      if (currentIndex >= loaded.length) {
        currentIndex = 0;
      }
    });
  }

  Future<void> _playReviewFeedback(bool isCorrect) async {
    final settings = await SettingsService.getSettings();

    if (isCorrect) {
      await SoundService.playCorrect();

      if (settings.vibration) {
        await HapticFeedback.lightImpact();
      }
    } else {
      await SoundService.playWrong();

      if (settings.vibration) {
        await HapticFeedback.mediumImpact();
      }
    }
  }

  String _safeAnswer(dynamic answer) {
    if (answer == null) return 'Cevap bulunamadı';

    final value = answer.toString().trim();

    if (value.isEmpty || value == 'null') {
      return 'Cevap bulunamadı';
    }

    if (value.toLowerCase() == 'true') {
      return 'Doğru';
    }

    if (value.toLowerCase() == 'false') {
      return 'Yanlış';
    }

    return value;
  }

  String _normalize(String value) {
    return value
        .toLowerCase()
        .trim()
        .replaceAll('ı', 'i')
        .replaceAll('İ', 'i')
        .replaceAll('ğ', 'g')
        .replaceAll('Ğ', 'g')
        .replaceAll('ü', 'u')
        .replaceAll('Ü', 'u')
        .replaceAll('ş', 's')
        .replaceAll('Ş', 's')
        .replaceAll('ö', 'o')
        .replaceAll('Ö', 'o')
        .replaceAll('ç', 'c')
        .replaceAll('Ç', 'c');
  }

  String _typeText(String? type) {
    if (type == 'mcq') return '4 Seçenekli Soru';
    if (type == 'tf') return 'Doğru / Yanlış';
    if (type == 'fill') return 'Boşluk Doldurma';
    return 'Soru';
  }

  IconData _typeIcon(String? type) {
    if (type == 'mcq') return Icons.list_alt_rounded;
    if (type == 'tf') return Icons.rule_rounded;
    if (type == 'fill') return Icons.edit_note_rounded;
    return Icons.help_outline_rounded;
  }

  bool _checkCorrect(Map<String, dynamic> q, dynamic selected) {
    final type = q['type']?.toString();
    final answer = q['answer'];

    if (type == 'fill') {
      return _normalize(selected.toString()) == _normalize(_safeAnswer(answer));
    }

    return selected.toString() == answer.toString();
  }

  Future<void> _removeWrongQuestion(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final rawList = prefs.getStringList(_wrongQuestionsKey) ?? [];

    final updated = rawList.where((item) {
      try {
        final decoded = jsonDecode(item);
        return decoded['id'] != id;
      } catch (_) {
        return true;
      }
    }).toList();

    await prefs.setStringList(_wrongQuestionsKey, updated);
    await _loadWrongQuestions();
  }

  Future<void> _answerWrongQuestion(dynamic selected) async {
    final q = wrongQuestions[currentIndex];
    final isCorrect = _checkCorrect(q, selected);

    await _playReviewFeedback(isCorrect);

    if (isCorrect) {
      score++;
      await XPManager.addXP(5);
      await _removeWrongQuestion(q['id'].toString());
    }

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return _ReviewResultSheet(
          isCorrect: isCorrect,
          correctAnswer: _safeAnswer(q['answer']),
          onNext: () {
            Navigator.pop(context);
            _nextReviewQuestion();
          },
        );
      },
    );
  }

  void _nextReviewQuestion() {
    fillController.clear();

    if (wrongQuestions.isEmpty) {
      setState(() {
        reviewMode = false;
        currentIndex = 0;
      });

      _showFinishedDialog(allCleared: true);
      return;
    }

    if (currentIndex + 1 < wrongQuestions.length) {
      setState(() {
        currentIndex++;
      });
    } else {
      setState(() {
        reviewMode = false;
        currentIndex = 0;
      });

      _showFinishedDialog(allCleared: false);
    }
  }

  void _showFinishedDialog({required bool allCleared}) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
        ),
        title: Text(allCleared ? "Harika! 🎉" : "Tekrar Bitti"),
        content: Text(
          allCleared
              ? "Tüm yanlış soruları doğru çözdün. Yanlışlar listen temizlendi."
              : "Doğru çözdüklerin listeden kaldırıldı. Kalan yanlışları sonra tekrar çözebilirsin.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Tamam"),
          ),
        ],
      ),
    );
  }

  void _startReview() {
    if (wrongQuestions.isEmpty) return;

    setState(() {
      reviewMode = true;
      currentIndex = 0;
      score = 0;
      wrongQuestions.shuffle();
    });
  }

  Future<void> _clearWrongQuestions() async {
    final shouldClear = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
        ),
        title: const Text("Tüm yanlışları sil?"),
        content: const Text(
          "Bu işlem sadece bu kullanıcıya ait yanlış soruları temizler.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Vazgeç"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF5252),
              foregroundColor: Colors.white,
            ),
            child: const Text("Sil"),
          ),
        ],
      ),
    );

    if (shouldClear != true) return;

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_wrongQuestionsKey);

    if (!mounted) return;

    setState(() {
      wrongQuestions = [];
      reviewMode = false;
      currentIndex = 0;
      score = 0;
    });
  }

  @override
  void dispose() {
    fillController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;

    if (loading) {
      return Scaffold(
        backgroundColor:
        dark ? const Color(0xFF0F172A) : const Color(0xFFFFF5F5),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (reviewMode && wrongQuestions.isNotEmpty) {
      return _buildReviewScreen();
    }

    return _buildListScreen();
  }

  Widget _buildListScreen() {
    final dark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
      dark ? const Color(0xFF0F172A) : const Color(0xFFFFF5F5),
      appBar: AppBar(
        title: const Text("Yanlışlarım"),
        centerTitle: true,
        backgroundColor:
        dark ? const Color(0xFF111827) : const Color(0xFFFF5252),
        foregroundColor: Colors.white,
        actions: [
          if (wrongQuestions.isNotEmpty)
            IconButton(
              onPressed: _clearWrongQuestions,
              icon: const Icon(Icons.delete_sweep_rounded),
              tooltip: "Tümünü Temizle",
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
              const Color(0xFFFFF8F8),
              const Color(0xFFFFEBEE),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: wrongQuestions.isEmpty
            ? const _EmptyWrongState()
            : Column(
          children: [
            _WrongSummaryHeader(
              count: wrongQuestions.length,
              onStartReview: _startReview,
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 18),
                itemCount: wrongQuestions.length,
                itemBuilder: (context, index) {
                  final q = wrongQuestions[index];

                  return _WrongQuestionCard(
                    question: q['question']?.toString() ?? '',
                    answer: _safeAnswer(q['answer']),
                    typeText: _typeText(q['type']?.toString()),
                    icon: _typeIcon(q['type']?.toString()),
                    onDelete: () =>
                        _removeWrongQuestion(q['id'].toString()),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReviewScreen() {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final q = wrongQuestions[currentIndex];
    final type = q['type']?.toString();
    final optionsRaw = q['options'];
    final List options = optionsRaw is List ? optionsRaw : [];

    final progress = wrongQuestions.isEmpty
        ? 0.0
        : (currentIndex + 1) / wrongQuestions.length;

    return Scaffold(
      backgroundColor:
      dark ? const Color(0xFF0F172A) : const Color(0xFFFFF5F5),
      appBar: AppBar(
        title: const Text("Yanlışları Tekrar Çöz"),
        centerTitle: true,
        backgroundColor:
        dark ? const Color(0xFF111827) : const Color(0xFFFF5252),
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
              const Color(0xFFFFF8F8),
              const Color(0xFFFFEBEE),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _ReviewTopCard(
                  current: currentIndex + 1,
                  total: wrongQuestions.length,
                  score: score,
                  progress: progress,
                ),
                const SizedBox(height: 24),
                _ReviewQuestionCard(
                  question: q['question']?.toString() ?? '',
                  typeText: _typeText(type),
                  icon: _typeIcon(type),
                ),
                const SizedBox(height: 24),
                if (type == 'mcq')
                  ...options.map(
                        (option) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _WrongAnswerButton(
                        text: option.toString(),
                        onTap: () => _answerWrongQuestion(option),
                      ),
                    ),
                  ),
                if (type == 'tf')
                  Column(
                    children: [
                      _WrongAnswerButton(
                        text: "Doğru",
                        icon: Icons.check_circle_outline_rounded,
                        onTap: () => _answerWrongQuestion(true),
                      ),
                      const SizedBox(height: 12),
                      _WrongAnswerButton(
                        text: "Yanlış",
                        icon: Icons.cancel_outlined,
                        onTap: () => _answerWrongQuestion(false),
                      ),
                    ],
                  ),
                if (type == 'fill')
                  _FillReviewArea(
                    controller: fillController,
                    onSubmit: () {
                      if (fillController.text.trim().isEmpty) return;
                      _answerWrongQuestion(fillController.text);
                    },
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/* ---------------- LIST UI ---------------- */

class _WrongSummaryHeader extends StatelessWidget {
  final int count;
  final VoidCallback onStartReview;

  const _WrongSummaryHeader({
    required this.count,
    required this.onStartReview,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          colors: [
            Color(0xFFFF5252),
            Color(0xFFFF8A80),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.redAccent.withOpacity(0.25),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              const CircleAvatar(
                backgroundColor: Colors.white,
                child: Icon(
                  Icons.error_outline_rounded,
                  color: Color(0xFFFF5252),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  "$count yanlış soru seni bekliyor",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 19,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton.icon(
              onPressed: onStartReview,
              icon: const Icon(Icons.replay_rounded),
              label: const Text(
                "Yanlışları Tekrar Çöz",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFFFF5252),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _WrongQuestionCard extends StatelessWidget {
  final String question;
  final String answer;
  final String typeText;
  final IconData icon;
  final VoidCallback onDelete;

  const _WrongQuestionCard({
    required this.question,
    required this.answer,
    required this.typeText,
    required this.icon,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;

    return Container(
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor:
                dark ? const Color(0xFF451A1A) : const Color(0xFFFFEBEE),
                child: Icon(
                  icon,
                  color: Colors.redAccent,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  typeText,
                  style: const TextStyle(
                    color: Colors.redAccent,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              IconButton(
                onPressed: onDelete,
                icon: Icon(
                  Icons.delete_outline_rounded,
                  color: dark ? Colors.white70 : Colors.black54,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            question,
            style: TextStyle(
              color: dark ? Colors.white : Colors.black87,
              fontSize: 17,
              height: 1.4,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(13),
            decoration: BoxDecoration(
              color: dark ? const Color(0xFF451A1A) : const Color(0xFFFFEBEE),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              "Doğru cevap: $answer",
              style: const TextStyle(
                color: Colors.redAccent,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyWrongState extends StatelessWidget {
  const _EmptyWrongState();

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: Container(
        margin: const EdgeInsets.all(24),
        padding: const EdgeInsets.all(24),
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
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              "🎉",
              style: TextStyle(fontSize: 54),
            ),
            const SizedBox(height: 12),
            Text(
              "Hiç yanlışın yok!",
              style: TextStyle(
                color: dark ? Colors.white : Colors.black87,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Harika gidiyorsun. Quiz çözmeye devam et.",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: dark ? Colors.white60 : Colors.black54,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/* ---------------- REVIEW UI ---------------- */

class _ReviewTopCard extends StatelessWidget {
  final int current;
  final int total;
  final int score;
  final double progress;

  const _ReviewTopCard({
    required this.current,
    required this.total,
    required this.score,
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          colors: [
            Color(0xFFFF5252),
            Color(0xFFFF8A80),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.redAccent.withOpacity(0.25),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              const CircleAvatar(
                backgroundColor: Colors.white,
                child: Icon(
                  Icons.replay_rounded,
                  color: Color(0xFFFF5252),
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  "Yanlış Tekrarı",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 19,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Text(
                "Skor: $score",
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 10,
              backgroundColor: Colors.white38,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "$current/$total",
            style: const TextStyle(color: Colors.white),
          ),
        ],
      ),
    );
  }
}

class _ReviewQuestionCard extends StatelessWidget {
  final String question;
  final String typeText;
  final IconData icon;

  const _ReviewQuestionCard({
    required this.question,
    required this.typeText,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;

    return Container(
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
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: dark ? const Color(0xFF451A1A) : const Color(0xFFFFEBEE),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 18, color: Colors.redAccent),
                const SizedBox(width: 6),
                Text(
                  typeText,
                  style: const TextStyle(
                    color: Colors.redAccent,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Text(
            question,
            style: TextStyle(
              color: dark ? Colors.white : Colors.black87,
              fontSize: 21,
              height: 1.45,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _WrongAnswerButton extends StatelessWidget {
  final String text;
  final IconData? icon;
  final VoidCallback onTap;

  const _WrongAnswerButton({
    required this.text,
    required this.onTap,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;

    return SizedBox(
      height: 58,
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: dark ? const Color(0xFF1E293B) : Colors.white,
          foregroundColor: dark ? Colors.white : Colors.black87,
          elevation: 3,
          shadowColor: Colors.black.withOpacity(dark ? 0.3 : 0.12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: BorderSide(
              color: dark ? Colors.white10 : Colors.transparent,
            ),
          ),
          alignment: Alignment.centerLeft,
          padding: const EdgeInsets.symmetric(horizontal: 18),
        ),
        child: Row(
          children: [
            if (icon != null) ...[
              Icon(icon, color: Colors.redAccent),
              const SizedBox(width: 12),
            ] else ...[
              CircleAvatar(
                radius: 14,
                backgroundColor:
                dark ? const Color(0xFF451A1A) : const Color(0xFFFFEBEE),
                child: const Icon(
                  Icons.circle,
                  size: 10,
                  color: Colors.redAccent,
                ),
              ),
              const SizedBox(width: 12),
            ],
            Expanded(
              child: Text(
                text,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: dark ? Colors.white38 : Colors.black38,
            ),
          ],
        ),
      ),
    );
  }
}

class _FillReviewArea extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSubmit;

  const _FillReviewArea({
    required this.controller,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      children: [
        TextField(
          controller: controller,
          style: TextStyle(
            color: dark ? Colors.white : Colors.black87,
            fontWeight: FontWeight.w600,
          ),
          decoration: InputDecoration(
            hintText: "Cevabı yaz...",
            hintStyle: TextStyle(
              color: dark ? Colors.white38 : Colors.black38,
            ),
            filled: true,
            fillColor: dark ? const Color(0xFF1E293B) : Colors.white,
            prefixIcon: Icon(
              Icons.edit_rounded,
              color: dark ? Colors.white70 : Colors.black54,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: BorderSide(
                color: dark ? Colors.white10 : Colors.transparent,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: const BorderSide(
                color: Color(0xFFFF5252),
                width: 1.5,
              ),
            ),
          ),
        ),
        const SizedBox(height: 14),
        SizedBox(
          width: double.infinity,
          height: 54,
          child: ElevatedButton.icon(
            onPressed: onSubmit,
            icon: const Icon(Icons.send_rounded),
            label: const Text(
              "Kontrol Et",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF5252),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/* ---------------- RESULT SHEET ---------------- */

class _ReviewResultSheet extends StatelessWidget {
  final bool isCorrect;
  final String correctAnswer;
  final VoidCallback onNext;

  const _ReviewResultSheet({
    required this.isCorrect,
    required this.correctAnswer,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    final color = isCorrect ? Colors.green : Colors.redAccent;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: color,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isCorrect ? Icons.check_circle_rounded : Icons.cancel_rounded,
              color: Colors.white,
              size: 58,
            ),
            const SizedBox(height: 10),
            Text(
              isCorrect ? "Doğru! +5 XP" : "Yanlış!",
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (!isCorrect) ...[
              const SizedBox(height: 8),
              Text(
                "Doğru cevap: $correctAnswer",
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white),
              ),
            ],
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: onNext,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: color,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
                child: const Text(
                  "Devam",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}