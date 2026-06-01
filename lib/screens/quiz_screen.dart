import 'dart:async';
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/question.dart';
import '../models/app_badge.dart';
import '../services/question_service.dart';
import '../services/level_service.dart';
import '../services/badge_service.dart';
import '../services/daily_quest_service.dart';
import '../services/settings_service.dart';
import '../services/notification_service.dart';
import '../services/sound_service.dart';
import '../xp_manager.dart';
import 'home_screen.dart';

class QuizScreen extends StatefulWidget {
  final int levelNumber;
  final String levelTitle;
  final int startQuestion;
  final int endQuestion;
  final int questionCount;
  final int passPercent;
  final List<String> fallbackTopics;

  const QuizScreen({
    super.key,
    required this.levelNumber,
    required this.levelTitle,
    required this.startQuestion,
    required this.endQuestion,
    required this.questionCount,
    required this.passPercent,
    required this.fallbackTopics,
  });

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  List<Question> _questions = [];
  int _index = 0;
  int _score = 0;
  int _combo = 0;

  bool _loading = true;
  String _error = '';
  String? _floatingXPText;

  Timer? _timer;
  final int _maxTime = 15;
  int _timeLeft = 15;
  bool _answered = false;

  final TextEditingController _fillController = TextEditingController();

  String get _uid => FirebaseAuth.instance.currentUser?.uid ?? 'guest';

  String get _solvedKey => 'solved_level_${widget.levelNumber}_$_uid';

  String get _wrongQuestionsKey => 'wrong_questions_$_uid';

  @override
  void initState() {
    super.initState();
    _loadQuestions();
  }

  Future<void> _confirmExit() async {
    final shouldExit = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
        ),
        title: const Text("Quizden çıkmak istiyor musun?"),
        content: const Text(
          "Çıkarsan şimdiye kadar çözdüğün sorular kaydedilmiş olacak.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Devam Et"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1FA2FF),
              foregroundColor: Colors.white,
            ),
            child: const Text("Çık"),
          ),
        ],
      ),
    );

    if (shouldExit == true && mounted) {
      _timer?.cancel();
      Navigator.pop(context);
    }
  }

  Future<Set<String>> _getWrongQuestionIds() async {
    final prefs = await SharedPreferences.getInstance();
    final wrongList = prefs.getStringList(_wrongQuestionsKey) ?? [];
    final ids = <String>{};

    for (final item in wrongList) {
      try {
        final decoded = jsonDecode(item);
        final id = decoded['id']?.toString();
        if (id != null && id.isNotEmpty) ids.add(id);
      } catch (_) {}
    }

    return ids;
  }

  Future<void> _loadQuestions() async {
    try {
      final allQuestions = await QuestionService.getQuestionsForLevel(
        start: widget.startQuestion,
        end: widget.endQuestion,
        fallbackTopics: widget.fallbackTopics,
      );

      final prefs = await SharedPreferences.getInstance();
      final solvedIds = prefs.getStringList(_solvedKey) ?? [];
      final wrongIds = await _getWrongQuestionIds();

      List<Question> availableQuestions = allQuestions.where((q) {
        final isSolved = solvedIds.contains(q.id);
        final isWrong = wrongIds.contains(q.id);
        return !isSolved && !isWrong;
      }).toList();

      if (availableQuestions.isEmpty && allQuestions.isNotEmpty) {
        await prefs.remove(_solvedKey);

        availableQuestions = allQuestions.where((q) {
          final isWrong = wrongIds.contains(q.id);
          return !isWrong;
        }).toList();
      }

      availableQuestions.shuffle();

      setState(() {
        _questions = availableQuestions.take(widget.questionCount).toList();
        _loading = false;
      });

      if (_questions.isEmpty) {
        setState(() {
          _error =
          'Bu seviyede çözülecek yeni soru kalmadı.\nYanlışlarım ekranındaki soruları tekrar çözebilirsin.';
        });
      } else {
        _startTimer();
      }
    } catch (e) {
      setState(() {
        _error = 'Veri okunamadı ❌\n$e';
        _loading = false;
      });
    }
  }

  void _startTimer() {
    _timer?.cancel();

    setState(() {
      _timeLeft = _maxTime;
      _answered = false;
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;

      if (_timeLeft <= 0) {
        timer.cancel();
        _onTimeUp();
      } else {
        setState(() {
          _timeLeft--;
        });
      }
    });
  }

  Future<void> _onTimeUp() async {
    if (_answered || _questions.isEmpty) return;

    setState(() {
      _answered = true;
      _combo = 0;
    });

    final q = _questions[_index];

    await _playFeedback(false);
    await SoundService.playWrong();
    await DailyQuestService.recordAnswer(false);
    await _saveWrongQuestion(q);
    await _markSolved(q.id);

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return _ResultSheet(
          isCorrect: false,
          correctAnswer: q.answer?.toString() ?? 'Cevap bulunamadı',
          xpResult: null,
          newBadges: const [],
          gainedXP: 0,
          combo: 0,
          comboBonus: 0,
          questBonus: 0,
          completedQuests: const [],
          timeUp: true,
          onNext: () {
            Navigator.pop(context);
            _next();
          },
        );
      },
    );
  }

  Future<void> _markSolved(String questionId) async {
    final prefs = await SharedPreferences.getInstance();
    final solvedIds = prefs.getStringList(_solvedKey) ?? [];

    if (!solvedIds.contains(questionId)) {
      solvedIds.add(questionId);
      await prefs.setStringList(_solvedKey, solvedIds);
    }
  }

  Future<void> _saveWrongQuestion(Question q) async {
    final prefs = await SharedPreferences.getInstance();
    final wrongList = prefs.getStringList(_wrongQuestionsKey) ?? [];

    final alreadyExists = wrongList.any((item) {
      try {
        final decoded = jsonDecode(item);
        return decoded['id'] == q.id;
      } catch (_) {
        return false;
      }
    });

    if (alreadyExists) return;

    final data = {
      'id': q.id,
      'question': q.question,
      'answer': q.answer?.toString() ?? 'Cevap bulunamadı',
      'type': q.type,
      'topic': q.topic,
      'options': q.options ?? [],
    };

    wrongList.add(jsonEncode(data));
    await prefs.setStringList(_wrongQuestionsKey, wrongList);
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

  bool _checkCorrect(Question q, dynamic selected) {
    if (q.type == 'fill') {
      return _normalize(selected.toString()) == _normalize(q.answer.toString());
    }

    return selected == q.answer;
  }

  Future<void> _playFeedback(bool correct) async {
    final settings = await SettingsService.getSettings();

    if (settings.sound) {
      if (correct) {
        await SystemSound.play(SystemSoundType.click);
      } else {
        await SystemSound.play(SystemSoundType.alert);
      }
    }

    if (settings.vibration) {
      if (correct) {
        await HapticFeedback.lightImpact();
      } else {
        await HapticFeedback.mediumImpact();
      }
    }
  }

  void _showFloatingXP(String text) {
    setState(() {
      _floatingXPText = text;
    });

    Future.delayed(const Duration(milliseconds: 900), () {
      if (!mounted) return;
      setState(() {
        _floatingXPText = null;
      });
    });
  }

  Future<void> _answer(dynamic selected) async {
    if (_answered) return;

    _timer?.cancel();

    setState(() {
      _answered = true;
    });

    final q = _questions[_index];
    final isCorrect = _checkCorrect(q, selected);

    await _playFeedback(isCorrect);
    await DailyQuestService.recordAnswer(isCorrect);

    XPResult? xpResult;
    List<AppBadge> newBadges = [];
    int gainedXP = 0;
    int comboBonus = 0;
    int questBonus = 0;
    List<String> completedQuests = [];

    if (isCorrect) {
      await SoundService.playCorrect();

      _score++;
      _combo++;

      final baseResult = await XPManager.addXP(10);
      xpResult = baseResult;
      gainedXP += 10;

      if (_combo >= 3 && _combo % 3 == 0) {
        comboBonus = 20;
        xpResult = await XPManager.addXP(comboBonus);
        gainedXP += comboBonus;
      }

      final questResult = await DailyQuestService.checkAndClaimRewards();

      questBonus = questResult.bonusXP;
      completedQuests = questResult.completedQuests;
      gainedXP += questBonus;

      final settings = await SettingsService.getSettings();

      if (settings.notifications && completedQuests.isNotEmpty) {
        await NotificationService.showCompletedNotification();
      }

      final latestXP = await XPManager.getXP();

      newBadges = await BadgeService.checkAndUnlockBadges(
        xp: latestXP,
        level: XPManager.getLevel(latestXP),
      );

      if (newBadges.isNotEmpty) {
        await SoundService.playBadge();
      }

      if (xpResult != null && xpResult.leveledUp) {
        await SoundService.playLevelUp();
      }

      _showFloatingXP("+$gainedXP XP");
    } else {
      await SoundService.playWrong();

      _combo = 0;
      await _saveWrongQuestion(q);
    }

    await _markSolved(q.id);

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return _ResultSheet(
          isCorrect: isCorrect,
          correctAnswer: q.answer?.toString() ?? 'Cevap bulunamadı',
          xpResult: xpResult,
          newBadges: newBadges,
          gainedXP: gainedXP,
          combo: _combo,
          comboBonus: comboBonus,
          questBonus: questBonus,
          completedQuests: completedQuests,
          timeUp: false,
          onNext: () {
            Navigator.pop(context);
            _next();
          },
        );
      },
    );
  }

  void _next() {
    _fillController.clear();

    if (_index + 1 < _questions.length) {
      setState(() {
        _index++;
      });
      _startTimer();
    } else {
      _timer?.cancel();
      _finish();
    }
  }

  Future<void> _finish() async {
    final percent = (_score / _questions.length) * 100;
    final passed = percent >= widget.passPercent;

    if (passed) {
      await LevelService.unlockNextLevel(widget.levelNumber);
    }

    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        title: Text(
          passed ? 'Seviye Tamamlandı 🎉' : 'Tekrar Denemelisin',
        ),
        content: Text(
          'Skor: $_score / ${_questions.length}\n'
              'Başarı: ${percent.toStringAsFixed(0)}%\n'
              'Gerekli başarı: ${widget.passPercent}%\n\n'
              '${passed ? "Sonraki seviyenin kilidi açıldı!" : "Bu seviyeyi geçmek için daha yüksek skor yapmalısın."}',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const HomeScreen()),
                    (_) => false,
              );
            },
            child: const Text('Ana Sayfa'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _fillController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_loading) {
      return Scaffold(
        backgroundColor:
        isDark ? const Color(0xFF0F172A) : const Color(0xFFF5F7FB),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_error.isNotEmpty) {
      return Scaffold(
        backgroundColor:
        isDark ? const Color(0xFF0F172A) : const Color(0xFFF5F7FB),
        appBar: AppBar(
          title: Text(widget.levelTitle),
          backgroundColor:
          isDark ? const Color(0xFF111827) : const Color(0xFF1FA2FF),
          foregroundColor: Colors.white,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              _error,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isDark ? Colors.white70 : Colors.black87,
              ),
            ),
          ),
        ),
      );
    }

    final q = _questions[_index];
    final progress = (_index + 1) / _questions.length;

    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) async {
        if (didPop) return;
        await _confirmExit();
      },
      child: Scaffold(
        backgroundColor:
        isDark ? const Color(0xFF0F172A) : const Color(0xFFF5F7FB),
        appBar: AppBar(
          title: Text(widget.levelTitle),
          centerTitle: true,
          backgroundColor:
          isDark ? const Color(0xFF111827) : const Color(0xFF1FA2FF),
          foregroundColor: Colors.white,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: _confirmExit,
          ),
        ),
        body: Stack(
          children: [
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isDark
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
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _TopStatusCard(
                        levelTitle: widget.levelTitle,
                        current: _index + 1,
                        total: _questions.length,
                        progress: progress,
                        score: _score,
                        combo: _combo,
                      ),
                      const SizedBox(height: 16),
                      _QuizTimerBar(
                        timeLeft: _timeLeft,
                        maxTime: _maxTime,
                      ),
                      const SizedBox(height: 24),
                      _QuestionCard(question: q.question, type: q.type),
                      const SizedBox(height: 26),
                      if (q.type == 'mcq' && q.options != null)
                        ...q.options!.map(
                              (option) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _AnswerButton(
                              text: option,
                              onTap: () => _answer(option),
                            ),
                          ),
                        ),
                      if (q.type == 'tf')
                        Column(
                          children: [
                            _AnswerButton(
                              text: 'Doğru',
                              icon: Icons.check_circle_outline,
                              onTap: () => _answer(true),
                            ),
                            const SizedBox(height: 12),
                            _AnswerButton(
                              text: 'Yanlış',
                              icon: Icons.cancel_outlined,
                              onTap: () => _answer(false),
                            ),
                          ],
                        ),
                      if (q.type == 'fill')
                        _FillAnswerArea(
                          controller: _fillController,
                          onSubmit: () {
                            if (_fillController.text.trim().isEmpty) return;
                            _answer(_fillController.text);
                          },
                        ),
                    ],
                  ),
                ),
              ),
            ),
            if (_floatingXPText != null)
              Positioned(
                top: 80,
                right: 24,
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.6, end: 1.15),
                  duration: const Duration(milliseconds: 700),
                  curve: Curves.elasticOut,
                  builder: (context, value, child) {
                    return Transform.scale(
                      scale: value,
                      child: child,
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.green,
                      borderRadius: BorderRadius.circular(22),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 10,
                        ),
                      ],
                    ),
                    child: Text(
                      _floatingXPText!,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/* ---------------- UI ---------------- */

class _TopStatusCard extends StatelessWidget {
  final String levelTitle;
  final int current;
  final int total;
  final double progress;
  final int score;
  final int combo;

  const _TopStatusCard({
    required this.levelTitle,
    required this.current,
    required this.total,
    required this.progress,
    required this.score,
    required this.combo,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          colors: isDark
              ? [
            const Color(0xFF1E3A8A),
            const Color(0xFF312E81),
          ]
              : [
            const Color(0xFF1FA2FF),
            const Color(0xFF12D8FA),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.28 : 0.08),
            blurRadius: 18,
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
                child: Icon(Icons.school, color: Color(0xFF1FA2FF)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  levelTitle,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 19,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Text(
                combo >= 2 ? '🔥 Combo $combo' : 'Skor: $score',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              )
            ],
          ),
          const SizedBox(height: 18),
          LinearProgressIndicator(
            value: progress,
            minHeight: 10,
            backgroundColor: Colors.white38,
            color: Colors.white,
          ),
          const SizedBox(height: 8),
          Text('$current/$total', style: const TextStyle(color: Colors.white)),
        ],
      ),
    );
  }
}

class _QuizTimerBar extends StatelessWidget {
  final int timeLeft;
  final int maxTime;

  const _QuizTimerBar({
    required this.timeLeft,
    required this.maxTime,
  });

  @override
  Widget build(BuildContext context) {
    final progress = timeLeft / maxTime;
    final isDanger = timeLeft <= 5;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: isDark ? Border.all(color: Colors.white10) : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.26 : 0.08),
            blurRadius: 10,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(
                Icons.timer,
                color: isDanger ? Colors.redAccent : const Color(0xFF1FA2FF),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  "Süre",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
              ),
              Text(
                "$timeLeft sn",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isDanger
                      ? Colors.redAccent
                      : isDark
                      ? Colors.white70
                      : Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 9,
              backgroundColor:
              isDark ? const Color(0xFF334155) : Colors.grey.shade200,
              color: isDanger ? Colors.redAccent : Colors.green,
            ),
          ),
        ],
      ),
    );
  }
}

class _QuestionCard extends StatelessWidget {
  final String question;
  final String type;

  const _QuestionCard({
    required this.question,
    required this.type,
  });

  String get typeText {
    if (type == 'mcq') return '4 Seçenekli Soru';
    if (type == 'tf') return 'Doğru / Yanlış';
    if (type == 'fill') return 'Boşluk Doldurma';
    return 'Soru';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(26),
        border: isDark ? Border.all(color: Colors.white10) : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.28 : 0.08),
            blurRadius: 14,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            typeText,
            style: const TextStyle(
              color: Color(0xFF1FA2FF),
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            question,
            style: TextStyle(
              color: isDark ? Colors.white : const Color(0xFF0F172A),
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

class _AnswerButton extends StatelessWidget {
  final String text;
  final IconData? icon;
  final VoidCallback onTap;

  const _AnswerButton({
    required this.text,
    required this.onTap,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SizedBox(
      height: 58,
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
          foregroundColor: isDark ? Colors.white : const Color(0xFF0F172A),
          elevation: 3,
          shadowColor: Colors.black.withOpacity(isDark ? 0.35 : 0.12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: BorderSide(
              color: isDark ? Colors.white10 : const Color(0xFFE5E7EB),
            ),
          ),
          alignment: Alignment.centerLeft,
          padding: const EdgeInsets.symmetric(horizontal: 18),
        ),
        child: Row(
          children: [
            if (icon != null) ...[
              Icon(icon, color: const Color(0xFF1FA2FF)),
              const SizedBox(width: 12),
            ],
            Expanded(
              child: Text(
                text,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              size: 16,
              color: isDark ? Colors.white38 : Colors.black38,
            ),
          ],
        ),
      ),
    );
  }
}

class _FillAnswerArea extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSubmit;

  const _FillAnswerArea({
    required this.controller,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      children: [
        TextField(
          controller: controller,
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black87,
            fontWeight: FontWeight.w600,
          ),
          decoration: InputDecoration(
            hintText: 'Cevabı yaz...',
            hintStyle: TextStyle(
              color: isDark ? Colors.white38 : Colors.black38,
            ),
            filled: true,
            fillColor: isDark ? const Color(0xFF1E293B) : Colors.white,
            prefixIcon: Icon(
              Icons.edit,
              color: isDark ? Colors.white70 : Colors.black54,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: BorderSide(
                color: isDark ? Colors.white10 : Colors.transparent,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: const BorderSide(
                color: Color(0xFF1FA2FF),
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
            icon: const Icon(Icons.send),
            label: const Text('Kontrol Et'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1FA2FF),
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

class _ResultSheet extends StatelessWidget {
  final bool isCorrect;
  final String correctAnswer;
  final XPResult? xpResult;
  final List<AppBadge> newBadges;
  final int gainedXP;
  final int combo;
  final int comboBonus;
  final int questBonus;
  final List<String> completedQuests;
  final bool timeUp;
  final VoidCallback onNext;

  const _ResultSheet({
    required this.isCorrect,
    required this.correctAnswer,
    required this.xpResult,
    required this.newBadges,
    required this.gainedXP,
    required this.combo,
    required this.comboBonus,
    required this.questBonus,
    required this.completedQuests,
    required this.timeUp,
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
              isCorrect ? Icons.check_circle : Icons.cancel,
              color: Colors.white,
              size: 58,
            ),
            const SizedBox(height: 10),
            Text(
              isCorrect
                  ? 'Doğru! +$gainedXP XP'
                  : timeUp
                  ? 'Süre Bitti!'
                  : 'Yanlış!',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 25,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (!isCorrect) ...[
              const SizedBox(height: 8),
              Text(
                'Doğru cevap: $correctAnswer',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white),
              ),
            ],
            if (comboBonus > 0) ...[
              const SizedBox(height: 8),
              Text(
                '🔥 Combo bonus: +$comboBonus XP',
                style: const TextStyle(color: Colors.white),
              ),
            ],
            if (questBonus > 0) ...[
              const SizedBox(height: 8),
              Text(
                '🎯 Günlük görev bonusu: +$questBonus XP',
                style: const TextStyle(color: Colors.white),
              ),
            ],
            if (completedQuests.isNotEmpty) ...[
              const SizedBox(height: 8),
              ...completedQuests.map(
                    (quest) => Text(
                  '✅ $quest tamamlandı',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ],
            if (xpResult != null && xpResult!.leveledUp) ...[
              const SizedBox(height: 12),
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.5, end: 1),
                duration: const Duration(milliseconds: 600),
                curve: Curves.elasticOut,
                builder: (context, value, child) {
                  return Transform.scale(scale: value, child: child);
                },
                child: Text(
                  'LEVEL UP! ${xpResult!.oldLevel} → ${xpResult!.newLevel} 🚀',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 21,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
            if (newBadges.isNotEmpty) ...[
              const SizedBox(height: 14),
              ...newBadges.map(
                    (badge) => TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.6, end: 1),
                  duration: const Duration(milliseconds: 500),
                  curve: Curves.elasticOut,
                  builder: (context, value, child) {
                    return Transform.scale(scale: value, child: child);
                  },
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.22),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Text(
                      '${badge.emoji} Yeni rozet: ${badge.title}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
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
                  'Devam',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}