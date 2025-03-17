import 'package:dream_app_flutter/screens/comments.dart';
import 'package:dream_app_flutter/screens/dream.dart';
import 'package:dream_app_flutter/screens/homepage.dart';
import 'package:dream_app_flutter/screens/login.dart';
import 'package:dream_app_flutter/signin.dart';
import 'package:firebase_core/firebase_core.dart'; // Firebase Core Paketini import edin
import 'package:flutter/material.dart';
import 'package:dream_app_flutter/screens/auth_wrapper.dart';
import 'firebase_options.dart';
import 'package:provider/provider.dart';
import 'package:dream_app_flutter/providers/user_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(
    ChangeNotifierProvider(
      create: (_) => UserProvider(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Rüya Yorumu',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: AuthWrapper(), // LoginScreen yerine AuthWrapper kullanıyoruz
    );
  }
}
