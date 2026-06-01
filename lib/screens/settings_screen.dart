// DARK MODE destekli tam dosya
// Senin eski yapın korunmuştur. Sadece renkler tema uyumlu hale getirildi.

import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../services/settings_service.dart';
import '../services/notification_service.dart';

import 'login_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  AppSettings settings = AppSettings.defaults();

  bool loading = true;
  bool saving = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final loaded = await SettingsService.getSettings();

    if (!mounted) return;

    setState(() {
      settings = loaded;
      loading = false;
    });
  }

  Future<void> _save(AppSettings updated) async {
    setState(() {
      settings = updated;
      saving = true;
    });

    await SettingsService.saveSettings(updated);

    if (!mounted) return;

    setState(() {
      saving = false;
    });
  }

  Future<void> _toggleNotifications(bool value) async {
    final updated = settings.copyWith(notifications: value);

    setState(() {
      settings = updated;
    });

    await SettingsService.saveSettings(updated);

    if (value) {
      await NotificationService.requestPermission();

      if (!mounted) return;

      ScaffoldMessenger.of(context).hideCurrentSnackBar();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          backgroundColor: const Color(0xFF10B981),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          duration: const Duration(seconds: 2),
          content: const Row(
            children: [
              Icon(Icons.notifications_active, color: Colors.white),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Bildirimler aktif edildi 🔔',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      );

      await NotificationService.scheduleDailyReminder(hour: 20, minute: 0);
      await NotificationService.showTestNotification();
    } else {
      await NotificationService.cancelAll();

      if (!mounted) return;

      ScaffoldMessenger.of(context).hideCurrentSnackBar();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          backgroundColor: Colors.red,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          duration: const Duration(seconds: 2),
          content: const Row(
            children: [
              Icon(Icons.notifications_off, color: Colors.white),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Bildirimler kapatıldı',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }
  }

  Future<void> _resetSettings() async {
    await SettingsService.resetSettings();
    await NotificationService.cancelAll();
    await _loadSettings();

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Ayarlar varsayılana döndürüldü.')),
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

  String get themeText {
    switch (settings.themeMode) {
      case 'light':
        return 'Açık Tema';
      case 'dark':
        return 'Koyu Tema';
      default:
        return 'Sistem Teması';
    }
  }

  void _showThemeSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return _ThemeSheet(
          selected: settings.themeMode,
          onSelect: (value) async {
            final updated = settings.copyWith(themeMode: value);

            setState(() {
              settings = updated;
            });

            SettingsService.notifier.value = updated;

            Navigator.pop(context);

            await SettingsService.saveSettings(updated);

            if (!mounted) return;

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                behavior: SnackBarBehavior.floating,
                backgroundColor: const Color(0xFF6D4AFF),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
                content: Text(
                  value == 'dark'
                      ? 'Koyu tema aktif edildi 🌙'
                      : value == 'light'
                      ? 'Açık tema aktif edildi ☀️'
                      : 'Sistem teması aktif edildi 📱',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            );
          },
        );
      },
    );
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
        title: const Text('Ayarlar'),
        centerTitle: true,
        backgroundColor:
        isDark ? const Color(0xFF111827) : const Color(0xFF6D4AFF),
        foregroundColor: Colors.white,
        actions: [
          if (saving)
            const Padding(
              padding: EdgeInsets.only(right: 16),
              child: Center(
                child: SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
        ],
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
        child: ListView(
          padding: const EdgeInsets.all(18),
          children: [
            _SettingsHeaderCard(
              saving: saving,
              themeText: themeText,
            ),
            const SizedBox(height: 20),
            const _SectionTitle('Tercihler'),
            _PremiumSwitchTile(
              icon: Icons.notifications_active_rounded,
              title: 'Bildirimler',
              subtitle: 'Günlük görev ve hatırlatmaları aç/kapat',
              color: const Color(0xFF6D4AFF),
              value: settings.notifications,
              onChanged: _toggleNotifications,
            ),
            const SizedBox(height: 12),
            _PremiumSwitchTile(
              icon: Icons.volume_up_rounded,
              title: 'Ses Efektleri',
              subtitle: 'Quiz doğru/yanlış geri bildirim sesleri',
              color: const Color(0xFF1FA2FF),
              value: settings.sound,
              onChanged: (value) {
                _save(settings.copyWith(sound: value));
              },
            ),
            const SizedBox(height: 12),
            _PremiumSwitchTile(
              icon: Icons.vibration_rounded,
              title: 'Titreşim',
              subtitle: 'Cevap geri bildirimlerinde titreşim kullan',
              color: const Color(0xFF10B981),
              value: settings.vibration,
              onChanged: (value) {
                _save(settings.copyWith(vibration: value));
              },
            ),
            const SizedBox(height: 22),
            const _SectionTitle('Görünüm'),
            _PremiumActionTile(
              icon: Icons.palette_rounded,
              title: 'Tema Modu',
              subtitle: themeText,
              color: const Color(0xFFFFB300),
              onTap: _showThemeSheet,
            ),
            const SizedBox(height: 22),
            const _SectionTitle('Veri ve Hesap'),
            _PremiumActionTile(
              icon: Icons.cloud_done_rounded,
              title: 'Cloud Senkronizasyon',
              subtitle: 'Ayarların Firebase hesabına kaydediliyor',
              color: const Color(0xFF6D4AFF),
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Ayarlar cloud ile senkron.')),
                );
              },
            ),
            const SizedBox(height: 12),
            _PremiumActionTile(
              icon: Icons.restart_alt_rounded,
              title: 'Ayarları Sıfırla',
              subtitle: 'Bildirim, ses, titreşim ve tema varsayılana döner',
              color: const Color(0xFFFF8A00),
              onTap: _resetSettings,
            ),
            const SizedBox(height: 12),
            _PremiumActionTile(
              icon: Icons.info_outline_rounded,
              title: 'Uygulama Hakkında',
              subtitle: 'Yazım Kuralları v1.0.0',
              color: const Color(0xFF1FA2FF),
              onTap: () {
                showAboutDialog(
                  context: context,
                  applicationName: 'Yazım Kuralları',
                  applicationVersion: '1.0.0',
                  applicationIcon: const Icon(
                    Icons.school_rounded,
                    color: Color(0xFF6D4AFF),
                    size: 36,
                  ),
                );
              },
            ),
            const SizedBox(height: 22),
            _LogoutButton(onTap: _logout),
            const SizedBox(height: 18),
          ],
        ),
      ),
    );
  }
}

/* ---------------- UI COMPONENTS ---------------- */

class _SettingsHeaderCard extends StatelessWidget {
  final bool saving;
  final String themeText;

  const _SettingsHeaderCard({
    required this.saving,
    required this.themeText,
  });

  @override
  Widget build(BuildContext context) {
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
      child: Row(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.18),
              borderRadius: BorderRadius.circular(24),
            ),
            child: const Icon(
              Icons.settings_rounded,
              color: Colors.white,
              size: 42,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Uygulama Ayarları',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  saving
                      ? 'Değişiklikler kaydediliyor...'
                      : 'Ayarların cloud üzerinde saklanıyor.',
                  style: const TextStyle(
                    color: Colors.white70,
                    height: 1.35,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.18),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Text(
                    themeText,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
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

class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle(this.title);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 10),
      child: Text(
        title,
        style: TextStyle(
          color: isDark ? Colors.white : const Color(0xFF0F172A),
          fontSize: 17,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _PremiumSwitchTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final bool value;
  final Function(bool) onChanged;

  const _PremiumSwitchTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return _SettingsCard(
      child: Row(
        children: [
          _IconBox(icon: icon, color: color),
          const SizedBox(width: 14),
          Expanded(
            child: _TileTexts(
              title: title,
              subtitle: subtitle,
            ),
          ),
          Switch(
            value: value,
            activeColor: color,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

class _PremiumActionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _PremiumActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return _SettingsCard(
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onTap,
        child: Row(
          children: [
            _IconBox(icon: icon, color: color),
            const SizedBox(width: 14),
            Expanded(
              child: _TileTexts(
                title: title,
                subtitle: subtitle,
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              size: 17,
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.white54
                  : const Color(0xFF9CA3AF),
            ),
          ],
        ),
      ),
    );
  }
}

class _TileTexts extends StatelessWidget {
  final String title;
  final String subtitle;

  const _TileTexts({
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
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
            height: 1.3,
          ),
        ),
      ],
    );
  }
}

class _ThemeSheet extends StatelessWidget {
  final String selected;
  final Function(String) onSelect;

  const _ThemeSheet({
    required this.selected,
    required this.onSelect,
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
              'Tema Seçimi',
              style: TextStyle(
                color: isDark ? Colors.white : const Color(0xFF0F172A),
                fontSize: 22,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 18),
            _ThemeOption(
              title: 'Sistem Teması',
              subtitle: 'Cihaz ayarına göre otomatik',
              icon: Icons.phone_android_rounded,
              value: 'system',
              selected: selected,
              onTap: onSelect,
            ),
            _ThemeOption(
              title: 'Açık Tema',
              subtitle: 'Aydınlık görünüm',
              icon: Icons.light_mode_rounded,
              value: 'light',
              selected: selected,
              onTap: onSelect,
            ),
            _ThemeOption(
              title: 'Koyu Tema',
              subtitle: 'Gece kullanımına uygun',
              icon: Icons.dark_mode_rounded,
              value: 'dark',
              selected: selected,
              onTap: onSelect,
            ),
          ],
        ),
      ),
    );
  }
}

class _ThemeOption extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final String value;
  final String selected;
  final Function(String) onTap;

  const _ThemeOption({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.value,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = selected == value;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ListTile(
      onTap: () => onTap(value),
      contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      leading: CircleAvatar(
        backgroundColor: isSelected
            ? const Color(0xFFEDE9FE)
            : isDark
            ? const Color(0xFF334155)
            : const Color(0xFFF3F4F6),
        child: Icon(
          icon,
          color: isSelected ? const Color(0xFF6D4AFF) : Colors.grey,
        ),
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
        isSelected
            ? Icons.check_circle_rounded
            : Icons.radio_button_unchecked_rounded,
        color: isSelected ? const Color(0xFF6D4AFF) : Colors.grey,
      ),
    );
  }
}

class _LogoutButton extends StatelessWidget {
  final VoidCallback onTap;

  const _LogoutButton({
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(24),
      onTap: onTap,
      child: Container(
        height: 58,
        decoration: BoxDecoration(
          color: const Color(0xFFFF3D57),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFFF3D57).withOpacity(0.24),
              blurRadius: 20,
              offset: const Offset(0, 9),
            ),
          ],
        ),
        child: const Center(
          child: Text(
            'Çıkış Yap',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16.5,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  final Widget child;

  const _SettingsCard({
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
      child: child,
    );
  }
}

class _IconBox extends StatelessWidget {
  final IconData icon;
  final Color color;

  const _IconBox({
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 54,
      height: 54,
      decoration: BoxDecoration(
        color: color.withOpacity(0.14),
        borderRadius: BorderRadius.circular(19),
      ),
      child: Icon(
        icon,
        color: color,
        size: 30,
      ),
    );
  }
}