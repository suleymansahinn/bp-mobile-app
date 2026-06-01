import 'package:flutter/material.dart';

import '../models/app_badge.dart';
import '../services/badge_service.dart';
import '../xp_manager.dart';

class AchievementsScreen extends StatefulWidget {
  const AchievementsScreen({super.key});

  @override
  State<AchievementsScreen> createState() => _AchievementsScreenState();
}

class _AchievementsScreenState extends State<AchievementsScreen> {
  int xp = 0;
  List<String> unlockedBadges = [];

  final List<AppBadge> badges = BadgeService.allBadges;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    xp = await XPManager.getXP();

    await BadgeService.checkAndUnlockBadges(
      xp: xp,
      level: XPManager.getLevel(xp),
    );

    unlockedBadges = await BadgeService.getUnlockedBadgeIds();

    if (!mounted) return;
    setState(() {});
  }

  bool _isUnlocked(AppBadge badge) {
    return unlockedBadges.contains(badge.id) || xp >= badge.requiredXP;
  }

  int _remainingXP(AppBadge badge) {
    final remaining = badge.requiredXP - xp;
    return remaining < 0 ? 0 : remaining;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text("Başarılar"),
        centerTitle: true,
        backgroundColor:
        isDark ? const Color(0xFF111827) : const Color(0xFF00BFA5),
        foregroundColor: Colors.white,
      ),
      body: Container(
        width: double.infinity,
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
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: badges.length,
          itemBuilder: (context, index) {
            final badge = badges[index];
            final unlocked = _isUnlocked(badge);

            return Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                borderRadius: BorderRadius.circular(22),
                border: isDark ? Border.all(color: Colors.white10) : null,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(isDark ? 0.25 : 0.08),
                    blurRadius: 14,
                    offset: const Offset(0, 7),
                  ),
                ],
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: unlocked
                        ? isDark
                        ? const Color(0xFF064E3B)
                        : const Color(0xFFE0F2F1)
                        : isDark
                        ? const Color(0xFF334155)
                        : Colors.grey.shade200,
                    child: Icon(
                      unlocked ? Icons.emoji_events : Icons.lock,
                      color: unlocked
                          ? const Color(0xFF00BFA5)
                          : isDark
                          ? Colors.white38
                          : Colors.grey,
                      size: 32,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          badge.title,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: unlocked
                                ? isDark
                                ? Colors.white
                                : Colors.black87
                                : isDark
                                ? Colors.white38
                                : Colors.black45,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          badge.description,
                          style: TextStyle(
                            color: unlocked
                                ? isDark
                                ? Colors.white70
                                : Colors.black54
                                : isDark
                                ? Colors.white38
                                : Colors.black38,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          unlocked
                              ? "Açıldı ✅"
                              : "${_remainingXP(badge)} XP kaldı",
                          style: TextStyle(
                            color: unlocked
                                ? const Color(0xFF00BFA5)
                                : Colors.redAccent,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}