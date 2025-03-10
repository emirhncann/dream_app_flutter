import 'package:dream_app_flutter/screens/comments.dart';
import 'package:dream_app_flutter/screens/dream.dart';
import 'package:dream_app_flutter/screens/homepage.dart';
import 'package:dream_app_flutter/screens/login.dart';
import 'package:dream_app_flutter/signin.dart';
import 'package:firebase_core/firebase_core.dart'; // Firebase Core Paketini import edin
import 'package:flutter/material.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized(); // Uygulama başlangıcında Firebase'i başlatabilmek için bu çağrıyı yapın
  await Firebase.initializeApp();  // Firebase'i başlatın
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: RegisterScreen(), // Giriş ekranını buraya ekliyoruz
    );
  }
}
