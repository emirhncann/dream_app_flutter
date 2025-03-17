import 'package:dream_app_flutter/screens/login.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:dream_app_flutter/screens/homepage.dart';


class AuthWrapper extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }
        
        if (snapshot.hasData && snapshot.data != null) {
          // Kullanıcı giriş yapmışsa HomePage'e yönlendir
          return HomePage();
        }
        
        // Kullanıcı giriş yapmamışsa LoginScreen'e yönlendir
        return AuthScreen();
      },
    );
  }
} 