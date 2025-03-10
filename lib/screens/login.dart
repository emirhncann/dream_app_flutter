import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'homepage.dart'; // Homepage ekranını import ettik

class AuthScreen extends StatefulWidget {
  @override
  _AuthScreenState createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoginMode = true;
  bool _isLoading = false;

  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Giriş veya kayıt işlemi
  Future<void> _submitAuthForm() async {
    setState(() {
      _isLoading = true;
    });

    try {
      if (_isLoginMode) {
        // Kullanıcı giriş yapıyor
        await _auth.signInWithEmailAndPassword(
          email: "emir@emir.com", //_emailController.text,
          password: "141414"//_passwordController.text,
        );
      } else {
        // Kullanıcı kayıt oluyor
        await _auth.createUserWithEmailAndPassword(
          email: _emailController.text,
          password: _passwordController.text,
        );
      }

      // Başarılı giriş veya kayıt sonrası kullanıcıyı yönlendiriyoruz
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => HomePage()), // Homepage ekranına yönlendirme
      );
    } on FirebaseAuthException catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message ?? 'Bir hata oluştu')),
      );
    }
  }

  // Modlar arasında geçiş fonksiyonu
  void _switchAuthMode() {
    setState(() {
      _isLoginMode = !_isLoginMode;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isLoginMode ? 'Giriş Yap' : 'Kayıt Ol'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _emailController,
              decoration: InputDecoration(labelText: 'E-posta'),
            ),
            SizedBox(height: 8),
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: InputDecoration(labelText: 'Şifre'),
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: _isLoading ? null : _submitAuthForm,
              child: _isLoading ? CircularProgressIndicator() : Text(_isLoginMode ? 'Giriş Yap' : 'Kayıt Ol'),
            ),
            TextButton(
              onPressed: _switchAuthMode,
              child: Text(_isLoginMode
                  ? 'Hesabınız yok mu? Kayıt Olun'
                  : 'Zaten bir hesabınız var mı? Giriş Yapın'),
            ),
          ],
        ),
      ),
    );
  }
}
