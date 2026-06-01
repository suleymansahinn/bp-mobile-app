import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CloudService {
  static final _firestore = FirebaseFirestore.instance;
  static final _auth = FirebaseAuth.instance;

  static String get _uid => _auth.currentUser!.uid;

  /// 🔹 Kullanıcı doküman referansı
  static DocumentReference get _userDoc =>
      _firestore.collection('users').doc(_uid);

  /// 🔹 Kullanıcı verisini kaydet / güncelle
  static Future<void> saveUserData({
    required int xp,
    required int level,
    required int streak,
    required List<String> badges,
    required String lastDate,
  }) async {
    await _userDoc.set({
      'xp': xp,
      'level': level,
      'streak': streak,
      'badges': badges,
      'lastDate': lastDate,
    }, SetOptions(merge: true));
  }

  /// 🏆 Açılmış rozetleri getir
  static Future<List<String>> getUnlockedBadges() async {
    final doc = await _userDoc.get();

    if (!doc.exists) return [];

    final data = doc.data() as Map<String, dynamic>;
    final badges = data['badges'];

    if (badges == null) return [];

    return List<String>.from(badges);
  }

  /// 🏆 Yeni rozet ekle
  static Future<void> addBadge(String badgeId) async {
    await _userDoc.update({
      'badges': FieldValue.arrayUnion([badgeId]),
    });
  }
}
