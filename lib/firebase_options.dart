import 'package:firebase_core/firebase_core.dart';

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform => android;

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: "AIzaSyCjxWZKuNC5VN6bqrV5XCjhKSjybEuUxtk",
    appId: "1:71664591084:android:d867ec90751c00eb5305c9",
    messagingSenderId: "71664591084",
    projectId: "yazimkurallari-3883f",
    databaseURL: "https://yazimkurallari-3883f-default-rtdb.firebaseio.com/",
  );
}