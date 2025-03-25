import 'package:dream_app_flutter/screens/comments.dart';
import 'package:dream_app_flutter/screens/dream.dart';
import 'package:dream_app_flutter/screens/homepage.dart';
import 'package:dream_app_flutter/screens/login.dart';
import 'package:dream_app_flutter/signin.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:dream_app_flutter/screens/auth_wrapper.dart';
import 'firebase_options.dart';
import 'package:provider/provider.dart';
import 'package:dream_app_flutter/providers/user_provider.dart';
import 'package:flutter/foundation.dart';
import 'package:dream_app_flutter/screens/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => UserProvider()),
      ],
      child: MaterialApp(
        title: 'Rüya Yorumları',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          primaryColor: Color(0xFF6602ad),
          scaffoldBackgroundColor: Color(0xFF1d0042),
          colorScheme: ColorScheme.dark(
            primary: Color(0xFF6602ad),
            secondary: Color(0xFF8b64bd),
          ),
        ),
        home: SplashScreen(),
      ),
    );
  }
}
//carl jung a göre yorumlatacak