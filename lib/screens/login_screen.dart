import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../services/auth_service.dart';
import '../services/settings_service.dart';
import 'home_screen.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _loading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    FocusScope.of(context).unfocus();

    setState(() {
      _loading = true;
    });

    try {
      await AuthService.login(
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );

      final user = FirebaseAuth.instance.currentUser;

      if (user != null && !user.emailVerified) {
        await AuthService.logout();

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Lütfen e-posta adresini doğrula. Doğrulama linki mail kutuna gönderilmişti.',
            ),
            backgroundColor: Colors.orange,
          ),
        );

        return;
      }

      await SettingsService.getSettings();

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => const HomeScreen(),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AuthService.getErrorMessage(e)),
          backgroundColor: Colors.redAccent,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  Future<void> _resendVerificationEmail() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Doğrulama maili için e-posta ve şifreyi gir.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _loading = true;
    });

    try {
      await AuthService.login(email, password);

      final user = FirebaseAuth.instance.currentUser;

      if (user != null && !user.emailVerified) {
        await user.sendEmailVerification();
        await AuthService.logout();

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Doğrulama maili tekrar gönderildi.'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        await AuthService.logout();

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Bu e-posta zaten doğrulanmış. Giriş yapabilirsin.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AuthService.getErrorMessage(e)),
          backgroundColor: Colors.redAccent,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  Future<void> _resetPassword() async {
    final email = _emailController.text.trim();

    if (email.isEmpty || !email.contains('@')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Şifre sıfırlamak için geçerli e-posta gir.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Şifre sıfırlama bağlantısı e-posta adresine gönderildi.'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AuthService.getErrorMessage(e)),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
      dark ? const Color(0xFF0F172A) : const Color(0xFFF5F7FB),
      body: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: dark
                ? [
              const Color(0xFF0F172A),
              const Color(0xFF111827),
              const Color(0xFF1E293B),
            ]
                : [
              const Color(0xFF6D4AFF),
              const Color(0xFF12D8FA),
              const Color(0xFFA6FFCB),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(22),
              child: Container(
                padding: const EdgeInsets.all(26),
                decoration: BoxDecoration(
                  color: dark ? const Color(0xFF1E293B) : Colors.white,
                  borderRadius: BorderRadius.circular(32),
                  border: dark ? Border.all(color: Colors.white10) : null,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(dark ? 0.28 : 0.10),
                      blurRadius: 24,
                      offset: const Offset(0, 12),
                    ),
                  ],
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      Container(
                        width: 88,
                        height: 88,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [
                              Color(0xFF6D4AFF),
                              Color(0xFF12D8FA),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(28),
                        ),
                        child: const Icon(
                          Icons.school_rounded,
                          color: Colors.white,
                          size: 44,
                        ),
                      ),

                      const SizedBox(height: 22),

                      Text(
                        'Tekrar Hoş Geldin 👋',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: dark ? Colors.white : const Color(0xFF0F172A),
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                        ),
                      ),

                      const SizedBox(height: 8),

                      Text(
                        'Gerçek e-posta adresinle giriş yap',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: dark ? Colors.white60 : Colors.black54,
                          fontSize: 14.5,
                          fontWeight: FontWeight.w500,
                        ),
                      ),

                      const SizedBox(height: 30),

                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        style: TextStyle(
                          color: dark ? Colors.white : Colors.black87,
                          fontWeight: FontWeight.w600,
                        ),
                        decoration: _inputDecoration(
                          context: context,
                          label: 'E-posta veya Kullanıcı Adı',
                          icon: Icons.person_rounded,
                        ),
                        validator: (value) {
                          final input = value?.trim() ?? '';

                          if (input.isEmpty) {
                            return 'E-posta veya kullanıcı adı boş olamaz';
                          }

                          if (input.length < 3) {
                            return 'En az 3 karakter gir';
                          }

                          return null;
                        },
                      ),

                      const SizedBox(height: 18),

                      TextFormField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        style: TextStyle(
                          color: dark ? Colors.white : Colors.black87,
                          fontWeight: FontWeight.w600,
                        ),
                        decoration: _inputDecoration(
                          context: context,
                          label: 'Şifre',
                          icon: Icons.lock_outline_rounded,
                          suffixIcon: IconButton(
                            onPressed: () {
                              setState(() {
                                _obscurePassword = !_obscurePassword;
                              });
                            },
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_rounded
                                  : Icons.visibility_off_rounded,
                            ),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Şifre boş olamaz';
                          }

                          if (value.length < 6) {
                            return 'Şifre en az 6 karakter olmalı';
                          }

                          return null;
                        },
                      ),

                      const SizedBox(height: 10),

                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: _loading ? null : _resetPassword,
                          child: const Text('Şifremi Unuttum'),
                        ),
                      ),

                      const SizedBox(height: 12),

                      SizedBox(
                        width: double.infinity,
                        height: 58,
                        child: ElevatedButton(
                          onPressed: _loading ? null : _login,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF6D4AFF),
                            foregroundColor: Colors.white,
                            elevation: 5,
                            shadowColor:
                            const Color(0xFF6D4AFF).withOpacity(0.32),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                            ),
                          ),
                          child: _loading
                              ? const SizedBox(
                            width: 26,
                            height: 26,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2.6,
                            ),
                          )
                              : const Text(
                            'Giriş Yap',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 14),

                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: OutlinedButton.icon(
                          onPressed:
                          _loading ? null : _resendVerificationEmail,
                          icon: const Icon(Icons.mark_email_read_rounded),
                          label: const Text('Doğrulama Mailini Tekrar Gönder'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF6D4AFF),
                            side: const BorderSide(
                              color: Color(0xFF6D4AFF),
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Hesabın yok mu?',
                            style: TextStyle(
                              color: dark ? Colors.white60 : Colors.black54,
                            ),
                          ),
                          TextButton(
                            onPressed: _loading
                                ? null
                                : () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                  const RegisterScreen(),
                                ),
                              );
                            },
                            child: const Text('Kayıt Ol'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration({
    required BuildContext context,
    required String label,
    required IconData icon,
    Widget? suffixIcon,
  }) {
    final dark = Theme.of(context).brightness == Brightness.dark;

    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(
        color: dark ? Colors.white60 : Colors.black54,
      ),
      prefixIcon: Icon(
        icon,
        color: dark ? Colors.white70 : Colors.black54,
      ),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: dark ? const Color(0xFF0F172A) : const Color(0xFFF5F7FB),
      errorMaxLines: 2,
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
          color: Color(0xFF6D4AFF),
          width: 1.5,
        ),
      ),
    );
  }
}