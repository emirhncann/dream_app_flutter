import 'package:dream_app_flutter/screens/homepage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class RegisterScreen extends StatefulWidget {
  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();

  bool _isLoading = false;

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Kullanıcıyı kaydetme
  Future<void> _registerUser() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Firebase Authentication ile kullanıcı kaydet
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: _emailController.text,
        password: _passwordController.text,
      );

      // Firestore'a kullanıcı bilgilerini kaydet
      String email = userCredential.user?.email ?? '';
      String firstName = _firstNameController.text;
      String lastName = _lastNameController.text;

      // Kullanıcı koleksiyonuna yeni kullanıcıyı ekle
      await _firestore.collection('users').doc(email).set({
        'email': email,
        'first_name': firstName,
        'last_name': lastName,
        'coin': 600,  // İlk kullanıcıya 600 coin ver
      });

      // Başarılı işlem sonrası bir mesaj göster
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Kayıt başarılı!')),
      );

      // Kayıt sonrası, kullanıcıyı yönlendir
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Kayıt Ol'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
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
            SizedBox(height: 8),
            TextField(
              controller: _firstNameController,
              decoration: InputDecoration(labelText: 'Ad'),
            ),
            SizedBox(height: 8),
            TextField(
              controller: _lastNameController,
              decoration: InputDecoration(labelText: 'Soyad'),
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: _isLoading ? null : _registerUser,
              child: _isLoading ? CircularProgressIndicator() : Text('Kayıt Ol'),
            ),
          ],
        ),
      ),
    );
  }
}
