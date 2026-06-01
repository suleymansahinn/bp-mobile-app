import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../services/auth_service.dart';
import 'login_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();

  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _loading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  bool _isStrongPassword(String password) {
    return password.length >= 6;
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    FocusScope.of(context).unfocus();

    setState(() {
      _loading = true;
    });

    try {
      await AuthService.register(
        _emailController.text.trim(),
        _passwordController.text.trim(),
        username: _usernameController.text.trim(),
      );

      final user = FirebaseAuth.instance.currentUser;

      if (user != null && !user.emailVerified) {
        await user.sendEmailVerification();
      }

      if (!mounted) return;

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          title: const Text("Kayıt Başarılı 🎉"),
          content: Text(
            "${_emailController.text.trim()} adresine doğrulama bağlantısı gönderildi.\n\n"
                "Mailini doğruladıktan sonra giriş yapabilirsin.\n\n"
                "Not: Doğrulama maili Spam/Gereksiz klasörüne düşebilir. Lütfen orayı da kontrol et.",
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const LoginScreen(),
                  ),
                      (_) => false,
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6D4AFF),
                foregroundColor: Colors.white,
              ),
              child: const Text("Tamam"),
            ),
          ],
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
                  color: dark
                      ? const Color(0xFF1E293B)
                      : Colors.white,
                  borderRadius: BorderRadius.circular(32),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(
                        dark ? 0.28 : 0.10,
                      ),
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
                          Icons.person_add_alt_1_rounded,
                          color: Colors.white,
                          size: 42,
                        ),
                      ),

                      const SizedBox(height: 22),

                      Text(
                        "Hesap Oluştur",
                        style: TextStyle(
                          color: dark
                              ? Colors.white
                              : const Color(0xFF0F172A),
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                        ),
                      ),

                      const SizedBox(height: 8),

                      Text(
                        "Gerçek e-posta adresinle kayıt ol",
                        style: TextStyle(
                          color: dark
                              ? Colors.white60
                              : Colors.black54,
                        ),
                      ),

                      const SizedBox(height: 30),

                      // USERNAME
                      TextFormField(
                        controller: _usernameController,
                        style: TextStyle(
                          color: dark
                              ? Colors.white
                              : Colors.black87,
                        ),
                        decoration: InputDecoration(
                          labelText: "Kullanıcı Adı",
                          prefixIcon: const Icon(
                            Icons.person_outline_rounded,
                          ),
                          filled: true,
                          fillColor: dark
                              ? const Color(0xFF0F172A)
                              : const Color(0xFFF5F7FB),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(18),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return "Kullanıcı adı boş olamaz";
                          }

                          if (value.trim().length < 3) {
                            return "En az 3 karakter olmalı";
                          }

                          return null;
                        },
                      ),

                      const SizedBox(height: 18),

                      // EMAIL
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        style: TextStyle(
                          color: dark
                              ? Colors.white
                              : Colors.black87,
                        ),
                        decoration: InputDecoration(
                          labelText: "E-posta",
                          prefixIcon: const Icon(Icons.email_rounded),
                          filled: true,
                          fillColor: dark
                              ? const Color(0xFF0F172A)
                              : const Color(0xFFF5F7FB),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(18),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return "E-posta boş olamaz";
                          }

                          if (!value.contains("@") ||
                              !value.contains(".")) {
                            return "Geçerli bir e-posta gir";
                          }

                          return null;
                        },
                      ),

                      const SizedBox(height: 18),

                      // PASSWORD
                      TextFormField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        style: TextStyle(
                          color: dark
                              ? Colors.white
                              : Colors.black87,
                        ),
                        decoration: InputDecoration(
                          labelText: "Şifre",
                          prefixIcon: const Icon(Icons.lock_outline_rounded),
                          suffixIcon: IconButton(
                            onPressed: () {
                              setState(() {
                                _obscurePassword =
                                !_obscurePassword;
                              });
                            },
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_rounded
                                  : Icons.visibility_off_rounded,
                            ),
                          ),
                          filled: true,
                          fillColor: dark
                              ? const Color(0xFF0F172A)
                              : const Color(0xFFF5F7FB),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(18),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return "Şifre boş olamaz";
                          }

                          if (!_isStrongPassword(value)) {
                            return "Şifre en az 6 karakter olmalı";
                          }

                          return null;
                        },
                      ),

                      const SizedBox(height: 30),

                      SizedBox(
                        width: double.infinity,
                        height: 58,
                        child: ElevatedButton(
                          onPressed: _loading ? null : _register,
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                            const Color(0xFF6D4AFF),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius:
                              BorderRadius.circular(18),
                            ),
                          ),
                          child: _loading
                              ? const SizedBox(
                            width: 26,
                            height: 26,
                            child:
                            CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2.6,
                            ),
                          )
                              : const Text(
                            "Kayıt Ol",
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 18),

                      TextButton(
                        onPressed: () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                              const LoginScreen(),
                            ),
                          );
                        },
                        child: const Text(
                          "Zaten hesabın var mı? Giriş Yap",
                        ),
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
}