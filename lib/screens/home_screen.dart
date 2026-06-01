import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../services/progress_service.dart';
import '../services/daily_quest_service.dart';
import '../xp_manager.dart';

import 'login_screen.dart';
import 'quiz_level_screen.dart';
import 'wrong_questions_screen.dart';
import 'lesson_list_screen.dart';
import 'achievements_screen.dart';
import 'profile_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int xp = 0;
  int streak = 0;
  int solved = 0;
  int correct = 0;

  @override
  void initState() {
    super.initState();
    _loadHomeData();
  }

  Future<void> _loadHomeData() async {
    await ProgressService.updateStreak();

    final loadedXP = await XPManager.getXP();
    final loadedStreak = await ProgressService.getStreak();
    final solvedCount = await DailyQuestService.getSolvedCount();
    final correctCount = await DailyQuestService.getCorrectCount();

    if (!mounted) return;

    setState(() {
      xp = loadedXP;
      streak = loadedStreak;
      solved = solvedCount;
      correct = correctCount;
    });
  }

  int get level => XPManager.getLevel(xp);

  double get levelProgress {
    final start = XPManager.getCurrentLevelStartXP(xp);
    final next = XPManager.getNextLevelXP(xp);
    if (next == start) return 1;
    return ((xp - start) / (next - start)).clamp(0.0, 1.0);
  }

  Future<void> _logout() async {
    await AuthService.logout();

    if (!mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
          (_) => false,
    );
  }

  void _openAchievements() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AchievementsScreen()),
    ).then((_) => _loadHomeData());
  }

  void _openProfile() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ProfileScreen()),
    ).then((_) => _loadHomeData());
  }

  void _openSettings() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const SettingsScreen()),
    ).then((_) => _loadHomeData());
  }

  void _openQuiz() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const QuizLevelScreen()),
    ).then((_) => _loadHomeData());
  }

  void _openWrongQuestions() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const WrongQuestionsScreen()),
    ).then((_) => _loadHomeData());
  }

  void _openLessons() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const LessonListScreen()),
    ).then((_) => _loadHomeData());
  }

  void _showSettings() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return _SettingsSheet(
          onLogout: _logout,
          onRefresh: _loadHomeData,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final remainingTasks =
        (solved >= 10 ? 0 : 1) + (correct >= 5 ? 0 : 1);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      bottomNavigationBar: _CustomBottomNav(
        onAchievements: _openAchievements,
        onSettings: _openSettings,
        onProfile: _openProfile,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: Theme.of(context).brightness == Brightness.dark
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
          child: RefreshIndicator(
            onRefresh: _loadHomeData,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _HomeHeader(
                    onNotificationTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Şimdilik yeni bildirim yok.'),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 20),
                  _DailyQuestCard(
                    solved: solved,
                    correct: correct,
                    remainingTasks: remainingTasks,
                  ),
                  const SizedBox(height: 18),
                  _HeroQuizCard(onTap: _openQuiz),
                  const SizedBox(height: 16),
                  _ActionCard(
                    title: 'Yanlışlarım',
                    subtitle: 'Yanlış yaptığın soruları tekrar incele',
                    icon: Icons.error_rounded,
                    color: const Color(0xFFFF3D57),
                    lightBackgroundColor: const Color(0xFFFFF1F3),
                    onTap: _openWrongQuestions,
                  ),
                  const SizedBox(height: 14),
                  _ActionCard(
                    title: 'Dersler',
                    subtitle: 'Tüm yazım kuralları derslerini görüntüle',
                    icon: Icons.school_rounded,
                    color: const Color(0xFF10B981),
                    lightBackgroundColor: const Color(0xFFEFFFF8),
                    onTap: _openLessons,
                  ),
                  const SizedBox(height: 18),
                  _ProgressStatusCard(
                    xp: xp,
                    level: level,
                    streak: streak,
                    progress: levelProgress,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/* ---------------- HEADER ---------------- */

class _HomeHeader extends StatelessWidget {
  final VoidCallback onNotificationTap;

  const _HomeHeader({
    required this.onNotificationTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Merhaba, 👋',
                style: TextStyle(
                  color: isDark ? Colors.white70 : const Color(0xFF6B7280),
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                'Ana Sayfa',
                style: TextStyle(
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                  fontSize: 30,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.6,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                'Bugün yeni şeyler öğrenme zamanı! ✨',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: isDark ? Colors.white60 : const Color(0xFF6B7280),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onNotificationTap,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(isDark ? 0.25 : 0.07),
                      blurRadius: 18,
                      offset: const Offset(0, 9),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.notifications_none_rounded,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                  size: 28,
                ),
              ),
              Positioned(
                right: 12,
                top: 11,
                child: Container(
                  width: 9,
                  height: 9,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF3D57),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isDark ? const Color(0xFF1E293B) : Colors.white,
                      width: 2,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/* ---------------- DAILY QUEST ---------------- */

class _DailyQuestCard extends StatelessWidget {
  final int solved;
  final int correct;
  final int remainingTasks;

  const _DailyQuestCard({
    required this.solved,
    required this.correct,
    required this.remainingTasks,
  });

  double _progress(int value, int target) {
    return (value / target).clamp(0.0, 1.0);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return _WhiteCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF312E81)
                      : const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Icon(
                  Icons.flag_rounded,
                  color: Color(0xFF818CF8),
                  size: 28,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Günlük\nGörevler',
                  maxLines: 2,
                  style: TextStyle(
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF064E3B)
                      : const Color(0xFFE7F8F2),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  '$remainingTasks görev kaldı',
                  style: const TextStyle(
                    color: Color(0xFF10B981),
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
          _QuestItem(
            title: '10 soru çöz',
            reward: '+50 XP',
            current: solved,
            target: 10,
            progress: _progress(solved, 10),
          ),
          Divider(
            height: 31,
            color: isDark ? Colors.white12 : const Color(0xFFE5E7EB),
          ),
          _QuestItem(
            title: '5 doğru cevap ver',
            reward: '+30 XP',
            current: correct,
            target: 5,
            progress: _progress(correct, 5),
          ),
        ],
      ),
    );
  }
}

class _QuestItem extends StatelessWidget {
  final String title;
  final String reward;
  final int current;
  final int target;
  final double progress;

  const _QuestItem({
    required this.title,
    required this.reward,
    required this.current,
    required this.target,
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    final completed = current >= target;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Row(
      children: [
        Icon(
          completed
              ? Icons.check_circle_rounded
              : Icons.radio_button_unchecked_rounded,
          color: completed ? const Color(0xFF10B981) : const Color(0xFF8B8E99),
          size: 42,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 9),
              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 8,
                  backgroundColor:
                  isDark ? const Color(0xFF334155) : const Color(0xFFE6E7ED),
                  color: const Color(0xFF10B981),
                ),
              ),
              const SizedBox(height: 7),
              Text(
                '${current.clamp(0, target)} / $target',
                style: TextStyle(
                  color: isDark ? Colors.white60 : const Color(0xFF6B7280),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        const Text(
          '+50 XP',
          style: TextStyle(
            color: Color(0xFF6D4AFF),
            fontSize: 16,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(width: 6),
        Icon(
          Icons.arrow_forward_ios_rounded,
          size: 18,
          color: isDark ? Colors.white38 : const Color(0xFF8B8E99),
        ),
      ],
    );
  }
}

/* ---------------- QUIZ CARD ---------------- */

class _HeroQuizCard extends StatelessWidget {
  final VoidCallback onTap;

  const _HeroQuizCard({
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      borderRadius: BorderRadius.circular(26),
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(26),
          gradient: LinearGradient(
            colors: isDark
                ? [
              const Color(0xFF312E81),
              const Color(0xFF1E1B4B),
            ]
                : [
              const Color(0xFF6D4AFF),
              const Color(0xFF536DFE),
              const Color(0xFF5B7CFF),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF6D4AFF).withOpacity(isDark ? 0.18 : 0.28),
              blurRadius: 24,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 62,
                  height: 62,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.14),
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Text(
                      '🚀',
                      style: TextStyle(fontSize: 36),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Text(
                    'Öğrenmeye Devam Et! 🚀',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            const Text(
              'Yazım kurallarını adım adım öğren, seviye atla ve rozetler kazan!',
              style: TextStyle(
                color: Colors.white,
                height: 1.45,
                fontSize: 14.5,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerRight,
              child: Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(22),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Quiz’e Başla',
                      style: TextStyle(
                        color: Color(0xFF6D4AFF),
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    SizedBox(width: 8),
                    Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 16,
                      color: Color(0xFF6D4AFF),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/* ---------------- ACTION CARD ---------------- */

class _ActionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final Color lightBackgroundColor;
  final VoidCallback onTap;

  const _ActionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.lightBackgroundColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return _WhiteCard(
      padding: EdgeInsets.zero,
      child: InkWell(
        borderRadius: BorderRadius.circular(26),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(17),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : lightBackgroundColor,
            borderRadius: BorderRadius.circular(26),
            border: isDark
                ? Border.all(color: Colors.white10)
                : null,
          ),
          child: Row(
            children: [
              Container(
                width: 62,
                height: 62,
                decoration: BoxDecoration(
                  color: color.withOpacity(isDark ? 0.20 : 0.13),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      icon,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: color,
                        fontSize: 19,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color:
                        isDark ? Colors.white60 : const Color(0xFF6B7280),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                color: color,
                size: 22,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/* ---------------- PROGRESS CARD ---------------- */

class _ProgressStatusCard extends StatelessWidget {
  final int xp;
  final int level;
  final int streak;
  final double progress;

  const _ProgressStatusCard({
    required this.xp,
    required this.level,
    required this.streak,
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return _WhiteCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'İlerleme Durumun',
            style: TextStyle(
              color: isDark ? Colors.white : const Color(0xFF0F172A),
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 18),
          _ProgressMiniCard(
            icon: '🏅',
            title: 'Level $level',
            subtitle: 'XP: $xp',
            progress: progress,
            progressColor: const Color(0xFFFFB300),
          ),
          const SizedBox(height: 14),
          _ProgressMiniCard(
            iconWidget: const Icon(
              Icons.trending_up_rounded,
              color: Color(0xFF7C3AED),
              size: 32,
            ),
            iconBg: const Color(0xFFF2EAFE),
            title: 'Seri',
            subtitle: '🔥 $streak gün',
            bottomText: 'Harika gidiyorsun! 🎉',
            progress: null,
            progressColor: const Color(0xFF7C3AED),
          ),
        ],
      ),
    );
  }
}

class _ProgressMiniCard extends StatelessWidget {
  final String? icon;
  final Widget? iconWidget;
  final Color iconBg;
  final String title;
  final String subtitle;
  final String? bottomText;
  final double? progress;
  final Color progressColor;

  const _ProgressMiniCard({
    this.icon,
    this.iconWidget,
    this.iconBg = const Color(0xFFFFF3D6),
    required this.title,
    required this.subtitle,
    this.bottomText,
    required this.progress,
    required this.progressColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(22),
        border: isDark ? Border.all(color: Colors.white10) : null,
      ),
      child: Row(
        children: [
          Container(
            width: 62,
            height: 62,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(21),
            ),
            child: Center(
              child: iconWidget ??
                  Text(
                    icon ?? '',
                    style: const TextStyle(fontSize: 34),
                  ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF6D4AFF),
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                if (progress != null) ...[
                  const SizedBox(height: 9),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 8,
                      backgroundColor:
                      isDark ? const Color(0xFF334155) : const Color(0xFFE6E7ED),
                      color: progressColor,
                    ),
                  ),
                ],
                if (bottomText != null) ...[
                  const SizedBox(height: 5),
                  Text(
                    bottomText!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: isDark ? Colors.white60 : const Color(0xFF6B7280),
                      fontSize: 12.5,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/* ---------------- BOTTOM NAV ---------------- */

class _CustomBottomNav extends StatelessWidget {
  final VoidCallback onAchievements;
  final VoidCallback onSettings;
  final VoidCallback onProfile;

  const _CustomBottomNav({
    required this.onAchievements,
    required this.onSettings,
    required this.onProfile,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SafeArea(
      top: false,
      minimum: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Container(
        height: 92,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: BorderRadius.circular(28),
          border: isDark ? Border.all(color: Colors.white10) : null,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.25 : 0.08),
              blurRadius: 28,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Row(
          children: [
            const Expanded(
              child: _NavItem(
                icon: Icons.home_rounded,
                label: 'Ana Sayfa',
                active: true,
              ),
            ),
            Expanded(
              child: _NavItem(
                icon: Icons.emoji_events_outlined,
                label: 'Başarılar',
                active: false,
                onTap: onAchievements,
              ),
            ),
            Expanded(
              child: _NavItem(
                icon: Icons.settings_outlined,
                label: 'Ayarlar',
                active: false,
                onTap: onSettings,
              ),
            ),
            Expanded(
              child: _NavItem(
                icon: Icons.person_outline_rounded,
                label: 'Profil',
                active: false,
                onTap: onProfile,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback? onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.active,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = active ? const Color(0xFF8B5CF6) : (isDark ? Colors.white60 : const Color(0xFF6B7280));

    return InkWell(
      borderRadius: BorderRadius.circular(22),
      onTap: active ? null : onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (active)
            Container(
              width: 50,
              height: 36,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF312E81) : const Color(0xFFEDE9FE),
                borderRadius: BorderRadius.circular(22),
              ),
              child: Icon(icon, color: color, size: 28),
            )
          else
            Icon(icon, color: color, size: 28),
          const SizedBox(height: 3),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: active ? FontWeight.w900 : FontWeight.w600,
            ),
          ),
          const SizedBox(height: 2),
          Container(
            width: active ? 7 : 0,
            height: active ? 7 : 0,
            decoration: const BoxDecoration(
              color: Color(0xFF8B5CF6),
              shape: BoxShape.circle,
            ),
          ),
        ],
      ),
    );
  }
}

/* ---------------- SETTINGS SHEET ---------------- */

class _SettingsSheet extends StatelessWidget {
  final VoidCallback onLogout;
  final Future<void> Function() onRefresh;

  const _SettingsSheet({
    required this.onLogout,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 48,
              height: 5,
              decoration: BoxDecoration(
                color: isDark ? Colors.white24 : const Color(0xFFE5E7EB),
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Ayarlar',
              style: TextStyle(
                color: isDark ? Colors.white : const Color(0xFF0F172A),
                fontSize: 22,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 18),
            _SettingsTile(
              icon: Icons.refresh_rounded,
              title: 'Verileri Yenile',
              subtitle: 'Ana sayfa bilgilerini güncelle',
              onTap: () async {
                Navigator.pop(context);
                await onRefresh();
              },
            ),
            _SettingsTile(
              icon: Icons.logout_rounded,
              title: 'Çıkış Yap',
              subtitle: 'Hesabından güvenli şekilde çık',
              color: const Color(0xFFFF3D57),
              onTap: () {
                Navigator.pop(context);
                onLogout();
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.color = const Color(0xFF1FA2FF),
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      leading: CircleAvatar(
        backgroundColor: color.withOpacity(0.12),
        child: Icon(icon, color: color),
      ),
      title: Text(
        title,
        style: TextStyle(
          color: isDark ? Colors.white : const Color(0xFF0F172A),
          fontWeight: FontWeight.w900,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          color: isDark ? Colors.white60 : Colors.black54,
        ),
      ),
      trailing: Icon(
        Icons.arrow_forward_ios_rounded,
        size: 17,
        color: isDark ? Colors.white54 : Colors.black54,
      ),
    );
  }
}

/* ---------------- BASE CARD ---------------- */

class _WhiteCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;

  const _WhiteCard({
    required this.child,
    this.padding = const EdgeInsets.all(18),
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(26),
        border: isDark ? Border.all(color: Colors.white10) : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.24 : 0.065),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: child,
    );
  }
}