import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/auth_service.dart';
import '../services/progress_service.dart';
import '../services/badge_service.dart';
import '../xp_manager.dart';

import 'login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  int xp = 0;
  int streak = 0;
  int badgeCount = 0;

  String username = 'Kullanıcı';
  String email = '';
  String? profileImagePath;

  bool loading = true;

  final TextEditingController usernameController = TextEditingController();

  final FirebaseDatabase _db = FirebaseDatabase.instanceFor(
    app: Firebase.app(),
    databaseURL: 'https://yazimkurallari-3883f-default-rtdb.firebaseio.com/',
  );

  String? get uid => FirebaseAuth.instance.currentUser?.uid;

  String get _imageKey {
    final currentUid = uid ?? 'guest';
    return 'profile_image_path_$currentUid';
  }

  DatabaseReference? get _profileRef {
    final currentUid = uid;
    if (currentUid == null) return null;
    return _db.ref('users/$currentUid/profile');
  }

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final user = FirebaseAuth.instance.currentUser;

    final loadedXP = await XPManager.getXP();
    final loadedStreak = await ProgressService.getStreak();
    final badges = await BadgeService.getUnlockedBadgeIds();

    String loadedUsername = user?.displayName ?? 'Kullanıcı';
    String loadedEmail = user?.email ?? '';

    final ref = _profileRef;

    if (ref != null) {
      final snapshot = await ref.get();

      if (snapshot.exists && snapshot.value is Map) {
        final data = Map<String, dynamic>.from(
          (snapshot.value as Map).map(
                (key, value) => MapEntry(key.toString(), value),
          ),
        );

        loadedUsername =
        data['username']?.toString().trim().isNotEmpty == true
            ? data['username'].toString()
            : loadedUsername;

        loadedEmail =
        data['email']?.toString().trim().isNotEmpty == true
            ? data['email'].toString()
            : loadedEmail;
      } else {
        await ref.set({
          'username': loadedUsername,
          'email': loadedEmail,
          'photoUrl': '',
          'createdAt': DateTime.now().toIso8601String(),
        });
      }
    }

    if (!mounted) return;

    setState(() {
      xp = loadedXP;
      streak = loadedStreak;
      badgeCount = badges.length;
      username = loadedUsername;
      email = loadedEmail;
      profileImagePath = prefs.getString(_imageKey);
      usernameController.text = username;
      loading = false;
    });
  }

  int get level => XPManager.getLevel(xp);

  double get levelProgress {
    final start = XPManager.getCurrentLevelStartXP(xp);
    final next = XPManager.getNextLevelXP(xp);

    if (next == start) return 1;

    return ((xp - start) / (next - start)).clamp(0.0, 1.0);
  }

  Future<void> _pickProfileImage() async {
    final picker = ImagePicker();

    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );

    if (picked == null) return;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_imageKey, picked.path);

    if (!mounted) return;

    setState(() {
      profileImagePath = picked.path;
    });
  }

  Future<void> _saveUsername() async {
    final name = usernameController.text.trim();

    if (name.isEmpty) return;

    final user = FirebaseAuth.instance.currentUser;
    final ref = _profileRef;

    if (user != null) {
      await user.updateDisplayName(name);
    }

    if (ref != null) {
      await ref.update({
        'username': name,
        'email': user?.email ?? email,
        'updatedAt': DateTime.now().toIso8601String(),
      });
    }

    if (!mounted) return;

    setState(() {
      username = name;
    });

    Navigator.pop(context);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Kullanıcı adı güncellendi.')),
    );
  }

  void _showUsernameSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) {
        final isDark = Theme.of(context).brightness == Brightness.dark;

        return Container(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
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
                  'Kullanıcı Adını Düzenle',
                  style: TextStyle(
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                    fontSize: 21,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 18),
                TextField(
                  controller: usernameController,
                  style: TextStyle(
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Kullanıcı adı',
                    hintStyle: TextStyle(
                      color: isDark ? Colors.white38 : Colors.black38,
                    ),
                    prefixIcon: Icon(
                      Icons.person_outline_rounded,
                      color: isDark ? Colors.white70 : Colors.black54,
                    ),
                    filled: true,
                    fillColor:
                    isDark ? const Color(0xFF0F172A) : const Color(0xFFF5F7FB),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(18),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    onPressed: _saveUsername,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6D4AFF),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                    child: const Text(
                      'Kaydet',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
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

  Future<void> _resetProfileData() async {
    final shouldReset = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
        ),
        title: const Text('Profil verileri sıfırlansın mı?'),
        content: const Text(
          'Profil fotoğrafı sıfırlanır. XP ve quiz ilerlemesi etkilenmez.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Vazgeç'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF3D57),
              foregroundColor: Colors.white,
            ),
            child: const Text('Sıfırla'),
          ),
        ],
      ),
    );

    if (shouldReset != true) return;

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_imageKey);

    final user = FirebaseAuth.instance.currentUser;
    final ref = _profileRef;

    if (ref != null) {
      await ref.update({
        'photoUrl': '',
        'updatedAt': DateTime.now().toIso8601String(),
      });
    }

    if (!mounted) return;

    setState(() {
      profileImagePath = null;
    });
  }

  @override
  void dispose() {
    usernameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (loading) {
      return Scaffold(
        backgroundColor:
        isDark ? const Color(0xFF0F172A) : const Color(0xFFF5F7FB),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor:
      isDark ? const Color(0xFF0F172A) : const Color(0xFFF5F7FB),
      appBar: AppBar(
        title: const Text('Profil'),
        centerTitle: true,
        backgroundColor:
        isDark ? const Color(0xFF111827) : const Color(0xFF6D4AFF),
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
              const Color(0xFFEDE9FE),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: RefreshIndicator(
          onRefresh: _loadProfile,
          child: ListView(
            padding: const EdgeInsets.all(18),
            children: [
              _ProfileHeaderCard(
                username: username,
                email: email,
                imagePath: profileImagePath,
                level: level,
                xp: xp,
                progress: levelProgress,
                onPickImage: _pickProfileImage,
                onEditUsername: _showUsernameSheet,
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: _StatCard(
                      icon: '🔥',
                      title: 'Seri',
                      value: '$streak gün',
                      color: const Color(0xFFFF8A00),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _StatCard(
                      icon: '🏆',
                      title: 'Rozet',
                      value: '$badgeCount adet',
                      color: const Color(0xFF10B981),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              const SizedBox(height: 12),
              _ProfileActionCard(
                icon: Icons.image_rounded,
                title: 'Profil Fotoğrafı Değiştir',
                subtitle: 'Galeriden yeni fotoğraf seç',
                color: const Color(0xFF1FA2FF),
                onTap: _pickProfileImage,
              ),
              const SizedBox(height: 12),
              _ProfileActionCard(
                icon: Icons.refresh_rounded,
                title: 'Profil Bilgilerini Sıfırla',
                subtitle: 'Ad ve fotoğraf bilgilerini temizle',
                color: const Color(0xFFFFB300),
                onTap: _resetProfileData,
              ),
              const SizedBox(height: 12),
              _ProfileActionCard(
                icon: Icons.logout_rounded,
                title: 'Çıkış Yap',
                subtitle: 'Hesabından güvenli şekilde çık',
                color: const Color(0xFFFF3D57),
                onTap: _logout,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/* ---------------- HEADER CARD ---------------- */

class _ProfileHeaderCard extends StatelessWidget {
  final String username;
  final String email;
  final String? imagePath;
  final int level;
  final int xp;
  final double progress;
  final VoidCallback onPickImage;
  final VoidCallback onEditUsername;

  const _ProfileHeaderCard({
    required this.username,
    required this.email,
    required this.imagePath,
    required this.level,
    required this.xp,
    required this.progress,
    required this.onPickImage,
    required this.onEditUsername,
  });

  @override
  Widget build(BuildContext context) {
    final hasImage = imagePath != null && File(imagePath!).existsSync();

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        gradient: const LinearGradient(
          colors: [
            Color(0xFF6D4AFF),
            Color(0xFF536DFE),
            Color(0xFF12D8FA),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6D4AFF).withOpacity(0.28),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              CircleAvatar(
                radius: 54,
                backgroundColor: Colors.white,
                backgroundImage: hasImage ? FileImage(File(imagePath!)) : null,
                child: !hasImage
                    ? const Icon(
                  Icons.person_rounded,
                  size: 58,
                  color: Color(0xFF6D4AFF),
                )
                    : null,
              ),
              Positioned(
                right: -2,
                bottom: 2,
                child: InkWell(
                  onTap: onPickImage,
                  borderRadius: BorderRadius.circular(18),
                  child: Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.15),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.camera_alt_rounded,
                      color: Color(0xFF6D4AFF),
                      size: 21,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Flexible(
                child: Text(
                  username,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(width: 8),
            ],
          ),
          if (email.isNotEmpty) ...[
            const SizedBox(height: 5),
            Text(
              email,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          const SizedBox(height: 8),
          Text(
            'Level $level • $xp XP',
            style: const TextStyle(
              color: Colors.white70,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 18),
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 10,
              backgroundColor: Colors.white.withOpacity(0.3),
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Bir sonraki seviyeye doğru ilerliyorsun 🚀',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

/* ---------------- STAT CARD ---------------- */

class _StatCard extends StatelessWidget {
  final String icon;
  final String title;
  final String value;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.title,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: isDark ? Border.all(color: Colors.white10) : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.24 : 0.065),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            icon,
            style: const TextStyle(fontSize: 34),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(
              color: isDark ? Colors.white60 : const Color(0xFF6B7280),
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 19,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

/* ---------------- ACTION CARD ---------------- */

class _ProfileActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _ProfileActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      borderRadius: BorderRadius.circular(24),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(17),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: isDark ? Border.all(color: Colors.white10) : null,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.24 : 0.055),
              blurRadius: 20,
              offset: const Offset(0, 9),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: color.withOpacity(0.14),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Icon(
                icon,
                color: color,
                size: 29,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                      fontSize: 16.5,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: isDark ? Colors.white60 : const Color(0xFF6B7280),
                      fontSize: 13.5,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              color: isDark ? Colors.white54 : const Color(0xFF9CA3AF),
              size: 17,
            ),
          ],
        ),
      ),
    );
  }
}