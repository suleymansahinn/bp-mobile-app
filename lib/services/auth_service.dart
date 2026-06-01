import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';

class AuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  static final FirebaseDatabase _db = FirebaseDatabase.instanceFor(
    app: Firebase.app(),
    databaseURL: 'https://yazimkurallari-3883f-default-rtdb.firebaseio.com/',
  );

  static User? get currentUser => _auth.currentUser;
  static String? get currentUid => _auth.currentUser?.uid;

  static DatabaseReference? get currentUserRef {
    final uid = currentUid;
    if (uid == null) return null;
    return _db.ref('users/$uid');
  }

  static String normalizeUsername(String username) {
    return username
        .trim()
        .toLowerCase()
        .replaceAll(' ', '')
        .replaceAll('ı', 'i')
        .replaceAll('İ', 'i')
        .replaceAll('ğ', 'g')
        .replaceAll('ü', 'u')
        .replaceAll('ş', 's')
        .replaceAll('ö', 'o')
        .replaceAll('ç', 'c');
  }

  static Future<bool> isUsernameAvailable(String username) async {
    final cleanUsername = normalizeUsername(username);

    final snapshot = await _db.ref('usernames/$cleanUsername').get();

    return !snapshot.exists;
  }

  static Future<String?> getEmailByUsername(String username) async {
    final cleanUsername = normalizeUsername(username);

    final snapshot = await _db.ref('usernames/$cleanUsername/email').get();

    if (!snapshot.exists || snapshot.value == null) {
      return null;
    }

    return snapshot.value.toString();
  }

  // 🔐 E-posta veya kullanıcı adı ile giriş
  static Future<void> login(String emailOrUsername, String password) async {
    final input = emailOrUsername.trim();

    String email = input;

    if (!input.contains('@')) {
      final foundEmail = await getEmailByUsername(input);

      if (foundEmail == null) {
        throw FirebaseAuthException(
          code: 'user-not-found',
          message: 'Bu kullanıcı adı bulunamadı',
        );
      }

      email = foundEmail;
    }

    await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password.trim(),
    );
  }

  // 📝 Kayıt
  static Future<void> register(
      String email,
      String password, {
        required String username,
      }) async {
    final cleanUsername = normalizeUsername(username);

    if (cleanUsername.length < 3) {
      throw FirebaseAuthException(
        code: 'invalid-username',
        message: 'Kullanıcı adı en az 3 karakter olmalı',
      );
    }

    final usernameRef = _db.ref('usernames/$cleanUsername');

    // Kullanıcı adını önce kilitle / rezerve et
    final transaction = await usernameRef.runTransaction((currentData) {
      if (currentData != null) {
        return Transaction.abort();
      }

      return Transaction.success({
        'reserved': true,
        'email': email.trim(),
        'createdAt': DateTime.now().toIso8601String(),
      });
    });

    if (!transaction.committed) {
      throw FirebaseAuthException(
        code: 'username-already-in-use',
        message: 'Bu kullanıcı adı zaten alınmış',
      );
    }

    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );

      final user = credential.user;
      if (user == null) {
        await usernameRef.remove();
        return;
      }

      await user.updateDisplayName(cleanUsername);

      await _db.ref('users/${user.uid}').set({
        'profile': {
          'username': cleanUsername,
          'email': email.trim(),
          'photoUrl': '',
          'emailVerified': false,
          'usernameChangeAllowed': false,
          'createdAt': DateTime.now().toIso8601String(),
        },
        'progress': {
          'xp': 0,
          'streak': 0,
          'lastLoginDate': '',
        },
        'badges': {
          'unlocked': [],
        },
        'dailyQuest': {
          'date': '',
          'solved': 0,
          'correct': 0,
          'quest1Claimed': false,
          'quest2Claimed': false,
        },
      });

      await usernameRef.update({
        'reserved': false,
        'uid': user.uid,
        'email': email.trim(),
        'completedAt': DateTime.now().toIso8601String(),
      });

      if (!user.emailVerified) {
        await user.sendEmailVerification();
      }
    } catch (e) {
      // Kayıt başarısız olursa username boşa çıksın
      await usernameRef.remove();
      rethrow;
    }
  }

  // 📩 Doğrulama mailini tekrar gönder
  static Future<void> sendVerificationEmail() async {
    final user = _auth.currentUser;

    if (user == null) {
      throw FirebaseAuthException(
        code: 'user-not-found',
        message: 'Aktif kullanıcı yok',
      );
    }

    await user.reload();

    final refreshedUser = _auth.currentUser;

    if (refreshedUser == null) {
      throw FirebaseAuthException(
        code: 'user-not-found',
        message: 'Aktif kullanıcı yok',
      );
    }

    if (!refreshedUser.emailVerified) {
      await refreshedUser.sendEmailVerification();
    }
  }

  static Future<bool> isEmailVerified() async {
    final user = _auth.currentUser;

    if (user == null) return false;

    await user.reload();

    return _auth.currentUser?.emailVerified ?? false;
  }

  // 🚪 Çıkış
  static Future<void> logout() async {
    await _auth.signOut();
  }

  // ❗ Firebase hata mesajlarını Türkçeleştir
  static String getErrorMessage(Object error) {
    if (error is FirebaseAuthException) {
      switch (error.code) {
        case 'user-not-found':
          return 'Bu e-posta veya kullanıcı adı ile kayıtlı kullanıcı bulunamadı';
        case 'wrong-password':
          return 'Şifre hatalı';
        case 'invalid-credential':
          return 'E-posta/kullanıcı adı veya şifre hatalı';
        case 'email-already-in-use':
          return 'Bu e-posta zaten kullanımda';
        case 'username-already-in-use':
          return 'Bu kullanıcı adı zaten alınmış';
        case 'invalid-username':
          return 'Kullanıcı adı en az 3 karakter olmalı';
        case 'invalid-email':
          return 'Geçersiz e-posta adresi';
        case 'weak-password':
          return 'Şifre en az 6 karakter olmalı';
        case 'user-disabled':
          return 'Bu kullanıcı devre dışı bırakılmış';
        case 'network-request-failed':
          return 'İnternet bağlantını kontrol et';
        case 'too-many-requests':
          return 'Çok fazla deneme yapıldı. Biraz bekleyip tekrar dene';
        default:
          return 'Bir hata oluştu (${error.code})';
      }
    }

    return 'Beklenmeyen bir hata oluştu';
  }
}